#!/usr/bin/env python3
"""Run process_suite on all test cases to generate missing updated_* files."""
import sys
import os
import json

# The script lives at: /backend/qa-automation/Scripts/run_process_suite.py
script_dir = os.path.dirname(os.path.abspath(__file__))
qa_automation_dir = os.path.dirname(script_dir)  # parent of Scripts/

sys.path.insert(0, os.path.join(qa_automation_dir, 'Library', 'Scripts'))
from generateRandomNumberAndReplaceAllXMLS import process_suite

def run_all():
    base_dir = os.path.join(qa_automation_dir, 'Test_Cases')
    if not os.path.isdir(base_dir):
        print(f"Test_Cases directory not found at: {base_dir}")
        return
    
    all_tcs = sorted([
        d for d in os.listdir(base_dir)
        if d.startswith('TC_') and os.path.isdir(os.path.join(base_dir, d))
    ])
    
    print(f"Found {len(all_tcs)} test cases to process")
    print(f"Working directory: {qa_automation_dir}")
    
    for tc in all_tcs:
        tc_path = os.path.join(base_dir, tc)
        print(f"\n{'='*60}")
        print(f"Processing: {tc}")
        print(f"{'='*60}")
        
        # Check if already has updated_files.json
        updated_json = os.path.join(tc_path, 'Data', 'updated_files.json')
        if os.path.exists(updated_json):
            print(f"  -> Already has updated_files.json, skipping...")
            continue
        
        try:
            result = process_suite(tc_path)
            has_json = os.path.exists(updated_json)
            has_input = os.path.isdir(os.path.join(tc_path, 'Data', 'updated_input'))
            has_setup = os.path.isdir(os.path.join(tc_path, 'Data', 'updated_setup'))
            
            if has_json:
                with open(updated_json) as f:
                    data = json.load(f)
                tc_name = list(data.keys())[0] if data else '?'
                file_count = len(data.get(tc_name, [])) if tc_name in data else 0
                print(f"  -> updated_files.json with {file_count} files")
                print(f"  -> updated_input/: {'YES' if has_input else 'FAILED'}")
                print(f"  -> updated_setup/: {'YES' if has_setup else 'FAILED'}")
            else:
                print(f"  -> FAILED to generate files")
        except Exception as e:
            print(f"  -> ERROR: {e}")
    
    print(f"\n{'='*60}")
    print("Processing complete!")

if __name__ == '__main__':
    run_all()

