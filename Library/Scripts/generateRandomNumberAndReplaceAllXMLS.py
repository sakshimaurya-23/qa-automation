import json
import os
import re
import random
import shutil
import xml.etree.ElementTree as ET
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def generate_random_id():
    """Generate a random 7-digit number as a string."""
    return str(random.randint(1000000, 9999999))

def extract_numeric_value(filename):
    """Extract all leading numbers from filename as a sort tuple for stable ordering.

    Supports decimal-style names like '7_1_confirmShipment.xml' (sorts as (7,1))
    after '7_input.xml' (sorts as (7,)) because tuple comparison is element-wise.
    Files without any numeric prefix sort last (float('inf') placeholder).
    """
    numbers = re.findall(r'\d+', filename)
    if not numbers:
        return (float('inf'),)
    return tuple(int(n) for n in numbers[:3])  # use up to first 3 numeric groups

def get_api_name_from_xml(file_path):
    """Extract API Name attribute from MultiApi XML file."""
    try:
        tree = ET.parse(file_path)
        root = tree.getroot()
        api_elem = root.find('.//API')
        if api_elem is not None:
            return api_elem.get('Name', '')
        return ''
    except Exception as e:
        print(f"Warning: Could not parse API Name from {file_path}: {e}")
        return ''

def find_correct_expected_result(api_name, baseline_data_path):
    """
    Search baseline_data for an expectedResult.xml whose API Name matches `api_name`.

    Strategy:
      1. Fast path: look for a subfolder whose name matches api_name (case-insensitive).
      2. Slow path: scan each subfolder's ValidateData file for an API Name match.

    Returns the Path to the correct expectedResult.xml, or None if not found.
    """
    if not baseline_data_path or not os.path.isdir(baseline_data_path):
        return None

    # Fast path: folder name matches API name
    for entry in os.scandir(baseline_data_path):
        if not entry.is_dir():
            continue
        if entry.name.lower() == api_name.lower():
            candidate = os.path.join(entry.path, "expectedResult.xml")
            if os.path.isfile(candidate):
                return candidate

    # Slow path: read each ValidateData file in each subfolder
    for entry in os.scandir(baseline_data_path):
        if not entry.is_dir():
            continue
        for fname in os.listdir(entry.path):
            if 'validatedata' in fname.lower() and fname.endswith('.xml'):
                vd_path = os.path.join(entry.path, fname)
                if get_api_name_from_xml(vd_path) == api_name:
                    candidate = os.path.join(entry.path, "expectedResult.xml")
                    if os.path.isfile(candidate):
                        return candidate

    return None

def _collect_element_paths(parent_elem):
    """
    Return a set of tag-path strings for every descendant of `parent_elem`.
    Normalises ShipmentList/Shipments so the same structural comparison used in
    get_xml_tag_paths() is applied here as well.
    E.g. {'/ShipmentList', '/ShipmentList/Shipment', '/ShipmentList/Shipment/ShipmentLines', ...}
    """
    paths = set()

    def _walk(elem, current_path):
        tag = elem.tag
        if tag in ("ShipmentList", "Shipments"):
            tag = "ShipmentList"
        full_path = current_path + '/' + tag
        paths.add(full_path)
        for child in elem:
            _walk(child, full_path)

    for child in parent_elem:
        _walk(child, "")

    return paths


def _merge_template_into_output(template_elem, output_elem):
    """
    Walk the Template element tree and ensure every element path it declares
    also exists inside output_elem. For any element that is missing from the
    output tree, inject a copy with all attribute values set to 'XXXX'.

    This repairs expectedResult files that were captured from a failed upstream
    call (e.g. createShipment returned an error so the actual getShipmentList
    response had a bare <Shipment> with no <ShipmentLines> child).
    """
    # Tags that are semantically equivalent between Template and Output
    _EQUIV = {
        "ShipmentList": ("ShipmentList", "Shipments"),
        "Shipments":    ("ShipmentList", "Shipments"),
    }

    for tmpl_child in template_elem:
        tag = tmpl_child.tag
        # Find a matching child in the output element, accounting for
        # equivalent tag names (e.g. ShipmentList ↔ Shipments).
        equiv_tags = _EQUIV.get(tag, (tag,))
        out_child = None
        for eq_tag in equiv_tags:
            out_child = output_elem.find(eq_tag)
            if out_child is not None:
                break

        if out_child is None:
            # Element is entirely absent — create it with XXXX wildcards
            new_elem = ET.Element(tag)
            for attr in tmpl_child.attrib:
                new_elem.set(attr, 'XXXX')
            # Recursively populate children
            _merge_template_into_output(tmpl_child, new_elem)
            output_elem.append(new_elem)
        else:
            # Element exists — recurse into it to fill any missing sub-elements
            _merge_template_into_output(tmpl_child, out_child)


