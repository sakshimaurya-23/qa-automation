
#!/usr/bin/env python3
"""
Generate Custom HTML Report from Robot Framework output.xml
Usage:
  python3 Scripts/generate_custom_report.py                        # whole suite (Test_Cases/)
  python3 Scripts/generate_custom_report.py Test_Cases/<TestCaseID>  # single test case
"""
import xml.etree.ElementTree as ET
from datetime import datetime
import os
import sys


# ---------------------------------------------------------------------------
# Parsing helpers
# ---------------------------------------------------------------------------

def parse_output_xml(xml_file):
    """Parse Robot Framework output.xml and return a data dict."""
    tree = ET.parse(xml_file)
    root = tree.getroot()

    robot_info = {
        'generator': root.get('generator', 'Unknown'),
        'generated': root.get('generated', ''),
        'rpa': root.get('rpa', 'false'),
    }

    suite = root.find('.//suite')
    suite_info = {
        'name': suite.get('name', 'Unknown') if suite is not None else 'Unknown',
        'source': suite.get('source', '') if suite is not None else '',
        'id': suite.get('id', '') if suite is not None else '',
    }

    # Collect all tests
    tests = root.findall('.//test')
    test_rows = []
    for t in tests:
        ts = t.find('status')
        test_rows.append({
            'name': t.get('name', 'Unknown'),
            'id': t.get('id', ''),
            'status': ts.get('status', 'UNKNOWN') if ts is not None else 'UNKNOWN',
            'start': ts.get('start', '') if ts is not None else '',
            'elapsed': ts.get('elapsed', '0') if ts is not None else '0',
        })

    # Statistics from <statistics/total/stat>
    stats_el = root.find('.//statistics/total/stat')
    if stats_el is not None:
        statistics = {
            'pass': int(stats_el.get('pass', 0)),
            'fail': int(stats_el.get('fail', 0)),
            'skip': int(stats_el.get('skip', 0)),
        }
    else:
        statistics = {'pass': 0, 'fail': 0, 'skip': 0}
    statistics['total'] = statistics['pass'] + statistics['fail'] + statistics['skip']

    suite_status_el = root.find('.//suite/status')
    suite_info['status'] = suite_status_el.get('status', 'UNKNOWN') if suite_status_el is not None else 'UNKNOWN'
    suite_info['start'] = suite_status_el.get('start', '') if suite_status_el is not None else ''
    suite_info['elapsed'] = suite_status_el.get('elapsed', '0') if suite_status_el is not None else '0'

    return {
        'robot_info': robot_info,
        'suite_info': suite_info,
        'test_rows': test_rows,
        'statistics': statistics,
    }


def format_timestamp(ts):
    if not ts:
        return 'N/A'
    try:
        dt = datetime.fromisoformat(ts.replace('T', ' '))
        return dt.strftime('%Y-%m-%d %H:%M:%S')
    except Exception:
        return ts


def format_duration(elapsed):
    try:
        seconds = float(elapsed)
        h = int(seconds // 3600)
        m = int((seconds % 3600) // 60)
        s = int(seconds % 60)
        return f"{h:02d}:{m:02d}:{s:02d}"
    except Exception:
        return "00:00:00"


def extract_tc_id(source_path):
    """Try to extract a Test Case ID segment from the source path."""
    for part in source_path.replace('\\', '/').split('/'):
        if part.startswith('TC'):
            return part
    return os.path.basename(source_path)


# ---------------------------------------------------------------------------
# HTML generation
# ---------------------------------------------------------------------------

def generate_html_report(data, template_path, output_path):
    """Render the HTML template with live data and write to output_path."""
    with open(template_path, 'r', encoding='utf-8') as f:
        html = f.read()

    stats = data['statistics']
    suite = data['suite_info']
    robot = data['robot_info']
    test_rows = data['test_rows']

    total = stats['total']
    pass_pct = (stats['pass'] / total * 100) if total > 0 else 0
    fail_pct = (stats['fail'] / total * 100) if total > 0 else 0
    skip_pct = (stats['skip'] / total * 100) if total > 0 else 0

    overall_status = 'EXECUTION PASSED' if stats['fail'] == 0 else 'EXECUTION FAILED'
    status_color = '#198038' if stats['fail'] == 0 else '#da1e28'

    tc_id = extract_tc_id(suite['source'])
    generated_time = format_timestamp(robot['generated'])
    suite_duration = format_duration(suite['elapsed'])

    # Build test rows HTML
    rows_html = ''
    for t in test_rows:
        badge_color = '#198038' if t['status'] == 'PASS' else ('#d2a106' if t['status'] == 'SKIP' else '#da1e28')
        rows_html += f"""
        <tr>
          <td>{t['name']}</td>
          <td><span style="background:{badge_color};color:#fff;padding:2px 10px;border-radius:2px;font-size:12px;font-weight:600;">{t['status']}</span></td>
          <td>{format_timestamp(t['start'])}</td>
          <td>{format_duration(t['elapsed'])}</td>
        </tr>"""

    # Replace template placeholders
    replacements = {
        '{{TC_ID}}': tc_id,
        '{{SUITE_NAME}}': suite['name'],
        '{{SUITE_SOURCE}}': suite['source'],
        '{{GENERATED_TIME}}': generated_time,
        '{{SUITE_DURATION}}': suite_duration,
        '{{OVERALL_STATUS}}': overall_status,
        '{{STATUS_COLOR}}': status_color,
        '{{TOTAL}}': str(stats['total']),
        '{{PASS}}': str(stats['pass']),
        '{{FAIL}}': str(stats['fail']),
        '{{SKIP}}': str(stats['skip']),
        '{{PASS_PCT}}': f"{pass_pct:.1f}",
        '{{FAIL_PCT}}': f"{fail_pct:.1f}",
        '{{SKIP_PCT}}': f"{skip_pct:.1f}",
        '{{TEST_ROWS}}': rows_html,
    }

    for placeholder, value in replacements.items():
        html = html.replace(placeholder, value)

    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(html)

    print(f"Custom report generated: {output_path}")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    # Resolve base path argument (default = Test_Cases/ relative to script dir)
    script_dir = os.path.dirname(os.path.abspath(__file__))
    qa_root = os.path.dirname(script_dir)   # qa-automation/

    if len(sys.argv) > 1:
        test_case_path = sys.argv[1]
        if not os.path.isabs(test_case_path):
            test_case_path = os.path.abspath(test_case_path)
    else:
        test_case_path = qa_root   # whole suite run

    output_xml = os.path.join(test_case_path, 'output.xml')
    template_path = os.path.join(qa_root, 'report_templates', 'template.html')
    custom_report_path = os.path.join(test_case_path, 'custom_report.html')

    if not os.path.exists(output_xml):
        print(f"Error: output.xml not found at {output_xml}")
        sys.exit(1)

    if not os.path.exists(template_path):
        print(f"Error: template.html not found at {template_path}")
        sys.exit(1)

    print(f"Parsing {output_xml}...")
    data = parse_output_xml(output_xml)

    print("Generating custom report from template...")
    generate_html_report(data, template_path, custom_report_path)

    print("Done!")


if __name__ == '__main__':
    main()

# Made with Bob
