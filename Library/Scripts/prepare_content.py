# import os
# import time
# from datetime import datetime
# import string
# from venv import logger
# from xml.dom import minidom

# import xmltodict
# import dicttoxml
# import json
# import xml.etree.ElementTree as ET
# import re
# from lxml import etree
# from robot.api import logger


# from robot.api.deco import keyword


# def replace_key(xml_string):
#     # Regular expression to find 'OrderHeaderKey' and replace its value with 'XXXX'
#     #updated_xml = re.sub(r'OrderHeaderKey="\d+"', 'OrderHeaderKey="XXXX"', xml_string)
#     #updated_xml = re.sub(r'(\w+Key)="\d+"', r'\1="XXXX"', xml_string)
#     # Replace any key ending with "Key" or "No" followed by a number with "XXXX"
#     #updated_xml = re.sub(r'(\w+(Key|No))="\d+"', r'\1="XXXX"', xml_string)
#     # Fix 4: Extended suffix list to also mask ItemID, OrderedQty, Quantity, MinOrderStatus, MaxOrderStatus
#     updated_xml = re.sub(r'(\w+(Key|No|Date|Desc|ID|Qty|Quantity|Status))="[^"]+"', r'\1="XXXX"', xml_string)
#     # Fix 5: Also mask standalone attributes like Status, ShipNode, EnterpriseCode that aren't caught by suffix pattern
#     updated_xml = re.sub(r'(?<=\s)(Status|ShipNode|EnterpriseCode)="[^"]+"', r'\1="XXXX"', updated_xml)
#     return updated_xml

# @keyword("Normalize Xml")
# def normalize_xml(xml_string):
#     """Normalize XML by parsing, cleaning up and reserializing it to ignore irrelevant differences.
    
#     1. Parses XML and removes blank text
#     2. Sorts child elements by tag name alphabetically
#     3. Removes attributes with "XXXX" value (wildcards used for dynamic values)
#     4. Pretty-prints the result
    
#     This ensures two semantically equivalent XMLs produce identical string output,
#     regardless of child element ordering or dynamic attribute values.
#     """
#     parser = etree.XMLParser(remove_blank_text=True)
#     tree = etree.XML(xml_string, parser)
    
#     def sort_children(element):
#         """Recursively sort child elements by their tag name."""
#         element[:] = sorted(element, key=lambda e: e.tag)
#         for child in element:
#             sort_children(child)
    
#     def remove_xxxx_attributes(element):
#         """Recursively remove attributes with 'XXXX' value (wildcard placeholders)."""
#         attrs_to_remove = [attr for attr, value in element.attrib.items() if value == "XXXX"]
#         for attr in attrs_to_remove:
#             del element.attrib[attr]
#         for child in element:
#             remove_xxxx_attributes(child)
    
#     sort_children(tree)
#     remove_xxxx_attributes(tree)
#     return etree.tostring(tree, pretty_print=True).decode('utf-8')

# def manage_item_with_dynamic_item1(folder_path):
#     folder_path1 = "\\".join(folder_path.split("\\")[0:-1])
#     tpath = folder_path1 + '/Input/manageItemInputWithItemId.xml'
#     with open(tpath) as fd:
#         doc = fd.read()
#         print('after mod', doc)
#         doc1 = xmltodict.parse(doc)
#         json_content = json.loads(json.dumps(doc1).replace("@", "_"))
#         return json_content

# def manage_item_with_dynamic_item(folder_path,file_name):
#     folder_path1 = "\\".join(folder_path.split("\\")[0:-1])
#     tpath = folder_path1 + '/Setup/'+file_name +'.xml'
#     with open(tpath) as fd:
#         doc = fd.read()
#         dt = datetime.today().strftime('%Y%m%d%H%M%S')+ str(int(time.time() * 1000) % 1000)
#         print('before mod', doc)
#         doc = doc.replace('$ItemID', dt)
#     return doc,dt

# def setup_with_dynamic_item(folder_path):
#     with open(folder_path) as fd:
#         doc = fd.read()
#         dt = datetime.today().strftime('%Y%m%d%H%M%S')+ str(int(time.time() * 1000) % 1000)
#         print('before mod', doc)
#         doc = doc.replace('$ItemID', dt)
#         time.sleep(2)  # Sleep for 5 seconds
#     return doc

# def replace_with_dynamic_item(folder_path,dt):
#     with open(folder_path) as fd:
#         doc = fd.read()
#         #dt = datetime.today().strftime('%Y%m%d%H%M%S')+ str(int(time.time() * 1000) % 1000)
#         print('before mod', doc)
#         doc = doc.replace('$ItemID', dt)
#         time.sleep(2)  # Sleep for 5 seconds
#     return doc

# def adjust_inventory_file(item_id,folder_path):
#     folder_path1 = "\\".join(folder_path.split("\\")[0:-1])
#     tpath = folder_path1 + '/Input/adjInvInput.xml'
#     tdirpath = folder_path1 + '/Input/adjInvInputWithItemId.xml'
#     with open(tpath) as fd:
#         doc = fd.read()
#         doc = doc.replace('$ItemID', item_id)
#     return doc

# def create_order_file(item_id,folder_path):
#     folder_path1 = "\\".join(folder_path.split("\\")[0:-1])
#     tpath = folder_path1 + '/Input/createOrderInput.xml'
#     with open(tpath) as fd:
#         doc = fd.read()
#         doc = doc.replace('$ItemID', item_id)
#         doc = doc.replace('$OrderNo', item_id)
#     return doc

# def write_output_file(output1,output,folder_path):
#     folder_path1 = "\\".join(folder_path.split("\\")[0:-1])
#     # Ensure that the content is a string before writing to the file
#     if isinstance(output1, bytes):
#         output1 = output1.decode('utf-8')  # Decoding bytes to string using UTF-8
#     with open(folder_path1 +'/Output/'+output+'.xml', 'w', newline='') as fd:
#         fd.write(output1)

# def xml_to_string(xml_element):
#     # Convert the XML element to a string using `ElementTree.tostring()`
#     xml_string = ET.tostring(xml_element, encoding='unicode', method='xml')
#     return xml_string

# def read_xml_from_file(file_path):
#     # Read XML content from a file and parse it
#     tree = ET.parse(file_path)
#     root1 = tree.getroot()
#     return root1

# def xml_to_string1(xml_element):
#     # Convert the XML element to a string using `ElementTree.tostring()`
#     xml_string = ET.tostring(xml_element, encoding='unicode', method='xml')
#     return xml_string

# def dict_to_xml(dictionary):
#     return dicttoxml.dicttoxml(dictionary).decode()