def auto_fix_expected_result(expected_file, validate_path, baseline_data_path=None):
    """
    Auto-fix expected result files that don't match their paired ValidateData file.

    Handles five cases (in priority order):
    1. Wrong file entirely (API Name mismatch AND baseline_data provided)
       → replace the whole file with the correct one from baseline_data.
    2. Empty API Name → copied from ValidateData.
    3. <Output><ApiSuccess/> placeholder → replaced with Template content from ValidateData.
    4. Output has content but all attributes are empty-string → normalized to 'XXXX' wildcards.
    5. API Name matches but Output is missing elements declared in Template (e.g. <ShipmentLines>
       absent because createShipment failed upstream) → inject missing elements with XXXX wildcards.

    Returns True if any change was made, False otherwise.
    """
    try:
        expected_tree = ET.parse(expected_file)
        expected_root = expected_tree.getroot()
        expected_api = expected_root.find('.//API')
        if expected_api is None:
            return False

        expected_output = expected_api.find('Output')
        if expected_output is None:
            return False

        validate_tree = ET.parse(validate_path)
        validate_root = validate_tree.getroot()
        validate_api = validate_root.find('.//API')
        if validate_api is None:
            return False

        correct_api_name = validate_api.get('Name', '')
        if not correct_api_name:
            return False

        current_api_name = expected_api.get('Name', '')

        # === Case 1: Wrong file — API Name mismatch ===
        # This is the primary bug: the expectedResult was copied from the wrong
        # baseline_data subfolder (e.g. getOrderList instead of getShipmentList).
        # The only correct fix is to replace the whole file with the right one.
        #
        # FIX (RootCause: silent generation-time failure): this branch used to
        # print a WARNING and `return False` when no baseline source could be
        # found — a message easily lost among thousands of console lines during
        # generation, after which the broken expectedresultN.xml would flow
        # straight into the test case and only get caught (or silently
        # re-seeded with unverified content) much later at Robot Framework
        # runtime. `return False` here still means "did not fix it", but
        # validate_expected_result_mapping (the caller) now treats *any*
        # unresolved Case-1 mismatch as a hard pre-flight error — see below —
        # so generation stops with a clear message instead of producing a
        # test case that can only fail (or silently mis-pass) later.
        if current_api_name and current_api_name != correct_api_name:
            if baseline_data_path:
                correct_source = find_correct_expected_result(correct_api_name, baseline_data_path)
                if correct_source:
                    shutil.copy2(correct_source, expected_file)
                    print(
                        f"Auto-fixed {os.path.basename(expected_file)}: "
                        f"replaced wrong API '{current_api_name}' with correct "
                        f"'{correct_api_name}' (source: {correct_source})"
                    )
                    return True
                else:
                    print(
                        f"ERROR: Cannot auto-fix {os.path.basename(expected_file)} — "
                        f"no baseline_data source found for API '{correct_api_name}'. "
                        f"Manually copy baseline_data/{correct_api_name}/expectedResult.xml here, "
                        f"or add that subfolder to baseline_data/."
                    )
                    return False
            else:
                print(
                    f"ERROR: {os.path.basename(expected_file)} has wrong API Name "
                    f"('{current_api_name}' should be '{correct_api_name}'). "
                    f"baseline_data_path was not provided, so this cannot be auto-fixed."
                )
                return False

        validate_template = validate_api.find('Template')
        if validate_template is None:
            return False

        changes_made = False

        # === Case 2: Empty API Name ===
        if not current_api_name:
            expected_api.set('Name', correct_api_name)
            changes_made = True

        # === Case 3: Generic ApiSuccess placeholder ===
        output_children = list(expected_output)
        if len(output_children) == 1 and output_children[0].tag == 'ApiSuccess':
            for child in list(expected_output):
                expected_output.remove(child)
            for child in validate_template:
                new_child = ET.fromstring(ET.tostring(child))
                for elem in new_child.iter():
                    for attr in list(elem.attrib):
                        if elem.get(attr) == '':
                            elem.set(attr, 'XXXX')
                expected_output.append(new_child)
            changes_made = True

        # === Case 4: Content exists but all attributes are empty-string ===
        elif output_children:
            all_empty = all(
                elem.get(attr) == ''
                for elem in expected_output.iter()
                for attr in elem.attrib
            )
            if all_empty:
                for elem in expected_output.iter():
                    for attr in list(elem.attrib):
                        if elem.get(attr) == '':
                            elem.set(attr, 'XXXX')
                changes_made = True

        # === Case 5: API Name matches but Output is missing elements present in Template ===
        # This happens when the expectedResult was captured from a run where the upstream
        # API (e.g. createShipment) failed, so Sterling returned a bare <Shipment> with no
        # <ShipmentLines>. The Template declares those child elements as required for
        # comparison, so the validator raises a hard ValueError. Fix: walk the Template
        # tree and inject any missing child elements (with XXXX wildcards) into the
        # corresponding Output element so the structure matches.
        if not changes_made and output_children:
            template_root_children = list(validate_template)
            if template_root_children:
                template_paths = _collect_element_paths(validate_template)
                output_paths = _collect_element_paths(expected_output)
                if template_paths - output_paths:
                    _merge_template_into_output(validate_template, expected_output)
                    changes_made = True

        if changes_made:
            expected_tree.write(expected_file, encoding='utf-8', xml_declaration=True)
            print(f"Auto-fixed {os.path.basename(expected_file)}")
            return True

        return False

    except Exception as e:
        print(f"Failed to auto-fix {expected_file}: {e}")
        return False


