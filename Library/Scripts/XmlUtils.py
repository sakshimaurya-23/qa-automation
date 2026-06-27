import xml.etree.ElementTree as ET


def pretty_print_xml(xml_string):
    """Return a consistently indented XML string. Useful for logging."""
    try:
        root = ET.fromstring(xml_string)
        ET.indent(root, space="  ")
        return ET.tostring(root, encoding="unicode")
    except ET.ParseError:
        return xml_string


def get_attribute_value(xml_string, element_tag, attribute_name):
    """
    Extract a single attribute value from the first matching element.

    Example:
        get_attribute_value(xml, "Shipment", "ShipmentNo")  →  "SHP001"
    """
    try:
        root = ET.fromstring(xml_string)
        element = root.find(f".//{element_tag}")
        if element is not None:
            return element.get(attribute_name)
        return None
    except ET.ParseError:
        return None