# def get_date_time():
#     dt = datetime.today().strftime('%Y%m%d%H%M%S') + str(int(time.time() * 1000) % 1000)
#     return dt

# def generic_input_file(file_name,dt):
#     with open(file_name, 'r') as fd:
#         doc = fd.read()
#         #dt = datetime.today().strftime('%Y%m%d%H%M%S') + str(int(time.time() * 1000) % 1000)
#         print('before mod', doc)
#         doc = doc.replace('${DATETS}', dt)
#     return doc


# def generic_input_file2(folder_path, file_name):
#     folder_path1 = "\\".join(folder_path.split("\\")[0:-1])
#     # folder_path1 = folder_path


#     tpath = folder_path1 + '/Input/' + file_name + '.xml'
#     with open(tpath) as fd:
#         doc = fd.read()
#     return doc


# def generic_input_file_with_replace_itemid(folder_path, file_name, dt):
#     # Construct the file path by removing the last directory name
#     folder_path1 = "\\".join(folder_path.split("\\")[0:-1])
#     tpath = folder_path1 + '/Input/' + file_name + '.xml'

#     # Open and read the XML file
#     with open(tpath) as fd:
#         doc = fd.read()

#     # Check if $ItemID is present in the document and replace it with $abc if found
#     if '$ItemID' in doc:
#         doc = doc.replace('$ItemID', dt)

#     # Return the potentially modified document
#     return doc


# def read_input_file(folder_path,file):
#     folder_path1 = "\\".join(folder_path.split("\\")[0:-1])
#     tpath = folder_path1 + file
#     with open(tpath) as fd:
#         doc = fd.read()
#     return doc

# def remove_last_folder_from_path(folder_path):
#     # Normalize the path (convert forward slashes to backslashes if needed)
#     folder_path = folder_path.replace('/', '\\')

#     # Remove trailing backslash if present
#     if folder_path.endswith('\\'):
#         folder_path = folder_path[:-1]

#     # Split the path into its parts
#     path_parts = folder_path.split('\\')

#     # Remove the last folder from the path
#     path_parts_without_last = path_parts[:-1]

#     # Join the remaining parts to form the new path
#     updated_folder_path = '\\'.join(path_parts_without_last)

#     return updated_folder_path

# def generic_setup_file(folder_path,file_name):
#     folder_path1 = "\\".join(folder_path.split("\\")[0:-1])
#     tpath = folder_path1 + '/Setup/'+file_name+'.xml'
#     with open(tpath) as fd:
#         doc = fd.read()
#     return doc

# def generic_teardown_file(folder_path,file_name):
#     folder_path1 = "\\".join(folder_path.split("\\")[0:-1])
#     tpath = folder_path1 + '/Teardown/'+file_name+'.xml'
#     with open(tpath) as fd:
#         doc = fd.read()
#     return doc

# def generic_input_json_file(folder_path, file_name):
#     # If file_name is already a full path (contains path separators), use it directly
#     if os.path.dirname(file_name) or file_name.startswith('/'):
#         tpath = file_name
#     else:
#         # Otherwise, construct path from folder_path (legacy behavior)
#         folder_path1 = "\\".join(folder_path.split("\\"))
#         tpath = folder_path1 + '/Data/updated_input/' + file_name + '.json'
#     with open(tpath) as fd:
#         doc = json.load(fd)  # <- PARSE JSON here
#     return doc

# def generic_input_file_oh(folder_path,file_name,oh):
#     folder_path1 = "\\".join(folder_path.split("\\")[0:-1])
#     tpath = folder_path1 + '/Input/'+file_name+'.xml'
#     with open(tpath) as fd:
#         doc = fd.read()
#         doc = doc.replace('${OrderHeaderKey}', oh)
#     return doc


# def generic_input_file_ship(folder_path, file_name, orderReleaseKey, CarrierServiceCode, EnterpriseCode, SCAC, ShipNode,
#                             OrderLineKey, OrderedQty, DocumentType, OrderNo):
#     folder_path1 = "\\".join(folder_path.split("\\")[0:-1])
#     tpath = folder_path1 + '/Input/'+file_name+'.xml'
#     with open(tpath) as fd:
#         doc = fd.read()
#         doc = doc.replace('${OrderReleaseKey}', orderReleaseKey)
#         doc = doc.replace('${CarrierServiceCode}', CarrierServiceCode)
#         doc = doc.replace('${EnterpriseCode}', EnterpriseCode)
#         doc = doc.replace('${SCAC}', SCAC)
#         doc = doc.replace('${ShipNode}', ShipNode)
#         doc = doc.replace('${OrderLineKey}', OrderLineKey)
#         doc = doc.replace('${OrderedQty}', OrderedQty)
#         doc = doc.replace('${DocumentType}', DocumentType)
#         doc = doc.replace('${OrderNo}', OrderNo)
#     return doc

# def generic_input_file_ord(folder_path,file_name,oh):
#     folder_path1 = "\\".join(folder_path.split("\\")[0:-1])
#     tpath = folder_path1 + '/Input/'+file_name+'.xml'
#     with open(tpath) as fd:
#         doc = fd.read()
#         doc = doc.replace('${OrderNo}', oh)
#     return doc

# def generic_input_file_ord_headerkey(folder_path, file_name, order_no, order_header_key, document_type,req_del):
#     folder_path1 = "\\".join(folder_path.split("\\")[0:-1])
#     tpath = folder_path1 + '/Input/' + file_name + '.xml'

#     with open(tpath) as fd:
#         doc = fd.read()
#         doc = doc.replace('${OrderNo}', order_no)
#         doc = doc.replace('${OrderHeaderKey}', order_header_key)
#         doc = doc.replace('${DocumentType}', document_type)
#         doc = doc.replace('${ReqDeliveryDate}', req_del)

#     return doc

# def generic_input_file_ordno_doctype(folder_path, file_name, order_no, document_type):
#     """
#     Reads XML from /Input folder, replaces both ${OrderNo} and ${DocumentType} placeholders.
#     """
#     folder_path1 = "\\".join(folder_path.split("\\")[0:-1])
#     tpath = folder_path1 + '/Input/' + file_name + '.xml'
#     with open(tpath, encoding="utf-8") as fd:
#         doc = fd.read()
#         doc = doc.replace("${OrderNo}", order_no)
#         doc = doc.replace("${DocumentType}", document_type)
#     return doc

# def prepare_update_orderline_input(
#         folder_path,
#         file_name,
#         order_header_key,
#         release_keys,
#         indices="",
#         order_no=""
# ):
#     if indices is None:
#         indices = []
#     elif isinstance(indices, str):
#         indices = indices.strip()