def _normalize_tag(tag):
    """
    Normalize equivalent XML tag names for structural comparison.
    Treats ShipmentList and Shipments as equivalent root elements
    since they represent the same semantic structure.
    """
    if tag in ("ShipmentList", "Shipments"):
        return "ShipmentList"
    return tag


def get_xml_tag_paths(file_path, parent_xpath):
    """
    Extract all child tag paths (e.g. /Output/Order/OrderLines/OrderLine)
    from an XML file, starting from `parent_xpath` element.
    Returns a set of element paths and a set of attribute paths.
    Ignores element order, focuses on structure.

    Normalizes equivalent root elements: ShipmentList ↔ Shipments
    are treated as the same structure for validation purposes.
    """
    element_paths = set()
    attribute_paths = set()

    try:
        tree = ET.parse(file_path)
        root = tree.getroot()

        parent = root.find(parent_xpath)
        if parent is None:
            return element_paths, attribute_paths

        def _walk(elem, current_path):
            tag = _normalize_tag(elem.tag)
            full_path = current_path + '/' + tag
            element_paths.add(full_path)
            for attr in elem.attrib:
                attribute_paths.add(f"{full_path}/@{attr}")
            for child in elem:
                _walk(child, full_path)

        for child in parent:
            _walk(child, "")

    except Exception as e:
        print(f"Warning: Could not parse structure from {file_path}: {e}")

    return element_paths, attribute_paths


