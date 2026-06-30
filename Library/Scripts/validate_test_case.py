#!/usr/bin/env python3
"""
validate_test_case.py — Pre-flight validator for qa-automation test case folders.

Run this AFTER Bob populates a test case folder and BEFORE running `robot Test.robot`.
It catches expectedResult mismatches (wrong API name, wrong element structure) at build
time so they never reach the runtime comparator in XmlCompare.py.

Usage:
    # Validate one test case:
    python3 validate_test_case.py path/to/Test_Cases/TC_20260629_153709_001

    # Validate all test cases at once:
    python3 validate_test_case.py path/to/Test_Cases/

    # Auto-fix mismatches by copying correct expectedResult files from baseline_data:
    python3 validate_test_case.py path/to/Test_Cases/TC_20260629_153709_001 --fix path/to/baseline_data

Exit codes:
    0 — all checks passed
    1 — one or more mismatches found (or fixed — re-run without --fix to confirm)
"""

import sys
import re
import shutil
import argparse
from pathlib import Path
from lxml import etree


# ---------------------------------------------------------------------------
# XML helpers
# ---------------------------------------------------------------------------

def _parse_xml(path: Path) -> etree._Element | None:
    """Parse an XML file; return None and print a warning on failure."""
    try:
        parser = etree.XMLParser(remove_blank_text=True)
        return etree.parse(str(path), parser).getroot()
    except Exception as e:
        print(f"  ⚠️  Cannot parse {path.name}: {e}")
        return None


def _get_api_name(root: etree._Element) -> str | None:
    """
    Extract the API Name from an OMS XML file.
    Checks two locations used across the codebase:
      1. <MultiApi><API Name="...">    — ValidateData / response wrapper
      2. Root attribute API="..."      — some input files
    Returns None if not found.
    """
    # Pattern 1: <API Name="..."> anywhere in the tree
    for elem in root.iter("API"):
        name = elem.get("Name")
        if name:
            return name
    # Pattern 2: root-level APIName attribute (some OMS templates)
    name = root.get("APIName") or root.get("ApiName")
    if name:
        return name
    return None


def _get_template_elements(root: etree._Element) -> set[str]:
    """
    Return the set of XPath-like element paths defined inside <Template> in a ValidateData file.
    Example: {'/ShipmentList', '/ShipmentList/Shipment', ...}
    """
    template = root.find(".//Template")
    if template is None:
        return set()
    paths = set()
    _collect_paths(template, "", paths)
    return paths


def _get_output_elements(root: etree._Element) -> set[str]:
    """
    Return the set of XPath-like element paths inside the <Output> section of an expectedResult file.
    """
    output = root.find(".//Output")
    if output is None:
        # Some expectedResult files have the content directly under root
        output = root
    paths = set()
    _collect_paths(output, "", paths)
    return paths


def _collect_paths(elem: etree._Element, prefix: str, paths: set):
    for child in elem:
        path = f"{prefix}/{child.tag}"
        paths.add(path)
        _collect_paths(child, path, paths)


# ---------------------------------------------------------------------------
# Core pairing logic
# ---------------------------------------------------------------------------

def _number_from_filename(name: str) -> int:
    """Extract the leading integer from a filename like '8_getShipmentList_ValidateData.xml'."""
    m = re.match(r"^(\d+)", name)
    return int(m.group(1)) if m else 0


def _expected_result_number(validate_filename: str, validate_files_sorted: list[str]) -> int:
    """
    The runtime assigns expectedresult{N}.xml by counting how many ValidateData files
    have been seen so far (via Write Actual Result's counter).  Reproduce that counter
    so we can find the paired expectedresult file.
    """
    return validate_files_sorted.index(validate_filename) + 1