#         if indices in ("", '""'):
#             indices = []
#         else:
#             indices = [int(x.strip()) for x in indices.split(",") if x.strip()]

#     folder_path1 = "\\".join(folder_path.split("\\")[0:-1])
#     file_path = folder_path1 + '/Input/' + file_name + '.xml'
#     print(f"indices = [{indices}]")
#     print(type(indices))

#     with open(file_path, "r", encoding="utf-8") as fd:
#         xml_text = fd.read()

#     # Count OrderReleaseKey placeholders
#     placeholder_count = xml_text.count("${OrderReleaseKey}")

#     # Only validate if placeholders exist
#     if placeholder_count > 0:

#         if len(indices) != placeholder_count:
#             raise ValueError(
#                 f"Your XML supports {placeholder_count} "
#                 f"OrderReleaseKey replacements but "
#                 f"you passed {len(indices)} indices: {indices}. "
#                 f"Please correct XML or index list."
#             )

#         max_key_index = len(release_keys)

#         # Validate indices
#         for idx in indices:
#             if idx < 1 or idx > max_key_index:
#                 raise ValueError(
#                     f"Invalid ReleaseKey index: {idx}. "
#                     f"You only have {max_key_index} ReleaseKeys."
#                 )

#         # Replace placeholders one by one
#         for key_index in indices:
#             replace_value = release_keys[key_index - 1]

#             xml_text = xml_text.replace(
#                 "${OrderReleaseKey}",
#                 replace_value,
#                 1
#             )

#     # Replace OrderHeaderKey placeholder if present
#     if "${OrderHeaderKey}" in xml_text:
#         xml_text = xml_text.replace(
#             "${OrderHeaderKey}",
#             order_header_key
#         )

#     # Replace OrderNo placeholder if present
#     if "${OrderNo}" in xml_text:
#         xml_text = xml_text.replace(
#             "${OrderNo}",
#             order_no
#         )

#     return xml_text




# def generic_input_file_ord2(folder_path, file_name, order_no):
#     # folder_path = C:\CityFurnitureV1\Sprint1\orderFulfillment\CreateOrder
#     input_path = os.path.join(folder_path, 'Input', file_name + '.xml')

#     with open(input_path, 'r', encoding='utf-8') as fd:
#         doc = fd.read()
#         doc = doc.replace('${OrderNo}', order_no)

#     # Write temp file in the same Input directory
#     temp_file_name = 'temp_' + file_name + '.xml'
#     temp_path = os.path.join(folder_path, 'Input', temp_file_name)

#     with open(temp_path, 'w', encoding='utf-8') as f:
#         f.write(doc)
#     return temp_file_name




# def extract_email_or_firstname_from_xml(xml_path):
#     tree = ET.parse(xml_path)
#     root = tree.getroot()

#     ns = {}  # Add namespace if needed

#     email_elem = root.find(".//CustomerContact/EmailID", ns)
#     if email_elem is not None and email_elem.text:
#         return email_elem.text

#     first_name_elem = root.find(".//CustomerContact/FirstName", ns)
#     if first_name_elem is not None and first_name_elem.text:
#         return first_name_elem.text

#     return None
# def replace_customer_search_value(xml_path, search_value):
#     tree = ET.parse(xml_path)
#     root = tree.getroot()

#     for exp in root.findall(".//Exp"):
#         if exp.attrib.get("Name") in ["FirstName", "LastName", "MobilePhone", "EmailID"]:
#             exp.set("Value", search_value)

#     updated_xml = ET.tostring(root, encoding='unicode')
#     return updated_xml


# def assertion_file(folder_path, file_name, oh):
#     folder_path1 = "\\".join(folder_path.split("\\")[0:-1])
#     tpath = folder_path1 + '/assertionFiles/'+file_name+'.xml'
#     with open(tpath) as fd:
#         doc = fd.read()
#         doc = doc.replace('${OrderNo}', oh)
#     return doc

# def json_to_xml(json_obj, root_element):
#     """
#     Convert a JSON object to XML, recursively.
#     """
#     for key, value in json_obj.items():
#         if isinstance(value, dict):
#             # Create a new sub-element for each dictionary
#             sub_element = ET.SubElement(root_element, key)
#             json_to_xml(value, sub_element)
#         elif isinstance(value, list):
#             # If the value is a list, create elements for each item
#             for item in value:
#                 sub_element = ET.SubElement(root_element, key)
#                 json_to_xml(item, sub_element)
#         else:
#             # If the value is a string or number, add it as text in the XML element
#             root_element.set(key, str(value))


# def convert_json_to_xml(json_data1):
#     """
#     Convert JSON string to XML format.
#     """
#     json_content = json.loads(json.dumps(json_data1))
#     # Convert dictionary to a JSON string and write it to the file
#     json_data = json.dumps(json_content)  # Convert dict to JSON string
#     json_obj = json.loads(json_data)

#     # Create the root element of the XML
#     root_element = ET.Element("Root")

#     # Convert the JSON to XML, starting from the root
#     json_to_xml(json_obj, root_element)

#     # Convert the XML tree to a string
#     xml_str = ET.tostring(root_element, encoding="unicode", method="xml")

#     # Format the XML (optional for readability)
#     xml_str = minidom.parseString(xml_str).toprettyxml()

#     return xml_str

# def getOrderDetails_input_file2(order_no,Order_Header_Key,folder_path):
#     folder_path1 = "\\".join(folder_path.split("\\")[0:-1])
#     tpath = folder_path1 + '/Input/getOrderDetails.xml'
#     inner_template = string.Template(
#         '    <Order DocumentType="${DocumentType}" EnterpriseCode="${EnterpriseCode}" OrderHeaderKey="${OrderHeaderKey}" OrderNo="${OrderNo}"></Order>')
#     outer_template = string.Template("""
#     ${document_list}
#      """)
#     # <ScheduleOrder  DocumentType="0001" EnterpriseCode="Liverpool" OrderHeaderKey="20241203090251475620" OrderNo="0904202401"/>
#     data = [('0001', 'Liverpool', Order_Header_Key, order_no)]
#     inner_contents = [inner_template.substitute(DocumentType=DocumentType, EnterpriseCode=EnterpriseCode,
#                                                 OrderHeaderKey=OrderHeaderKey, OrderNo=OrderNo) for
#                       (DocumentType, EnterpriseCode, OrderHeaderKey, OrderNo) in data]
#     result = outer_template.substitute(document_list='\n'.join(inner_contents))
#     print(result)
#     with open(tpath, 'w', newline='') as fd:
#         fd.write(result)
#         return result

