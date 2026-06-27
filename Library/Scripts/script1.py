import itertools
import json
import os
import glob
import xml.etree.ElementTree as ET
import re
import uuid
import random
import time
from datetime import datetime
import xml.dom.minidom

# Global flag to track the first iteration
first_iteration = True
index_tracker = {"index": 1, "last_folder": None}  # Track index & last used folder

def generate_7_digit_unique_id():
    return str(random.randint(1000000, 9999999))

def generate_unique_id_itemid():
    return str(uuid.uuid4())

def execute_xml(xml_path):
    # Placeholder function to "execute" the XML file (replace with actual logic)
    # For now, we'll return the XML path to indicate it was processed.
    return f"{xml_path}"


def get_files_ending_with_map(file_path):
    # Extract the filename from the full file path
    filename = os.path.basename(file_path)

    # Debugging: Print the filename for verification
    print(f"Checking if it's map: '{filename}'")

    # Check if the filename ends with 'map' (case-insensitive)
    if filename.strip().lower().endswith('map'):
        return filename
    else:
        return None


def list_xml_files_in_folder(folder):
    # List XML files in the folder and return them sorted by name
    xml_files = glob.glob(os.path.join(folder, "*.xml"))
    return sorted(xml_files)

def tc_folder(suite_folder):
    # Get the directory path up to TC001
    dir_path = os.path.dirname(suite_folder)  # Remove the filename
    path_up_to_tc001 = os.path.dirname(dir_path)  # Remove 'setup' folder
    return path_up_to_tc001

def get_date_timestamp():
    dt = datetime.today().strftime('%Y%m%d%H%M%S') + str(int(time.time() * 1000) % 1000)
    return dt

def get_all_folders(suite_folder):
    all_executed_xmls = []  # List to store the executed XMLs

    # List all TC subfolders (TC001, TC002, ..., TC020)
    tc_folders = [folder for folder in os.listdir(suite_folder) if
                  os.path.isdir(os.path.join(suite_folder, folder)) and folder.startswith("TC")]

    # Sort the TC folders in ascending order (if not already)
    tc_folders.sort()

    for tc_folder in tc_folders:
        tc_path = os.path.join(suite_folder, tc_folder)

        # Define the subfolders (setup, input, output)
        subfolders = ['setup', 'input', 'output']

        for subfolder in subfolders:
            datetm = get_date_timestamp()
            subfolder_path = os.path.join(tc_path, subfolder)

    return subfolders,datetm

def process_suite_v1(suite_folder):
    all_executed_xmls = []  # List to store the executed XMLs

    # List all TC subfolders (TC001, TC002, ..., TC020)
    tc_folders = [folder for folder in os.listdir(suite_folder) if
                  os.path.isdir(os.path.join(suite_folder, folder)) and folder.startswith("TC")]

    # Sort the TC folders in ascending order (if not already)
    tc_folders.sort()

    for tc_folder in tc_folders:
        tc_path = os.path.join(suite_folder, tc_folder)

        # Define the subfolders (setup, input, output)
        subfolders = ['setup', 'input', 'output']

        for subfolder in subfolders:
            datetm = get_date_timestamp()
            subfolder_path = os.path.join(tc_path, subfolder)

            if os.path.exists(subfolder_path):
                # List XML files in the current subfolder
                xml_files = list_xml_files_in_folder(subfolder_path)

                for xml in xml_files:
                    # Execute the XML file (or collect the XML path in this case)
                    result = execute_xml(xml)
                    all_executed_xmls.append(result)  # Collect result into list

    return all_executed_xmls,datetm


# Example usage
#suite_folder = "Suite"  # Path to the "Suite" folder
#executed_xmls = process_suite(suite_folder)

# Return the list of executed XMLs
#print(executed_xmls)

# Function to extract value from test1.xml based on XPath
def extract_value_from_xml(xml_content, xpath):
    root = ET.fromstring(xml_content)

    # Handle case where the xpath is for an attribute (contains @)
    if '@' in xpath:
        # Split XPath at '@' to separate element and attribute
        element_tag, attribute_name = xpath.split('@')
        element = root.find(element_tag)
        if element is not None:
            return element.get(attribute_name)  # Use get() to fetch attribute value
        else:
            raise ValueError(f"Element '{element_tag}' not found in the XML.")
    else:
        # Handle normal element search
        element = root.find(xpath)
        if element is not None:
            return element.text
        else:
            raise ValueError(f"XPath '{xpath}' not found in the XML.")