def validate_test_case(tc_path: Path, baseline_path: Path | None = None) -> list[dict]:
    """
    Validate one test case folder.

    Returns a list of issue dicts:
      {
        "validate_file": str,
        "expected_file": str,
        "validate_api": str | None,
        "expected_api": str | None,
        "missing_in_expected": list[str],
        "extra_in_expected": list[str],
        "fix_source": Path | None,   # set when --fix is requested and source found
      }
    """
    input_dir = tc_path / "Data" / "Input"
    expected_dir = tc_path / "Data" / "ExpectedResult"

    if not input_dir.exists():
        print(f"  ⚠️  No Data/Input/ folder found in {tc_path.name} — skipping.")
        return []
    if not expected_dir.exists():
        print(f"  ⚠️  No Data/ExpectedResult/ folder found in {tc_path.name} — skipping.")
        return []

    # Collect ValidateData files, sorted by their numeric prefix
    validate_files = sorted(
        [f for f in input_dir.glob("*_ValidateData.xml")],
        key=lambda f: _number_from_filename(f.name)
    )

    if not validate_files:
        print(f"  ℹ️  No ValidateData files found in {tc_path.name}/Data/Input/ — nothing to validate.")
        return []

    validate_names_sorted = [f.name for f in validate_files]
    issues = []

    for vf in validate_files:
        counter = _expected_result_number(vf.name, validate_names_sorted)
        ef_name = f"expectedresult{counter}.xml"
        ef_path = expected_dir / ef_name

        issue = {
            "validate_file": vf.name,
            "expected_file": ef_name,
            "validate_api": None,
            "expected_api": None,
            "missing_in_expected": [],
            "extra_in_expected": [],
            "fix_source": None,
        }

        vf_root = _parse_xml(vf)
        if vf_root is None:
            issues.append(issue)
            continue

        issue["validate_api"] = _get_api_name(vf_root)

        if not ef_path.exists():
            issue["extra_in_expected"] = ["FILE MISSING"]
            issues.append(issue)
            continue

        ef_root = _parse_xml(ef_path)
        if ef_root is None:
            issues.append(issue)
            continue

        issue["expected_api"] = _get_api_name(ef_root)

        # Check 1: API Name match
        api_mismatch = (
            issue["validate_api"] and
            issue["expected_api"] and
            issue["validate_api"] != issue["expected_api"]
        )

        # Check 2: Element structure match (Template vs Output)
        template_elems = _get_template_elements(vf_root)
        output_elems = _get_output_elements(ef_root)

        missing = sorted(template_elems - output_elems)
        extra = sorted(output_elems - template_elems)

        issue["missing_in_expected"] = missing
        issue["extra_in_expected"] = extra

        has_problem = api_mismatch or missing or extra
        if not has_problem:
            continue  # ✅ this pair is good

        # Try to locate a fix source in baseline_data
        if baseline_path and issue["validate_api"]:
            # The correct expectedResult.xml lives in baseline_data/<APIFolder>/expectedResult.xml
            # We find the folder whose ValidateData file matches the validate API name
            fix_source = _find_fix_source(baseline_path, issue["validate_api"])
            issue["fix_source"] = fix_source

        issues.append(issue)

    return issues


def _find_fix_source(baseline_path: Path, api_name: str) -> Path | None:
    """
    Search baseline_data subfolders for an expectedResult.xml that belongs to `api_name`.
    Strategy: the subfolder name typically matches the API name (case-insensitive).
    Falls back to scanning each subfolder's ValidateData file for an API Name match.
    """
    # Direct folder name match first (fast path)
    for candidate in baseline_path.iterdir():
        if not candidate.is_dir():
            continue
        if candidate.name.lower() == api_name.lower():
            er = candidate / "expectedResult.xml"
            if er.exists():
                return er

    # Slow path: read each ValidateData file
    for candidate in baseline_path.iterdir():
        if not candidate.is_dir():
            continue
        vd_files = list(candidate.glob("*_ValidateData.xml")) + list(candidate.glob("*ValidateData.xml"))
        for vd in vd_files:
            root = _parse_xml(vd)
            if root and _get_api_name(root) == api_name:
                er = candidate / "expectedResult.xml"
                if er.exists():
                    return er

    return None


# ---------------------------------------------------------------------------
# Reporting & auto-fix
# ---------------------------------------------------------------------------