# #def getOrderDetails_input_file(order_no,Order_Header_Key,folder_path):
# #    folder_path1 = "\\".join(folder_path.split("\\")[0:-1])
# #    tpath = folder_path1 + '/Input/getOrderDetails.xml'
# #    with open(tpath) as fd:
# #        doc = fd.read()
# #        doc = doc.replace('$OrderNo', order_no)
# #        doc = doc.replace('$OrderHeaderKey', Order_Header_Key)
# #        tdirpath = folder_path1 + '/Input/getOrderDetailsInputWithOrderNo.xml'
# #    with open(tdirpath, 'w', newline='') as fd1:
# #            fd1.write(doc1)
# #    return json_content

# def traverse_xml(node, attribute_map):
#     # If the node is an element
#     if isinstance(node, ET.Element):
#         # Process attributes of the element
#         k = 0
#         for attr_name, attr_value in node.attrib.items():
#             # Create the key for the attribute
#             str_key = f"{node.tag}@{attr_name}"

#             # If the key already exists in the map, append a counter to make it unique
#             while str_key in attribute_map:
#                 k += 1
#                 str_key = f"{node.tag}_{k}@{attr_name}"

#             # Add the key-value pair to the dictionary
#             attribute_map[str_key] = attr_value
#             print(f"{node.tag}@{attr_name}: {attr_value}")

#         # Process child nodes recursively
#         for child in node:
#             traverse_xml(child, attribute_map)
#     print('Resulting map:', attribute_map)

# # Function to replace placeholders with dictionary values
# def replace_placeholders(xml_str, attribute_map):
#     # Regular expression to match placeholders like ${...}
#     pattern = r'\${(.*?)}'

#     # Find all placeholders in the XML string
#     matches = re.findall(pattern, xml_str)

#     # Iterate over all matches and replace them with dictionary values
#     for match in matches:
#         key = match.strip()  # Remove any extra spaces around the key
#         if key in attribute_map:
#             # Replace the placeholder with the corresponding value from the dictionary
#             value = attribute_map[key]
#             xml_str = xml_str.replace(f'${{{key}}}', value)

#     print('XML_STR:', xml_str)
#     return xml_str

# def custom_log(message, color):
#     """Custom log function with colored output"""
#     robot_message = f"<font color='{color}'>{message}</font>"

# def get_error_description(xml_string):
#     root = ET.fromstring(xml_string)
#     return root.find('Error').attrib.get('ErrorDescription')

# def get_error_description2(xml_string):
#     logger.info("Raw XML passed to get_error_description:\n" + xml_string)

#     try:
#         root = ET.fromstring(xml_string)
#     except ET.ParseError as e:
#         logger.error("Error parsing XML: " + str(e))
#         return "PARSE_ERROR"

#     error_element = root.find('Error')
#     if error_element is None:
#         logger.warn("No <Error> tag found in the response XML.")
#         return "NO_ERROR_TAG"

#     error_description = error_element.attrib.get('ErrorDescription', "NO_DESCRIPTION_ATTR")
#     logger.info("Extracted ErrorDescription: " + error_description)
#     return error_description

# @keyword("Build Order Status Change Xml")
# def build_order_status_change_xml(order_header_key, transaction_id, base_drop_status, order_line_keys,
#                                   save_to_file=None, line_numbers=None):
#     """
#     Dynamically generates an OrderStatusChange XML.

#     Args:
#         order_header_key (str): The OrderHeaderKey value.
#         transaction_id (str): The TransactionId value.
#         base_drop_status (str): The BaseDropStatus value for each OrderLine.
#         order_line_keys (list[str]): List of OrderLineKey values.
#         save_to_file (str, optional): Path to save XML file. If None, only returns XML string.

#     Returns:
#         str: The formatted XML string.
#     """
#     """ 
#     Example:
#         <OrderStatusChange OrderHeaderKey="" TransactionId="READY_FOR_SHIP.0001.ex">
#           <OrderLines>
#             <OrderLine OrderLineKey="" ChangeForAllAvailableQty="Y" BaseDropStatus="3200.10" />
#             <OrderLine OrderLineKey="=" ChangeForAllAvailableQty="Y" BaseDropStatus="3200.10" />
#           </OrderLines>
#         </OrderStatusChange>
#     """
#     if line_numbers:

#         numbers = [int(x) for x in line_numbers.split(",")]

#         for n in numbers:
#             if n < 1 or n > len(order_line_keys):
#                 raise ValueError(f"Invalid line number: {n}")

#         selected_lines = [order_line_keys[n - 1] for n in numbers]

#     else:
#         selected_lines = order_line_keys

#     osc = ET.Element("OrderStatusChange", {
#         "OrderHeaderKey": order_header_key,
#         "TransactionId": transaction_id
#     })

#     order_lines_elem = ET.SubElement(osc, "OrderLines")

#     for line_key in selected_lines:
#         ET.SubElement(order_lines_elem, "OrderLine", {
#             "OrderLineKey": line_key,
#             "ChangeForAllAvailableQty": "Y",
#             "BaseDropStatus": base_drop_status
#         })


#     multiapi = ET.Element("MultiApi")
#     api = ET.SubElement(multiapi, "API", {"Name": "changeOrderStatus"})
#     input_elem = ET.SubElement(api, "Input")

#     input_elem.append(osc)

#     xml_str = minidom.parseString(
#         ET.tostring(multiapi, encoding="utf-8")
#     ).toprettyxml(indent="  ")

#     logger.console("Generated Wrapped XML:\n" + xml_str)

#     if save_to_file:
#         with open(save_to_file, "w", encoding="utf-8") as f:
#             f.write(xml_str)

#     return xml_str

import os
import time
from datetime import datetime
import string
from venv import logger
from xml.dom import minidom

import xmltodict
import dicttoxml
import json
import xml.etree.ElementTree as ET
import re
from lxml import etree
from robot.api import logger


from robot.api.deco import keyword