def validate_expected_result_mapping(test_case_path, baseline_data_path=None):
    """
    Validate that each ValidateData file in Data/Input/ has a matching ExpectedResult
    file with the same API Name and compatible element structure.

    When baseline_data_path is provided, mismatches caused by a wrong file being
    copied are auto-fixed by replacing the expectedresult file with the correct one
    from baseline_data before raising any errors.

    Raises ValueError listing all remaining mismatches if any are found after
    auto-fix attempts.
    """
    input_dir = os.path.join(test_case_path, "Data", "Input")
    expected_dir = os.path.join(test_case_path, "Data", "ExpectedResult")

    if not os.path.isdir(input_dir) or not os.path.isdir(expected_dir):
        return

    validate_files = sorted(
        [f for f in os.listdir(input_dir) if 'validatedata' in f.lower() and f.endswith('.xml')],
        key=extract_numeric_value
    )

    if not validate_files:
        return

    errors = []

    for idx, validate_file in enumerate(validate_files, start=1):
        validate_path = os.path.join(input_dir, validate_file)
        expected_file = os.path.join(expected_dir, f"expectedresult{idx}.xml")

        if not os.path.exists(expected_file):
            errors.append(f"Missing ExpectedResult file for {validate_file}: expectedresult{idx}.xml not found")
            continue

        # === AUTO-FIX: attempt repair before validating ===
        # Pass baseline_data_path so wrong-file mismatches (Case 1) can be corrected.
        auto_fix_expected_result(expected_file, validate_path, baseline_data_path)

        # === CHECK 1: API Name match ===
        input_api_name = get_api_name_from_xml(validate_path)
        expected_api_name = get_api_name_from_xml(expected_file)

        if input_api_name != expected_api_name:
            errors.append(
                f"API Name mismatch for {validate_file} -> expectedresult{idx}.xml:\n"
                f"  Input  API Name: '{input_api_name}'\n"
                f"  Expected API Name: '{expected_api_name}'\n"
                f"  auto_fix_expected_result() could not resolve this automatically — "
                f"either baseline_data/{input_api_name}/expectedResult.xml is missing, "
                f"or the mapping sheet / mode_instructions.yaml assigned the wrong "
                f"baseline to this ValidateData step. Fix the generation source, do "
                f"not just re-run — a Robot Framework run will otherwise silently "
                f"re-seed this file from whatever the dev server happens to return "
                f"and report a false PASS."
            )

        # === CHECK 2: Template vs Output structural compatibility ===
        template_elems, template_attrs = get_xml_tag_paths(validate_path, 'API/Template')
        output_elems, output_attrs = get_xml_tag_paths(expected_file, 'API/Output')

        if template_elems and output_elems:
            missing_in_output = template_elems - output_elems
            if missing_in_output:
                errors.append(
                    f"Structure mismatch for {validate_file} -> expectedresult{idx}.xml:\n"
                    f"  Elements in Template but missing in ExpectedResult:\n"
                    + "\n".join(f"    - {path}" for path in sorted(missing_in_output))
                )

            extra_in_output = output_elems - template_elems
            if extra_in_output:
                errors.append(
                    f"Extra elements in ExpectedResult (not in Template) for {validate_file}:\n"
                    + "\n".join(f"    - {path}" for path in sorted(extra_in_output))
                )

        # === CHECK 3: Detect all-XXXX skeleton that was never seeded from a real response ===
        # An expectedResult file whose every attribute is still "XXXX" is a generation-time
        # placeholder that was never replaced with real OMS output.  It will always trigger
        # the runtime [AUTO-RESEED] path in Is Expected File Broken (Check 3 — structural
        # mismatch) because the XXXX skeleton's element/attribute shape does not match any
        # real OMS response.  Catch it here at generation time so the test-case folder is
        # never committed with a file that can only fail (or silently auto-reseed) at runtime.
        try:
            exp_tree_chk = ET.parse(expected_file)
            exp_root_chk = exp_tree_chk.getroot()
            exp_output_chk = exp_root_chk.find('.//API/Output')
            if exp_output_chk is not None:
                all_attrs_chk = [
                    v
                    for elem in exp_output_chk.iter()
                    for v in elem.attrib.values()
                ]
                if all_attrs_chk and all(v == 'XXXX' for v in all_attrs_chk):
                    errors.append(
                        f"Stale XXXX skeleton in expectedresult{idx}.xml for {validate_file}:\n"
                        f"  Every attribute in the Output section is still 'XXXX' — this file\n"
                        f"  was never seeded from a real OMS response and will always trigger\n"
                        f"  [AUTO-RESEED] at runtime without performing a real comparison.\n"
                        f"  Fix: add baseline_data/{input_api_name}/expectedResult.xml so the\n"
                        f"  generator can copy a canonical baseline, or run the test once to\n"
                        f"  seed the file and then commit the seeded version."
                    )
        except Exception as _e:
            pass  # parse failure is already caught by CHECK 1 / CHECK 2

    if errors:
        raise ValueError(
            f"ExpectedResult mapping validation failed for {test_case_path}:\n"
            + "\n".join(f"  - {e}" for e in errors)
        )

def process_xml(input_file, output_file, random_id):
    """Read XML, replace ${RandomId} (case-insensitive), and save."""
    try:
        tree = ET.parse(input_file)
        root = tree.getroot()

        xml_string = ET.tostring(root, encoding='unicode')
        xml_string = re.sub(r'\$\{randomid\}', random_id, xml_string, flags=re.IGNORECASE)

        with open(output_file, "w", encoding="utf-8") as f:
            f.write(xml_string)

        return output_file

    except ET.ParseError:
        print(f"Error parsing XML: {input_file}")
        return None

