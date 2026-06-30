#!/usr/bin/env python3
"""
CSV-to-TestCase Generator for City Furniture OMS QA Automation.

Reads TestCase Sheet.csv, interprets the test steps and preconditions,
and auto-generates the complete test case folder structure.

Usage:
    python3 generate_testcase_from_csv.py [--csv PATH] [--output DIR] [--process]
"""
import csv, json, os, re, sys, shutil
from datetime import datetime
from pathlib import Path

# === CONFIG ===
SCRIPT_DIR = Path(__file__).resolve().parent
QA_AUTOMATION_DIR = SCRIPT_DIR.parent
DEFAULT_CSV = QA_AUTOMATION_DIR / "../../frontend/TestCase Sheet.csv"
DEFAULT_OUTPUT = QA_AUTOMATION_DIR / "Test_Cases"
BASELINE_DIR = QA_AUTOMATION_DIR / "baseline_data"
LIB_SCRIPTS = QA_AUTOMATION_DIR / "Library" / "Scripts"

# OMS Business Logic Engine
sys.path.insert(0, str(LIB_SCRIPTS))
from oms_business_logic import OMSConceptExtractor, OMSXmlModifier, OMSTestMetadata

# Template for Test.robot
TEST_ROBOT_TEMPLATE = """\
*** Settings ***
Resource    ${{CURDIR}}/../../Library/Robots/keywords.robot

*** Variables ***
${{CUR_DIR}}     ${{CURDIR}}

*** Test Cases ***
{test_case_name}
    [Documentation]    {documentation}
    [Tags]    REGRESSION    {concept_tags}
    Log To Console    curDir:${{CUR_DIR}}
    ${{suite_exists}}=    Run Keyword And Return Status    Directory Should Exist    ${{CUR_DIR}}
    Run Keyword If    ${{suite_exists}}    Process Suite    ${{CUR_DIR}}
    ${{subfolders}}=    Check folders    ${{CUR_DIR}}
    ${{folders}}    List Directories In Directory    ${{CUR_DIR}}
    ${{index}}=    Set Variable    0
    FOR    ${{folder}}    IN    @{{folders}}
        Process All JSON Files    ${{CUR_DIR}}    ${{folder}}    ${{index}}
    END
"""