def replace_key(xml_string):
    # Regular expression to find 'OrderHeaderKey' and replace its value with 'XXXX'
    #updated_xml = re.sub(r'OrderHeaderKey="\d+"', 'OrderHeaderKey="XXXX"', xml_string)
    #updated_xml = re.sub(r'(\w+Key)="\d+"', r'\1="XXXX"', xml_string)
    # Replace any key ending with "Key" or "No" followed by a number with "XXXX"
    #updated_xml = re.sub(r'(\w+(Key|No))="\d+"', r'\1="XXXX"', xml_string)
    # Fix 4: Extended suffix list to also mask ItemID, OrderedQty, Quantity, MinOrderStatus, MaxOrderStatus
    updated_xml = re.sub(r'(\w+(Key|No|Date|Desc|ID|Qty|Quantity|Status))="[^"]+"', r'\1="XXXX"', xml_string)
    # Fix 5: Also mask standalone attributes like Status, ShipNode, EnterpriseCode that aren't caught by suffix pattern
    updated_xml = re.sub(r'(?<=\s)(Status|ShipNode|EnterpriseCode)="[^"]+"', r'\1="XXXX"', updated_xml)
    return updated_xml

@keyword("Normalize Xml")
def normalize_xml(xml_string):
    """Normalize XML by parsing, cleaning up and reserializing it to ignore irrelevant differences.

    1. Parses XML and removes blank text
    2. Renames aliased wrapper tags (e.g. <Shipments> -> <ShipmentList>) to a single
       canonical name, so two semantically-equivalent OMS responses that differ only
       in wrapper element naming produce identical string output
    3. Sorts child elements by tag name alphabetically
    4. Removes attributes with "XXXX" value (wildcards used for dynamic values)
    5. Pretty-prints the result

    This ensures two semantically equivalent XMLs produce identical string output,
    regardless of child element ordering, dynamic attribute values, or wrapper-tag
    aliasing (ShipmentList/Shipments). Keep this alias list in sync with
    XmlCompare.py's _TAG_ALIAS_GROUPS so both comparison paths agree.
    """
    parser = etree.XMLParser(remove_blank_text=True)
    tree = etree.XML(xml_string, parser)

    # Must mirror _TAG_ALIAS_GROUPS in XmlCompare.py — keep both lists in sync.
    tag_alias_groups = [
        {"ShipmentList", "Shipments"},
    ]
    tag_canonical = {}
    for group in tag_alias_groups:
        canonical_name = sorted(group)[0]
        for alias in group:
            tag_canonical[alias] = canonical_name

    def canonicalize_tags(element):
        """Recursively rename aliased tags to their canonical form."""
        if element.tag in tag_canonical:
            element.tag = tag_canonical[element.tag]
        for child in element:
            canonicalize_tags(child)

    def sort_children(element):
        """Recursively sort child elements by their tag name."""
        element[:] = sorted(element, key=lambda e: e.tag)
        for child in element:
            sort_children(child)
    
    def remove_xxxx_attributes(element):
        """Recursively remove attributes with 'XXXX' value (wildcard placeholders)."""
        attrs_to_remove = [attr for attr, value in element.attrib.items() if value == "XXXX"]
        for attr in attrs_to_remove:
            del element.attrib[attr]
        for child in element:
            remove_xxxx_attributes(child)
    
    canonicalize_tags(tree)
    sort_children(tree)
    remove_xxxx_attributes(tree)
    return etree.tostring(tree, pretty_print=True).decode('utf-8')

def manage_item_with_dynamic_item1(folder_path):
    folder_path1 = "\\".join(folder_path.split("\\")[0:-1])
    tpath = folder_path1 + '/Input/manageItemInputWithItemId.xml'
    with open(tpath) as fd:
        doc = fd.read()
        print('after mod', doc)
        doc1 = xmltodict.parse(doc)
        json_content = json.loads(json.dumps(doc1).replace("@", "_"))
        return json_content

def manage_item_with_dynamic_item(folder_path,file_name):
    folder_path1 = "\\".join(folder_path.split("\\")[0:-1])
    tpath = folder_path1 + '/Setup/'+file_name +'.xml'
    with open(tpath) as fd:
        doc = fd.read()
        dt = datetime.today().strftime('%Y%m%d%H%M%S')+ str(int(time.time() * 1000) % 1000)
        print('before mod', doc)
        doc = doc.replace('$ItemID', dt)
    return doc,dt

def setup_with_dynamic_item(folder_path):
    with open(folder_path) as fd:
        doc = fd.read()
        dt = datetime.today().strftime('%Y%m%d%H%M%S')+ str(int(time.time() * 1000) % 1000)
        print('before mod', doc)
        doc = doc.replace('$ItemID', dt)
        time.sleep(2)  # Sleep for 5 seconds
    return doc

def replace_with_dynamic_item(folder_path,dt):
    with open(folder_path) as fd:
        doc = fd.read()
        #dt = datetime.today().strftime('%Y%m%d%H%M%S')+ str(int(time.time() * 1000) % 1000)
        print('before mod', doc)
        doc = doc.replace('$ItemID', dt)
        time.sleep(2)  # Sleep for 5 seconds
    return doc

def adjust_inventory_file(item_id,folder_path):
    folder_path1 = "\\".join(folder_path.split("\\")[0:-1])
    tpath = folder_path1 + '/Input/adjInvInput.xml'
    tdirpath = folder_path1 + '/Input/adjInvInputWithItemId.xml'
    with open(tpath) as fd:
        doc = fd.read()
        doc = doc.replace('$ItemID', item_id)
    return doc

def create_order_file(item_id,folder_path):
    folder_path1 = "\\".join(folder_path.split("\\")[0:-1])
    tpath = folder_path1 + '/Input/createOrderInput.xml'
    with open(tpath) as fd:
        doc = fd.read()
        doc = doc.replace('$ItemID', item_id)
        doc = doc.replace('$OrderNo', item_id)
    return doc

def write_output_file(output1,output,folder_path):
    folder_path1 = "\\".join(folder_path.split("\\")[0:-1])
    # Ensure that the content is a string before writing to the file
    if isinstance(output1, bytes):
        output1 = output1.decode('utf-8')  # Decoding bytes to string using UTF-8
    with open(folder_path1 +'/Output/'+output+'.xml', 'w', newline='') as fd:
        fd.write(output1)

def xml_to_string(xml_element):
    # Convert the XML element to a string using `ElementTree.tostring()`
    xml_string = ET.tostring(xml_element, encoding='unicode', method='xml')
    return xml_string

def read_xml_from_file(file_path):
    # Read XML content from a file and parse it
    tree = ET.parse(file_path)
    root1 = tree.getroot()
    return root1

def xml_to_string1(xml_element):
    # Convert the XML element to a string using `ElementTree.tostring()`
    xml_string = ET.tostring(xml_element, encoding='unicode', method='xml')
    return xml_string

def dict_to_xml(dictionary):
    return dicttoxml.dicttoxml(dictionary).decode()

def get_date_time():
    dt = datetime.today().strftime('%Y%m%d%H%M%S') + str(int(time.time() * 1000) % 1000)
    return dt