# Function to replace placeholders in test2.xml with values extracted from test1.xml
def replace_placeholders_in_xml(test1_content, test2_content):
    # Regular expression to match placeholders like ${Object@Attribute}
    placeholder_pattern = r'\$\{([^@]+)@([^}]+)\}'

    # Dictionary to store extracted values
    extracted_values = {}

    # Function to extract values for placeholders dynamically
    def replace_placeholder(match):
        # Extract the placeholder name and corresponding field
        object_name = match.group(1)
        attribute_name = match.group(2)

        # Create XPath expression based on object and attribute
        xpath = f".//{object_name}@{attribute_name}"

        # Extract the value using XPath
        try:
            value = extract_value_from_xml(test1_content, xpath)
            extracted_values[match.group(0)] = value  # Store the extracted value for reference
            return value  # Replace the placeholder with the extracted value
        except ValueError:
            return match.group(0)  # If XPath not found, keep the original placeholder

    # Replace all placeholders in test2.xml using the regex pattern
    modified_test2_xml = re.sub(placeholder_pattern, replace_placeholder, test2_content)

    return modified_test2_xml, extracted_values


def check_file_contains_mapData(file_path,attribute_name):
    """Check if the filename contains 'mapData' (case insensitive)."""

    file_name = os.path.basename(file_path).strip()  # Remove leading/trailing spaces
    cleaned_file_name = re.sub(r'\s+', '', file_name)  # Remove hidden spaces

    print(f" Checking filename: '{file_name}' (raw)")
    print(f"ASCII Debug: {[ord(c) for c in file_name]}")  # Debug ASCII values

    # Convert to lowercase and check for 'mapData'
    if attribute_name in cleaned_file_name.lower():
        print(" Found 'mapData' in filename!")
        return True
    else:
        print(" 'mapData' NOT found in filename!")
        return False

def check_file_contains_condition(file_path,attribute_name):
    """Check if the filename contains 'mapData' (case insensitive)."""

    file_name = os.path.basename(file_path).strip()  # Remove leading/trailing spaces
    cleaned_file_name = re.sub(r'\s+', '', file_name)  # Remove hidden spaces

    print(f" Checking filename: '{file_name}' (raw)")
    print(f"ASCII Debug: {[ord(c) for c in file_name]}")  # Debug ASCII values

    # Convert to lowercase and check for 'mapData'
    if attribute_name in cleaned_file_name.lower():
        print(" Found 'mapData' in filename!")
        return True
    else:
        print(" 'mapData' NOT found in filename!")
        return False

def check_flag_if_true(flag):
        # Check if the flag is True
        if flag:
            print("The flag is True")
            return True
        else:
            print("The flag is False")
            return False

def fecth_response(Resp,folder_path,file_name):
    #global first_iteration
    # ${Resp.content}
    # Parse the XML data
    root = ET.fromstring(Resp)
    # Create an empty hashmap (dictionary)
    hash_map = {}
    extract_attributes_to_map(file_name,hash_map, folder_path, root)
    # Update the first iteration flag after the first run
    #first_iteration = False



# Function to extract all attributes from an element and add them to the hashmap
def extract_attributes_to_map(file_name,hash_map,folder_path,element, prefix=''):
    # Parse the XML data
    #element = ET.fromstring(xml_data)
    # Loop through all attributes of the element
    for key, value in element.attrib.items():
        # Add each attribute to the hashmap with the full key
        full_key = f"{prefix}{key}" if prefix else key
        hash_map[full_key] = value

    # Recursively add attributes from child elements
    for child in element:
        # Recursively call with the element's tag as a prefix
        extract_attributes_to_map(file_name,hash_map,folder_path,child, prefix=f"{child.tag}@")
        # Write the hashmap to a JSON file
        #if first_iteration:
        with open(folder_path+'/Output/'+file_name+'mapData.json', 'w') as file:
                json.dump(hash_map, file, indent=4)
        #else:
            #with open(folder_path+'/Output/mapData.json', 'a') as file:
                #json.dump(hash_map, file, indent=4)