# ---------------------------------------------------------------------------
# API-STEP MAPPING
# Maps CSV test-step action phrases to baseline_data/ folders and file types.
# ---------------------------------------------------------------------------
API_STEP_MAP = {
    "manageItem": {
        "baseline": "manageItem", "input": "input.xml",
        "validate": "getItemList_ValidateData.xml",
        "expected": "expectedResult.xml", "category": "setup",
        "file_prefix": "manageItem",
    },
    "adjustInventory": {
        "baseline": "adjustInventory", "input": "input.json",
        "validate": "getInventorySupply_ValidateData.json",
        "expected": "expectedResult.json", "category": "setup",
        "file_prefix": "adjustInventory",
    },
    "createOrder": {
        "baseline": "createOrder", "input": "input.xml",
        "validate": "getOrderList.xml",
        "expected": "expectedResult.xml", "category": "input",
        "file_prefix": "input",
    },
    "scheduleOrder": {
        "baseline": "scheduleOrder", "input": "input.xml",
        "validate": "getOrderList_ValidateData.xml",
        "expected": "expectedResult.xml", "category": "input",
        "file_prefix": "input",
    },
    "releaseOrder": {
        "baseline": "releaseOrder", "input": "input.xml",
        "validate": "getOrderList_ValidateData.xml",
        "expected": "expectedResult.xml", "category": "input",
        "file_prefix": "input",
    },
    "CT069ForAutomationService": {
        "baseline": "CT069ForAutomationService", "input": "input.xml",
        "validate": "getOrderDetails_ValidateData.xml",
        "expected": "expectedResult.xml", "category": "input",
        "file_prefix": "input",
    },
    "getOrderReleaseList": {
        "baseline": "getOrderReleaseList", "input": "input.xml",
        "validate": "getOrderReleaseList_ValidateData.xml",
        "expected": "expectedResult.xml", "category": "input",
        "file_prefix": "input",
    },
    "getOrderDetails": {
        "baseline": "getOrderDetails",
        "validate": "getOrderDetails_ValidateData.xml",
        "expected": "expectedResult.xml", "category": "input",
        "file_prefix": "input", "skip_input": True,
    },
    "getOrderList": {
        "baseline": "getOrderList",
        "validate": "getOrderList_ValidateData.xml",
        "expected": "expectedResult.xml", "category": "input",
        "file_prefix": "input", "skip_input": True,
    },
    "changeOrderStatus": {
        "baseline": "changeOrderStatus", "input": "input.xml",
        "validate": "getOrderDetails_ValidateData.xml",
        "expected": "expectedResult.xml", "category": "input",
        "file_prefix": "input",
    },
    "orderEnquiry": {
        "baseline": "orderEnquiry", "input": "input.xml",
        "validate": "getOrderList_ValidateData.xml",
        "expected": "expectedResult.xml", "category": "input",
        "file_prefix": "input",
    },
    "updateOrderFromRouting": {
        "baseline": "updateOrderFromRouting", "input": "input.xml",
        "validate": "getOrderDetails_ValidateData.xml",
        "expected": "expectedResult.xml", "category": "input",
        "file_prefix": "input",
    },
    "confirmShipment": {
        "baseline": "confirmShipment", "input": "input.xml",
        "validate": "getShipmentList_ValidateData.xml",
        "expected": "expectedResult.xml", "category": "input",
        "file_prefix": "input",
    },
    "createShipment": {
        "baseline": "createShipment", "input": "input.xml",
        "validate": "getShipmentList_ValidateData.xml",
        "expected": "expectedResult.xml", "category": "input",
        "file_prefix": "input",
    },
    "shipDepart": {
        "baseline": "shipDepart", "input": "input.xml",
        "validate": "getShipmentList_ValidateData.xml",
        "expected": "expectedResult.xml", "category": "input",
        "file_prefix": "input",
    },
}