def generic_input_file(file_name,dt):
    with open(file_name, 'r') as fd:
        doc = fd.read()
        #dt = datetime.today().strftime('%Y%m%d%H%M%S') + str(int(time.time() * 1000) % 1000)
        print('before mod', doc)
        doc = doc.replace('${DATETS}', dt)
    return doc


def generic_input_file2(folder_path, file_name):
    folder_path1 = "\\".join(folder_path.split("\\")[0:-1])
    # folder_path1 = folder_path


    tpath = folder_path1 + '/Input/' + file_name + '.xml'
    with open(tpath) as fd:
        doc = fd.read()
    return doc


def generic_input_file_with_replace_itemid(folder_path, file_name, dt):
    # Construct the file path by removing the last directory name
    folder_path1 = "\\".join(folder_path.split("\\")[0:-1])
    tpath = folder_path1 + '/Input/' + file_name + '.xml'

    # Open and read the XML file
    with open(tpath) as fd:
        doc = fd.read()

    # Check if $ItemID is present in the document and replace it with $abc if found
    if '$ItemID' in doc:
        doc = doc.replace('$ItemID', dt)

    # Return the potentially modified document
    return doc


def read_input_file(folder_path,file):
    folder_path1 = "\\".join(folder_path.split("\\")[0:-1])
    tpath = folder_path1 + file
    with open(tpath) as fd:
        doc = fd.read()
    return doc

def remove_last_folder_from_path(folder_path):
    # Normalize the path (convert forward slashes to backslashes if needed)
    folder_path = folder_path.replace('/', '\\')

    # Remove trailing backslash if present
    if folder_path.endswith('\\'):
        folder_path = folder_path[:-1]

    # Split the path into its parts
    path_parts = folder_path.split('\\')

    # Remove the last folder from the path
    path_parts_without_last = path_parts[:-1]

    # Join the remaining parts to form the new path
    updated_folder_path = '\\'.join(path_parts_without_last)

    return updated_folder_path

def generic_setup_file(folder_path,file_name):
    folder_path1 = "\\".join(folder_path.split("\\")[0:-1])
    tpath = folder_path1 + '/Setup/'+file_name+'.xml'
    with open(tpath) as fd:
        doc = fd.read()
    return doc

def generic_teardown_file(folder_path,file_name):
    folder_path1 = "\\".join(folder_path.split("\\")[0:-1])
    tpath = folder_path1 + '/Teardown/'+file_name+'.xml'
    with open(tpath) as fd:
        doc = fd.read()
    return doc

def generic_input_json_file(folder_path, file_name):
    # If file_name is already a full path (contains path separators), use it directly
    if os.path.dirname(file_name) or file_name.startswith('/'):
        tpath = file_name
    else:
        # Otherwise, construct path from folder_path (legacy behavior)
        folder_path1 = "\\".join(folder_path.split("\\"))
        tpath = folder_path1 + '/Data/updated_input/' + file_name + '.json'
    with open(tpath) as fd:
        doc = json.load(fd)  # <- PARSE JSON here

    # IV-specific validation: shipNode must be numeric.
    # OMS uses OrganizationCode (e.g. "CT_Furniture_INC") as ShipNode in XML payloads,
    # but IV only accepts numeric node IDs (e.g. "1", "71").
    # Catch this mismatch here at load time so we get a clear error instead of a
    # silent 400/404 from the IV API deep in the test run.
    _validate_iv_ship_nodes(doc, tpath)

    return doc


def _validate_iv_ship_nodes(doc, source_path):
    """Validate that every shipNode in an IV JSON payload is a numeric string.

    IV API rejects non-numeric shipNode values (e.g. 'CT_Furniture_INC', '').
    OMS XML payloads use OrganizationCode as ShipNode — those must never reach IV.
    Raises ValueError with a clear message so the framework fails fast with context.
    """
    supplies = doc.get('supplies', [])
    if not isinstance(supplies, list):
        return  # Not an IV supply payload — skip validation

    for i, supply in enumerate(supplies):
        ship_node = supply.get('shipNode', '')
        ship_node_str = str(ship_node).strip()

        # Valid: purely numeric (e.g. "1", "71", 1, 71)
        if ship_node_str.lstrip('-').isdigit():
            continue

        # Invalid: empty, OMS org code, or any non-numeric value
        if not ship_node_str:
            raise ValueError(
                f"IV JSON validation failed in '{source_path}': "
                f"supplies[{i}].shipNode is empty. "
                f"IV requires a numeric shipNode (e.g. '1', '71'). "
                f"Check your adjustInventory.json — never use an OMS OrganizationCode here."
            )
        else:
            raise ValueError(
                f"IV JSON validation failed in '{source_path}': "
                f"supplies[{i}].shipNode='{ship_node_str}' is not numeric. "
                f"IV requires a numeric shipNode (e.g. '1', '71'). "
                f"OMS uses OrganizationCode ('{ship_node_str}') as ShipNode in XML — "
                f"never pass that to the IV API. Fix your adjustInventory.json."
            )

def generic_input_file_oh(folder_path,file_name,oh):
    folder_path1 = "\\".join(folder_path.split("\\")[0:-1])
    tpath = folder_path1 + '/Input/'+file_name+'.xml'
    with open(tpath) as fd:
        doc = fd.read()
        doc = doc.replace('${OrderHeaderKey}', oh)
    return doc


def generic_input_file_ship(folder_path, file_name, orderReleaseKey, CarrierServiceCode, EnterpriseCode, SCAC, ShipNode,
                            OrderLineKey, OrderedQty, DocumentType, OrderNo):
    folder_path1 = "\\".join(folder_path.split("\\")[0:-1])
    tpath = folder_path1 + '/Input/'+file_name+'.xml'
    with open(tpath) as fd:
        doc = fd.read()
        doc = doc.replace('${OrderReleaseKey}', orderReleaseKey)
        doc = doc.replace('${CarrierServiceCode}', CarrierServiceCode)
        doc = doc.replace('${EnterpriseCode}', EnterpriseCode)
        doc = doc.replace('${SCAC}', SCAC)
        doc = doc.replace('${ShipNode}', ShipNode)
        doc = doc.replace('${OrderLineKey}', OrderLineKey)
        doc = doc.replace('${OrderedQty}', OrderedQty)
        doc = doc.replace('${DocumentType}', DocumentType)
        doc = doc.replace('${OrderNo}', OrderNo)
    return doc