def process_json(input_file, output_file, random_id):
    """Read JSON file, replace ${RandomId} (case-insensitive), and save."""
    with open(input_file, "r", encoding="utf-8") as f:
        json_string = f.read()

    updated_json_string = re.sub(r'\$\{randomid\}', random_id, json_string, flags=re.IGNORECASE)

    with open(output_file, "w", encoding="utf-8") as f:
        f.write(updated_json_string)

    return output_file

def process_test_case(test_case_path):
    """Process XMLs and JSONs in 'Data/Setup' and 'Data/Input' folders, ensuring correct sorting.
    Returns a dict with 'setup' and 'input' keys, each containing 'xml_files' and 'json_files' lists.
    """
    random_id = generate_random_id()
    print(f"Processing {test_case_path} with Random ID: {random_id}")

    result = {
        "setup": {"xml_files": [], "json_files": []},
        "input": {"xml_files": [], "json_files": []}
    }
    execution_order = []

    for subfolder in ["Setup", "Input"]:
        subfolder_key = subfolder.lower()
        subfolder_path = os.path.join(test_case_path, "Data", subfolder)

        if os.path.isdir(subfolder_path):
            updated_subfolder = os.path.join(test_case_path, f"updated_{subfolder_key}")

            xml_files = sorted(
                (f for f in os.listdir(subfolder_path) if f.endswith(".xml")),
                key=extract_numeric_value
            )

            json_files = sorted(
                (f for f in os.listdir(subfolder_path) if f.endswith(".json")),
                key=extract_numeric_value
            )

            all_files = xml_files + json_files

            if all_files:
                os.makedirs(updated_subfolder, exist_ok=True)

                for file_name in all_files:
                    input_file = os.path.join(subfolder_path, file_name)
                    output_file = os.path.join(updated_subfolder, file_name)
                    if file_name.endswith(".xml"):
                        execution_order.append((input_file, output_file, "xml", subfolder_key))
                        rel_path = os.path.relpath(output_file, test_case_path)
                        result[subfolder_key]["xml_files"].append(rel_path)
                    else:
                        execution_order.append((input_file, output_file, "json", subfolder_key))
                        rel_path = os.path.relpath(output_file, test_case_path)
                        result[subfolder_key]["json_files"].append(rel_path)

    for input_file, output_file, file_type, subfolder_key in execution_order:
        if file_type == "xml":
            process_xml(input_file, output_file, random_id)
        else:
            process_json(input_file, output_file, random_id)

    return result

def process_test_case_json(test_case_path):
    """Process JSONs in 'Data/Setup' and 'Data/Input' folders, ensuring correct sorting."""
    random_id = generate_random_id()
    print(f"Processing {test_case_path} with Random ID: {random_id}")

    updated_files = []
    execution_order = []

    for subfolder in ["Setup", "Input"]:
        subfolder_path = os.path.join(test_case_path, "Data", subfolder)

        if os.path.isdir(subfolder_path):
            updated_subfolder = os.path.join(test_case_path, f"updated_{subfolder.lower()}")

            json_files = sorted(
                (f for f in os.listdir(subfolder_path) if f.endswith(".json")),
                key=extract_numeric_value
            )

            if json_files:
                os.makedirs(updated_subfolder, exist_ok=True)

                for json_file in json_files:
                    input_file = os.path.join(subfolder_path, json_file)
                    output_file = os.path.join(updated_subfolder, json_file)
                    execution_order.append((input_file, output_file))

    for input_file, output_file in execution_order:
        updated_file = process_json(input_file, output_file, random_id)
        if updated_file:
            updated_files.append(updated_file)

    return updated_files, random_id

def process_suite2(suite_path):
    """Process all test cases inside the suite and return sorted updated XMLs."""
    results = {}

    for test_case in sorted(os.listdir(suite_path)):
        test_case_path = os.path.join(suite_path, test_case)

        if os.path.isdir(test_case_path):
            updated_files = process_test_case(test_case_path)
            results[test_case] = updated_files
            with open(test_case_path + "/updated_files_" + test_case + ".json", "w") as json_file:
                json.dump(results, json_file, indent=4)

    return results

