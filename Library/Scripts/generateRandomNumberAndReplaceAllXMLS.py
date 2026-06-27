import json
import os
import re
import random
import xml.etree.ElementTree as ET
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def generate_random_id():
    """Generate a random 7-digit number as a string."""
    return str(random.randint(1000000, 9999999))

def extract_numeric_value(filename):
    """Extract the first number from filename for sorting."""
    numbers = re.findall(r'\d+', filename)  # Find all numbers
    return int(numbers[0]) if numbers else float('inf')

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

def get_xml_tag_paths(file_path, parent_xpath):
    """
    Extract all child tag paths (e.g. /Output/Order/OrderLines/OrderLine)
    from an XML file, starting from `parent_xpath` element.
    Returns a set of paths (tuples) and a set of attribute paths.
    Ignores element order, focuses on structure.
    """
    element_paths = set()
    attribute_paths = set()

    try:
        tree = ET.parse(file_path)
        root = tree.getroot()

        # Find the parent element
        parent = root.find(parent_xpath)
        if parent is None:
            return element_paths, attribute_paths

        def _walk(elem, current_path):
            tag = elem.tag
            full_path = current_path + '/' + tag
            element_paths.add(full_path)

            # Collect attributes at this level
            for attr in elem.attrib:
                attribute_paths.add(f"{full_path}/@{attr}")

            for child in elem:
                _walk(child, full_path)

        for child in parent:
            _walk(child, f"/{root.tag}/{parent.tag}")

    except Exception as e:
        print(f"Warning: Could not parse structure from {file_path}: {e}")

    return element_paths, attribute_paths


def validate_expected_result_mapping(test_case_path):
    """
    Validate that each ValidateData file in Input/ has a matching ExpectedResult file
    with the same API Name. This catches mismatches like getOrderList vs getOrderDetails.
    Also validates structural compatibility between the ValidateData Template and
    the ExpectedResult Output, catching issues like:
    - Wrong element tag names
    - Missing or extra required elements/attributes
    - Structural hierarchy mismatches
    """
    input_dir = os.path.join(test_case_path, "Input")
    expected_dir = os.path.join(test_case_path, "ExpectedResult")

    if not os.path.isdir(input_dir) or not os.path.isdir(expected_dir):
        return  # Skip if directories don't exist

    # Find all ValidateData files in Input/
    validate_files = sorted(
        [f for f in os.listdir(input_dir) if 'validatedata' in f.lower() and f.endswith('.xml')],
        key=extract_numeric_value
    )

    if not validate_files:
        return  # No ValidateData files to validate

    errors = []

    for idx, validate_file in enumerate(validate_files, start=1):
        validate_path = os.path.join(input_dir, validate_file)
        expected_file = os.path.join(expected_dir, f"expectedresult{idx}.xml")

        if not os.path.exists(expected_file):
            errors.append(f"Missing ExpectedResult file for {validate_file}: expectedresult{idx}.xml not found")
            continue

        # === CHECK 1: Compare API Names ===
        input_api_name = get_api_name_from_xml(validate_path)
        expected_api_name = get_api_name_from_xml(expected_file)

        if input_api_name != expected_api_name:
            errors.append(
                f"API Name mismatch for {validate_file}:\n"
                f"  Input  API Name: '{input_api_name}'\n"
                f"  Expected API Name: '{expected_api_name}'"
            )

        # === CHECK 2: Compare Template vs Output structural compatibility ===
        # Extract tag structure from the Template section of ValidateData
        template_elems, template_attrs = get_xml_tag_paths(validate_path, 'MultiApi/API/Template')
        # Extract tag structure from the Output section of ExpectedResult
        output_elems, output_attrs = get_xml_tag_paths(expected_file, 'MultiApi/API/Output')

        # Skip structural check if either is empty (e.g. ApiSuccess response or simple response)
        if template_elems and output_elems:
            # Check for template elements missing in expected output
            missing_in_output = template_elems - output_elems
            if missing_in_output:
                errors.append(
                    f"Structure mismatch for {validate_file} -> expectedresult{idx}.xml:\n"
                    f"  Elements in Template but missing in ExpectedResult:\n"
                    + "\n".join(f"    - {path}" for path in sorted(missing_in_output))
                )

            # Check for output elements not found in template
            extra_in_output = output_elems - template_elems
            if extra_in_output:
                errors.append(
                    f"Extra elements in ExpectedResult (not in Template) for {validate_file}:\n"
                    + "\n".join(f"    - {path}" for path in sorted(extra_in_output))
                )

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

        # Convert tree to string, replace ${RandomId} ignoring case
        xml_string = ET.tostring(root, encoding='unicode')
        xml_string = re.sub(r'\$\{randomid\}', random_id, xml_string, flags=re.IGNORECASE)

        # Save updated XML
        with open(output_file, "w", encoding="utf-8") as f:
            f.write(xml_string)

        return output_file  # Return updated file path

    except ET.ParseError:
        print(f"Error parsing XML: {input_file}")
        return None

def process_json(input_file, output_file, random_id):
    """Read JSON file, replace ${RandomId} (case-insensitive), and save."""

    # Read JSON file as text
    with open(input_file, "r", encoding="utf-8") as f:
        json_string = f.read()

    # Replace ${RandomId} (case-insensitive)
    updated_json_string = re.sub(r'\$\{randomid\}', random_id, json_string, flags=re.IGNORECASE)

    # Save updated JSON string to output file
    with open(output_file, "w", encoding="utf-8") as f:
        f.write(updated_json_string)

    return output_file  # Return updated file path