def _report_issues(tc_name: str, issues: list[dict]) -> None:
    if not issues:
        print(f"  ✅  {tc_name} — all ValidateData↔expectedResult pairs are correct.")
        return

    print(f"  ❌  {tc_name} — {len(issues)} mismatch(es) found:\n")
    for issue in issues:
        print(f"     Pair:  {issue['validate_file']}  →  {issue['expected_file']}")
        if issue["validate_api"] and issue["expected_api"] and issue["validate_api"] != issue["expected_api"]:
            print(f"            API mismatch: ValidateData says '{issue['validate_api']}' "
                  f"but expectedResult says '{issue['expected_api']}'")
        if issue["missing_in_expected"]:
            print(f"            Missing from expectedResult (present in Template):")
            for e in issue["missing_in_expected"]:
                print(f"              - {e}")
        if issue["extra_in_expected"] == ["FILE MISSING"]:
            print(f"            expectedResult file does not exist")
        elif issue["extra_in_expected"]:
            print(f"            Extra in expectedResult (not in Template):")
            for e in issue["extra_in_expected"]:
                print(f"              - {e}")
        if issue["fix_source"]:
            print(f"            Fix source: {issue['fix_source']}")
        else:
            print(f"            Fix source: not found in baseline_data "
                  f"(copy manually from baseline_data/<{issue['validate_api']}>/expectedResult.xml)")
        print()


def _apply_fixes(tc_path: Path, issues: list[dict]) -> int:
    """Copy fix sources into ExpectedResult/. Returns number of fixes applied."""
    expected_dir = tc_path / "Data" / "ExpectedResult"
    fixed = 0
    for issue in issues:
        if issue["fix_source"] is None:
            print(f"     ⚠️  Cannot auto-fix {issue['expected_file']} — no source found for "
                  f"API '{issue['validate_api']}' in baseline_data.")
            continue
        dest = expected_dir / issue["expected_file"]
        shutil.copy2(issue["fix_source"], dest)
        print(f"     🔧  Replaced {issue['expected_file']} ← {issue['fix_source']}")
        fixed += 1
    return fixed


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Pre-flight validator: checks ValidateData↔expectedResult pairing before robot runs."
    )
    parser.add_argument(
        "target",
        help="Path to a single test case folder (e.g. Test_Cases/TC_001) "
             "or to Test_Cases/ to validate all test cases."
    )
    parser.add_argument(
        "--fix",
        metavar="BASELINE_PATH",
        help="Path to baseline_data/. When provided, auto-copies the correct "
             "expectedResult.xml files for any mismatches that can be resolved."
    )
    args = parser.parse_args()

    target = Path(args.target).resolve()
    baseline = Path(args.fix).resolve() if args.fix else None

    if not target.exists():
        print(f"ERROR: Path does not exist: {target}")
        sys.exit(1)

    # Determine which folders to validate
    if (target / "Data").exists():
        # Single test case folder
        tc_folders = [target]
    else:
        # Directory of test case folders
        tc_folders = sorted([d for d in target.iterdir() if d.is_dir() and (d / "Data").exists()])
        if not tc_folders:
            print(f"No test case folders found under {target}")
            sys.exit(0)

    total_issues = 0
    total_fixed = 0

    for tc_path in tc_folders:
        print(f"\n{'─'*60}")
        print(f"Validating: {tc_path.name}")
        issues = validate_test_case(tc_path, baseline)
        _report_issues(tc_path.name, issues)

        if issues and baseline:
            fixed = _apply_fixes(tc_path, issues)
            total_fixed += fixed
            if fixed:
                print(f"     → {fixed} file(s) replaced. Re-run without --fix to confirm.")

        total_issues += len(issues)

    print(f"\n{'='*60}")
    if total_fixed:
        print(f"Summary: {total_issues} issue(s) found, {total_fixed} auto-fixed.")
        print("Re-run without --fix to confirm all pairs are now correct.")
        sys.exit(1)  # still exit 1 so CI/Bob knows to re-validate
    elif total_issues:
        print(f"Summary: {total_issues} issue(s) found. Fix manually or re-run with --fix <baseline_data_path>.")
        sys.exit(1)
    else:
        print("Summary: All ValidateData↔expectedResult pairs are correct. Safe to run robot.")
        sys.exit(0)


if __name__ == "__main__":
    main()