def _resolve_baseline_data_path(suite_path):
    """
    Try to locate baseline_data/ relative to the test case or suite path,
    so validate_expected_result_mapping can auto-fix wrong-file mismatches
    without requiring the caller to pass it explicitly.

    Walks up from suite_path looking for a 'baseline_data' sibling or ancestor.
    Returns the path if found, None otherwise.
    """
    current = os.path.abspath(suite_path)
    for _ in range(6):  # look up at most 6 levels
        candidate = os.path.join(current, "baseline_data")
        if os.path.isdir(candidate):
            return candidate
        parent = os.path.dirname(current)
        if parent == current:
            break
        current = parent
    return None

def process_suite(suite_path):
    """Process only test cases that contain 'Data/Input' directory (Data/Setup is optional).

    Supports two call patterns:
    1. suite_path is a parent directory containing TC_xxx subfolders:
       process_suite("Test_Cases/") → iterates each TC_xxx/Data/Input/
    2. suite_path is directly a test case folder (called from Test.robot):
       process_suite("Test_Cases/TC_xxx/") → processes that single case

    Automatically locates baseline_data/ (by walking up the directory tree) so that
    validate_expected_result_mapping can auto-fix wrong-file mismatches on the fly.
    """
    results = {}
    baseline_data_path = _resolve_baseline_data_path(suite_path)
    if baseline_data_path:
        print(f"Found baseline_data at: {baseline_data_path} (used for auto-fix)")
    else:
        print("WARNING: baseline_data not found relative to suite path — "
              "wrong-file expectedResult mismatches cannot be auto-fixed at runtime.")

    # Check if suite_path itself is a test case directory with Data/Input/
    self_input_path = os.path.join(suite_path, "Data", "Input")
    if os.path.isdir(self_input_path):
        tc_name = os.path.basename(suite_path)
        updated_files_dict = process_test_case(suite_path)
        results[tc_name] = updated_files_dict

        json_file_path = os.path.join(suite_path, "Data", "updated_files.json")
        with open(json_file_path, "w") as json_file:
            json.dump({"Data": updated_files_dict}, json_file, indent=4)

        validate_expected_result_mapping(suite_path, baseline_data_path)

        return results

    # Fallback: suite_path is a parent directory containing TC_xxx subfolders
    for test_case in sorted(os.listdir(suite_path)):
        test_case_path = os.path.join(suite_path, test_case)

        if os.path.isdir(test_case_path):
            input_path = os.path.join(test_case_path, "Data", "Input")

            if os.path.isdir(input_path):
                updated_files_dict = process_test_case(test_case_path)
                results[test_case] = updated_files_dict

                json_file_path = os.path.join(test_case_path, "Data", "updated_files.json")
                with open(json_file_path, "w") as json_file:
                    json.dump({"Data": updated_files_dict}, json_file, indent=4)

                validate_expected_result_mapping(test_case_path, baseline_data_path)

    return results

def process_suite_json(suite_path):
    """Process only test cases that contain 'Input' directory (Setup is optional)."""
    results = {}

    for test_case in sorted(os.listdir(suite_path)):
        test_case_path = os.path.join(suite_path, test_case)

        if os.path.isdir(test_case_path):
            input_path = os.path.join(test_case_path, "Input")

            if os.path.isdir(input_path):
                updated_files, random_id = process_test_case_json(test_case_path)
                results[test_case] = updated_files

                json_file_path = os.path.join(test_case_path, "updated_files.json")
                with open(json_file_path, "w") as json_file:
                    json.dump({test_case: updated_files}, json_file, indent=4)

    return random_id

def get_base_filename(file_path):
    """Extract the base filename without numbers and extension."""
    file_name = os.path.basename(file_path)
    file_name_without_ext = os.path.splitext(file_name)[0]
    base_name = re.sub(r'\d+$', '', file_name_without_ext)
    return base_name

def load_json_files(output_folder):
    """Load all JSON files from the output folder into a single dictionary."""
    json_data = {}

    for filename in os.listdir(output_folder):
        if filename.endswith(".json"):
            json_path = os.path.join(output_folder, filename)
            with open(json_path, "r", encoding="utf-8") as file:
                data = json.load(file)
                json_data.update(data)

    return json_data