def process_test_case(test_case_path):
    """Process XMLs and JSONs in 'Input' and 'Setup' folders, ensuring correct sorting."""
    random_id = generate_random_id()
    print(f"Processing {test_case_path} with Random ID: {random_id}")

    updated_files = []
    execution_order = []

    # Only consider 'Setup' and 'Input' directories (Setup first to ensure it runs before Input)
    for subfolder in ["Setup", "Input"]:
        subfolder_path = os.path.join(test_case_path, subfolder)

        if os.path.isdir(subfolder_path):  # Ensure the folder exists
            updated_subfolder = os.path.join(test_case_path, f"updated_{subfolder.lower()}")

            # Get XML files in sorted order
            xml_files = sorted(
                (f for f in os.listdir(subfolder_path) if f.endswith(".xml")),
                key=extract_numeric_value
            )

            # Get JSON files in sorted order (for adjustInventory)
            json_files = sorted(
                (f for f in os.listdir(subfolder_path) if f.endswith(".json")),
                key=extract_numeric_value
            )

            all_files = xml_files + json_files

            if all_files:
                os.makedirs(updated_subfolder, exist_ok=True)  # Create only if files exist

                for file_name in all_files:
                    input_file = os.path.join(subfolder_path, file_name)
                    output_file = os.path.join(updated_subfolder, file_name)
                    if file_name.endswith(".xml"):
                        execution_order.append((input_file, output_file, "xml"))
                    else:
                        execution_order.append((input_file, output_file, "json"))

    # Process files and store updated ones
    for input_file, output_file, file_type in execution_order:
        if file_type == "xml":
            updated_file = process_xml(input_file, output_file, random_id)
        else:
            updated_file = process_json(input_file, output_file, random_id)
        if updated_file:
            updated_files.append(updated_file)

    return updated_files

def process_test_case_json(test_case_path):
    """Process JSONs in 'Input' and 'Setup' folders, ensuring correct sorting."""
    random_id = generate_random_id()
    print(f"Processing {test_case_path} with Random ID: {random_id}")

    updated_files = []
    execution_order = []

    # Only consider 'Setup' and 'Input' directories (Setup first to ensure it runs before Input)
    for subfolder in ["Setup", "Input"]:
        subfolder_path = os.path.join(test_case_path, subfolder)

        if os.path.isdir(subfolder_path):  # Ensure the folder exists
            updated_subfolder = os.path.join(test_case_path, f"updated_{subfolder.lower()}")

            # Get JSON files in sorted order
            json_files = sorted(
                (f for f in os.listdir(subfolder_path) if f.endswith(".json")),
                key=extract_numeric_value
            )

            if json_files:
                os.makedirs(updated_subfolder, exist_ok=True)  # Create only if files exist

                for json_file in json_files:
                    input_file = os.path.join(subfolder_path, json_file)
                    output_file = os.path.join(updated_subfolder, json_file)
                    execution_order.append((input_file, output_file))

    # Process files and store updated ones
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

        if os.path.isdir(test_case_path):  # Ensure it's a folder
            updated_files = process_test_case(test_case_path)
            results[test_case] = updated_files
            # Save to JSON file
            with open(test_case_path+"/updated_files_"+test_case+".json", "w") as json_file:
                json.dump(results, json_file, indent=4)

    # Save to JSON file
    #with open("updated_files1.json", "w") as json_file:
        #json.dump(results, json_file, indent=4)
        return results

def process_suite(suite_path):
    """Process only test cases that contain 'Input' directory (Setup is optional)."""
    results = {}

    for test_case in sorted(os.listdir(suite_path)):
        test_case_path = os.path.join(suite_path, test_case)

        if os.path.isdir(test_case_path):  # Ensure it's a folder
            # Check if 'Input' directory exists (Setup is optional)
            input_path = os.path.join(test_case_path, "Input")

            if os.path.isdir(input_path):  # Only process cases with Input folder
                updated_files = process_test_case(test_case_path)
                results[test_case] = updated_files

                # Save each test case's data separately
                json_file_path = os.path.join(test_case_path, f"updated_files.json")
                with open(json_file_path, "w") as json_file:
                    json.dump({test_case: updated_files}, json_file, indent=4)

                # Validate ExpectedResult mapping against ValidateData files
                validate_expected_result_mapping(test_case_path)

    return results  # Return all processed test cases

def process_suite_json(suite_path):
    """Process only test cases that contain 'Input' directory (Setup is optional)."""
    results = {}

    for test_case in sorted(os.listdir(suite_path)):
        test_case_path = os.path.join(suite_path, test_case)

        if os.path.isdir(test_case_path):  # Ensure it's a folder
            # Check if 'Input' directory exists (Setup is optional)
            input_path = os.path.join(test_case_path, "Input")

            if os.path.isdir(input_path):  # Only process cases with Input folder
                updated_files, random_id = process_test_case_json(test_case_path)
                results[test_case] = updated_files

                # Save each test case's data separately
                json_file_path = os.path.join(test_case_path, f"updated_files.json")
                with open(json_file_path, "w") as json_file:
                    json.dump({test_case: updated_files}, json_file, indent=4)

    return random_id  # Returning only processed test cases


def get_base_filename(file_path):
    """Extract the base filename without numbers and extension."""

    # Get filename without path
    file_name = os.path.basename(file_path)  # "create1.xml"

    # Remove extension
    file_name_without_ext = os.path.splitext(file_name)[0]  # "create1"

    # Remove trailing numbers
    base_name = re.sub(r'\d+$', '', file_name_without_ext)  # "create"

    return base_name

#  Test Cases

def load_json_files(output_folder):
    """Load all JSON files from the output folder into a single dictionary."""
    json_data = {}

    for filename in os.listdir(output_folder):
        if filename.endswith(".json"):
            json_path = os.path.join(output_folder, filename)
            with open(json_path, "r", encoding="utf-8") as file:
                data = json.load(file)
                json_data.update(data)  # Merge JSON key-value pairs

    return json_data