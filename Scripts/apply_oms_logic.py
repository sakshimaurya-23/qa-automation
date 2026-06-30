#!/usr/bin/env python3
"""
Step 5B – Apply OMS Business Logic to all Test_Cases XML files.
Reads each test case row from frontend/TestCase Sheet.csv,
extracts OMS concepts, applies modifications to Setup/ and Input/ files,
and saves oms_metadata.json for each test case.
"""
import sys
import csv
import json
from pathlib import Path

# Ensure Library/Scripts is on the path
SCRIPT_DIR = Path(__file__).parent
REPO_ROOT = SCRIPT_DIR.parent
sys.path.insert(0, str(REPO_ROOT / "Library" / "Scripts"))

from oms_business_logic import OMSConceptExtractor, OMSXmlModifier, OMSTestMetadata
import xml.etree.ElementTree as ET

CSV_PATH = Path(__file__).parent.parent.parent.parent / "frontend" / "TestCase Sheet.csv"
TEST_CASES_DIR = REPO_ROOT / "Test_Cases"


def get_api_name_from_xml(file_path: Path) -> str:
    """Extract API Name or FlowName from XML file."""
    try:
        tree = ET.parse(file_path)
        root = tree.getroot()
        api_elem = root.find('.//API')
        if api_elem is not None:
            return api_elem.get('Name', '') or api_elem.get('FlowName', '')
    except Exception:
        pass
    return file_path.stem


def process_test_case(tc_row: dict):
    tc_id = tc_row["Test Case ID"].strip()
    tc_dir = TEST_CASES_DIR / tc_id
    if not tc_dir.exists():
        print(f"  ✗ Folder not found: {tc_dir}")
        return

    extractor = OMSConceptExtractor()
    concepts = extractor.extract_from_test_case({
        "description":      tc_row.get("Description", ""),
        "preconditions":    tc_row.get("Preconditions", ""),
        "test_steps":       tc_row.get("Test Steps", ""),
        "expected_results": tc_row.get("Expected Results", ""),
    })

    # Infer primary_api from title
    title = tc_row.get("Title", "")
    for api_kw in ["CT069ForAutomationService", "updateOrderFromRouting", "createOrder",
                   "scheduleOrder", "releaseOrder", "changeOrderStatus"]:
        if api_kw.lower() in title.lower():
            concepts = extractor.apply_fallback_inference(concepts, api_kw, title)
            break

    modifier = OMSXmlModifier()
    step_mappings = []

    for folder in ["Setup", "Input"]:
        folder_path = tc_dir / "Data" / folder
        if not folder_path.exists():
            continue
        for f in sorted(folder_path.iterdir()):
            if f.suffix.lower() in (".xml", ".json"):
                api_name = get_api_name_from_xml(f) if f.suffix.lower() == ".xml" else f.stem
                modified = modifier.apply_to_file(f, api_name, concepts)
                step_mappings.append({"file": str(f.relative_to(REPO_ROOT)), "api": api_name})
                if modified:
                    print(f"    ✓ Modified: {f.name} (api={api_name})")

    metadata = OMSTestMetadata()
    metadata.save_complete(
        output_path=tc_dir / "Data" / "oms_metadata.json",
        tc=tc_row,
        step_mappings=step_mappings
    )
    print(f"  ✓ {tc_id}: oms_metadata.json saved ({len(step_mappings)} files processed)")


def main():
    if not CSV_PATH.exists():
        print(f"ERROR: CSV not found at {CSV_PATH}")
        sys.exit(1)

    with open(CSV_PATH, newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    print(f"Processing {len(rows)} test cases...")
    for row in rows:
        print(f"\n[{row['Test Case ID']}]")
        process_test_case(row)

    print("\n✓ Step 5B complete.")


if __name__ == "__main__":
    main()