def generic_input_file_ord(folder_path,file_name,oh):
    folder_path1 = "\\".join(folder_path.split("\\")[0:-1])
    tpath = folder_path1 + '/Input/'+file_name+'.xml'
    with open(tpath) as fd:
        doc = fd.read()
        doc = doc.replace('${OrderNo}', oh)
    return doc

def generic_input_file_ord_headerkey(folder_path, file_name, order_no, order_header_key, document_type,req_del):
    folder_path1 = "\\".join(folder_path.split("\\")[0:-1])
    tpath = folder_path1 + '/Input/' + file_name + '.xml'

    with open(tpath) as fd:
        doc = fd.read()
        doc = doc.replace('${OrderNo}', order_no)
        doc = doc.replace('${OrderHeaderKey}', order_header_key)
        doc = doc.replace('${DocumentType}', document_type)
        doc = doc.replace('${ReqDeliveryDate}', req_del)

    return doc

def generic_input_file_ordno_doctype(folder_path, file_name, order_no, document_type):
    """
    Reads XML from /Input folder, replaces both ${OrderNo} and ${DocumentType} placeholders.
    """
    folder_path1 = "\\".join(folder_path.split("\\")[0:-1])
    tpath = folder_path1 + '/Input/' + file_name + '.xml'
    with open(tpath, encoding="utf-8") as fd:
        doc = fd.read()
        doc = doc.replace("${OrderNo}", order_no)
        doc = doc.replace("${DocumentType}", document_type)
    return doc

def prepare_update_orderline_input(
        folder_path,
        file_name,
        order_header_key,
        release_keys,
        indices="",
        order_no=""
):
    if indices is None:
        indices = []
    elif isinstance(indices, str):
        indices = indices.strip()

        if indices in ("", '""'):
            indices = []
        else:
            indices = [int(x.strip()) for x in indices.split(",") if x.strip()]

    folder_path1 = "\\".join(folder_path.split("\\")[0:-1])
    file_path = folder_path1 + '/Input/' + file_name + '.xml'
    print(f"indices = [{indices}]")
    print(type(indices))

    with open(file_path, "r", encoding="utf-8") as fd:
        xml_text = fd.read()

    # Count OrderReleaseKey placeholders
    placeholder_count = xml_text.count("${OrderReleaseKey}")

    # Only validate if placeholders exist
    if placeholder_count > 0:

        if len(indices) != placeholder_count:
            raise ValueError(
                f"Your XML supports {placeholder_count} "
                f"OrderReleaseKey replacements but "
                f"you passed {len(indices)} indices: {indices}. "
                f"Please correct XML or index list."
            )

        max_key_index = len(release_keys)

        # Validate indices
        for idx in indices:
            if idx < 1 or idx > max_key_index:
                raise ValueError(
                    f"Invalid ReleaseKey index: {idx}. "
                    f"You only have {max_key_index} ReleaseKeys."
                )

        # Replace placeholders one by one
        for key_index in indices:
            replace_value = release_keys[key_index - 1]

            xml_text = xml_text.replace(
                "${OrderReleaseKey}",
                replace_value,
                1
            )

    # Replace OrderHeaderKey placeholder if present
    if "${OrderHeaderKey}" in xml_text:
        xml_text = xml_text.replace(
            "${OrderHeaderKey}",
            order_header_key
        )

    # Replace OrderNo placeholder if present
    if "${OrderNo}" in xml_text:
        xml_text = xml_text.replace(
            "${OrderNo}",
            order_no
        )

    return xml_text




def generic_input_file_ord2(folder_path, file_name, order_no):
    # folder_path = C:\CityFurnitureV1\Sprint1\orderFulfillment\CreateOrder
    input_path = os.path.join(folder_path, 'Input', file_name + '.xml')

    with open(input_path, 'r', encoding='utf-8') as fd:
        doc = fd.read()
        doc = doc.replace('${OrderNo}', order_no)

    # Write temp file in the same Input directory
    temp_file_name = 'temp_' + file_name + '.xml'
    temp_path = os.path.join(folder_path, 'Input', temp_file_name)

    with open(temp_path, 'w', encoding='utf-8') as f:
        f.write(doc)
    return temp_file_name




def extract_email_or_firstname_from_xml(xml_path):
    tree = ET.parse(xml_path)
    root = tree.getroot()

    ns = {}  # Add namespace if needed

    email_elem = root.find(".//CustomerContact/EmailID", ns)
    if email_elem is not None and email_elem.text:
        return email_elem.text

    first_name_elem = root.find(".//CustomerContact/FirstName", ns)
    if first_name_elem is not None and first_name_elem.text:
        return first_name_elem.text

    return None
def replace_customer_search_value(xml_path, search_value):
    tree = ET.parse(xml_path)
    root = tree.getroot()

    for exp in root.findall(".//Exp"):
        if exp.attrib.get("Name") in ["FirstName", "LastName", "MobilePhone", "EmailID"]:
            exp.set("Value", search_value)

    updated_xml = ET.tostring(root, encoding='unicode')
    return updated_xml


def assertion_file(folder_path, file_name, oh):
    folder_path1 = "\\".join(folder_path.split("\\")[0:-1])
    tpath = folder_path1 + '/assertionFiles/'+file_name+'.xml'
    with open(tpath) as fd:
        doc = fd.read()
        doc = doc.replace('${OrderNo}', oh)
    return doc

def json_to_xml(json_obj, root_element):
    """
    Convert a JSON object to XML, recursively.
    """
    for key, value in json_obj.items():
        if isinstance(value, dict):
            # Create a new sub-element for each dictionary
            sub_element = ET.SubElement(root_element, key)
            json_to_xml(value, sub_element)
        elif isinstance(value, list):
            # If the value is a list, create elements for each item
            for item in value:
                sub_element = ET.SubElement(root_element, key)
                json_to_xml(item, sub_element)
        else:
            # If the value is a string or number, add it as text in the XML element
            root_element.set(key, str(value))


def convert_json_to_xml(json_data1):
    """
    Convert JSON string to XML format.
    """
    json_content = json.loads(json.dumps(json_data1))
    # Convert dictionary to a JSON string and write it to the file
    json_data = json.dumps(json_content)  # Convert dict to JSON string
    json_obj = json.loads(json_data)

    # Create the root element of the XML
    root_element = ET.Element("Root")

    # Convert the JSON to XML, starting from the root
    json_to_xml(json_obj, root_element)

    # Convert the XML tree to a string
    xml_str = ET.tostring(root_element, encoding="unicode", method="xml")

    # Format the XML (optional for readability)
    xml_str = minidom.parseString(xml_str).toprettyxml()

    return xml_str

