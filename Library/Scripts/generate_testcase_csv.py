#!/usr/bin/env python3
"""
Generate TestCase Sheet.csv from structured test case data.
Uses csv.writer to ensure proper quoting of fields containing commas, quotes, or newlines.
"""

import csv
import re
import sys
from datetime import datetime
from pathlib import Path


def format_numbered_text(text: str) -> str:
    """
    Convert numbered items from a single line to separate lines.
    
    Example:
        "1. First item. 2. Second item. 3. Third item."
        becomes:
        "1. First item.
        2. Second item.
        3. Third item."
    """
    # Match pattern: number followed by dot and space, then text until next number or end
    # Handles multi-digit numbers like 10. 11. etc.
    pattern = r'(\d+\.\s.*?)(?=\s*\d+\.|$)'
    matches = re.findall(pattern, text, flags=re.DOTALL)
    if matches:
        # Clean up each item and join with newlines
        items = [m.strip() for m in matches if m.strip()]
        return '\n'.join(items)
    return text


def format_test_case(tc: dict) -> dict:
    """
    Format fields in a test case dict so numbered items appear on separate lines.
    Applies to Description, Preconditions, Test Steps, Expected Results.
    """
    formatted = tc.copy()
    for field in ["description", "preconditions", "test_steps", "expected_results"]:
        if field in formatted:
            formatted[field] = format_numbered_text(formatted[field])
    return formatted


def generate_csv(test_cases: list[dict], output_path: str | Path, multiline: bool = True) -> None:
    """
    Write test cases to a CSV file with proper quoting.

    Args:
        test_cases: List of dicts with keys:
            test_case_id, title, description, preconditions,
            test_steps, expected_results, priority, status
        output_path: Path to write the CSV file.
        multiline: If True, format numbered items on separate lines.

    Raises:
        ValueError: If any required field is missing in a test case.
    """
    required_fields = [
        "test_case_id", "title", "description", "preconditions",
        "test_steps", "expected_results", "priority", "status"
    ]

    # Validate
    for idx, tc in enumerate(test_cases):
        missing = [f for f in required_fields if f not in tc or not tc[f]]
        if missing:
            raise ValueError(f"Test case {idx} missing fields: {missing}")

    # Format for readability
    processed = [format_test_case(tc) if multiline else tc for tc in test_cases]

    # Write with proper quoting
    output_path = Path(output_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    with open(output_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f, quoting=csv.QUOTE_MINIMAL)
        # Header
        writer.writerow([
            "Test Case ID", "Title", "Description", "Preconditions",
            "Test Steps", "Expected Results", "Priority", "Status"
        ])
        # Rows
        for tc in processed:
            writer.writerow([
                tc["test_case_id"],
                tc["title"],
                tc["description"],
                tc["preconditions"],
                tc["test_steps"],
                tc["expected_results"],
                tc["priority"],
                tc["status"],
            ])

    print(f"✓ Wrote {len(processed)} test cases to {output_path} {'(multiline)' if multiline else '(single-line)'}")


def validate_csv(csv_path: str | Path) -> bool:
    """Validate that a CSV has exactly 8 columns per row."""
    csv_path = Path(csv_path)
    with open(csv_path, newline="", encoding="utf-8") as f:
        rows = list(csv.reader(f))

    if not rows:
        print(f"✗ {csv_path}: empty file")
        return False

    expected_cols = len(rows[0])
    bad = [i for i, r in enumerate(rows) if len(r) != expected_cols]
    if bad:
        print(f"✗ {csv_path}: {len(bad)} bad rows (expected {expected_cols} cols) at {bad}")
        return False

    print(f"✓ {csv_path}: {len(rows)} rows, all with {expected_cols} columns")
    return True


if __name__ == "__main__":
    # Example usage
    if len(sys.argv) > 1 and sys.argv[1] == "validate":
        if len(sys.argv) < 3:
            print("Usage: generate_testcase_csv.py validate <path/to/TestCase Sheet.csv> [...]")
            sys.exit(1)
        results = [validate_csv(path) for path in sys.argv[2:]]
        sys.exit(0 if all(results) else 1)
    else:
        print("Usage:")
        print("  generate_testcase_csv.py validate <path/to/TestCase Sheet.csv> [...]")
        print("")
        print("To generate a CSV, import and call generate_csv() from your own script:")
        print("  from generate_testcase_csv import generate_csv")
        print("  generate_csv(test_cases, 'TestCase Sheet.csv')")
        sys.exit(0)