from lxml import etree
from robot.api import logger
from collections import defaultdict


def compare_xml(expected_xml, actual_xml):
    """
    Compare two XML documents recursively.
    Ignores whitespace, attribute ordering, and child element ordering.
    Logs differences in nodes, text, and attributes.
    Fails if any difference is found.
    """
    parser = etree.XMLParser(remove_blank_text=True)

    exp_root = etree.fromstring(expected_xml.encode("utf-8"), parser)
    act_root = etree.fromstring(actual_xml.encode("utf-8"), parser)

    diffs = []
    _compare_elements(exp_root, act_root, diffs, path=f"/{exp_root.tag}")

    if diffs:
        msg = "\n".join(diffs)
        logger.error(msg)
        raise AssertionError("XMLs differ:\n" + msg)

    return "✅ XMLs match"


def _group_children_by_tag(elem):
    """Return children grouped by tag name (each group is a list, order within group preserved)."""
    groups = defaultdict(list)
    for child in elem:
        groups[child.tag].append(child)
    return dict(groups)


def _compare_elements(exp_elem, act_elem, diffs, path):
    # Compare tag
    if exp_elem.tag != act_elem.tag:
        diffs.append(f"{path}: Expected tag <{exp_elem.tag}> but found <{act_elem.tag}>")
        return

    # Compare attributes (order-insensitive)
    all_attrs = set(exp_elem.attrib.keys()).union(act_elem.attrib.keys())
    for attr in all_attrs:
        exp_val = exp_elem.attrib.get(attr)
        act_val = act_elem.attrib.get(attr)
        # "XXXX" in the expected file is a wildcard — skip comparison for that attribute
        if exp_val == "XXXX":
            continue
        if exp_val != act_val:
            diffs.append(f"{path}/@{attr}: expected '{exp_val}', actual '{act_val}'")

    # Compare text (trim whitespace)
    exp_text = (exp_elem.text or "").strip()
    act_text = (act_elem.text or "").strip()
    if exp_text != act_text:
        diffs.append(f"{path}/text(): expected '{exp_text}', actual '{act_text}'")

    # Compare children (order-insensitive by tag — multi-set semantics)
    exp_groups = _group_children_by_tag(exp_elem)
    act_groups = _group_children_by_tag(act_elem)

    all_child_tags = set(exp_groups.keys()).union(act_groups.keys())
    for tag in sorted(all_child_tags):
        exp_list = exp_groups.get(tag, [])
        act_list = act_groups.get(tag, [])

        if len(exp_list) != len(act_list):
            diffs.append(f"{path}/{tag}[*]: expected {len(exp_list)} <{tag}>, actual {len(act_list)}")
            continue

        for i, (e, a) in enumerate(zip(exp_list, act_list), start=1):
            _compare_elements(e, a, diffs, path=f"{path}/{tag}[{i}]")