# === CSV PARSER ===
def parse_csv(csv_path):
    """Parse the TestCase Sheet.csv and return list of test case dicts."""
    test_cases = []
    with open(csv_path, newline="", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        for row in reader:
            tc = {
                "test_case_id": row.get("Test Case ID", "").strip(),
                "title": row.get("Title", "").strip(),
                "description": row.get("Description", "").strip(),
                "preconditions": row.get("Preconditions", "").strip(),
                "test_steps": row.get("Test Steps", "").strip(),
                "expected_results": row.get("Expected Results", "").strip(),
                "priority": row.get("Priority", "").strip(),
                "status": row.get("Status", "").strip(),
            }
            if tc["test_case_id"]:
                test_cases.append(tc)
    return test_cases

def parse_numbered_steps(steps_text):
    """Parse numbered steps from CSV text into a list of step strings."""
    if not steps_text:
        return []
    parts = re.split(r"\d+\.\s+", steps_text)
    return [p.strip() for p in parts if p.strip()]

# === FILE GENERATORS ===
def copy_baseline_file(baseline_folder, filename, target_path, placeholders=None):
    src = baseline_folder / filename
    if not src.exists():
        print(f"  ⚠ Baseline not found: {src}")
        return False
    content = src.read_text(encoding="utf-8")
    if placeholders:
        for key, value in placeholders.items():
            content = content.replace(f"${{{key}}}", value)
    target_path.parent.mkdir(parents=True, exist_ok=True)
    target_path.write_text(content, encoding="utf-8")
    return True

def generate_expected_result_from_template(validate_path, output_path):
    if not validate_path or not validate_path.exists():
        return False
    try:
        import xml.etree.ElementTree as ET
        tree = ET.parse(str(validate_path))
        root = tree.getroot()
        api = root.find(".//API")
        if api is None:
            return False
        api_name = api.get("Name", "")
        template = api.find("Template")
        if template is None:
            return False
        multiapi = ET.Element("MultiApi")
        api_elem = ET.SubElement(multiapi, "API", {"Name": api_name})
        output_elem = ET.SubElement(api_elem, "Output")
        for child in template:
            new_child = ET.fromstring(ET.tostring(child))
            for elem in new_child.iter():
                for attr in list(elem.attrib):
                    if elem.get(attr) == "":
                        elem.set(attr, "XXXX")
            output_elem.append(new_child)
        ET.indent(multiapi, space="  ")
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(ET.tostring(multiapi, encoding="unicode"), encoding="utf-8")
        return True
    except Exception as e:
        print(f"  ⚠ Error generating expected result: {e}")
        return False
# === MAIN GENERATION ENGINE ===
def generate_test_case(tc, baseline_dir, output_dir):
    """Generate the complete test case folder for a single CSV row."""
    tc_id = tc["test_case_id"]
    folder_name = tc_id  # e.g. TC_20260627_185500_001
    tc_path = output_dir / folder_name
    data_path = tc_path / "Data"

    input_idx = 0
    expected_idx = 0
    setup_count = 0
    placeholders = {"RandomId": "${RandomId}", "OrderNo": "${OrderNo}"}

    print(f"\n{'='*70}")
    print(f"Generating: {tc_id} — {tc['title'][:60]}...")
    print(f"{'='*70}")

    for sub in ["Input", "Setup", "ExpectedResult", "ActualResult"]:
        ensure_dir(data_path / sub)

    # OMS Business Logic Engine
    extractor = OMSConceptExtractor()
    modifier = OMSXmlModifier()
    metadata = OMSTestMetadata()
    concepts = extractor.extract_from_test_case(tc)
    step_mappings = []
    if concepts:
        print(f"  🧠 Extracted OMS concepts: {list(concepts.keys())}")

    steps = parse_numbered_steps(tc["test_steps"])
    print(f"  Steps identified: {len(steps)}")
    
    # Track which APIs are used to detect order fulfillment workflows
    used_apis = set()
    
    for step in steps:
        step_api = find_baseline_for_step(step)
        if not step_api:
            print(f"  ⚠ Could not map step: '{step[:60]}...'")
            step_mappings.append({"step": step, "api": None, "mapped": False})
            continue

        used_apis.add(step_api)
        api_config = API_STEP_MAP.get(step_api, {})
        baseline_folder = baseline_dir / api_config.get("baseline", step_api)
        input_file = api_config.get("input", "")
        validate_file = api_config.get("validate", "")
        expected_name = api_config.get("expected", "")

        if api_config.get("category") == "setup":
            setup_count += 1
            file_prefix = api_config.get("file_prefix", step_api)
            if input_file:
                ext = Path(input_file).suffix
                target = data_path / "Setup" / f"{file_prefix}{ext}"
                copy_baseline_file(baseline_folder, input_file, target, placeholders)
                modifier.apply_to_file(target, step_api, concepts)
                metadata.record_modification(target.name, step_api)
                step_mappings.append({"step": step, "api": step_api, "mapped": True})
                print(f"  📄 Setup: {target.name}")
            if expected_name:
                expected_idx += 1
                et = data_path / "ExpectedResult" / f"expectedresult{expected_idx}.xml"
                generate_baseline_expected_result(baseline_folder, expected_name, et)
                print(f"  📄 Expected: {et.name} (from setup)")
        else:
            input_idx += 1
            file_prefix = api_config.get("file_prefix", "input")

            if not api_config.get("skip_input", False) and input_file:
                target = data_path / "Input" / f"{input_idx}_input.xml"
                copy_baseline_file(baseline_folder, input_file, target, placeholders)
                modifier.apply_to_file(target, step_api, concepts)
                metadata.record_modification(target.name, step_api)
                step_mappings.append({"step": step, "api": step_api, "mapped": True})
                print(f"  📄 Input: {target.name} ({step_api})")

            if validate_file:
                input_idx += 1
                vt = data_path / "Input" / f"{input_idx}_{validate_file}"
                copy_baseline_file(baseline_folder, validate_file, vt, placeholders)
                modifier.apply_to_file(vt, step_api, concepts)
                metadata.record_modification(vt.name, step_api)
                print(f"  📄 Input: {vt.name} (validation)")

                if expected_name:
                    expected_idx += 1
                    et = data_path / "ExpectedResult" / f"expectedresult{expected_idx}.xml"
                    if not generate_expected_result_from_template(vt, et):
                        generate_baseline_expected_result(baseline_folder, expected_name, et)
                    print(f"  📄 Expected: {et.name}")
    
    # Automatically inject adjustInventory into setup for order fulfillment workflows
    order_fulfillment_apis = {
        "createOrder", "scheduleOrder", "releaseOrder", "CT069ForAutomationService",
        "getOrderReleaseList", "getOrderDetails", "getOrderList", "changeOrderStatus",
        "orderEnquiry", "updateOrderFromRouting", "confirmShipment", "createShipment"
    }
    
    has_order_fulfillment = bool(used_apis & order_fulfillment_apis)
    has_adjust_inventory = "adjustInventory" in used_apis
    
    if has_order_fulfillment and not has_adjust_inventory:
        print(f"  🔄 Order fulfillment workflow detected — auto-injecting adjustInventory into setup")
        adjust_inventory_src = baseline_dir / "adjustInventory" / "input.json"
        if adjust_inventory_src.exists():
            adjust_inventory_target = data_path / "Setup" / "adjustInventory.json"
            copy_baseline_file(baseline_dir / "adjustInventory", "input.json", adjust_inventory_target, placeholders)
            modifier.apply_to_file(adjust_inventory_target, "adjustInventory", concepts)
            metadata.record_modification(adjust_inventory_target.name, "adjustInventory")
            step_mappings.append({
                "step": "Auto-injected: Adjust inventory for order fulfillment",
                "api": "adjustInventory",
                "mapped": True
            })
            print(f"  📄 Setup: {adjust_inventory_target.name}")
        else:
            print(f"  ⚠ adjustInventory baseline not found at {adjust_inventory_src}")

    # Save enriched metadata before function return
    metadata_path = tc_path / "test_case_metadata.json"
    metadata.save_complete(metadata_path, tc, step_mappings)
    metadata.save_complete(metadata_path, tc, step_mappings)
    print(f"  📋 Metadata: {metadata_path.name}")
def generate_baseline_expected_result(baseline_folder, expected_name, output_path):
    src = baseline_folder / expected_name
    if not src.exists():
        return False
    content = src.read_text(encoding="utf-8")
    content = re.sub(r'(\w+(?:Key|No|Date|Desc|ID|Qty|Quantity|Status))="[^"]*"', r'\1="XXXX"', content)
    content = re.sub(r'(?<=\s)(Status|ShipNode|EnterpriseCode|OrderNo|ItemID)="[^"]*"', r'\1="XXXX"', content)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(content, encoding="utf-8")
    return True


def ensure_dir(path):
    os.makedirs(path, exist_ok=True)


def find_baseline_for_step(step_text):
    """Match a CSV test step to an API definition key."""
    step_lower = step_text.lower()
    keywords = {
        "manageitem": "manageItem", "manage item": "manageItem",
        "seed item": "manageItem", "adjustinventory": "adjustInventory",
        "adjust inventory": "adjustInventory", "createorder": "createOrder",
        "create order": "createOrder", "scheduleorder": "scheduleOrder",
        "schedule order": "scheduleOrder", "releaseorder": "releaseOrder",
        "release order": "releaseOrder",
        "CT069ForAutomationService": "CT069ForAutomationService",
        "send order line for routing": "CT069ForAutomationService",
        "getorderreleaselist": "getOrderReleaseList",
        "get order release list": "getOrderReleaseList",
        "getorderdetails": "getOrderDetails",
        "get order details": "getOrderDetails",
        "getorderlist": "getOrderList",
        "get order list": "getOrderList",
        "changeorderstatus": "changeOrderStatus",
        "change order status": "changeOrderStatus",
        # NOTE: "changeRelease" is NOT mapped to changeOrderStatus.
        # changeRelease is a different OMS concept (backordering shortage qty
        # during shipDepart processing) and should not generate a separate
        # changeOrderStatus API call in the test flow.
        "orderenquiry": "orderEnquiry",
        "order enquiry": "orderEnquiry",
        "updateorderfromrouting": "updateOrderFromRouting",
        "update order from routing": "updateOrderFromRouting",
        "confirmshipment": "confirmShipment",
        "confirm shipment": "confirmShipment",
        "createshipment": "createShipment",
        "create shipment": "createShipment",
        "shipdepart": "shipDepart",
        "ship depart": "shipDepart",
    }
    for kw, api_name in keywords.items():
        if kw in step_lower:
            return api_name
    return None


def generate_test_robot(tc, output_dir):
    """Write the Test.robot file for a single test case."""
    import re as _re
    tc_id = tc["test_case_id"]
    folder_name = tc_id
    tc_path = output_dir / folder_name
    tc_path.mkdir(parents=True, exist_ok=True)

    safe_title = _re.sub(r'[^a-zA-Z0-9_ ]', '', tc["title"])[:50].strip().replace(" ", "_")
    if not safe_title:
        safe_title = "Test_" + tc_id

    extractor = OMSConceptExtractor()
    concepts = extractor.extract_from_test_case(tc)

    # Build concept tags
    tags = ["REGRESSION"]
    if concepts.get("document_type"):
        tags.append(concepts["document_type"])
    if concepts.get("delivery_method"):
        tags.append(concepts["delivery_method"])
    if concepts.get("release_status"):
        tags.append(concepts["release_status"])
    concept_tags = "    ".join(tags)

    # Build comprehensive documentation
    doc_parts = [
        f"Title: {tc['title']}",
        f"Priority: {tc['priority']}",
        f"Status: {tc['status']}",
    ]
    if tc.get("description"):
        doc_parts.append(f"\nDescription:\n{tc['description']}")
    if tc.get("preconditions"):
        doc_parts.append(f"\nPreconditions:\n{tc['preconditions']}")
    if tc.get("test_steps"):
        doc_parts.append(f"\nTest Steps:\n{tc['test_steps']}")
    if tc.get("expected_results"):
        doc_parts.append(f"\nExpected Results:\n{tc['expected_results']}")
    if concepts:
        doc_parts.append(f"\nOMS Concepts:\n{json.dumps(concepts, indent=2)}")

    full_doc = "\n".join(doc_parts).replace("\n", "\\n")

    robot_content = TEST_ROBOT_TEMPLATE.format(
        test_case_name=safe_title,
        documentation=full_doc,
        concept_tags=concept_tags,
    )
    robot_file = tc_path / "Test.robot"
    robot_file.write_text(robot_content, encoding="utf-8")
    print(f"  \U0001f4c4 Test.robot: {robot_file.name}")


# ---------------------------------------------------------------------------
# CLI ENTRY POINT
# ---------------------------------------------------------------------------
if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Generate test case folders from CSV")
    parser.add_argument("--csv", default=str(DEFAULT_CSV), help="Path to TestCase Sheet.csv")
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT), help="Output directory for Test_Cases")
    parser.add_argument("--all", action="store_true", help="Process all test cases from CSV")
    parser.add_argument("--ids", nargs="*", help="Specific test case IDs to generate")

    args = parser.parse_args()
    csv_path = Path(args.csv)
    output_dir = Path(args.output)
    baseline_dir = BASELINE_DIR

    if not csv_path.exists():
        print(f"\u2716 CSV not found: {csv_path}")
        sys.exit(1)

    print(f"\nReading CSV: {csv_path}")
    test_cases = parse_csv(csv_path)
    print(f"Found {len(test_cases)} test case(s) in CSV.\n")

    if args.all:
        selected = test_cases
    elif args.ids:
        selected = [tc for tc in test_cases if tc["test_case_id"] in args.ids]
        found = {tc["test_case_id"] for tc in selected}
        missing = set(args.ids) - found
        if missing:
            print(f"\u26a0 Test case IDs not found in CSV: {missing}")
    else:
        print("Provide --all to process all test cases or --ids ID1 ID2 ... for specific ones.")
        sys.exit(0)

    for tc in selected:
        generate_test_case(tc, baseline_dir, output_dir)
        generate_test_robot(tc, output_dir)

    print(f"\n\u2713 Done. Generated {len(selected)} test case(s) in {output_dir}")
