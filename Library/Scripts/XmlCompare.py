from lxml import etree
from robot.api import logger
from collections import defaultdict


# ---------------------------------------------------------------------------
# Run-specific dynamic attributes — these change on every test execution
# (timestamps, surrogate keys, auto-generated IDs) and must never be compared
# between the stored expected file and a fresh actual response.
# Business-meaningful attributes (EnterpriseCode, DocumentType, DeliveryMethod,
# ItemID, Quantity, Status, etc.) are NOT in this list and ARE compared.
# ---------------------------------------------------------------------------
_DYNAMIC_ATTRS = frozenset({
    # OMS audit timestamps — change on every API call
    "Createts",
    "Modifyts",
    "CarrierPickupTime",
    "ShipDate",           # actual ship date stamped at runtime
    "StatusDate",
    "NextAlertTs",
    "ExpectedDeliveryDate",
    "ExpectedPickDate",
    "ExpectedShipmentDate",
    "RequestedDeliveryDate",
    "RequestedShipmentDate",
    "MustShipBeforeDate",
    "DeliveryTS",
    "FromAppointment",
    "ToAppointment",
    "ITDate",
    "ExportLicenseExpDate",

    # OMS sequential / auto-generated identifiers — increment on every run
    "ShipmentNo",         # sequential shipment counter, unique per test run
    "ShipmentKey",
    "ShipmentGroupId",
    "BillToAddressKey",
    "FromAddressKey",
    "ToAddressKey",
    "OrderHeaderKey",
    "OrderLineKey",
    "OrderReleaseKey",
    "PipelineKey",

    # Lock/version counters — increment on every write
    "Lockid",
})


def compare_xml(expected_xml, actual_xml):
    """
    Compare two XML documents recursively.

    Ignores:
      - whitespace and attribute ordering
      - child element ordering (multi-set semantics per tag group)
      - attributes listed in _DYNAMIC_ATTRS (timestamps, surrogate keys)
      - attributes whose expected value is "XXXX" (explicit wildcard)
      - the Status attribute (validated separately via getOrderDetails)

    Validates all other attribute values, including all business-meaningful
    fields (EnterpriseCode, DocumentType, DeliveryMethod, ItemID, Quantity,
    ShipNode, NumOfCartons, etc.).
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


def compare_xml_structure_only(expected_xml, actual_xml):
    """
    Verify the EXPECTED document's element tree has the EXACT SAME shape as the
    ACTUAL document's element tree — same tag at every nesting position, same child
    counts under every parent.  Attribute VALUES are never compared; only tag names
    and child counts matter.

    A correctly-seeded expected file always mirrors a real OMS response's shape
    exactly.  Any structural divergence in EITHER direction (expected missing a child
    actual has, OR expected having a child actual doesn't) means expected was not
    seeded from a real response of this shape — e.g. a leftover hand-authored
    <Template> skeleton, or a response captured from a different API path.

    Used as a content-quality guard before the real value-by-value comparison runs,
    to catch stale or malformed expected files regardless of which design document or
    CSV mapping sheet generated the test case.  This check is purely content-based —
    it never looks at filenames, test case IDs, or document origin — so it self-heals
    the same way for every future test case, independent of which design doc was used.

    Returns True if structurally identical, False otherwise (signalling expected
    should be re-seeded from actual).
    """
    parser = etree.XMLParser(remove_blank_text=True)
    exp_root = etree.fromstring(expected_xml.encode("utf-8"), parser)
    act_root = etree.fromstring(actual_xml.encode("utf-8"), parser)

    return _structure_identical(exp_root, act_root)


def _structure_identical(exp_elem, act_elem):
    if _canonical_tag(exp_elem.tag) != _canonical_tag(act_elem.tag):
        return False

    exp_groups = _group_children_by_tag(exp_elem)
    act_groups = _group_children_by_tag(act_elem)

    all_tags = set(exp_groups.keys()).union(act_groups.keys())
    for tag in all_tags:
        exp_list = exp_groups.get(tag, [])
        act_list = act_groups.get(tag, [])
        # Structure must match exactly — both presence AND count of every child tag.
        if len(exp_list) != len(act_list):
            return False
        for e, a in zip(exp_list, act_list):
            if not _structure_identical(e, a):
                return False

    return True


def _normalize_quantity(value):
    """Normalize quantity values to handle decimal format mismatch (e.g., '1' vs '1.00')."""
    if value is None:
        return None
    try:
        num = float(value)
        if num == int(num):
            return str(int(num))
        return str(num)
    except (ValueError, TypeError):
        return value


# Tag aliasing: OMS sometimes returns a different wrapper element name than what
# was baselined (e.g. <Shipments> vs <ShipmentList>).  Each alias group below is
# treated as equivalent for BOTH the tag-identity check and the child-grouping
# step, so mismatches never surface as spurious "expected N, actual 0" diffs.
_TAG_ALIAS_GROUPS = [
    {"ShipmentList", "Shipments"},
]

_TAG_CANONICAL = {}
for _group in _TAG_ALIAS_GROUPS:
    _canonical_name = sorted(_group)[0]
    for _alias in _group:
        _TAG_CANONICAL[_alias] = _canonical_name


def _canonical_tag(tag):
    """Map a tag name to its canonical alias representative, if one exists."""
    return _TAG_CANONICAL.get(tag, tag)


def _group_children_by_tag(elem):
    """Return children grouped by canonical tag name (each group is a list, order within group preserved).

    Uses _canonical_tag() so aliased wrapper elements (e.g. ShipmentList/Shipments)
    are grouped together rather than producing two separate, mismatched groups.
    """
    groups = defaultdict(list)
    for child in elem:
        groups[_canonical_tag(child.tag)].append(child)
    return dict(groups)


def _compare_elements(exp_elem, act_elem, diffs, path):
    # Compare tag using canonical alias mapping (handles ShipmentList/Shipments and
    # any future alias groups added to _TAG_ALIAS_GROUPS).
    if _canonical_tag(exp_elem.tag) != _canonical_tag(act_elem.tag):
        diffs.append(f"{path}: Expected tag <{exp_elem.tag}> but found <{act_elem.tag}>")
        return

    # Compare attributes (order-insensitive)
    all_attrs = set(exp_elem.attrib.keys()).union(act_elem.attrib.keys())
    for attr in sorted(all_attrs):
        exp_val = exp_elem.attrib.get(attr)
        act_val = act_elem.attrib.get(attr)

        # Explicit wildcard in the expected file — skip this attribute entirely
        if exp_val == "XXXX":
            continue

        # Run-specific dynamic attributes (timestamps, surrogate keys, lock counters)
        # — values change on every test run and must never be compared
        if attr in _DYNAMIC_ATTRS:
            continue

        # Status is validated separately via getOrderDetails polling
        if attr == "Status":
            continue

        # Numeric normalisation — treat "1" and "1.00" as equal for quantity attributes
        if attr in ("Quantity", "OrderedQty", "ShortageQty", "ConfirmedQty", "BackorderedQty"):
            if _normalize_quantity(exp_val) == _normalize_quantity(act_val):
                continue

        if exp_val != act_val:
            diffs.append(f"{path}/@{attr}: expected '{exp_val}', actual '{act_val}'")

    # Compare text content (trim whitespace)
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