def getOrderDetails_input_file2(order_no,Order_Header_Key,folder_path):
    folder_path1 = "\\".join(folder_path.split("\\")[0:-1])
    tpath = folder_path1 + '/Input/getOrderDetails.xml'
    inner_template = string.Template(
        '    <Order DocumentType="${DocumentType}" EnterpriseCode="${EnterpriseCode}" OrderHeaderKey="${OrderHeaderKey}" OrderNo="${OrderNo}"></Order>')
    outer_template = string.Template("""
    ${document_list}
     """)
    # <ScheduleOrder  DocumentType="0001" EnterpriseCode="Liverpool" OrderHeaderKey="20241203090251475620" OrderNo="0904202401"/>
    data = [('0001', 'Liverpool', Order_Header_Key, order_no)]
    inner_contents = [inner_template.substitute(DocumentType=DocumentType, EnterpriseCode=EnterpriseCode,
                                                OrderHeaderKey=OrderHeaderKey, OrderNo=OrderNo) for
                      (DocumentType, EnterpriseCode, OrderHeaderKey, OrderNo) in data]
    result = outer_template.substitute(document_list='\n'.join(inner_contents))
    print(result)
    with open(tpath, 'w', newline='') as fd:
        fd.write(result)
        return result

#def getOrderDetails_input_file(order_no,Order_Header_Key,folder_path):
#    folder_path1 = "\\".join(folder_path.split("\\")[0:-1])
#    tpath = folder_path1 + '/Input/getOrderDetails.xml'
#    with open(tpath) as fd:
#        doc = fd.read()
#        doc = doc.replace('$OrderNo', order_no)
#        doc = doc.replace('$OrderHeaderKey', Order_Header_Key)
#        tdirpath = folder_path1 + '/Input/getOrderDetailsInputWithOrderNo.xml'
#    with open(tdirpath, 'w', newline='') as fd1:
#            fd1.write(doc1)
#    return json_content

def traverse_xml(node, attribute_map):
    # If the node is an element
    if isinstance(node, ET.Element):
        # Process attributes of the element
        k = 0
        for attr_name, attr_value in node.attrib.items():
            # Create the key for the attribute
            str_key = f"{node.tag}@{attr_name}"

            # If the key already exists in the map, append a counter to make it unique
            while str_key in attribute_map:
                k += 1
                str_key = f"{node.tag}_{k}@{attr_name}"

            # Add the key-value pair to the dictionary
            attribute_map[str_key] = attr_value
            print(f"{node.tag}@{attr_name}: {attr_value}")

        # Process child nodes recursively
        for child in node:
            traverse_xml(child, attribute_map)
    print('Resulting map:', attribute_map)

# Function to replace placeholders with dictionary values
def replace_placeholders(xml_str, attribute_map):
    # Regular expression to match placeholders like ${...}
    pattern = r'\${(.*?)}'

    # Find all placeholders in the XML string
    matches = re.findall(pattern, xml_str)

    # Iterate over all matches and replace them with dictionary values
    for match in matches:
        key = match.strip()  # Remove any extra spaces around the key
        if key in attribute_map:
            # Replace the placeholder with the corresponding value from the dictionary
            value = attribute_map[key]
            xml_str = xml_str.replace(f'${{{key}}}', value)

    print('XML_STR:', xml_str)
    return xml_str

def custom_log(message, color):
    """Custom log function with colored output"""
    robot_message = f"<font color='{color}'>{message}</font>"

def get_error_description(xml_string):
    root = ET.fromstring(xml_string)
    return root.find('Error').attrib.get('ErrorDescription')

def get_error_description2(xml_string):
    logger.info("Raw XML passed to get_error_description:\n" + xml_string)

    try:
        root = ET.fromstring(xml_string)
    except ET.ParseError as e:
        logger.error("Error parsing XML: " + str(e))
        return "PARSE_ERROR"

    error_element = root.find('Error')
    if error_element is None:
        logger.warn("No <Error> tag found in the response XML.")
        return "NO_ERROR_TAG"

    error_description = error_element.attrib.get('ErrorDescription', "NO_DESCRIPTION_ATTR")
    logger.info("Extracted ErrorDescription: " + error_description)
    return error_description

@keyword("Build Order Status Change Xml")
def build_order_status_change_xml(order_header_key, transaction_id, base_drop_status, order_line_keys,
                                  save_to_file=None, line_numbers=None):
    """
    Dynamically generates an OrderStatusChange XML.

    Args:
        order_header_key (str): The OrderHeaderKey value.
        transaction_id (str): The TransactionId value.
        base_drop_status (str): The BaseDropStatus value for each OrderLine.
        order_line_keys (list[str]): List of OrderLineKey values.
        save_to_file (str, optional): Path to save XML file. If None, only returns XML string.

    Returns:
        str: The formatted XML string.
    """
    """ 
    Example:
        <OrderStatusChange OrderHeaderKey="" TransactionId="READY_FOR_SHIP.0001.ex">
          <OrderLines>
            <OrderLine OrderLineKey="" ChangeForAllAvailableQty="Y" BaseDropStatus="3200.10" />
            <OrderLine OrderLineKey="=" ChangeForAllAvailableQty="Y" BaseDropStatus="3200.10" />
          </OrderLines>
        </OrderStatusChange>
    """
    if line_numbers:

        numbers = [int(x) for x in line_numbers.split(",")]

        for n in numbers:
            if n < 1 or n > len(order_line_keys):
                raise ValueError(f"Invalid line number: {n}")

        selected_lines = [order_line_keys[n - 1] for n in numbers]

    else:
        selected_lines = order_line_keys

    osc = ET.Element("OrderStatusChange", {
        "OrderHeaderKey": order_header_key,
        "TransactionId": transaction_id
    })

    order_lines_elem = ET.SubElement(osc, "OrderLines")

    for line_key in selected_lines:
        ET.SubElement(order_lines_elem, "OrderLine", {
            "OrderLineKey": line_key,
            "ChangeForAllAvailableQty": "Y",
            "BaseDropStatus": base_drop_status
        })


    multiapi = ET.Element("MultiApi")
    api = ET.SubElement(multiapi, "API", {"Name": "changeOrderStatus"})
    input_elem = ET.SubElement(api, "Input")

    input_elem.append(osc)

    xml_str = minidom.parseString(
        ET.tostring(multiapi, encoding="utf-8")
    ).toprettyxml(indent="  ")

    logger.console("Generated Wrapped XML:\n" + xml_str)

    if save_to_file:
        with open(save_to_file, "w", encoding="utf-8") as f:
            f.write(xml_str)

    return xml_str