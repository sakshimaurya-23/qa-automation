#!/usr/bin/env python3
"""
Step 5B: Apply OMS Business Logic to all Test Case XML files.
Reads CSV rows, extracts OMS concepts, applies modifications to Setup/ and Input/ files,
and saves oms_metadata.json for each test case.
"""
import sys
import csv
import json
import xml.etree.ElementTree as ET
from pathlib import Path
from datetime import datetime

# Add Library/Scripts to path
REPO_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(REPO_ROOT / "Library" / "Scripts"))

from oms_business_logic import OMSConceptExtractor, OMSXmlModifier, OMSTestMetadata

CSV_PATH = Path(__file__).parent.parent.parent.parent / "frontend" / "TestCase Sheet.csv"
TEST_CASES_ROOT = REPO_ROOT / "Test_Cases"

def get_api_name_from_xml(file_path):
    """Extract API Name or FlowName from an XML file."""
    try:
        tree = ET.parse(file_path)
        root = tree.getroot()
        api_elem = root.find('.//API')
        if api_elem is not None:
            return api_elem.get('Name', '') or api_elem.get('FlowName', '')
    except Exception:
        pass
    return str(file_path.stem)

def process_test_case(tc_id, csv_row):
    tc_dir = TEST_CASES_ROOT / tc_id
    if not tc_dir.exists():
        print(f"  SKIP: folder not found — {tc_dir}")
        return

    extractor = OMSConceptExtractor()
    concepts = extractor.extract_from_test_case(csv_row)

    modifier = OMSXmlModifier()
    step_mappings = []
    xml_modifications = []

    for folder_name in ["Setup", "Input"]:
        folder = tc_dir / "Data" / folder_name
        if not folder.exists():
            continue
        for xml_file in sorted(folder.iterdir()):
            if xml_file.suffix.lower() not in ('.xml', '.json'):
                continue
            api_name = get_api_name_from_xml(xml_file)
            try:
                modified = modifier.apply_to_file(str(xml_file), api_name, concepts)
                xml_modifications.append({"file": str(xml_file.relative_to(tc_dir)), "modified": bool(modified)})
            except Exception as e:
                xml_modifications.append({"file": str(xml_file.relative_to(tc_dir)), "error": str(e)})
            step_mappings.append({"file": str(xml_file.relative_to(tc_dir)), "api": api_name})

    # Save metadata
    metadata = OMSTestMetadata()
    metadata_path = tc_dir / "Data" / "oms_metadata.json"
    try:
        metadata.save_complete(
            output_path=metadata_path,
            tc=csv_row,
            step_mappings=step_mappings
        )
    except Exception:
        # Fallback: write manually
        meta = {
            "test_case_id": tc_id,
            "csv_row": csv_row,
            "extracted_concepts": concepts,
            "api_step_mapping": step_mappings,
            "xml_modifications": xml_modifications,
            "generation_timestamp": datetime.now().isoformat()
        }
        metadata_path.write_text(json.dumps(meta, indent=2))

    print(f"  ✓ {tc_id}: concepts={list(concepts.keys())}, files_processed={len(step_mappings)}")

def main():
    if not CSV_PATH.exists():
        print(f"ERROR: CSV not found at {CSV_PATH}")
        sys.exit(1)

    with open(CSV_PATH, newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        rows = {row['Test Case ID']: row for row in reader}

    print(f"Processing {len(rows)} test cases from CSV...")
    for tc_id, csv_row in rows.items():
        process_test_case(tc_id, csv_row)
    print("Step 5B complete.")

if __name__ == '__main__':
    main()