def load_json_files_output(output_folder):
    """Load all JSON files from the output folder into a single dictionary."""
    json_data = {}

    for filename in os.listdir(output_folder):
        if filename.endswith(".json"):
            json_path = os.path.join(output_folder, filename)
            with open(json_path, "r", encoding="utf-8") as file:
                data = json.load(file)
                json_data.update(data)  # Merge JSON key-value pairs

    return json_data


def replace_variables_in_xml(xml_path, json_data):
    """Replace placeholders in the XML with values from JSON if they exist."""

    # Load XML content
    tree = ET.parse(xml_path)
    root = tree.getroot()
    xml_str = ET.tostring(root, encoding="unicode")

    # Find all placeholders like ${Variable@Key}
    placeholders = re.findall(r"\$\{([^}]+)\}", xml_str)

    for placeholder in placeholders:
        if placeholder in json_data:
            value = json_data[placeholder]  # Get value from JSON
            xml_str = xml_str.replace(f"${{{placeholder}}}", value)  # Replace in XML
        else:
            print(f" Warning: No value found for '{placeholder}', keeping it unchanged.")

    # Save updated XML
    with open(xml_path, "w", encoding="utf-8") as file:
        file.write(xml_str)

    print(f" Updated XML saved: {xml_path}")
    return  xml_str


def write_actual_result(output1, output, folder_path):
    import os as _os
    folder_path1 = folder_path.replace("\\", "/")

    # Reset index if folder_path changes
    if index_tracker["last_folder"] != folder_path:
        index_tracker["index"] = 1  # Reset index
        index_tracker["last_folder"] = folder_path  # Update last_folder

    current_index = index_tracker["index"]  # Store current index before incrementing

    file_path = _os.path.join(folder_path1, "ActualResult", f"{output}{current_index}.xml")

    # Ensure output1 is a string
    if isinstance(output1, bytes):
        output1 = output1.decode('utf-8')  # Decode bytes to string using UTF-8

    with open(file_path, 'w', newline='') as fd:
        fd.write(output1)  # Write as string

    index_tracker["index"] += 1  # Increment index AFTER writing

    return current_index  # Return the SAME index used for writing

def write_actual_result_with_pretty_print(output1, output, folder_path):
    import os as _os
    folder_path1 = folder_path.replace("\\", "/")

    # Reset index if folder_path changes
    if index_tracker["last_folder"] != folder_path:
        index_tracker["index"] = 1  # Reset index
        index_tracker["last_folder"] = folder_path  # Update last_folder

    current_index = index_tracker["index"]  # Store current index before incrementing

    file_path = _os.path.join(folder_path1, "ActualResult", f"{output}{current_index}.xml")

    # Ensure output1 is a string
    if isinstance(output1, bytes):
        output1 = output1.decode('utf-8')  # Decode bytes to string using UTF-8

    # Beautify/format the XML
    try:
        dom = xml.dom.minidom.parseString(output1)  # Parse the XML string
        pretty_xml = dom.toprettyxml(indent="  ")  # Beautify with 2-space indentation
    except Exception as e:
        print(f"Error formatting XML: {e}")
        pretty_xml = output1  # Fallback to raw XML if formatting fails
        pretty_xml = '\n'.join([line for line in pretty_xml.split('\n') if line.strip()])

    # Write to file
    with open(file_path, 'w', newline='') as fd:
        fd.write(pretty_xml)

    index_tracker["index"] += 1  # Increment index AFTER writing

    return current_index  # Return the SAME index used for writing


def list_xml_files(input_dir):
    """Returns a list of all .xml file names (without .xml extension) in the given input directory."""
    pattern = os.path.join(input_dir, "*.xml")
    files = glob.glob(pattern)
    return [os.path.splitext(os.path.basename(f))[0] for f in files]

def get_basename(filepath):
    """Returns just the filename from a full file path."""
    return os.path.basename(filepath)

def get_full_path(base_dir, input_file_name):
    """Returns full path to an input XML file based on base dir and filename."""
    return os.path.join(base_dir, "Input", input_file_name)