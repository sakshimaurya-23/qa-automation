# *** Settings ***
# Library      ../Scripts/generateRandomNumberAndReplaceAllXMLS.py
# Library      ../Scripts/script1.py
# Resource    ../../Library/Robots/variables.robot
# Library      ../Scripts/read.py
# Library      ../Scripts/prepare_content.py
# Library    RequestsLibrary
# Library    OperatingSystem
# Library    SeleniumLibrary
# Library           DateTime
# Library      xmltodict
# Library         Collections
# Library         XML
# Library       Collections
# Library       RequestsLibrary
# Library      JSONLibrary
# Library            String
# Library    ../../Library/Scripts/certificates.py
# Library    ../../Library/Scripts/sessionUtils.py
# Library    ../../Library/Scripts/generateBearerToken.py
# Library    ../Scripts/env_variables.py
# Library    ../Scripts/XmlCompare.py


# *** Variables ***
# ${CUR_DIR}     ${CURDIR}

# #environment variables
# ${ENV}    DEV
# #${ENV}    QA
# *** Keywords ***
# Set Environment Variables
#     ${env_data}=    Evaluate    env_variables.ENVIRONMENTS['${ENV}']    modules=env_variables
#     #Set Suite Variable    ${URL}         ${env_data['URL']}
#     #Set Suite Variable    ${USERNAME}    ${env_data['USERNAME']}
#     #Set Suite Variable    ${PASSWORD}    ${env_data['PASSWORD']}
#     RETURN    ${env_data}

# Send Request to a post session
#     [Arguments]     ${xmlRequest}
#     ${env_data}=    Set Environment Variables
#     ${cert_file}    ${key_file}=    Extract Cert Key From P12    ${env_data['CERTlOCATION']}    ${env_data['CERTPASSWORD']}
#     Create Secure Session With Client Cert    dev    ${env_data['URL']}    ${cert_file}    ${key_file}    ${True}
#     ${params}   create dictionary   YFSEnvironment.progId=Test      InteropApiName=multiApi     ApiName=MultiApi        YFSEnvironment.userId=${env_data['USERNAME']}     YFSEnvironment.password=${env_data['PASSWORD']}       InteropApiData=${xmlRequest}       timeout=30
#     ${resp}=       POST On Session    dev    ${req_uri}  params=${params}
#     Log     Request:${xmlRequest}
#     Log     Response Status Code :${resp}
# #    Log To Console    ${resp.headers['Content-Type']}

#     Log     Response XML:${resp.content}
#     RETURN    ${resp}

# Process JSON For Folder
#     [Arguments]    ${folder}
#     ${json_path}    Set Variable    ${CUR_DIR}/${folder}/updated_files_${folder}.json
#     ${file_exists}    Run Keyword And Return Status    File Should Exist    ${json_path}

#     IF    ${file_exists}
#         ${json_data}    Load Json From File    ${json_path}
#         Log    Processing JSON for ${folder}: ${json_data}
#     ELSE
#         Fail    JSON file not found for ${folder}
#     END

# Process All JSON Files
#     [Arguments]    ${SUITE_PATH}    ${folder}    ${index}
#         ${json_path}    Set Variable    ${SUITE_PATH}/Data/updated_files.json
#         ${json_string}    Get File    ${json_path}
#         ${data}    Convert String To JSON    ${json_string}
#         FOR    ${test_case}    IN    @{data.keys()}
#         ${xml_files}=    Get From Dictionary    ${data}    ${test_case}
#             FOR    ${xml_file}    IN    @{xml_files}
#                 Log To Console    Processing XML file: ${xml_file}
#                 ${xml_content}=    Get File    ${xml_file}
#                 ${xml_content}=    Substitute Extracted Variables    ${xml_content}
#                 ${resp}=    Send XML File    ${xml_content}    ${xml_file}    ${index}

#                 # Extracting ItemID for manageItem*.xml files
#                 ${matchItemXML}=    Run Keyword And Return Status    Should Match Regexp    ${xml_file}    (?i)manageItem(1)?\.xml$
#                 IF    ${matchItemXML}
#                     ${ItemID}=    Extract ItemID    ${resp}
#                     Set Test Variable    ${ItemID}
#                     Set Test Message    Extracted ItemID: ${ItemID}
#                 END

#                 # Fix 1: Extract OrderNo/OrderHeaderKey from any _input.xml response that contains OrderNo=
#                 ${matchInputXML}=    Run Keyword And Return Status    Should Match Regexp    ${xml_file}    (?i)_input\.xml$
#                 IF    ${matchInputXML}
#                     ${hasOrder}=    Run Keyword And Return Status    Should Contain    ${resp.text}    OrderNo=
#                     IF    ${hasOrder}
#                         ${alreadyHasOrderNo}=    Run Keyword And Return Status    Variable Should Exist    \${OrderNo}
#                         IF    not ${alreadyHasOrderNo}
#                             Extract Order Info    ${resp.text}
#                         END
#                     END
#                 END

#                 # Fix 10: Extract OrderLineKey+ShipNode from any _input.xml response that contains OrderLineKey=
#                 ${matchInputXML3}=    Run Keyword And Return Status    Should Match Regexp    ${xml_file}    (?i)_input\.xml$
#                 IF    ${matchInputXML3}
#                     ${hasOrderLineKey}=    Run Keyword And Return Status    Should Contain    ${resp.text}    OrderLineKey=
#                     IF    ${hasOrderLineKey}
#                         ${alreadyHasOrderLineKey}=    Run Keyword And Return Status    Variable Should Exist    \${OrderLineKey_Extracted}
#                         IF    not ${alreadyHasOrderLineKey}
#                             Extract Order Line Key    ${resp.text}
#                         END
#                     END
#                 END

#                 # Fix 9: Extract ShipmentNo/ShipNode/OrderLineKey/OrderReleaseKey from any _input.xml
#                 # response that contains ShipmentNo= (replaces filename-based createShipment check)
#                 ${matchInputXML2}=    Run Keyword And Return Status    Should Match Regexp    ${xml_file}    (?i)_input\.xml$
#                 IF    ${matchInputXML2}
#                     ${hasShipment}=    Run Keyword And Return Status    Should Contain    ${resp.text}    ShipmentNo=
#                     IF    ${hasShipment}
#                         ${alreadyHasShipmentNo}=    Run Keyword And Return Status    Variable Should Exist    \${ShipmentNo_Extracted}
#                         IF    not ${alreadyHasShipmentNo}
#                             Extract Shipment Info    ${resp}
#                         END
#                     END
#                 END

#             END
#         END

#         RETURN    ${resp}

# Extract ItemID
#     [Arguments]    ${resp}
#     ${parsed}=    XML.Parse XML    ${resp.text}
#     ${item}=    XML.Get Element    ${parsed}    .//Item
#     ${ItemID}=    XML.Get Element Attribute    ${item}    ItemID
#     Log To Console    Came to extract ItemID
#     Log To Console    Extracted ItemID: ${ItemID}
#     RETURN   ${ItemID}

# Extract Shipment Info
#     [Arguments]    ${resp}
#     ${parsed}=    XML.Parse XML    ${resp.text}
#     ${shipment}=    XML.Get Element    ${parsed}    .//Shipment
#     ${ShipmentNo_Extracted}=    XML.Get Element Attribute    ${shipment}    ShipmentNo
#     ${ShipNode_Extracted}=    XML.Get Element Attribute    ${shipment}    ShipNode
#     Log To Console    Extracted ShipmentNo: ${ShipmentNo_Extracted}
#     Log To Console    Extracted ShipNode: ${ShipNode_Extracted}
#     Set Test Variable    ${ShipmentNo_Extracted}
#     Set Test Variable    ${ShipNode_Extracted}
#     # Extract the first ShipmentLine for OrderLineKey and OrderReleaseKey
#     ${shipline}=    XML.Get Element    ${parsed}    .//ShipmentLine
#     ${OrderLineKey_Extracted}=    XML.Get Element Attribute    ${shipline}    OrderLineKey
#     ${OrderReleaseKey_Extracted}=    XML.Get Element Attribute    ${shipline}    OrderReleaseKey
#     Log To Console    Extracted OrderLineKey: ${OrderLineKey_Extracted}
#     Log To Console    Extracted OrderReleaseKey: ${OrderReleaseKey_Extracted}
#     Set Test Variable    ${OrderLineKey_Extracted}
#     Set Test Variable    ${OrderReleaseKey_Extracted}
#     Set Test Message    Extracted Shipment: ShipmentNo=${ShipmentNo_Extracted}, ShipNode=${ShipNode_Extracted}

# Substitute Extracted Variables
#     [Arguments]    ${xml_content}
#     # Replace runtime-extracted placeholders that the file preprocessor cannot resolve.
#     # Each variable is only substituted when it has been set by a prior extraction step;
#     # if it has not been set yet the literal placeholder string is left unchanged.

#     # Substitute ${ItemID} extracted from manageItem response
#     ${has_item_id}=    Run Keyword And Return Status    Variable Should Exist    \${ItemID}
#     IF    ${has_item_id}
#         ${xml_content}=    Replace String    ${xml_content}    \${ItemID}    ${ItemID}
#     END

#     # Fix 2: Substitute ${OrderNo} and ${OrderHeaderKey} extracted from createOrder response
#     ${has_order_no}=    Run Keyword And Return Status    Variable Should Exist    \${OrderNo}
#     IF    ${has_order_no}
#         ${xml_content}=    Replace String    ${xml_content}    \${OrderNo}    ${OrderNo}
#     END
#     ${has_order_header_key}=    Run Keyword And Return Status    Variable Should Exist    \${OrderHeaderKey}
#     IF    ${has_order_header_key}
#         ${xml_content}=    Replace String    ${xml_content}    \${OrderHeaderKey}    ${OrderHeaderKey}
#     END

#     ${has_shipment_no}=    Run Keyword And Return Status    Variable Should Exist    \${ShipmentNo_Extracted}
#     IF    ${has_shipment_no}
#         ${xml_content}=    Replace String    ${xml_content}    \${ShipmentNo_Extracted}    ${ShipmentNo_Extracted}
#     END
#     ${has_ship_node}=    Run Keyword And Return Status    Variable Should Exist    \${ShipNode_Extracted}
#     IF    ${has_ship_node}
#         ${xml_content}=    Replace String    ${xml_content}    \${ShipNode_Extracted}    ${ShipNode_Extracted}
#     END
#     ${has_order_line_key}=    Run Keyword And Return Status    Variable Should Exist    \${OrderLineKey_Extracted}
#     IF    ${has_order_line_key}
#         ${xml_content}=    Replace String    ${xml_content}    \${OrderLineKey_Extracted}    ${OrderLineKey_Extracted}
#     END
#     ${has_order_release_key}=    Run Keyword And Return Status    Variable Should Exist    \${OrderReleaseKey_Extracted}
#     IF    ${has_order_release_key}
#         ${xml_content}=    Replace String    ${xml_content}    \${OrderReleaseKey_Extracted}    ${OrderReleaseKey_Extracted}
#     END
#     ${has_release_no}=    Run Keyword And Return Status    Variable Should Exist    \${ReleaseNo_Extracted}
#     IF    ${has_release_no}
#         ${xml_content}=    Replace String    ${xml_content}    \${ReleaseNo_Extracted}    ${ReleaseNo_Extracted}
#     END
#     ${has_prime_line_no}=    Run Keyword And Return Status    Variable Should Exist    \${PrimeLineNo_Extracted}
#     IF    ${has_prime_line_no}
#         ${xml_content}=    Replace String    ${xml_content}    \${PrimeLineNo_Extracted}    ${PrimeLineNo_Extracted}
#     END
#     RETURN    ${xml_content}

# Execute All XML Files
#     [Arguments]    ${SUITE_PATH}    ${folder}    ${index}
#         ${json_path}    Set Variable    ${SUITE_PATH}/Data/updated_files.json
#         ${json_string}    Get File    ${json_path}
#         ${data}    Convert String To JSON    ${json_string}
#         FOR    ${test_case}    IN    @{data.keys()}
#         ${xml_files}=    Get From Dictionary    ${data}    ${test_case}
#             FOR    ${xml_file}    IN    @{xml_files}
#                 ${xml_content}=    Get File    ${xml_file}
#                 ${resp}=    Execute XML File    ${xml_content}    ${xml_file}    ${index}
#             END
#         END
#         RETURN    ${resp}

# Process All JSON Files For IV
#     [Arguments]    ${SUITE_PATH}    ${folder}    ${index}
#         ${json_path}    Set Variable    ${SUITE_PATH}/Data/updated_files.json
#         ${json_string}    Get File    ${json_path}
#         ${data}    Convert String To JSON    ${json_string}
#         FOR    ${test_case}    IN    @{data.keys()}
#         ${xml_files}=    Get From Dictionary    ${data}    ${test_case}
#             FOR    ${xml_file}    IN    @{xml_files}
#                 ${xml_content}=    Get File    ${xml_file}
#                 ${resp}=    Send Json File    ${xml_content}    ${xml_file}    ${index}
#             END
#         END
#         RETURN    ${resp}

# Process All JSON Files to Validate Response
#     [Arguments]    ${SUITE_PATH}    ${folder}    ${index}    ${EXPECTED_ERROR_DESCRIPTION}
#         ${json_path}    Set Variable    ${SUITE_PATH}/Data/updated_files.json
#         ${json_string}    Get File    ${json_path}
#         ${data}    Convert String To JSON    ${json_string}
#         FOR    ${test_case}    IN    @{data.keys()}
#         ${xml_files}=    Get From Dictionary    ${data}    ${test_case}
#             FOR    ${xml_file}    IN    @{xml_files}
#                 ${xml_content}=    Get File    ${xml_file}
#                 Send XML File And Validate Response    ${xml_content}    ${xml_file}    ${index}    ${EXPECTED_ERROR_DESCRIPTION}
#             END
#         END

# Process JSON Data
#     [Arguments]    ${json_data}
#     Log    Processing JSON: ${json_data}

# Check folders
#     [Arguments]     ${CUR_DIR}
#     Log To Console    curdir in check folders:${CUR_DIR}
#     ${subfolders}=    Process Suite    ${CUR_DIR}
#     RETURN     ${subfolders}

# Traverse folders for Json files
#     [Arguments]     ${CUR_DIR}
#     Log To Console    curdir in check folders:${CUR_DIR}
#     ${subfolders}=    Process Suite Json    ${CUR_DIR}
#     RETURN     ${subfolders}

# Execute XML
#     [Arguments]    ${xml_file}
#     Log        Executing XML: ${xml_file}
#     ${folder_path}=    Tc Folder        ${xml_file}
#     RETURN     ${folder_path}

# Send XML File
#     [Arguments]    ${xml_data}    ${xml_file}    ${index}
#     ${resp}=    Invoke MultiApi by Sending Request    ${xml_data}
#     Log   req:${xml_data}
#     Log   resp:${resp}
#     Log To Console   respContent:${resp.content}
#     Check for MapData    ${xml_data}    ${resp.content}    ${xml_file}
#     Log To Console    Entered Here last-3
#     Check for ValidateData    ${resp.content}    ${xml_file}    ${index}
#     RETURN    ${resp}

# Execute XML File
#     [Arguments]    ${xml_data}    ${xml_file}    ${index}
#     ${status}    ${result}=    Run Keyword And Ignore Error    Check for ExecuteData    ${xml_data}    ${xml_file}

#     # Default value
#     ${body}=    Set Variable    </>

#     IF    $status == "PASS"
#         Log To Console    ****My Xml data${xml_data}*****
#         Log To Console    ****My Xml file***${xml_data}*****
#         # If result is a Response object with .text
#         ${has_text}=    Evaluate    hasattr($result, "text")
#         IF    $has_text
#             ${body}=    Set Variable    ${result.text}
#         ELSE
#             # If result is string
#             Run Keyword If    '${result}' != '' and '${result}' != 'None'
#             ...    Set Variable    ${body}    ${result}
#         END
#     END

#     &{resp}=    Create Dictionary    content=${body}
#     Log    req:${xml_data}
#     Log    resp:${resp}
#     Check for MapData    ${xml_data}    ${resp.content}    ${xml_file}
#     ${folder_path}=    Execute XML    ${xml_file}
#     #${resp}=    Get Data Flag    ${folder_path}    ${resp.content}    ${xml_file}
#     ${status}    ${result}=    Run Keyword And Ignore Error    Get Data Flag    ${folder_path}    ${resp.content}    ${xml_file}
#     # Default value
#     ${body}=    Set Variable    </>

#     IF    $status == "PASS"
#         # If result is a Response object with .text
#         ${has_text}=    Evaluate    hasattr($result, "text")
#         IF    $has_text
#             ${body}=    Set Variable    ${result.text}
#         ELSE
#             # If result is string
#             Run Keyword If    '${result}' != '' and '${result}' != 'None'
#             ...    Set Variable    ${body}    ${result}
#         END
#     END
    
#     &{resp}=    Create Dictionary    content=${body}
#     Log    req:${xml_data}
#     Log    resp:${resp}
#     Check for ValidateData    ${resp.content}    ${xml_file}    ${index}
#     RETURN    &{resp}

# Send Json File
#     [Arguments]    ${xml_data}    ${xml_file}    ${index}
#     ${resp}=    Invoke MultiApi by Sending Request    ${xml_data}
#     Log To Console        req:${xml_data}
#     Log To Console    resp:${resp}
#     RETURN    ${resp}

# Send XML File And Validate Response
#     [Arguments]    ${xml_data}    ${xml_file}    ${index}    ${EXPECTED_ERROR_DESCRIPTION}
#     ${resp}=    Invoke MultiApi by Sending Request    ${xml_data}
#     Log    req:${xml_data}
#     Log To Console   resp:${resp}
#     Log To Console   respContent:${resp.content} and XMLFile: ${xml_file}
#     Check for MapData    ${xml_data}    ${resp.content}    ${xml_file}
#     Check for ValidateResponse Content    ${resp}    ${xml_file}    ${index}    ${EXPECTED_ERROR_DESCRIPTION}


# Check for MapData
#        [Arguments]    ${xml_data}    ${resp.content}    ${xml_file}
#        Log    testcase:------------------${xml_file}
#        ${folder_path}=    Execute XML    ${xml_file}
#        ${mapDataflag}=     Check File Contains MapData       ${xml_file}    mapdata
#        Log To Console       mapDataflag:${mapDataflag}
#        Log    mapDataflag:${mapDataflag}
#        Log    content:${resp.content}
#        Log To Console    mapdata content:${resp.content}
#        ${flag}=    Check Flag If True    ${mapDataflag}
#        Log    flag::::::::::::::::::::${flag}
#        Log To Console    mapdata flag :: flag::::::::::::::::::::${flag}
#        ${file_name}=    Get Base Filename       ${xml_file}
#        Log To Console    The file name is....****:${file_name}
#        Log To Console    ****....The xml name is: ${xml_file}
#        #Running Extract Order Info to extract Order No details:
#         ${match}=    Run Keyword And Return Status    Should Match Regexp    ${file_name}    (?i)^create_execute_mapdata(_\d*)?$
#         Log To Console    ****Match is****:${match}
#         IF    ${match}
#             Extract Order Info    ${resp.content}
#         END

#        Run Keyword If    ${FLAG}    Fecth Response    ${resp.content}     ${folder_path}    ${file_name}
#        Get Data Flag    ${folder_path}    ${resp.content}    ${xml_file}

# Check for ExecuteData
#        [Arguments]    ${xml_data}   ${xml_file}
#        Log    testcase:------------------${xml_file}
#        ${folder_path}=    Execute XML    ${xml_file}
#        ${executeDataflag}=     Check File Contains MapData       ${xml_file}    execute
#        Log    executeDataflag:${executeDataflag}
#        ${flag}=    Check Flag If True    ${executeDataflag}
#        Log    flag::::::::::::::::::::${flag}
#        ${file_name}=    Get Base Filename       ${xml_file}
#        ${resp}=    Run Keyword If    ${FLAG}    Invoke Multiapi With Request XML    ${xml_data}
#        Log    content:${resp.content}
#        RETURN    ${resp}

# Invoke Multiapi With Request XML
#     [Arguments]    ${xml_data}
#     ${resp}=    Invoke MultiApi by Sending Request    ${xml_data}
#     RETURN    ${resp}


# Get Data Flag
#        [Arguments]    ${folder_path}    ${resp.content}    ${xml_file}
#        ${getDataflag}=     Check File Contains MapData       ${xml_file}    getdata
#        Log To Console    the folder Path checked here 2nd time:${folder_path}
#        Log    getDataflag:${getDataflag}
#        Log To Console    getDataflag:${getDataflag}
#        Log    content:${resp.content}
#        Log To Console    getDataflag content:${resp.content}
#        ${getflag}=    Check Flag If True    ${getDataflag}
#        Log   getFlag:${getflag}
#        Log To Console    getDataflag::::::::getFlag:${getDataflag}
#        ${resp}=     Run Keyword If    ${getflag}  Get Data Flag is true     ${folder_path}    ${resp.content}    ${xml_file}
#        RETURN    ${resp}

# Extract Order Info
#     [Arguments]    ${resp_content}
#     ${parsed}=    XML.Parse XML    ${resp_content}
#     ${order}=    XML.Get Element    ${parsed}    .//Order
#     ${OrderNo}=    XML.Get Element Attribute    ${order}    OrderNo
#     ${OrderHeaderKey}=    XML.Get Element Attribute    ${order}    OrderHeaderKey
#     Log To Console    Extracted OrderNo: ${OrderNo}
#     Log To Console    Extracted OrderHeaderKey: ${OrderHeaderKey}
#     Set Test Message    Extracted Order from response: OrderNo=${OrderNo}, OrderHeaderKey=${OrderHeaderKey}
#     Set Test Variable    ${OrderNo}
#     Set Test Variable    ${OrderHeaderKey}


# Extract Order Line Key
#     [Arguments]    ${resp_content}
#     ${parsed}=    XML.Parse XML    ${resp_content}
#     ${orderline}=    XML.Get Element    ${parsed}    .//OrderLine
#     ${OrderLineKey_Extracted}=    XML.Get Element Attribute    ${orderline}    OrderLineKey
#     Log To Console    Extracted OrderLineKey: ${OrderLineKey_Extracted}
#     Set Test Variable    ${OrderLineKey_Extracted}
#     # Also extract ShipNode from the order line so createShipment can use the correct node
#     ${hasShipNode}    ${ShipNode_Extracted}=    Run Keyword And Ignore Error    XML.Get Element Attribute    ${orderline}    ShipNode
#     IF    '${hasShipNode}' == 'PASS' and '${ShipNode_Extracted}' != 'None' and '${ShipNode_Extracted}' != ''
#         Log To Console    Extracted ShipNode from OrderLine: ${ShipNode_Extracted}
#         Set Test Variable    ${ShipNode_Extracted}
#     END
#     # Extract ReleaseNo so createShipment can reference the correct order release
#     ${hasReleaseNo}    ${ReleaseNo_Extracted}=    Run Keyword And Ignore Error    XML.Get Element Attribute    ${orderline}    ReleaseNo
#     IF    '${hasReleaseNo}' == 'PASS' and '${ReleaseNo_Extracted}' != 'None' and '${ReleaseNo_Extracted}' != ''
#         Log To Console    Extracted ReleaseNo: ${ReleaseNo_Extracted}
#         Set Test Variable    ${ReleaseNo_Extracted}
#     END
#     # Extract PrimeLineNo so createShipment can reference the correct order line
#     ${hasPrimeLineNo}    ${PrimeLineNo_Extracted}=    Run Keyword And Ignore Error    XML.Get Element Attribute    ${orderline}    PrimeLineNo
#     IF    '${hasPrimeLineNo}' == 'PASS' and '${PrimeLineNo_Extracted}' != 'None' and '${PrimeLineNo_Extracted}' != ''
#         Log To Console    Extracted PrimeLineNo: ${PrimeLineNo_Extracted}
#         Set Test Variable    ${PrimeLineNo_Extracted}
#     END

# Get Data Flag is true
#        [Arguments]    ${folder_path}    ${resp.content}    ${xml_file}
#        ${json_data}=    Load Json Files Output     ${folder_path}${output_foldername}
#        Log    jsonData:${json_data}
#        Log    xmlfile:${xml_file}
#        ${xml_str}=    Replace Variables In Xml    ${xml_file}    ${json_data}
#        Log    ${xml_str}
#        ${resp}=    Invoke MultiApi by Sending Request    ${xml_str}
#        RETURN    ${resp}

# Check for ValidateData
#        [Arguments]    ${resp.content}    ${xml_file}    ${index}
#        ${folder_path}=    Execute XML    ${xml_file}
#        Log    Folder Path:${folder_path} and XML File: ${xml_file}
#        ${valDataflag}=     Check File Contains MapData       ${xml_file}    validatedata
#        Log    mapDataflag:${valDataflag}
#        Log    content:${resp.content}
#        Log    ValidateData content in valdata:${resp.content}
#        Log     mapDataflag:${valDataflag}
#        Log    Entered Here step last-1-i
#        ${valDataflag}=    Check Flag If True    ${valDataflag}
#        ${index}=    Run Keyword If    ${valDataflag}      Increment Index    ${index}     # Increment index after each iteration
#        Log    Entered Here step last-1-ii-ValDataFlag:${valDataflag}
#        Log    Entered Here step last-1-iii
#        Run Keyword If    ${valDataflag}  Get Validate Data Flag Is True And Compare XML   ${folder_path}    ${resp.content}    ${xml_file}    ${index}

# Check for ValidateResponse Content
#        [Arguments]    ${resp}    ${xml_file}    ${index}     ${EXPECTED_ERROR_DESCRIPTION}
#        ${folder_path}=    Execute XML    ${xml_file}
#        ${valDataflag}=     Check File Contains MapData       ${xml_file}    validatedata
#        Log    mapDataflag:${valDataflag}
#        Log    content:${resp.content}
#        ${valDataflag}=    Check Flag If True    ${valDataflag}
#        ${index}=    Run Keyword If    ${valDataflag}      Increment Index    ${index}     # Increment index after each iteration
#        Run Keyword If    ${valDataflag}  Get Validate Data Flag Is True   ${folder_path}    ${resp}    ${xml_file}    ${index}    ${EXPECTED_ERROR_DESCRIPTION}

# Increment Index
#     [Arguments]    ${index}
#     ${index}=    Evaluate    ${index} + 1    # Increment index after each iteration
#     RETURN    ${index}

# Get Validate Data Flag is true
#        [Arguments]    ${folder_path}    ${response}    ${xml_file}    ${index}    ${EXPECTED_ERROR_DESCRIPTION}
#        ${counter}=    Write Actual Result      ${response.content}     ${actualresult_foldername}     ${folder_path}
#        Log    Get Validate Data Flag is true:${folder_path}${actual_result_file}${counter}.xml
#         ${xml_string}=    Decode Bytes To String    ${response.content}    UTF-8
#         ${description}=    Get Error Description    ${xml_string}
#         Should Be Equal    ${description}    ${EXPECTED_ERROR_DESCRIPTION}

# Get Validate Data Flag is true and compare XML
#        [Arguments]    ${folder_path}    ${resp.content}    ${xml_file}    ${index}
#        Log    Entered Here step last-i
#        ${counter}=    Write Actual Result      ${resp.content}     ${actualresult_foldername}     ${folder_path}
#        Log    Entered here step last-ii
#        Log   Get Validate Data Flag is true ::::::::counter:${counter}
#        Log    expectedResultFile:${folder_path}${expected_result_file}${counter}.xml
#        Log    ${folder_path}${actual_result_file}${counter}.xml
#        Compare Expected and Actual XML Files By Removing Dynamic Keys     ${folder_path}${expected_result_file}${counter}.xml    ${folder_path}${actual_result_file}${counter}.xml

# Creating Session
#     [Arguments]     ${SessionName}      ${xmlRequest}
#     Create Session    ${SessionName}    ${BASE_URL}
#     ${params}   create dictionary   YFSEnvironment.progId=Test      InteropApiName=multiApi     ApiName=MultiApi        YFSEnvironment.userId=admin     YFSEnvironment.password=password       InteropApiData=${xmlRequest}       timeout=30
#     ${resp}=       POST On Session    ${SessionName}    ${req_uri}  params=${params}
#     Log     Request:${xmlRequest}
#     Log     Response Status Code :${resp}
#     Log     Response XML:${resp.content}
#     RETURN    ${resp}


# Invoke MultiApi
#     [Arguments]         ${Input_file_Name}    ${dateTime}
#     ${Req}=     Generic Input File  ${Input_file_Name}    ${dateTime}
#     Log    Req:${Req}
#     ${Resp}=     Creating Session    ${Input_file_Name}   ${Req}
#     Log   Resp:${Resp.content}
#     #Set Test Variable    ${createOrderResp}    ${Resp}
#     RETURN     ${Resp}
#     #${order}=     Get Element    ${Resp.content}    .//Order
#     #${OrderNo}=    Get Element Attribute    ${order}    OrderNo
#     #RETURN     ${OrderNo}

# Invoke MultiApi by Sending Request
#     [Arguments]         ${Req}
#     ${Resp}=     Send Request to a post session    ${Req}
#     Status Should Be    200    ${Resp}
#     RETURN     ${Resp}

# Generate Unique ID
#     ${uid}=    Generate 7 Digit Unique Id
#     Set Test Variable    ${uid}

# Remove Dynamic Keys
#     [Arguments]    ${xml}
#     # Use regex to remove dynamic keys or values
#     #${xml}=    Replace String Using Regexp    ${xml}    OrderHeaderKey="\d+"    OrderHeaderKey="XXXX"
#     #${xml}=    Replace String Using Regexp    ${xml}    OrderLineKey="\d+"    OrderLineKey="XXXX"
#     #${updated_xml}=    Evaluate    import re; re.sub(r'OrderHeaderKey="\d+"', 'OrderHeaderKey="XXXX"', '''${xml}''')    # no need for globals()
#     #${updated_xml}=    Evaluate    import re; re.sub(r'OrderHeaderKey="\d+"', 'OrderHeaderKey="XXXX"', '''${xml_string}''')    # Use triple quotes to avoid escaping
#     ${updated_xml}=    Replace Key    ${xml}
#     #${updated_xml}=    Evaluate    import re; re.sub(r'OrderLineKey="\d+"', 'OrderLineKey="XXXX"', '${xml}')    # no need for globals()
#     RETURN    ${updated_xml}

# Convert XML To String By Removing Dynamic Keys
#     [Arguments]    ${xml_object}
#         #Log To Console    Convert XML To String By Removing Dynamic Keys:xmlObj:${xml_object}
#         ${xmlRoot}=       Read Xml From File    ${xml_object}
#         #Log To Console    Convert XML To String By Removing Dynamic Keys::xmlroot:${xmlRoot}
#         ${xml_str}=     Xml To String      ${xmlRoot}
#         #Log To Console    Convert XML To String By Removing Dynamic Keys::xmlstr:${xml_str}
#         RETURN     ${xml_str}

# Normalize XML String By Removing Dynamic Keys
#     [Arguments]    ${xml}
#     ${xml_string}=    Remove Dynamic Keys    ${xml}
#     #Log To Console    Normalize XML String By Removing Dynamic Keys::xmlStr:${xml_string}
#     ${normalized}=    Normalize Xml    ${xml_string}
#     #Log To Console    Normalize XML String By Removing Dynamic Keys::normalized:${normalized}
#     RETURN    ${normalized}

# Compare Expected and Actual XML
#       [Arguments]         ${Expected_Result}    ${ActualResult}    ${CUR_DIR}
#       ${updated_folder_path}=    Remove Last Folder From Path    ${CUR_DIR}
#       Log To Console    expected:${updated_folder_path}${Expected_Result}
#       Log To Console    actual:${updated_folder_path}${ActualResult}

#       ${expres}=     Convert XML To String By Removing Dynamic Keys    ${updated_folder_path}${Expected_Result}
#       ${actres}=     Convert XML To String By Removing Dynamic Keys    ${updated_folder_path}${ActualResult}

#       # Normalize XML strings to ignore formatting differences (e.g., spaces or newlines)
#     ${normalized_expected_string}=    Normalize XML String By Removing Dynamic Keys    ${expres}
#     ${normalized_actual_string}=      Normalize XML String By Removing Dynamic Keys    ${actres}
#     # Compare the normalized XML strings
#     Should Be Equal As Strings    ${normalized_expected_string}    ${normalized_actual_string}

# Compare Expected and Actual XML Files By Removing Dynamic Keys
#       [Arguments]         ${Expected_Result}    ${ActualResult}
#       #Log To Console    compareExp:${Expected_Result}
#       #Log To Console    compareAct:${ActualResult}
#       ${expres}=     Convert XML To String By Removing Dynamic Keys    ${Expected_Result}
#       ${actres}=     Convert XML To String By Removing Dynamic Keys    ${ActualResult}
#       #Log To Console    converted:${expres}
#       #Log To Console    converted:${actres}

#       # Normalize XML strings to ignore formatting differences (e.g., spaces or newlines)
#     ${normalized_expected_string}=    Normalize XML String By Removing Dynamic Keys    ${expres}
#     ${normalized_actual_string}=      Normalize XML String By Removing Dynamic Keys    ${actres}
#     # Compare the normalized XML strings
#     Run Keyword And Continue On Failure    Should Be Equal As Strings    ${normalized_expected_string}    ${normalized_actual_string}
#     Compare Xml    ${expres}    ${actres}
    
# #IV related keywords
# Initialize Token
#     ${token_url}=    Set Variable    https://api.watsoncommerce.ibm.com/inventory/us-1b8d5331/v1/oauth2/token
#     ${client_id}=    Set Variable    LDvKQpNiCyr3NU8gEfPvC0gwOzpF0jkw
#     ${client_secret}=    Set Variable    X3E2XV9wotpndnfvkipX7sGOqY6CqKpy

#     ${token}=    Get Bearer Token    ${token_url}    ${client_id}    ${client_secret}
#     Set Suite Variable    ${dev_b_token}    ${token}
#     Log    Token initialized: ${dev_b_token}
#     Log To Console    Token initialized: ${dev_b_token}

# Create IV GET Session
#     [Arguments]     ${SessionName}    ${url}
#     &{headers}    Create Dictionary    Authorization=${dev_b_token}
#     Create Session    ${SessionName}    ${dev_b_server}
#     #${url1}=    Strip String     ${url}
#     ${url1}=    Replace String    ${url}    ${SPACE}    %20
#     Log To Console    url1:::::::::::::::${url1}
#     ${response}=    GET On Session    ${SessionName}    ${url1}    headers=${headers}
#     Log     response:${response}
#     Log     responsejson:${response.json()}
#     RETURN    ${response}

# Create IV Post Session
#     [Arguments]     ${CUR_DIR}    ${SessionName}    ${url}    ${Input_file_Name}
#     &{headers}    Create Dictionary    Authorization=${dev_b_token}    Content-Type=application/json
#     Create Session    ${SessionName}    ${dev_b_server}
#     ${Request}=     Generic Input Json File    ${CUR_DIR}    ${Input_file_Name}
#     Log    createOrderReq:${Request}
#     ${response}=    Post On session    ${SessionName}    ${url}    headers=${headers}    json=${Request}
#     Log     response:${response}
#     #Status Should Be    202    ${response}
#     RETURN    ${response}

# Validate attribute in response
#     [Arguments]     ${response}    ${attribute}
#     Log To Console    not list ----------------------
#     Log To Console    ${response.json()}
#     Dictionary Should Contain Key     ${response.json()}     ${attribute}
#          ${attr_value}=    Get From Dictionary     ${response.json()}    ${attribute}
#          Log    ${attr_value}
#          #Should Be Equal As Strings    ${shipNode}    ${shipNode_value}
#          RETURN     ${attr_value}

# Validate attribute in response for List
#     [Arguments]     ${response}    ${attribute}
#     Log    has list------------------
#     Status Should Be    200    ${response}    #Check Status as 200
#     Log    ${response.json()}
#     ${item}=    Get From List    ${response.json()}   0
#     ${quantity}=    Get From Dictionary    ${item}    quantity
#     Log    quantity:${quantity}
#     Run Keyword If    ${quantity} > 0    Log    Quantity is greater than zero
#     Run Keyword If    ${quantity} <= 0    Fail    Quantity is not greater than zero
#     #Set Test Message    Test completed: Quantity from Response is :  ${quantity}
#     RETURN     ${quantity}

# #Fetch Order No
# #    [Arguments]         ${createOrderResp}
# #    ${order}=     Get Element    ${createOrderResp.content}    .//Order
# #    ${OrderNo}=    Get Element Attribute    ${order}    OrderNo
# #    RETURN     ${OrderNo}
# Fetch Order No
#     [Arguments]         ${createOrderResp}
#     Log To Console      Fetching Order No from Response
#     Log To Console      Response content: ${createOrderResp.content}
#     ${order}=     Get Element    ${createOrderResp.content}    .//Order
#     Log To Console      Extracted Order Element: ${order}
#     ${OrderNo}=    XML.Get Element Attribute    ${order}    OrderNo
#     Log To Console      OrderNo Extracted: ${OrderNo}
#     Set Test Message    OrderNo Extracted: ${OrderNo}
#     RETURN     ${OrderNo}

# Fetch OrderHeaderKey
#     [Arguments]         ${createOrderResp}
#     ${order}=     Get Element    ${createOrderResp.content}    .//Order
#     ${OrderHeaderKey}=    Get Element Attribute    ${order}    OrderHeaderKey
#     RETURN     ${OrderHeaderKey}
# Get Order Details
#     [Arguments]         ${CUR_DIR}    ${OrderNo}
#     Log To Console      Fetching Order Details for OrderNo: ${OrderNo}
#     ${getOrderDetailsxmlRequest}=     Generic Input File Ord    ${CUR_DIR}    ${getOrderDetails_Input_file_Name}    ${OrderNo}
#     Log To Console      Generated Order Details Request: ${getOrderDetailsxmlRequest}
#     ${getOrderDetailResp}=     Send Request to a post session    ${getOrderDetailsxmlRequest}
#     ${xml_content}=    Decode Bytes To String    ${getOrderDetailResp.content}    UTF-8
#     Log To Console      Decoded Order Details XML: ${xml_content}
#     RETURN     ${xml_content}


# Get Order Details With DocType
#     [Arguments]         ${CUR_DIR}    ${OrderNo}    ${DocumentType}
#     Log To Console      Fetching Order Details for OrderNo: ${OrderNo} and DocumentType: ${DocumentType}
#     ${getOrderDetailsxmlRequest}=     Generic Input File Ordno Doctype    ${CUR_DIR}    ${getOrderDetails_Input_file_Name}    ${OrderNo}    ${DocumentType}
#     Log To Console      Generated Order Details Request: ${getOrderDetailsxmlRequest}
#     ${getOrderDetailResp}=     Send Request to a post session    ${getOrderDetailsxmlRequest}
#     ${xml_content}=    Decode Bytes To String    ${getOrderDetailResp.content}    UTF-8
#     Log To Console      Decoded Order Details XML: ${xml_content}
#     RETURN     ${xml_content}

# Validate Order Status
#     [Arguments]         ${xml_string}    ${status_name}
#     ${order}=     Get Element    ${xml_string}    .//Order
#     ${Status}=    XML.Get Element Attribute    ${order}    Status
#     ${Status}=    Strip String    ${Status}
#     Log     Status From getOrderDetails: ${Status}
#     Should Be Equal As Strings    ${Status}    ${status_name}
#     RETURN     ${xml_string}


# Invoke MultiApi2
#     [Arguments]         ${CUR_DIR}    ${Input_file_Name}
#     ${Req}=     Generic Input File2   ${CUR_DIR}    ${Input_file_Name}
#     ${Resp}=    Send Request to a post session    ${Req}
#     Set Test Variable    ${createOrderResp}    ${Resp}
#     RETURN     ${Resp}


# Create Order V001 Old
#     [Arguments]         ${CUR_DIR}    ${Input_file_Name}
#     ${createOrderResp}=    Invoke MultiApi2    ${CUR_DIR}    ${createOrder_Input_file_Name}
#     Log To Console   createOrderResp: ${createOrderResp}
# #    ${OrderNo}=    Set Variable    CITY-VJ-20250424_341
#     ${OrderNo}=    Fetch Order No    ${createOrderResp}
#     ${getOrderDetailResp}=    Get Order Details    ${CUR_DIR}    ${OrderNo}
#     Log To Console    getOrderDetailResp: ${getOrderDetailResp}
#     ${parsed}=    XML.Parse XML    ${getOrderDetailResp}
#     ${order_element}=    XML.Get Element    ${parsed}    API[@Name="getOrderDetails"]/Output/Order
#     ${OrderHeaderKey}=    XML.Get Element Attribute    ${order_element}    OrderHeaderKey
#     Log To Console    OrderHeaderKey: ${OrderHeaderKey}
#     Validate Order Status    ${getOrderDetailResp}    Created
#     Set Test Message    Test completed: OrderNo is: ${OrderNo}, OrderHeaderKey is: ${OrderHeaderKey}
#     RETURN    ${OrderNo}    ${OrderHeaderKey}

# Create Order V001 Alter1
#     [Arguments]         ${CUR_DIR}    ${Input_file_Name}    ${DocumentType}
#     ${createOrderResp}=    Invoke MultiApi2    ${CUR_DIR}    ${Input_file_Name}
#     Log To Console   createOrderResp: ${createOrderResp.text}
#     # if CreateOrder response has error ---
#     Should Not Contain    ${createOrderResp.text}    <Errors>    CreateOrder API returned error
# #    ${error_found}=    Run Keyword And Return Status    Should Contain    ${createOrderResp.text}    <Errors>
#    # If no errors, continue
#     ${OrderNo}=    Fetch Order No    ${createOrderResp}
#     Log To Console    Extracted OrderNo: ${OrderNo}
#     # Get order details using both OrderNo and DocumentType
#     ${getOrderDetailResp}=    Get Order Details With DocType    ${CUR_DIR}    ${OrderNo}    ${DocumentType}
# #    Log To Console    getOrderDetailResp: ${getOrderDetailResp}

#     ${parsed}=    XML.Parse XML    ${getOrderDetailResp}
#     ${order_element}=    XML.Get Element    ${parsed}    API[@Name="getOrderDetails"]/Output/Order
#     ${OrderHeaderKey}=    XML.Get Element Attribute    ${order_element}    OrderHeaderKey
#     Log To Console    OrderHeaderKey: ${OrderHeaderKey}
#     Validate Order Status    ${getOrderDetailResp}    Created
#     Set Test Message    Test completed: OrderNo is: ${OrderNo}, OrderHeaderKey is: ${OrderHeaderKey}
# #    Set Test Message    OrderHeaderKey is: ${OrderHeaderKey}
#     ${output_dir}=    Replace String    ${CUR_DIR}    \Test    \Output
#     ${output_file}=   Set Variable    ${output_dir}\\actual_result.xml
#     Create Directory    ${output_dir}
#     Create File         ${output_file}    ${getOrderDetailResp}
#     Log To Console    XML saved to: ${output_file}

#     # Preparing the input xml
# #    ${updated_xml}=    Replace String    ${getOrderDetailResp}    <Output>    <Input>
# #    ${updated_xml}=    Replace String    ${updated_xml}    </Output>    </Input>
# #    ${input_dir}=      Replace String    ${CUR_DIR}    \Test    \Input
# #    ${order_details_file}=   Set Variable    ${input_dir}\\orderDetails_input.xml
# #    Create Directory   ${input_dir}
# #    Create File        ${order_details_file}    ${updated_xml}
# #    Log To Console     Updated XML saved to: ${order_details_file}
# #
# #    ${second_resp}=    Invoke MultiApi2    ${CUR_DIR}    ${orderDetails_Input_file_Name}
# #    ${second_resp_text}=    Convert To String    ${second_resp.text}
# #    Log To Console     Second API call response: ${second_resp_text}
# #
# #    ${output_file2}=   Set Variable    ${output_dir}\\getOrderDetails_result.xml
# #    Create File         ${output_file2}    ${second_resp_text}

#     RETURN    ${OrderNo}    ${OrderHeaderKey}

# Create Order V001 Alter
#     [Arguments]         ${CUR_DIR}    ${Input_file_Name}
#     ${createOrderResp}=    Invoke MultiApi2    ${CUR_DIR}    ${createOrder_Input_file_Name}
#     Log To Console   createOrderResp: ${createOrderResp}
# #    ${OrderNo}=    Set Variable    CITY-VJ-20250424_341
#     ${OrderNo}=    Fetch Order No    ${createOrderResp}
#     ${getOrderDetailResp}=    Get Order Details    ${CUR_DIR}    ${OrderNo}
#     Log To Console    getOrderDetailResp: ${getOrderDetailResp}
#     ${parsed}=    XML.Parse XML    ${getOrderDetailResp}
#     ${order_element}=    XML.Get Element    ${parsed}    API[@Name="getOrderDetails"]/Output/Order
#     ${OrderHeaderKey}=    XML.Get Element Attribute    ${order_element}    OrderHeaderKey
#     Log To Console    OrderHeaderKey: ${OrderHeaderKey}
#     Validate Order Status    ${getOrderDetailResp}    Created
#     Set Test Message    Test completed: OrderNo is: ${OrderNo}, OrderHeaderKey is: ${OrderHeaderKey}
#     ${output_dir}=    Replace String    ${CUR_DIR}    \Test    \Output
#     ${output_file}=   Set Variable    ${output_dir}\\actual_result.xml
#     Create Directory    ${output_dir}
#     Create File         ${output_file}    ${getOrderDetailResp}
#     Log To Console    XML saved to: ${output_file}
    
#     #Preparing the input xml
#     ${updated_xml}=    Replace String    ${getOrderDetailResp}    <Output>    <Input>
#     ${updated_xml}=    Replace String    ${updated_xml}    </Output>    </Input>
#     ${input_dir}=      Replace String    ${CUR_DIR}    \Test    \Input
#     ${order_details_file}=   Set Variable    ${input_dir}\\orderDetails_input.xml
#     Create Directory   ${input_dir}
#     Create File        ${order_details_file}    ${updated_xml}
#     Log To Console     Updated XML saved to: ${order_details_file}
    
#     ${second_resp}=    Invoke MultiApi2    ${CUR_DIR}    ${orderDetails_Input_file_Name}
#     ${second_resp_text}=    Convert To String    ${second_resp.text}
#     Log To Console     Second API call response: ${second_resp_text}
    
#     ${output_file2}=   Set Variable    ${output_dir}\\getOrderDetails_result.xml

#     Create File         ${output_file2}    ${second_resp_text}
#     RETURN    ${OrderNo}    ${OrderHeaderKey}

# Schedule Order V001
#     [Arguments]      ${CUR_DIR}   ${OrderNo}
#     Log To Console    Came here to schedule: ${OrderNo}
#     ${resp2}=   Invoke MultiApi2     ${CUR_DIR}    ${scheduleOrder_Input_file_Name}
#     Log To Console    Schedule API Response: ${resp2}  # Log the response

#     # Wait and retry logic, with additional logging for each retry
#     Wait Until Keyword Succeeds    10    10s    ${getOrderDetailResp}=    Get Order Details    ${CUR_DIR}      ${OrderNo}
#     Log To Console    Order Status after retry: ${getOrderDetailResp.Status}

#     # Validate the order status after retrying
#     Validate Order Status    ${getOrderDetailResp}    Scheduled
#     Set Test Message    Test completed: OrderNo is : ${OrderNo}
# #Schedule Order V001 Alter
# #    [Arguments]      ${CUR_DIR}   ${OrderNo}
# #
# #    ${scheduleOrderXML}=    Generic Input File Ord2    ${CUR_DIR}    ${scheduleOrder_Input_file_Name}    ${OrderNo}
# #    Log To Console    Path here ${scheduleOrder_Input_file_Name}
# #    ${resp2}=   Invoke MultiApi2     ${CUR_DIR}    ${scheduleOrderXML}
# #    ${getOrderDetailResp}=    Get Order Details    ${CUR_DIR}      ${OrderNo}
# #    Log To Console    get Order Details Response    ${getOrderDetailResp}
# #    Validate Order Status    ${getOrderDetailResp}    Scheduled
# #
# #    Set Test Message    Test completed: OrderNo is : ${OrderNo}
# Schedule Order V001 Alter
#     [Arguments]      ${CUR_DIR}   ${OrderNo}
#     ${resp2}=   Invoke MultiApi2     ${CUR_DIR}    ${scheduleOrder_Input_file_Name}
#     ${getOrderDetailResp}=    Get Order Details    ${CUR_DIR}      ${OrderNo}
#     Log To Console    get Order Details Response    ${getOrderDetailResp}
#     Validate Order Status    ${getOrderDetailResp}    Scheduled

#     Set Test Message    Test completed: OrderNo is : ${OrderNo}

# Release Order V001 Alter
#     [Arguments]      ${CUR_DIR}   ${OrderNo}
#     Invoke MultiApi2     ${CUR_DIR}    ${releaseOrder_Input_file_Name}
#     ${getOrderDetailResp}=    Get Order Details    ${CUR_DIR}      ${OrderNo}
#     Validate Order Status    ${getOrderDetailResp}    Released
#     Set Test Message    Test completed: OrderNo is : ${OrderNo}

# Confirm Shipment
#     [Arguments]         ${OrderNo}    ${OrderHeaderKey}
#     ${getOrderReleaseListxmlRequest}=     Generic Input File Oh     ${CUR_DIR}    ${getOrderReleaseList_Input_file_Name}    ${OrderHeaderKey}
#     ${resp}=     Send Request to a post session    ${getOrderReleaseListxmlRequest}
#     ${getOrderDetailResp}=    Get Order Details    ${CUR_DIR}     ${OrderNo}
#     ${order}=     Get Element    ${getOrderDetailResp}    .//Order
#     ${Status}=    XML.Get Element Attribute    ${order}    Status
#     ${OrderLine}=     Get Element    ${getOrderDetailResp}    .//OrderLine
#     ${OrderLineKey}=    XML.Get Element Attribute    ${OrderLine}    OrderLineKey
#     ${OrderedQty}=    XML.Get Element Attribute    ${OrderLine}    OrderedQty
#     Parse XML    ${resp.content}
#     ${orderAttr}=     Get Element    ${resp.content}    .//OrderReleaseList/OrderRelease
#     ${orderReleaseKey}=    XML.Get Element Attribute    ${orderAttr}    OrderReleaseKey
#     ${CarrierServiceCode}=    XML.Get Element Attribute    ${orderAttr}    CarrierServiceCode
#     ${DocumentType}=    XML.Get Element Attribute    ${orderAttr}    DocumentType
#     ${EnterpriseCode}=    XML.Get Element Attribute    ${orderAttr}    EnterpriseCode
#     ${SCAC}=    XML.Get Element Attribute    ${orderAttr}    SCAC
#     ${ShipNode}=    XML.Get Element Attribute    ${orderAttr}    ShipNode
#     ${confirmShipmentXmlRequest}=     Generic Input File Ship     ${CUR_DIR}    ${confirmShipment_Input_file_Name}    ${orderReleaseKey}     ${CarrierServiceCode}    ${EnterpriseCode}    ${SCAC}    ${ShipNode}    ${OrderLineKey}    ${OrderedQty}    ${DocumentType}    ${OrderNo}
#     RETURN     ${confirmShipmentXmlRequest}

# Confirm Shipment V001 Alter
#     [Arguments]      ${CUR_DIR}   ${OrderNo}    ${OrderHeaderKey}
#     ${confirmShipmentXmlRequest}=    Confirm Shipment    ${OrderNo}    ${OrderHeaderKey}
#     ${confirmShipmentResp}=     Send Request to a post session   ${confirmShipmentXmlRequest}
#     ${getOrderDetailResp}=    Get Order Details    ${CUR_DIR}       ${OrderNo}
#     Validate Order Status    ${getOrderDetailResp}    Shipped
#     Set Test Message    Test completed: OrderNo is : ${OrderNo}

# Change Order Status V001
#     [Arguments]      ${CUR_DIR}   ${OrderNo}
#     Invoke MultiApi2     ${CUR_DIR}    ${changeOrderStatus_Input_file_Name}
#     ${getOrderDetailResp}=    Get Order Details    ${CUR_DIR}      ${OrderNo}
#     Log To Console    get Order Details Response    ${getOrderDetailResp}
#     Validate Order Status    ${getOrderDetailResp}    Ready For Ship
#     Set Test Message    Test completed: OrderNo is : ${OrderNo}

# Create Shipment V001
#     [Arguments]      ${CUR_DIR}   ${OrderNo}
#     Invoke MultiApi2     ${CUR_DIR}    ${createShipment_Input_file_Name}
#     ${getOrderDetailResp}=    Get Order Details    ${CUR_DIR}      ${OrderNo}
#     Log To Console    get Order Details Response    ${getOrderDetailResp}
#     Validate Order Status    ${getOrderDetailResp}    Included In Shipment
#     Set Test Message    Test completed: OrderNo is : ${OrderNo}



# Get ATP For Nearest Stores V001
#     [Arguments]         ${CUR_DIR}    ${Input_file_Name}
#     ${getATPForNearestStoresResp}=    Invoke MultiApi2    ${CUR_DIR}    ${getATPForNearestStores_Input_file_Name}
#     Log To Console   getATPForNearestStoresRequest: ${getATPForNearestStoresResp}
#     ${xml_content}=    Decode Bytes To String    ${getATPForNearestStoresResp.content}    UTF-8
#     Log To Console      Decoded ATP For Nearest Stores Details XML: ${xml_content}
#     RETURN     ${xml_content}

# #Get ATP For Nearest Stores V001_01
# #    [Arguments]         ${CUR_DIR}    ${Input_file_Name}
# #    Log To Console    CUR_DIR printing here...: ${CUR_DIR} and InputFileName: ${Input_file_Name}
# #    ${getATPForNearestStoresResp}=    Invoke MultiApi2    ${CUR_DIR}    ${getATPForNearestStores_Input_file_Name1}
# #    Log To Console   getATPForNeareesstStoresRequest: ${getATPForNearestStoresResp}
# #    ${xml_content}=    Decode Bytes To String    ${getATPForNearestStoresResp.content}    UTF-8
# #    Log To Console      Decoded ATP For Nearest Stores Details XML: ${xml_content}
# #    # Generate output file path by replacing \Test with \Output
# #    ${output_dir}=    Replace String    ${CUR_DIR}    \Test    \Output
# #    ${output_file}=   Set Variable    ${output_dir}\\actual_result.xml
# #     # To ensure output directory exists
# #    Create Directory    ${output_dir}
# #     # Save decoded XML to the file:
# #    Create File    ${output_file}    ${xml_content}
# #    Log To Console    XML saved to: ${output_file}
# #
# #    RETURN     ${xml_content}

# Get ATP For Nearest Stores V001_01
#     [Arguments]    ${CUR_DIR}    ${Input_file_Name}
#     Log To Console    CUR_DIR printing here...: ${CUR_DIR}
#     Log To Console    Input File Name: ${Input_file_Name}
#     ${getATPForNearestStoresResp}=    Invoke MultiApi2    ${CUR_DIR}    ${Input_file_Name}
#     Log To Console    getATPForNearestStoresRequest: ${getATPForNearestStoresResp}
#     ${xml_content}=    Decode Bytes To String    ${getATPForNearestStoresResp.content}    UTF-8
#     Log To Console    Decoded ATP For Nearest Stores Details XML: ${xml_content}
#     ${output_dir}=    Replace String    ${CUR_DIR}    \Test    \Output
#     ${base_name}=     Get Basename    ${Input_file_Name}
#     ${output_file}=   Set Variable    ${output_dir}\\actual_result_${base_name}.xml
#     Create Directory    ${output_dir}
#     Create File         ${output_file}    ${xml_content}
#     Log To Console    XML saved to: ${output_file}
#     RETURN    ${xml_content}

# Order Status Inquiry V001
#     [Arguments]    ${CUR_DIR}    ${Input_file_Name}
#     Log To Console    CUR_DIR printing here...: ${CUR_DIR}
#     Log To Console    Input File Name: ${Input_file_Name}
#     ${OrderStatusResp}=    Invoke MultiApi2    ${CUR_DIR}    ${Input_file_Name}
#     Log To Console    getOrderStatusRequest: ${OrderStatusResp}
#     ${xml_content}=    Decode Bytes To String    ${OrderStatusResp.content}    UTF-8
#     Log To Console    Decoded Order Status Details XML: ${xml_content}
#     ${output_dir}=    Replace String    ${CUR_DIR}    \Test    \Output
#     ${base_name}=     Get Basename    ${Input_file_Name}
#     ${output_file}=   Set Variable    ${output_dir}\\result_${base_name}.xml
#     Create Directory    ${output_dir}
#     Create File         ${output_file}    ${xml_content}
#     Log To Console    XML saved to: ${output_file}
#     ${orderNos}=    Extract All OrderNos    ${xml_content}
#     Log To Console    >>> Extracted OrderNos: ${orderNos}
#     RETURN    ${xml_content}


# Extract All OrderNos
#     [Arguments]    ${xml_content}
#     ${root}=    Parse XML    ${xml_content}
#     ${Orders}=    Get Elements    ${root}    .//Order
#     ${orderNos}=    Create List
#     FOR    ${order}    IN    @{Orders}
#         ${OrderNo}=    XML.Get Element Attribute    ${order}    OrderNo
#         Append To List    ${orderNos}    ${OrderNo}
#     END
#     ${orderNosStr}=    Catenate    SEPARATOR=,    @{orderNos}
#     Log To Console    >>> All OrderNos: ${orderNosStr}
#     Set Test Message    OrderNos found: ${orderNosStr}
#     RETURN    ${orderNos}


# Create Customer V001
#     [Arguments]         ${CUR_DIR}    ${Input_file_Name}
#     ${createCustomerResp}=    Invoke MultiApi2    ${CUR_DIR}    ${manageCustomerList_Input_file_Name}
#     Log To Console   createOrderResp: ${createCustomerResp}
#     ${xml_content}=    Decode Bytes To String    ${createCustomerResp.content}    UTF-8
#     Log To Console      Decoded Customer Details XML: ${xml_content}
#     RETURN     ${xml_content}

# #Create Customer V001 Alter
# #    [Arguments]         ${CUR_DIR}    ${Input_file_Name}
# #    ${createCustomerResp}=    Invoke MultiApi2    ${CUR_DIR}    ${manageCustomerList_Input_file_Name}
# #    Log To Console   createCustomerResp: ${createCustomerResp}
# #    ${xml_content}=    Decode Bytes To String    ${createCustomerResp.content}    UTF-8
# #    Log To Console      Decoded Customer Details XML: ${xml_content}
# #
# #    # Extract EmailID or FirstName from input file
# #    ${customer_value}=    Extract Email Or Firstname From Xml    ${CUR_DIR}/Input/${manageCustomerList_Input_file_Name}.xml
# #    Log To Console    Extracted Customer Identifier: ${customer_value}
# #
# #    # Replace the value in the search customer input file
# #    ${updated_search_xml}=    Replace Customer Search Value    ${CUR_DIR}/Input/${getCustomerList_Input_file_Name}.xml    ${customer_value}
# #    Log To Console    Updated Search Customer XML: ${updated_search_xml}
# #
# #    # Send Search Request with updated payload
# #    ${getCustomerListResp}=    Send Request to a post session    ${updated_search_xml}
# #    ${search_response}=    Decode Bytes To String    ${getCustomerListResp.content}    UTF-8
# #    Log To Console      Decoded Search Response XML: ${search_response}
# #
# #    RETURN     ${xml_content}

# Item Create V001 Alter
#     [Arguments]    ${CUR_DIR}    ${Input_file_Name}
#     ${ItemCreateResp}=    Invoke MultiApi2    ${CUR_DIR}    ${manageItem_MultiAPi_Input_file_Name}
#     Log To Console    ItemCreateResp: ${ItemCreateResp}

# Search Customer V001
#     [Arguments]         ${CUR_DIR}    ${Input_file_Name}
#     ${getCustomerListResp}=    Invoke MultiApi2    ${CUR_DIR}    ${getCustomerList_Input_file_Name}
#     Log To Console   getCustomerListResponse: ${getCustomerListResp}
#     ${xml_content}=    Decode Bytes To String    ${getCustomerListResp.content}    UTF-8
#     Log To Console      Decoded Customer Details XML: ${xml_content}
#     RETURN     ${xml_content}


# Ship Depart V001
#     [Arguments]    ${CUR_DIR}    ${Input_file_Name}
#     ${ShipDepartResponse}=    Invoke MultiApi2    ${CUR_DIR}    ${Input_file_Name}
#     ${response_text}=    Decode Bytes To String    ${ShipDepartResponse.content}    UTF-8
#     Log To Console    Decoded ShipDepartResponse: ${response_text}
#     RETURN    ${response_text}

# Update Orderlines V001
#     [Arguments]    ${CUR_DIR}    ${Input_file_Name}    ${OrderHeaderKey}    ${order_line_keys}    ${indices}       ${OrderNo}
#     ${updated_xml}=    Prepare Update Orderline Input    ${CUR_DIR}    ${Input_file_Name}    ${OrderHeaderKey}    ${order_line_keys}    ${indices}    ${OrderNo}
#     Log To Console    ${updated_xml}
#     ${UpdateOrderLinesResp}=     Send Request to a post session    ${updated_xml}
#     ${response_text}=    Decode Bytes To String    ${UpdateOrderLinesResp.content}    UTF-8
#     Log To Console      Decoded UpdateOrderlinessFromRoutingResponse: ${response_text}
#     RETURN    ${response_text}

# Send OrderLineList For Routing
#     [Arguments]    ${CUR_DIR}    ${Input_file_Name}
#     ${SendOrderLineResponse}=    Invoke MultiApi2    ${CUR_DIR}    ${SendOrderLine_Input_file_Name}
#     ${response_text}=    Decode Bytes To String    ${SendOrderLineResponse.content}    UTF-8
#     Log To Console    Decoded SendOrderlinesForRoutingResponse: ${response_text}
#     RETURN    ${response_text}

# Should Contain Any
#     [Arguments]    ${text}    @{expected_list}
#     FOR    ${expected}    IN    @{expected_list}
#         ${found}=    Run Keyword And Return Status    Should Be Equal As Strings    ${text}    ${expected}
#         Run Keyword If    ${found}    RETURN
#     END
#     Fail    '${text}' did not match any of: ${expected_list}


# Schedule And Release Order V001
#     [Arguments]    ${CUR_DIR}    ${OrderNo}    ${DocumentType}
#     Log To Console    --- START: Schedule And Release Order for ${OrderNo} ---
#     Log    Starting Schedule and Release Order for OrderNo=${OrderNo}

#     Log To Console    Step 1: Invoking Schedule API using file: ${scheduleOrder_Input_file_Name}
#     ${request_body}=    generic_input_file_ord    ${CUR_DIR}    scheduleOrder    ${OrderNo}
# #    ${request_body}=     Generic Input File Ordno Doctype    ${CUR_DIR}    scheduleOrder    ${OrderNo}    ${DocumentType}

#     Log To Console    Updated XML: ${request_body}
#     Log To Console    ==== Schedule API Request ====
#     ${scheduleOrderResp}=     Send Request to a post session    ${request_body}
#     ${xml_content}=    Decode Bytes To String    ${scheduleOrderResp.content}    UTF-8
#     Log To Console      Decoded Order Details XML: ${xml_content}

#     ${getOrderDetailResp}=    Get Order Details With DocType    ${CUR_DIR}      ${OrderNo}    ${DocumentType}
# #    Log To Console    get Order Details Response    ${getOrderDetailResp}
#     Log To Console    Step 2 Completed: Order details fetched.



#     Log To Console    Step 3-4: Extracting <Order> element
#     ${order_element}=    XML.Get Element    ${getOrderDetailResp}    API[@Name="getOrderDetails"]/Output/Order
#     Log To Console  Extracted Order Element: ${order_element}
#     Log To Console    Step 3-4 Completed.

#     Log To Console    Step 5: Fetching Order Status attribute
#     ${actual_status}=    XML.Get Element Attribute    ${order_element}    Status
#     Log To Console    Actual Order Status: ${actual_status}
#     Log To Console    Order Status Retrieved: ${actual_status}

#     Log To Console    Step 6: Extracting Order Status Lines
#     ${order_status_elements}=    XML.Get Elements    ${getOrderDetailResp}    API[@Name="getOrderDetails"]/Output/Order/OrderStatuses/OrderStatus
#     Log To Console    Order Status Elements Found: ${order_status_elements}
#     Log To Console    Step 6 Completed.

#     Log To Console    Step 7: Extracting Line Keys & Release Keys from status elements
#     ${order_line_keys}=    Create List
#     ${release_keys}=      Create List
#     FOR    ${status_elem}    IN    @{order_status_elements}
#         ${line_key}=    XML.Get Element Attribute    ${status_elem}    OrderLineKey
#         ${release_key}=    XML.Get Element Attribute    ${status_elem}    OrderReleaseKey
#         Append To List    ${order_line_keys}    ${line_key}
#         Append To List    ${release_keys}    ${release_key}
#     END
#     Log To Console    OrderLineKeys: ${order_line_keys}
#     Log To Console    OrderReleaseKeys: ${release_keys}
#     Log To Console    Actual Status: ${actual_status}
#     Run Keyword If    '${actual_status}' == 'Scheduled' or '${actual_status}' == 'Released' or '${actual_status}' == 'Partially Released'    Log To Console    Status validation passed: ${actual_status}    ELSE    Fail    Order status invalid — expected Scheduled or Released but got ${actual_status}
#     Set Test Message    Test completed: OrderNo=${OrderNo}, Status=${actual_status}
#     RETURN    ${actual_status}    ${order_line_keys}    ${release_keys}


# Change Order Status V001 New
#     [Arguments]    ${CUR_DIR}    ${OrderHeaderKey}    ${order_line_keys}    ${TransactionId}    ${BaseDropStatus}    ${Status}    ${OrderNo}    ${DocumentType}    ${line_numbers}
#     ${output_dir}=    Replace String    ${CUR_DIR}    \Test    \Input
#     ${output_file}=   Set Variable    ${output_dir}\\changeOrderStatus_input.xml
#     Create Directory    ${output_dir}

#     ${xml_content_1}=    Build Order Status Change Xml    ${OrderHeaderKey}    ${TransactionId}    ${BaseDropStatus}    ${order_line_keys}    ${output_file}    line_numbers=${line_numbers}
# #    line_numbers=1,2
#     Log To Console    Generated ChangeOrderStatus XML is:
#     Log To Console    ${xml_content_1}

#     ${ChangeOrderResp}=     Send Request to a post session    ${xml_content_1}
#     ${xml_content_2}=    Decode Bytes To String    ${ChangeOrderResp.content}    UTF-8
#     Log To Console      Decoded Order Details XML: ${xml_content_2}

# #    ${getOrderDetailResp}=    Get Order Details    ${CUR_DIR}      ${OrderNo}
# #    Log To Console    get Order Details Response    ${getOrderDetailResp}
# #    Log To Console    ${xml_content}
# #    
# #    ${resp}=    Invoke MultiApi2    ${CUR_DIR}    ${output_file}
# #    ${getOrderDetailResp}=    Get Order Details    ${CUR_DIR}    ${OrderNo}
#     ${getOrderDetailResp}=    Get Order Details With DocType    ${CUR_DIR}      ${OrderNo}    ${DocumentType}
#     Log To Console    get Order Details Response: ${getOrderDetailResp}

#     ${order_node}=    XML.Get Element    ${getOrderDetailResp}    .//Order
#     ${actual_status}=    XML.Get Element Attribute    ${order_node}    Status
#     ${actual_status}=    Strip String    ${actual_status}
#     Log To Console    Actual Status: ${actual_status}

#     Run Keyword If    '${actual_status}' == 'Ready To Route' or '${actual_status}' == 'Partially Ready To Route'
#     ...    Validate Order Status    ${getOrderDetailResp}    ${actual_status}
#     ...    ELSE
#     ...    Fail    Unexpected status received: ${actual_status}

#     Set Test Message    Test completed: OrderHeaderKey=${OrderHeaderKey} OrderNo=${OrderNo}

# GetDeliveryOptions For Fulfillment
#     [Arguments]    ${CUR_DIR}    ${Input_file_Name}
#     ${GetDeliveryOptionsResponse}=    Invoke MultiApi2    ${CUR_DIR}    ${Input_file_Name}
#     ${response_text}=    Decode Bytes To String    ${GetDeliveryOptionsResponse.content}    UTF-8
# #    Log To Console    Decoded GetDeliveryOptionsResponse: ${response_text}
#     RETURN    ${response_text}

# CTOrderRouting New
#     [Arguments]    ${CUR_DIR}    ${Input_file_Name}    ${OrderNo}    ${OrderHeaderKey}    ${DocumentType}    ${ReqDeliveryDate}
#     ${request_body}=    Generic Input File Ord Headerkey
#     ...    ${CUR_DIR}
#     ...    ${Input_file_Name}
#     ...    ${OrderNo}
#     ...    ${OrderHeaderKey}
#     ...    ${DocumentType}
#     ...    ${ReqDeliveryDate}
#     Log To Console    Updated XML: ${request_body}
# #    ${SendOrderLineResponse}=    Invoke MultiApi2   ${CUR_DIR}    ${Input_file_Name}
#     ${SendOrderLineResponse}=    Send Request to a post session    ${request_body}
#     ${response_text}=    Decode Bytes To String
#     ...    ${SendOrderLineResponse.content}
#     ...    UTF-8
#     ${getOrderDetailResp}=    Get Order Details With DocType    ${CUR_DIR}      ${OrderNo}    ${DocumentType}
# #    Log To Console    get Order Details Response    ${getOrderDetailResp}
#     Log To Console    Step 2 Completed: Order details fetched.

#     Log To Console    Step 3-4: Extracting <Order> element
#     ${order_element}=    XML.Get Element    ${getOrderDetailResp}    API[@Name="getOrderDetails"]/Output/Order
#     Log To Console  Extracted Order Element: ${order_element}
#     Log To Console    Step 3-4 Completed.

#     Log To Console    Step 5: Fetching Order Status attribute
#     ${actual_status}=    XML.Get Element Attribute    ${order_element}    Status
#     Log To Console    Actual Order Status: ${actual_status}
#     Log To Console    Order Status Retrieved: ${actual_status}
#     Log To Console    Decoded SendOrderlinesForRoutingResponse: ${response_text}
#     Set Test Message    Test completed: OrderNo=${OrderNo}, Status=${actual_status}
#     RETURN    ${response_text}    ${actual_status}


*** Settings ***
Library      ../Scripts/generateRandomNumberAndReplaceAllXMLS.py
Library      ../Scripts/script1.py
Resource    ../../Library/Robots/variables.robot
Library      ../Scripts/read.py
Library      ../Scripts/prepare_content.py
Library    RequestsLibrary
Library    OperatingSystem
Library    SeleniumLibrary
Library           DateTime
Library      xmltodict
Library         Collections
Library         XML
Library       Collections
Library       RequestsLibrary
Library      JSONLibrary
Library            String
Library    ../../Library/Scripts/certificates.py
Library    ../../Library/Scripts/sessionUtils.py
Library    ../../Library/Scripts/generateBearerToken.py
Library    ../Scripts/env_variables.py
Library    ../Scripts/XmlCompare.py


*** Variables ***
${CUR_DIR}     ${CURDIR}

#environment variables
${ENV}    DEV
#${ENV}    QA
*** Keywords ***
Set Environment Variables
    ${env_data}=    Evaluate    env_variables.ENVIRONMENTS['${ENV}']    modules=env_variables
    #Set Suite Variable    ${URL}         ${env_data['URL']}
    #Set Suite Variable    ${USERNAME}    ${env_data['USERNAME']}
    #Set Suite Variable    ${PASSWORD}    ${env_data['PASSWORD']}
    RETURN    ${env_data}

Send Request to a post session
    [Arguments]     ${xmlRequest}
    ${env_data}=    Set Environment Variables
    ${cert_file}    ${key_file}=    Extract Cert Key From P12    ${env_data['CERTlOCATION']}    ${env_data['CERTPASSWORD']}
    Create Secure Session With Client Cert    dev    ${env_data['URL']}    ${cert_file}    ${key_file}    ${True}
    ${params}   create dictionary   YFSEnvironment.progId=Test      InteropApiName=multiApi     ApiName=MultiApi        YFSEnvironment.userId=${env_data['USERNAME']}     YFSEnvironment.password=${env_data['PASSWORD']}       InteropApiData=${xmlRequest}       timeout=30
    ${resp}=       POST On Session    dev    ${req_uri}  params=${params}
    Log     Request:${xmlRequest}
    Log     Response Status Code :${resp}
#    Log To Console    ${resp.headers['Content-Type']}

    Log     Response XML:${resp.content}
    RETURN    ${resp}

Process JSON For Folder
    [Arguments]    ${folder}
    ${json_path}    Set Variable    ${CUR_DIR}/${folder}/updated_files_${folder}.json
    ${file_exists}    Run Keyword And Return Status    File Should Exist    ${json_path}

    IF    ${file_exists}
        ${json_data}    Load Json From File    ${json_path}
        Log    Processing JSON for ${folder}: ${json_data}
    ELSE
        Fail    JSON file not found for ${folder}
    END

Process All JSON Files
    [Arguments]    ${SUITE_PATH}    ${folder}    ${index}
        ${json_path}    Set Variable    ${SUITE_PATH}/Data/updated_files.json
        ${json_string}    Get File    ${json_path}
        ${data}    Convert String To JSON    ${json_string}
        ${xml_files}=    Get From Dictionary    ${data}    Data
        FOR    ${xml_file}    IN    @{xml_files}
                Log To Console    Processing XML file: ${xml_file}
                ${xml_content}=    Get File    ${xml_file}
                ${xml_content}=    Substitute Extracted Variables    ${xml_content}
                ${resp}=    Send XML File    ${xml_content}    ${xml_file}    ${index}

                # Extracting ItemID for manageItem*.xml files
                ${matchItemXML}=    Run Keyword And Return Status    Should Match Regexp    ${xml_file}    (?i)manageItem(1)?\.xml$
                IF    ${matchItemXML}
                    ${ItemID}=    Extract ItemID    ${resp}
                    Set Test Variable    ${ItemID}
                    Set Test Message    Extracted ItemID: ${ItemID}
                END

                # Fix 1: Extract OrderNo/OrderHeaderKey from any _input.xml response that contains OrderNo=
                ${matchInputXML}=    Run Keyword And Return Status    Should Match Regexp    ${xml_file}    (?i)_input\.xml$
                IF    ${matchInputXML}
                    ${hasOrder}=    Run Keyword And Return Status    Should Contain    ${resp.text}    OrderNo=
                    IF    ${hasOrder}
                        ${alreadyHasOrderNo}=    Run Keyword And Return Status    Variable Should Exist    \${OrderNo}
                        IF    not ${alreadyHasOrderNo}
                            Extract Order Info    ${resp.text}
                        END
                    END
                END

                # Fix 10: Extract OrderLineKey+ShipNode from any _input.xml response that contains OrderLineKey=
                ${matchInputXML3}=    Run Keyword And Return Status    Should Match Regexp    ${xml_file}    (?i)_input\.xml$
                IF    ${matchInputXML3}
                    ${hasOrderLineKey}=    Run Keyword And Return Status    Should Contain    ${resp.text}    OrderLineKey=
                    IF    ${hasOrderLineKey}
                        ${alreadyHasOrderLineKey}=    Run Keyword And Return Status    Variable Should Exist    \${OrderLineKey_Extracted}
                        IF    not ${alreadyHasOrderLineKey}
                            Extract Order Line Key    ${resp.text}
                        END
                    END
                END

                # Fix 9: Extract ShipmentNo/ShipNode/OrderLineKey/OrderReleaseKey from any _input.xml
                # response that contains ShipmentNo= (replaces filename-based createShipment check)
                ${matchInputXML2}=    Run Keyword And Return Status    Should Match Regexp    ${xml_file}    (?i)_input\.xml$
                IF    ${matchInputXML2}
                    ${hasShipment}=    Run Keyword And Return Status    Should Contain    ${resp.text}    ShipmentNo=
                    IF    ${hasShipment}
                        ${alreadyHasShipmentNo}=    Run Keyword And Return Status    Variable Should Exist    \${ShipmentNo_Extracted}
                        IF    not ${alreadyHasShipmentNo}
                            Extract Shipment Info    ${resp}
                        END
                    END
                END

        END

        RETURN    ${resp}

Extract ItemID
    [Arguments]    ${resp}
    ${parsed}=    XML.Parse XML    ${resp.text}
    ${item}=    XML.Get Element    ${parsed}    .//Item
    ${ItemID}=    XML.Get Element Attribute    ${item}    ItemID
    Log To Console    Came to extract ItemID
    Log To Console    Extracted ItemID: ${ItemID}
    RETURN   ${ItemID}

Extract Shipment Info
    [Arguments]    ${resp}
    ${parsed}=    XML.Parse XML    ${resp.text}
    ${shipment}=    XML.Get Element    ${parsed}    .//Shipment
    ${ShipmentNo_Extracted}=    XML.Get Element Attribute    ${shipment}    ShipmentNo
    ${ShipNode_Extracted}=    XML.Get Element Attribute    ${shipment}    ShipNode
    Log To Console    Extracted ShipmentNo: ${ShipmentNo_Extracted}
    Log To Console    Extracted ShipNode: ${ShipNode_Extracted}
    Set Test Variable    ${ShipmentNo_Extracted}
    Set Test Variable    ${ShipNode_Extracted}
    # Extract the first ShipmentLine for OrderLineKey and OrderReleaseKey
    ${shipline}=    XML.Get Element    ${parsed}    .//ShipmentLine
    ${OrderLineKey_Extracted}=    XML.Get Element Attribute    ${shipline}    OrderLineKey
    ${OrderReleaseKey_Extracted}=    XML.Get Element Attribute    ${shipline}    OrderReleaseKey
    Log To Console    Extracted OrderLineKey: ${OrderLineKey_Extracted}
    Log To Console    Extracted OrderReleaseKey: ${OrderReleaseKey_Extracted}
    Set Test Variable    ${OrderLineKey_Extracted}
    Set Test Variable    ${OrderReleaseKey_Extracted}
    Set Test Message    Extracted Shipment: ShipmentNo=${ShipmentNo_Extracted}, ShipNode=${ShipNode_Extracted}

Substitute Extracted Variables
    [Arguments]    ${xml_content}
    # Replace runtime-extracted placeholders that the file preprocessor cannot resolve.
    # Each variable is only substituted when it has been set by a prior extraction step;
    # if it has not been set yet the literal placeholder string is left unchanged.

    # Substitute ${ItemID} extracted from manageItem response
    ${has_item_id}=    Run Keyword And Return Status    Variable Should Exist    \${ItemID}
    IF    ${has_item_id}
        ${xml_content}=    Replace String    ${xml_content}    \${ItemID}    ${ItemID}
    END

    # Fix 2: Substitute ${OrderNo} and ${OrderHeaderKey} extracted from createOrder response
    ${has_order_no}=    Run Keyword And Return Status    Variable Should Exist    \${OrderNo}
    IF    ${has_order_no}
        ${xml_content}=    Replace String    ${xml_content}    \${OrderNo}    ${OrderNo}
    END
    ${has_order_header_key}=    Run Keyword And Return Status    Variable Should Exist    \${OrderHeaderKey}
    IF    ${has_order_header_key}
        ${xml_content}=    Replace String    ${xml_content}    \${OrderHeaderKey}    ${OrderHeaderKey}
    END

    ${has_shipment_no}=    Run Keyword And Return Status    Variable Should Exist    \${ShipmentNo_Extracted}
    IF    ${has_shipment_no}
        ${xml_content}=    Replace String    ${xml_content}    \${ShipmentNo_Extracted}    ${ShipmentNo_Extracted}
    END
    ${has_ship_node}=    Run Keyword And Return Status    Variable Should Exist    \${ShipNode_Extracted}
    IF    ${has_ship_node}
        ${xml_content}=    Replace String    ${xml_content}    \${ShipNode_Extracted}    ${ShipNode_Extracted}
    END
    ${has_order_line_key}=    Run Keyword And Return Status    Variable Should Exist    \${OrderLineKey_Extracted}
    IF    ${has_order_line_key}
        ${xml_content}=    Replace String    ${xml_content}    \${OrderLineKey_Extracted}    ${OrderLineKey_Extracted}
    END
    ${has_order_release_key}=    Run Keyword And Return Status    Variable Should Exist    \${OrderReleaseKey_Extracted}
    IF    ${has_order_release_key}
        ${xml_content}=    Replace String    ${xml_content}    \${OrderReleaseKey_Extracted}    ${OrderReleaseKey_Extracted}
    END
    ${has_release_no}=    Run Keyword And Return Status    Variable Should Exist    \${ReleaseNo_Extracted}
    IF    ${has_release_no}
        ${xml_content}=    Replace String    ${xml_content}    \${ReleaseNo_Extracted}    ${ReleaseNo_Extracted}
    END
    ${has_prime_line_no}=    Run Keyword And Return Status    Variable Should Exist    \${PrimeLineNo_Extracted}
    IF    ${has_prime_line_no}
        ${xml_content}=    Replace String    ${xml_content}    \${PrimeLineNo_Extracted}    ${PrimeLineNo_Extracted}
    END
    RETURN    ${xml_content}

Execute All XML Files
    [Arguments]    ${SUITE_PATH}    ${folder}    ${index}
        ${json_path}    Set Variable    ${SUITE_PATH}/Data/updated_files.json
        ${json_string}    Get File    ${json_path}
        ${data}    Convert String To JSON    ${json_string}
        FOR    ${test_case}    IN    @{data.keys()}
        ${xml_files}=    Get From Dictionary    ${data}    ${test_case}
            FOR    ${xml_file}    IN    @{xml_files}
                ${xml_content}=    Get File    ${xml_file}
                ${resp}=    Execute XML File    ${xml_content}    ${xml_file}    ${index}
            END
        END
        RETURN    ${resp}

Process All JSON Files For IV
    [Arguments]    ${SUITE_PATH}    ${folder}    ${index}
        ${json_path}    Set Variable    ${SUITE_PATH}/Data/updated_files.json
        ${json_string}    Get File    ${json_path}
        ${data}    Convert String To JSON    ${json_string}
        FOR    ${test_case}    IN    @{data.keys()}
        ${xml_files}=    Get From Dictionary    ${data}    ${test_case}
            FOR    ${xml_file}    IN    @{xml_files}
                ${xml_content}=    Get File    ${xml_file}
                ${resp}=    Send Json File    ${xml_content}    ${xml_file}    ${index}
            END
        END
        RETURN    ${resp}

Process All JSON Files to Validate Response
    [Arguments]    ${SUITE_PATH}    ${folder}    ${index}    ${EXPECTED_ERROR_DESCRIPTION}
        ${json_path}    Set Variable    ${SUITE_PATH}/Data/updated_files.json
        ${json_string}    Get File    ${json_path}
        ${data}    Convert String To JSON    ${json_string}
        FOR    ${test_case}    IN    @{data.keys()}
        ${xml_files}=    Get From Dictionary    ${data}    ${test_case}
            FOR    ${xml_file}    IN    @{xml_files}
                ${xml_content}=    Get File    ${xml_file}
                Send XML File And Validate Response    ${xml_content}    ${xml_file}    ${index}    ${EXPECTED_ERROR_DESCRIPTION}
            END
        END

Process JSON Data
    [Arguments]    ${json_data}
    Log    Processing JSON: ${json_data}

Check folders
    [Arguments]     ${CUR_DIR}
    Log To Console    curdir in check folders:${CUR_DIR}
    ${subfolders}=    Process Suite    ${CUR_DIR}
    RETURN     ${subfolders}

Traverse folders for Json files
    [Arguments]     ${CUR_DIR}
    Log To Console    curdir in check folders:${CUR_DIR}
    ${subfolders}=    Process Suite Json    ${CUR_DIR}
    RETURN     ${subfolders}

Execute XML
    [Arguments]    ${xml_file}
    Log        Executing XML: ${xml_file}
    ${folder_path}=    Tc Folder        ${xml_file}
    RETURN     ${folder_path}

Send XML File
    [Arguments]    ${xml_data}    ${xml_file}    ${index}
    ${resp}=    Invoke MultiApi by Sending Request    ${xml_data}
    Log   req:${xml_data}
    Log   resp:${resp}
    Log To Console   respContent:${resp.content}
    Check for MapData    ${xml_data}    ${resp.content}    ${xml_file}
    Log To Console    Entered Here last-3
    Check for ValidateData    ${resp.content}    ${xml_file}    ${index}
    RETURN    ${resp}

Execute XML File
    [Arguments]    ${xml_data}    ${xml_file}    ${index}
    ${status}    ${result}=    Run Keyword And Ignore Error    Check for ExecuteData    ${xml_data}    ${xml_file}

    # Default value
    ${body}=    Set Variable    </>

    IF    $status == "PASS"
        Log To Console    ****My Xml data${xml_data}*****
        Log To Console    ****My Xml file***${xml_data}*****
        # If result is a Response object with .text
        ${has_text}=    Evaluate    hasattr($result, "text")
        IF    $has_text
            ${body}=    Set Variable    ${result.text}
        ELSE
            # If result is string
            Run Keyword If    '${result}' != '' and '${result}' != 'None'
            ...    Set Variable    ${body}    ${result}
        END
    END

    &{resp}=    Create Dictionary    content=${body}
    Log    req:${xml_data}
    Log    resp:${resp}
    Check for MapData    ${xml_data}    ${resp.content}    ${xml_file}
    ${folder_path}=    Execute XML    ${xml_file}
    #${resp}=    Get Data Flag    ${folder_path}    ${resp.content}    ${xml_file}
    ${status}    ${result}=    Run Keyword And Ignore Error    Get Data Flag    ${folder_path}    ${resp.content}    ${xml_file}
    # Default value
    ${body}=    Set Variable    </>

    IF    $status == "PASS"
        # If result is a Response object with .text
        ${has_text}=    Evaluate    hasattr($result, "text")
        IF    $has_text
            ${body}=    Set Variable    ${result.text}
        ELSE
            # If result is string
            Run Keyword If    '${result}' != '' and '${result}' != 'None'
            ...    Set Variable    ${body}    ${result}
        END
    END
    
    &{resp}=    Create Dictionary    content=${body}
    Log    req:${xml_data}
    Log    resp:${resp}
    Check for ValidateData    ${resp.content}    ${xml_file}    ${index}
    RETURN    &{resp}

Send Json File
    [Arguments]    ${xml_data}    ${xml_file}    ${index}
    ${resp}=    Invoke MultiApi by Sending Request    ${xml_data}
    Log To Console        req:${xml_data}
    Log To Console    resp:${resp}
    RETURN    ${resp}

Send XML File And Validate Response
    [Arguments]    ${xml_data}    ${xml_file}    ${index}    ${EXPECTED_ERROR_DESCRIPTION}
    ${resp}=    Invoke MultiApi by Sending Request    ${xml_data}
    Log    req:${xml_data}
    Log To Console   resp:${resp}
    Log To Console   respContent:${resp.content} and XMLFile: ${xml_file}
    Check for MapData    ${xml_data}    ${resp.content}    ${xml_file}
    Check for ValidateResponse Content    ${resp}    ${xml_file}    ${index}    ${EXPECTED_ERROR_DESCRIPTION}


Check for MapData
       [Arguments]    ${xml_data}    ${resp.content}    ${xml_file}
       Log    testcase:------------------${xml_file}
       ${folder_path}=    Execute XML    ${xml_file}
       ${mapDataflag}=     Check File Contains MapData       ${xml_file}    mapdata
       Log To Console       mapDataflag:${mapDataflag}
       Log    mapDataflag:${mapDataflag}
       Log    content:${resp.content}
       Log To Console    mapdata content:${resp.content}
       ${flag}=    Check Flag If True    ${mapDataflag}
       Log    flag::::::::::::::::::::${flag}
       Log To Console    mapdata flag :: flag::::::::::::::::::::${flag}
       ${file_name}=    Get Base Filename       ${xml_file}
       Log To Console    The file name is....****:${file_name}
       Log To Console    ****....The xml name is: ${xml_file}
       #Running Extract Order Info to extract Order No details:
        ${match}=    Run Keyword And Return Status    Should Match Regexp    ${file_name}    (?i)^create_execute_mapdata(_\d*)?$
        Log To Console    ****Match is****:${match}
        IF    ${match}
            Extract Order Info    ${resp.content}
        END

       Run Keyword If    ${FLAG}    Fecth Response    ${resp.content}     ${folder_path}    ${file_name}
       Get Data Flag    ${folder_path}    ${resp.content}    ${xml_file}

Check for ExecuteData
       [Arguments]    ${xml_data}   ${xml_file}
       Log    testcase:------------------${xml_file}
       ${folder_path}=    Execute XML    ${xml_file}
       ${executeDataflag}=     Check File Contains MapData       ${xml_file}    execute
       Log    executeDataflag:${executeDataflag}
       ${flag}=    Check Flag If True    ${executeDataflag}
       Log    flag::::::::::::::::::::${flag}
       ${file_name}=    Get Base Filename       ${xml_file}
       ${resp}=    Run Keyword If    ${FLAG}    Invoke Multiapi With Request XML    ${xml_data}
       Log    content:${resp.content}
       RETURN    ${resp}

Invoke Multiapi With Request XML
    [Arguments]    ${xml_data}
    ${resp}=    Invoke MultiApi by Sending Request    ${xml_data}
    RETURN    ${resp}


Get Data Flag
       [Arguments]    ${folder_path}    ${resp.content}    ${xml_file}
       ${getDataflag}=     Check File Contains MapData       ${xml_file}    getdata
       Log To Console    the folder Path checked here 2nd time:${folder_path}
       Log    getDataflag:${getDataflag}
       Log To Console    getDataflag:${getDataflag}
       Log    content:${resp.content}
       Log To Console    getDataflag content:${resp.content}
       ${getflag}=    Check Flag If True    ${getDataflag}
       Log   getFlag:${getflag}
       Log To Console    getDataflag::::::::getFlag:${getDataflag}
       ${resp}=     Run Keyword If    ${getflag}  Get Data Flag is true     ${folder_path}    ${resp.content}    ${xml_file}
       RETURN    ${resp}

Extract Order Info
    [Arguments]    ${resp_content}
    ${parsed}=    XML.Parse XML    ${resp_content}
    ${order}=    XML.Get Element    ${parsed}    .//Order
    ${OrderNo}=    XML.Get Element Attribute    ${order}    OrderNo
    ${OrderHeaderKey}=    XML.Get Element Attribute    ${order}    OrderHeaderKey
    Log To Console    Extracted OrderNo: ${OrderNo}
    Log To Console    Extracted OrderHeaderKey: ${OrderHeaderKey}
    Set Test Message    Extracted Order from response: OrderNo=${OrderNo}, OrderHeaderKey=${OrderHeaderKey}
    Set Test Variable    ${OrderNo}
    Set Test Variable    ${OrderHeaderKey}


Extract Order Line Key
    [Arguments]    ${resp_content}
    ${parsed}=    XML.Parse XML    ${resp_content}
    ${orderline}=    XML.Get Element    ${parsed}    .//OrderLine
    ${OrderLineKey_Extracted}=    XML.Get Element Attribute    ${orderline}    OrderLineKey
    Log To Console    Extracted OrderLineKey: ${OrderLineKey_Extracted}
    Set Test Variable    ${OrderLineKey_Extracted}
    # Also extract ShipNode from the order line so createShipment can use the correct node
    ${hasShipNode}    ${ShipNode_Extracted}=    Run Keyword And Ignore Error    XML.Get Element Attribute    ${orderline}    ShipNode
    IF    '${hasShipNode}' == 'PASS' and '${ShipNode_Extracted}' != 'None' and '${ShipNode_Extracted}' != ''
        Log To Console    Extracted ShipNode from OrderLine: ${ShipNode_Extracted}
        Set Test Variable    ${ShipNode_Extracted}
    END
    # Extract ReleaseNo so createShipment can reference the correct order release
    ${hasReleaseNo}    ${ReleaseNo_Extracted}=    Run Keyword And Ignore Error    XML.Get Element Attribute    ${orderline}    ReleaseNo
    IF    '${hasReleaseNo}' == 'PASS' and '${ReleaseNo_Extracted}' != 'None' and '${ReleaseNo_Extracted}' != ''
        Log To Console    Extracted ReleaseNo: ${ReleaseNo_Extracted}
        Set Test Variable    ${ReleaseNo_Extracted}
    END
    # Extract PrimeLineNo so createShipment can reference the correct order line
    ${hasPrimeLineNo}    ${PrimeLineNo_Extracted}=    Run Keyword And Ignore Error    XML.Get Element Attribute    ${orderline}    PrimeLineNo
    IF    '${hasPrimeLineNo}' == 'PASS' and '${PrimeLineNo_Extracted}' != 'None' and '${PrimeLineNo_Extracted}' != ''
        Log To Console    Extracted PrimeLineNo: ${PrimeLineNo_Extracted}
        Set Test Variable    ${PrimeLineNo_Extracted}
    END

Get Data Flag is true
       [Arguments]    ${folder_path}    ${resp.content}    ${xml_file}
       ${json_data}=    Load Json Files Output     ${folder_path}${output_foldername}
       Log    jsonData:${json_data}
       Log    xmlfile:${xml_file}
       ${xml_str}=    Replace Variables In Xml    ${xml_file}    ${json_data}
       Log    ${xml_str}
       ${resp}=    Invoke MultiApi by Sending Request    ${xml_str}
       RETURN    ${resp}

Check for ValidateData
       [Arguments]    ${resp.content}    ${xml_file}    ${index}
       ${folder_path}=    Execute XML    ${xml_file}
       Log    Folder Path:${folder_path} and XML File: ${xml_file}
       ${valDataflag}=     Check File Contains MapData       ${xml_file}    validatedata
       Log    mapDataflag:${valDataflag}
       Log    content:${resp.content}
       Log    ValidateData content in valdata:${resp.content}
       Log     mapDataflag:${valDataflag}
       Log    Entered Here step last-1-i
       ${valDataflag}=    Check Flag If True    ${valDataflag}
       ${index}=    Run Keyword If    ${valDataflag}      Increment Index    ${index}     # Increment index after each iteration
       Log    Entered Here step last-1-ii-ValDataFlag:${valDataflag}
       Log    Entered Here step last-1-iii
       Run Keyword If    ${valDataflag}  Get Validate Data Flag Is True And Compare XML   ${folder_path}    ${resp.content}    ${xml_file}    ${index}

Check for ValidateResponse Content
       [Arguments]    ${resp}    ${xml_file}    ${index}     ${EXPECTED_ERROR_DESCRIPTION}
       ${folder_path}=    Execute XML    ${xml_file}
       ${valDataflag}=     Check File Contains MapData       ${xml_file}    validatedata
       Log    mapDataflag:${valDataflag}
       Log    content:${resp.content}
       ${valDataflag}=    Check Flag If True    ${valDataflag}
       ${index}=    Run Keyword If    ${valDataflag}      Increment Index    ${index}     # Increment index after each iteration
       Run Keyword If    ${valDataflag}  Get Validate Data Flag Is True   ${folder_path}    ${resp}    ${xml_file}    ${index}    ${EXPECTED_ERROR_DESCRIPTION}

Increment Index
    [Arguments]    ${index}
    ${index}=    Evaluate    ${index} + 1    # Increment index after each iteration
    RETURN    ${index}

Get Validate Data Flag is true
       [Arguments]    ${folder_path}    ${response}    ${xml_file}    ${index}    ${EXPECTED_ERROR_DESCRIPTION}
       ${counter}=    Write Actual Result      ${response.content}     ${actualresult_foldername}     ${folder_path}
       Log    Get Validate Data Flag is true:${folder_path}${actual_result_file}${counter}.xml
        ${xml_string}=    Decode Bytes To String    ${response.content}    UTF-8
        ${description}=    Get Error Description    ${xml_string}
        Should Be Equal    ${description}    ${EXPECTED_ERROR_DESCRIPTION}

Get Validate Data Flag is true and compare XML
       [Arguments]    ${folder_path}    ${resp.content}    ${xml_file}    ${index}
       Log    Entered Here step last-i
       ${counter}=    Write Actual Result      ${resp.content}     ${actualresult_foldername}     ${folder_path}
       Log    Entered here step last-ii
       Log   Get Validate Data Flag is true ::::::::counter:${counter}
       Log    expectedResultFile:${folder_path}${expected_result_file}${counter}.xml
       Log    ${folder_path}${actual_result_file}${counter}.xml
       Compare Expected and Actual XML Files By Removing Dynamic Keys     ${folder_path}${expected_result_file}${counter}.xml    ${folder_path}${actual_result_file}${counter}.xml

Creating Session
    [Arguments]     ${SessionName}      ${xmlRequest}
    Create Session    ${SessionName}    ${BASE_URL}
    ${params}   create dictionary   YFSEnvironment.progId=Test      InteropApiName=multiApi     ApiName=MultiApi        YFSEnvironment.userId=admin     YFSEnvironment.password=password       InteropApiData=${xmlRequest}       timeout=30
    ${resp}=       POST On Session    ${SessionName}    ${req_uri}  params=${params}
    Log     Request:${xmlRequest}
    Log     Response Status Code :${resp}
    Log     Response XML:${resp.content}
    RETURN    ${resp}


Invoke MultiApi
    [Arguments]         ${Input_file_Name}    ${dateTime}
    ${Req}=     Generic Input File  ${Input_file_Name}    ${dateTime}
    Log    Req:${Req}
    ${Resp}=     Creating Session    ${Input_file_Name}   ${Req}
    Log   Resp:${Resp.content}
    #Set Test Variable    ${createOrderResp}    ${Resp}
    RETURN     ${Resp}
    #${order}=     Get Element    ${Resp.content}    .//Order
    #${OrderNo}=    Get Element Attribute    ${order}    OrderNo
    #RETURN     ${OrderNo}

Invoke MultiApi by Sending Request
    [Arguments]         ${Req}
    ${Resp}=     Send Request to a post session    ${Req}
    Status Should Be    200    ${Resp}
    RETURN     ${Resp}

Generate Unique ID
    ${uid}=    Generate 7 Digit Unique Id
    Set Test Variable    ${uid}

Remove Dynamic Keys
    [Arguments]    ${xml}
    # Use regex to remove dynamic keys or values
    #${xml}=    Replace String Using Regexp    ${xml}    OrderHeaderKey="\d+"    OrderHeaderKey="XXXX"
    #${xml}=    Replace String Using Regexp    ${xml}    OrderLineKey="\d+"    OrderLineKey="XXXX"
    #${updated_xml}=    Evaluate    import re; re.sub(r'OrderHeaderKey="\d+"', 'OrderHeaderKey="XXXX"', '''${xml}''')    # no need for globals()
    #${updated_xml}=    Evaluate    import re; re.sub(r'OrderHeaderKey="\d+"', 'OrderHeaderKey="XXXX"', '''${xml_string}''')    # Use triple quotes to avoid escaping
    ${updated_xml}=    Replace Key    ${xml}
    #${updated_xml}=    Evaluate    import re; re.sub(r'OrderLineKey="\d+"', 'OrderLineKey="XXXX"', '${xml}')    # no need for globals()
    RETURN    ${updated_xml}

Convert XML To String By Removing Dynamic Keys
    [Arguments]    ${xml_object}
        #Log To Console    Convert XML To String By Removing Dynamic Keys:xmlObj:${xml_object}
        ${xmlRoot}=       Read Xml From File    ${xml_object}
        #Log To Console    Convert XML To String By Removing Dynamic Keys::xmlroot:${xmlRoot}
        ${xml_str}=     Xml To String      ${xmlRoot}
        #Log To Console    Convert XML To String By Removing Dynamic Keys::xmlstr:${xml_str}
        RETURN     ${xml_str}

Normalize XML String By Removing Dynamic Keys
    [Arguments]    ${xml}
    ${xml_string}=    Remove Dynamic Keys    ${xml}
    #Log To Console    Normalize XML String By Removing Dynamic Keys::xmlStr:${xml_string}
    ${normalized}=    Normalize Xml    ${xml_string}
    #Log To Console    Normalize XML String By Removing Dynamic Keys::normalized:${normalized}
    RETURN    ${normalized}

Compare Expected and Actual XML
      [Arguments]         ${Expected_Result}    ${ActualResult}    ${CUR_DIR}
      ${updated_folder_path}=    Remove Last Folder From Path    ${CUR_DIR}
      Log To Console    expected:${updated_folder_path}${Expected_Result}
      Log To Console    actual:${updated_folder_path}${ActualResult}

      ${expres}=     Convert XML To String By Removing Dynamic Keys    ${updated_folder_path}${Expected_Result}
      ${actres}=     Convert XML To String By Removing Dynamic Keys    ${updated_folder_path}${ActualResult}

      # Normalize XML strings to ignore formatting differences (e.g., spaces or newlines)
    ${normalized_expected_string}=    Normalize XML String By Removing Dynamic Keys    ${expres}
    ${normalized_actual_string}=      Normalize XML String By Removing Dynamic Keys    ${actres}
    # Compare the normalized XML strings
    Should Be Equal As Strings    ${normalized_expected_string}    ${normalized_actual_string}

Compare Expected and Actual XML Files By Removing Dynamic Keys
      [Arguments]         ${Expected_Result}    ${ActualResult}
      #Log To Console    compareExp:${Expected_Result}
      #Log To Console    compareAct:${ActualResult}
      ${expres}=     Convert XML To String By Removing Dynamic Keys    ${Expected_Result}
      ${actres}=     Convert XML To String By Removing Dynamic Keys    ${ActualResult}
      #Log To Console    converted:${expres}
      #Log To Console    converted:${actres}

      # Normalize XML strings to ignore formatting differences (e.g., spaces or newlines)
    ${normalized_expected_string}=    Normalize XML String By Removing Dynamic Keys    ${expres}
    ${normalized_actual_string}=      Normalize XML String By Removing Dynamic Keys    ${actres}
    # Compare the normalized XML strings
    Run Keyword And Continue On Failure    Should Be Equal As Strings    ${normalized_expected_string}    ${normalized_actual_string}
    Compare Xml    ${expres}    ${actres}
    
#IV related keywords
Initialize Token
    ${token_url}=    Set Variable    https://api.watsoncommerce.ibm.com/inventory/us-1b8d5331/v1/oauth2/token
    ${client_id}=    Set Variable    LDvKQpNiCyr3NU8gEfPvC0gwOzpF0jkw
    ${client_secret}=    Set Variable    X3E2XV9wotpndnfvkipX7sGOqY6CqKpy

    ${token}=    Get Bearer Token    ${token_url}    ${client_id}    ${client_secret}
    Set Suite Variable    ${dev_b_token}    ${token}
    Log    Token initialized: ${dev_b_token}
    Log To Console    Token initialized: ${dev_b_token}

Create IV GET Session
    [Arguments]     ${SessionName}    ${url}
    &{headers}    Create Dictionary    Authorization=${dev_b_token}
    Create Session    ${SessionName}    ${dev_b_server}
    #${url1}=    Strip String     ${url}
    ${url1}=    Replace String    ${url}    ${SPACE}    %20
    Log To Console    url1:::::::::::::::${url1}
    ${response}=    GET On Session    ${SessionName}    ${url1}    headers=${headers}
    Log     response:${response}
    Log     responsejson:${response.json()}
    RETURN    ${response}

Create IV Post Session
    [Arguments]     ${CUR_DIR}    ${SessionName}    ${url}    ${Input_file_Name}
    &{headers}    Create Dictionary    Authorization=${dev_b_token}    Content-Type=application/json
    Create Session    ${SessionName}    ${dev_b_server}
    ${Request}=     Generic Input Json File    ${CUR_DIR}    ${Input_file_Name}
    Log    createOrderReq:${Request}
    ${response}=    Post On session    ${SessionName}    ${url}    headers=${headers}    json=${Request}
    Log     response:${response}
    #Status Should Be    202    ${response}
    RETURN    ${response}

Validate attribute in response
    [Arguments]     ${response}    ${attribute}
    Log To Console    not list ----------------------
    Log To Console    ${response.json()}
    Dictionary Should Contain Key     ${response.json()}     ${attribute}
         ${attr_value}=    Get From Dictionary     ${response.json()}    ${attribute}
         Log    ${attr_value}
         #Should Be Equal As Strings    ${shipNode}    ${shipNode_value}
         RETURN     ${attr_value}

Validate attribute in response for List
    [Arguments]     ${response}    ${attribute}
    Log    has list------------------
    Status Should Be    200    ${response}    #Check Status as 200
    Log    ${response.json()}
    ${item}=    Get From List    ${response.json()}   0
    ${quantity}=    Get From Dictionary    ${item}    quantity
    Log    quantity:${quantity}
    Run Keyword If    ${quantity} > 0    Log    Quantity is greater than zero
    Run Keyword If    ${quantity} <= 0    Fail    Quantity is not greater than zero
    #Set Test Message    Test completed: Quantity from Response is :  ${quantity}
    RETURN     ${quantity}

#Fetch Order No
#    [Arguments]         ${createOrderResp}
#    ${order}=     Get Element    ${createOrderResp.content}    .//Order
#    ${OrderNo}=    Get Element Attribute    ${order}    OrderNo
#    RETURN     ${OrderNo}
Fetch Order No
    [Arguments]         ${createOrderResp}
    Log To Console      Fetching Order No from Response
    Log To Console      Response content: ${createOrderResp.content}
    ${order}=     Get Element    ${createOrderResp.content}    .//Order
    Log To Console      Extracted Order Element: ${order}
    ${OrderNo}=    XML.Get Element Attribute    ${order}    OrderNo
    Log To Console      OrderNo Extracted: ${OrderNo}
    Set Test Message    OrderNo Extracted: ${OrderNo}
    RETURN     ${OrderNo}

Fetch OrderHeaderKey
    [Arguments]         ${createOrderResp}
    ${order}=     Get Element    ${createOrderResp.content}    .//Order
    ${OrderHeaderKey}=    Get Element Attribute    ${order}    OrderHeaderKey
    RETURN     ${OrderHeaderKey}
Get Order Details
    [Arguments]         ${CUR_DIR}    ${OrderNo}
    Log To Console      Fetching Order Details for OrderNo: ${OrderNo}
    ${getOrderDetailsxmlRequest}=     Generic Input File Ord    ${CUR_DIR}    ${getOrderDetails_Input_file_Name}    ${OrderNo}
    Log To Console      Generated Order Details Request: ${getOrderDetailsxmlRequest}
    ${getOrderDetailResp}=     Send Request to a post session    ${getOrderDetailsxmlRequest}
    ${xml_content}=    Decode Bytes To String    ${getOrderDetailResp.content}    UTF-8
    Log To Console      Decoded Order Details XML: ${xml_content}
    RETURN     ${xml_content}


Get Order Details With DocType
    [Arguments]         ${CUR_DIR}    ${OrderNo}    ${DocumentType}
    Log To Console      Fetching Order Details for OrderNo: ${OrderNo} and DocumentType: ${DocumentType}
    ${getOrderDetailsxmlRequest}=     Generic Input File Ordno Doctype    ${CUR_DIR}    ${getOrderDetails_Input_file_Name}    ${OrderNo}    ${DocumentType}
    Log To Console      Generated Order Details Request: ${getOrderDetailsxmlRequest}
    ${getOrderDetailResp}=     Send Request to a post session    ${getOrderDetailsxmlRequest}
    ${xml_content}=    Decode Bytes To String    ${getOrderDetailResp.content}    UTF-8
    Log To Console      Decoded Order Details XML: ${xml_content}
    RETURN     ${xml_content}

Validate Order Status
    [Arguments]         ${xml_string}    ${status_name}
    ${order}=     Get Element    ${xml_string}    .//Order
    ${Status}=    XML.Get Element Attribute    ${order}    Status
    ${Status}=    Strip String    ${Status}
    Log     Status From getOrderDetails: ${Status}
    Should Be Equal As Strings    ${Status}    ${status_name}
    RETURN     ${xml_string}


Invoke MultiApi2
    [Arguments]         ${CUR_DIR}    ${Input_file_Name}
    ${Req}=     Generic Input File2   ${CUR_DIR}    ${Input_file_Name}
    ${Resp}=    Send Request to a post session    ${Req}
    Set Test Variable    ${createOrderResp}    ${Resp}
    RETURN     ${Resp}


Create Order V001 Old
    [Arguments]         ${CUR_DIR}    ${Input_file_Name}
    ${createOrderResp}=    Invoke MultiApi2    ${CUR_DIR}    ${createOrder_Input_file_Name}
    Log To Console   createOrderResp: ${createOrderResp}
#    ${OrderNo}=    Set Variable    CITY-VJ-20250424_341
    ${OrderNo}=    Fetch Order No    ${createOrderResp}
    ${getOrderDetailResp}=    Get Order Details    ${CUR_DIR}    ${OrderNo}
    Log To Console    getOrderDetailResp: ${getOrderDetailResp}
    ${parsed}=    XML.Parse XML    ${getOrderDetailResp}
    ${order_element}=    XML.Get Element    ${parsed}    API[@Name="getOrderDetails"]/Output/Order
    ${OrderHeaderKey}=    XML.Get Element Attribute    ${order_element}    OrderHeaderKey
    Log To Console    OrderHeaderKey: ${OrderHeaderKey}
    Validate Order Status    ${getOrderDetailResp}    Created
    Set Test Message    Test completed: OrderNo is: ${OrderNo}, OrderHeaderKey is: ${OrderHeaderKey}
    RETURN    ${OrderNo}    ${OrderHeaderKey}

Create Order V001 Alter1
    [Arguments]         ${CUR_DIR}    ${Input_file_Name}    ${DocumentType}
    ${createOrderResp}=    Invoke MultiApi2    ${CUR_DIR}    ${Input_file_Name}
    Log To Console   createOrderResp: ${createOrderResp.text}
    # if CreateOrder response has error ---
    Should Not Contain    ${createOrderResp.text}    <Errors>    CreateOrder API returned error
#    ${error_found}=    Run Keyword And Return Status    Should Contain    ${createOrderResp.text}    <Errors>
   # If no errors, continue
    ${OrderNo}=    Fetch Order No    ${createOrderResp}
    Log To Console    Extracted OrderNo: ${OrderNo}
    # Get order details using both OrderNo and DocumentType
    ${getOrderDetailResp}=    Get Order Details With DocType    ${CUR_DIR}    ${OrderNo}    ${DocumentType}
#    Log To Console    getOrderDetailResp: ${getOrderDetailResp}

    ${parsed}=    XML.Parse XML    ${getOrderDetailResp}
    ${order_element}=    XML.Get Element    ${parsed}    API[@Name="getOrderDetails"]/Output/Order
    ${OrderHeaderKey}=    XML.Get Element Attribute    ${order_element}    OrderHeaderKey
    Log To Console    OrderHeaderKey: ${OrderHeaderKey}
    Validate Order Status    ${getOrderDetailResp}    Created
    Set Test Message    Test completed: OrderNo is: ${OrderNo}, OrderHeaderKey is: ${OrderHeaderKey}
#    Set Test Message    OrderHeaderKey is: ${OrderHeaderKey}
    ${output_dir}=    Replace String    ${CUR_DIR}    \Test    \Output
    ${output_file}=   Set Variable    ${output_dir}\\actual_result.xml
    Create Directory    ${output_dir}
    Create File         ${output_file}    ${getOrderDetailResp}
    Log To Console    XML saved to: ${output_file}

    # Preparing the input xml
#    ${updated_xml}=    Replace String    ${getOrderDetailResp}    <Output>    <Input>
#    ${updated_xml}=    Replace String    ${updated_xml}    </Output>    </Input>
#    ${input_dir}=      Replace String    ${CUR_DIR}    \Test    \Input
#    ${order_details_file}=   Set Variable    ${input_dir}\\orderDetails_input.xml
#    Create Directory   ${input_dir}
#    Create File        ${order_details_file}    ${updated_xml}
#    Log To Console     Updated XML saved to: ${order_details_file}
#
#    ${second_resp}=    Invoke MultiApi2    ${CUR_DIR}    ${orderDetails_Input_file_Name}
#    ${second_resp_text}=    Convert To String    ${second_resp.text}
#    Log To Console     Second API call response: ${second_resp_text}
#
#    ${output_file2}=   Set Variable    ${output_dir}\\getOrderDetails_result.xml
#    Create File         ${output_file2}    ${second_resp_text}

    RETURN    ${OrderNo}    ${OrderHeaderKey}

Create Order V001 Alter
    [Arguments]         ${CUR_DIR}    ${Input_file_Name}
    ${createOrderResp}=    Invoke MultiApi2    ${CUR_DIR}    ${createOrder_Input_file_Name}
    Log To Console   createOrderResp: ${createOrderResp}
#    ${OrderNo}=    Set Variable    CITY-VJ-20250424_341
    ${OrderNo}=    Fetch Order No    ${createOrderResp}
    ${getOrderDetailResp}=    Get Order Details    ${CUR_DIR}    ${OrderNo}
    Log To Console    getOrderDetailResp: ${getOrderDetailResp}
    ${parsed}=    XML.Parse XML    ${getOrderDetailResp}
    ${order_element}=    XML.Get Element    ${parsed}    API[@Name="getOrderDetails"]/Output/Order
    ${OrderHeaderKey}=    XML.Get Element Attribute    ${order_element}    OrderHeaderKey
    Log To Console    OrderHeaderKey: ${OrderHeaderKey}
    Validate Order Status    ${getOrderDetailResp}    Created
    Set Test Message    Test completed: OrderNo is: ${OrderNo}, OrderHeaderKey is: ${OrderHeaderKey}
    ${output_dir}=    Replace String    ${CUR_DIR}    \Test    \Output
    ${output_file}=   Set Variable    ${output_dir}\\actual_result.xml
    Create Directory    ${output_dir}
    Create File         ${output_file}    ${getOrderDetailResp}
    Log To Console    XML saved to: ${output_file}
    
    #Preparing the input xml
    ${updated_xml}=    Replace String    ${getOrderDetailResp}    <Output>    <Input>
    ${updated_xml}=    Replace String    ${updated_xml}    </Output>    </Input>
    ${input_dir}=      Replace String    ${CUR_DIR}    \Test    \Input
    ${order_details_file}=   Set Variable    ${input_dir}\\orderDetails_input.xml
    Create Directory   ${input_dir}
    Create File        ${order_details_file}    ${updated_xml}
    Log To Console     Updated XML saved to: ${order_details_file}
    
    ${second_resp}=    Invoke MultiApi2    ${CUR_DIR}    ${orderDetails_Input_file_Name}
    ${second_resp_text}=    Convert To String    ${second_resp.text}
    Log To Console     Second API call response: ${second_resp_text}
    
    ${output_file2}=   Set Variable    ${output_dir}\\getOrderDetails_result.xml

    Create File         ${output_file2}    ${second_resp_text}
    RETURN    ${OrderNo}    ${OrderHeaderKey}

Schedule Order V001
    [Arguments]      ${CUR_DIR}   ${OrderNo}
    Log To Console    Came here to schedule: ${OrderNo}
    ${resp2}=   Invoke MultiApi2     ${CUR_DIR}    ${scheduleOrder_Input_file_Name}
    Log To Console    Schedule API Response: ${resp2}  # Log the response

    # Wait and retry logic, with additional logging for each retry
    Wait Until Keyword Succeeds    10    10s    ${getOrderDetailResp}=    Get Order Details    ${CUR_DIR}      ${OrderNo}
    Log To Console    Order Status after retry: ${getOrderDetailResp.Status}

    # Validate the order status after retrying
    Validate Order Status    ${getOrderDetailResp}    Scheduled
    Set Test Message    Test completed: OrderNo is : ${OrderNo}
#Schedule Order V001 Alter
#    [Arguments]      ${CUR_DIR}   ${OrderNo}
#
#    ${scheduleOrderXML}=    Generic Input File Ord2    ${CUR_DIR}    ${scheduleOrder_Input_file_Name}    ${OrderNo}
#    Log To Console    Path here ${scheduleOrder_Input_file_Name}
#    ${resp2}=   Invoke MultiApi2     ${CUR_DIR}    ${scheduleOrderXML}
#    ${getOrderDetailResp}=    Get Order Details    ${CUR_DIR}      ${OrderNo}
#    Log To Console    get Order Details Response    ${getOrderDetailResp}
#    Validate Order Status    ${getOrderDetailResp}    Scheduled
#
#    Set Test Message    Test completed: OrderNo is : ${OrderNo}
Schedule Order V001 Alter
    [Arguments]      ${CUR_DIR}   ${OrderNo}
    ${resp2}=   Invoke MultiApi2     ${CUR_DIR}    ${scheduleOrder_Input_file_Name}
    ${getOrderDetailResp}=    Get Order Details    ${CUR_DIR}      ${OrderNo}
    Log To Console    get Order Details Response    ${getOrderDetailResp}
    Validate Order Status    ${getOrderDetailResp}    Scheduled

    Set Test Message    Test completed: OrderNo is : ${OrderNo}

Release Order V001 Alter
    [Arguments]      ${CUR_DIR}   ${OrderNo}
    Invoke MultiApi2     ${CUR_DIR}    ${releaseOrder_Input_file_Name}
    ${getOrderDetailResp}=    Get Order Details    ${CUR_DIR}      ${OrderNo}
    Validate Order Status    ${getOrderDetailResp}    Released
    Set Test Message    Test completed: OrderNo is : ${OrderNo}

Confirm Shipment
    [Arguments]         ${OrderNo}    ${OrderHeaderKey}
    ${getOrderReleaseListxmlRequest}=     Generic Input File Oh     ${CUR_DIR}    ${getOrderReleaseList_Input_file_Name}    ${OrderHeaderKey}
    ${resp}=     Send Request to a post session    ${getOrderReleaseListxmlRequest}
    ${getOrderDetailResp}=    Get Order Details    ${CUR_DIR}     ${OrderNo}
    ${order}=     Get Element    ${getOrderDetailResp}    .//Order
    ${Status}=    XML.Get Element Attribute    ${order}    Status
    ${OrderLine}=     Get Element    ${getOrderDetailResp}    .//OrderLine
    ${OrderLineKey}=    XML.Get Element Attribute    ${OrderLine}    OrderLineKey
    ${OrderedQty}=    XML.Get Element Attribute    ${OrderLine}    OrderedQty
    Parse XML    ${resp.content}
    ${orderAttr}=     Get Element    ${resp.content}    .//OrderReleaseList/OrderRelease
    ${orderReleaseKey}=    XML.Get Element Attribute    ${orderAttr}    OrderReleaseKey
    ${CarrierServiceCode}=    XML.Get Element Attribute    ${orderAttr}    CarrierServiceCode
    ${DocumentType}=    XML.Get Element Attribute    ${orderAttr}    DocumentType
    ${EnterpriseCode}=    XML.Get Element Attribute    ${orderAttr}    EnterpriseCode
    ${SCAC}=    XML.Get Element Attribute    ${orderAttr}    SCAC
    ${ShipNode}=    XML.Get Element Attribute    ${orderAttr}    ShipNode
    ${confirmShipmentXmlRequest}=     Generic Input File Ship     ${CUR_DIR}    ${confirmShipment_Input_file_Name}    ${orderReleaseKey}     ${CarrierServiceCode}    ${EnterpriseCode}    ${SCAC}    ${ShipNode}    ${OrderLineKey}    ${OrderedQty}    ${DocumentType}    ${OrderNo}
    RETURN     ${confirmShipmentXmlRequest}

Confirm Shipment V001 Alter
    [Arguments]      ${CUR_DIR}   ${OrderNo}    ${OrderHeaderKey}
    ${confirmShipmentXmlRequest}=    Confirm Shipment    ${OrderNo}    ${OrderHeaderKey}
    ${confirmShipmentResp}=     Send Request to a post session   ${confirmShipmentXmlRequest}
    ${getOrderDetailResp}=    Get Order Details    ${CUR_DIR}       ${OrderNo}
    Validate Order Status    ${getOrderDetailResp}    Shipped
    Set Test Message    Test completed: OrderNo is : ${OrderNo}

Change Order Status V001
    [Arguments]      ${CUR_DIR}   ${OrderNo}
    Invoke MultiApi2     ${CUR_DIR}    ${changeOrderStatus_Input_file_Name}
    ${getOrderDetailResp}=    Get Order Details    ${CUR_DIR}      ${OrderNo}
    Log To Console    get Order Details Response    ${getOrderDetailResp}
    Validate Order Status    ${getOrderDetailResp}    Ready For Ship
    Set Test Message    Test completed: OrderNo is : ${OrderNo}

Create Shipment V001
    [Arguments]      ${CUR_DIR}   ${OrderNo}
    Invoke MultiApi2     ${CUR_DIR}    ${createShipment_Input_file_Name}
    ${getOrderDetailResp}=    Get Order Details    ${CUR_DIR}      ${OrderNo}
    Log To Console    get Order Details Response    ${getOrderDetailResp}
    Validate Order Status    ${getOrderDetailResp}    Included In Shipment
    Set Test Message    Test completed: OrderNo is : ${OrderNo}



Get ATP For Nearest Stores V001
    [Arguments]         ${CUR_DIR}    ${Input_file_Name}
    ${getATPForNearestStoresResp}=    Invoke MultiApi2    ${CUR_DIR}    ${getATPForNearestStores_Input_file_Name}
    Log To Console   getATPForNearestStoresRequest: ${getATPForNearestStoresResp}
    ${xml_content}=    Decode Bytes To String    ${getATPForNearestStoresResp.content}    UTF-8
    Log To Console      Decoded ATP For Nearest Stores Details XML: ${xml_content}
    RETURN     ${xml_content}

#Get ATP For Nearest Stores V001_01
#    [Arguments]         ${CUR_DIR}    ${Input_file_Name}
#    Log To Console    CUR_DIR printing here...: ${CUR_DIR} and InputFileName: ${Input_file_Name}
#    ${getATPForNearestStoresResp}=    Invoke MultiApi2    ${CUR_DIR}    ${getATPForNearestStores_Input_file_Name1}
#    Log To Console   getATPForNeareesstStoresRequest: ${getATPForNearestStoresResp}
#    ${xml_content}=    Decode Bytes To String    ${getATPForNearestStoresResp.content}    UTF-8
#    Log To Console      Decoded ATP For Nearest Stores Details XML: ${xml_content}
#    # Generate output file path by replacing \Test with \Output
#    ${output_dir}=    Replace String    ${CUR_DIR}    \Test    \Output
#    ${output_file}=   Set Variable    ${output_dir}\\actual_result.xml
#     # To ensure output directory exists
#    Create Directory    ${output_dir}
#     # Save decoded XML to the file:
#    Create File    ${output_file}    ${xml_content}
#    Log To Console    XML saved to: ${output_file}
#
#    RETURN     ${xml_content}

Get ATP For Nearest Stores V001_01
    [Arguments]    ${CUR_DIR}    ${Input_file_Name}
    Log To Console    CUR_DIR printing here...: ${CUR_DIR}
    Log To Console    Input File Name: ${Input_file_Name}
    ${getATPForNearestStoresResp}=    Invoke MultiApi2    ${CUR_DIR}    ${Input_file_Name}
    Log To Console    getATPForNearestStoresRequest: ${getATPForNearestStoresResp}
    ${xml_content}=    Decode Bytes To String    ${getATPForNearestStoresResp.content}    UTF-8
    Log To Console    Decoded ATP For Nearest Stores Details XML: ${xml_content}
    ${output_dir}=    Replace String    ${CUR_DIR}    \Test    \Output
    ${base_name}=     Get Basename    ${Input_file_Name}
    ${output_file}=   Set Variable    ${output_dir}\\actual_result_${base_name}.xml
    Create Directory    ${output_dir}
    Create File         ${output_file}    ${xml_content}
    Log To Console    XML saved to: ${output_file}
    RETURN    ${xml_content}

Order Status Inquiry V001
    [Arguments]    ${CUR_DIR}    ${Input_file_Name}
    Log To Console    CUR_DIR printing here...: ${CUR_DIR}
    Log To Console    Input File Name: ${Input_file_Name}
    ${OrderStatusResp}=    Invoke MultiApi2    ${CUR_DIR}    ${Input_file_Name}
    Log To Console    getOrderStatusRequest: ${OrderStatusResp}
    ${xml_content}=    Decode Bytes To String    ${OrderStatusResp.content}    UTF-8
    Log To Console    Decoded Order Status Details XML: ${xml_content}
    ${output_dir}=    Replace String    ${CUR_DIR}    \Test    \Output
    ${base_name}=     Get Basename    ${Input_file_Name}
    ${output_file}=   Set Variable    ${output_dir}\\result_${base_name}.xml
    Create Directory    ${output_dir}
    Create File         ${output_file}    ${xml_content}
    Log To Console    XML saved to: ${output_file}
    ${orderNos}=    Extract All OrderNos    ${xml_content}
    Log To Console    >>> Extracted OrderNos: ${orderNos}
    RETURN    ${xml_content}


Extract All OrderNos
    [Arguments]    ${xml_content}
    ${root}=    Parse XML    ${xml_content}
    ${Orders}=    Get Elements    ${root}    .//Order
    ${orderNos}=    Create List
    FOR    ${order}    IN    @{Orders}
        ${OrderNo}=    XML.Get Element Attribute    ${order}    OrderNo
        Append To List    ${orderNos}    ${OrderNo}
    END
    ${orderNosStr}=    Catenate    SEPARATOR=,    @{orderNos}
    Log To Console    >>> All OrderNos: ${orderNosStr}
    Set Test Message    OrderNos found: ${orderNosStr}
    RETURN    ${orderNos}


Create Customer V001
    [Arguments]         ${CUR_DIR}    ${Input_file_Name}
    ${createCustomerResp}=    Invoke MultiApi2    ${CUR_DIR}    ${manageCustomerList_Input_file_Name}
    Log To Console   createOrderResp: ${createCustomerResp}
    ${xml_content}=    Decode Bytes To String    ${createCustomerResp.content}    UTF-8
    Log To Console      Decoded Customer Details XML: ${xml_content}
    RETURN     ${xml_content}

#Create Customer V001 Alter
#    [Arguments]         ${CUR_DIR}    ${Input_file_Name}
#    ${createCustomerResp}=    Invoke MultiApi2    ${CUR_DIR}    ${manageCustomerList_Input_file_Name}
#    Log To Console   createCustomerResp: ${createCustomerResp}
#    ${xml_content}=    Decode Bytes To String    ${createCustomerResp.content}    UTF-8
#    Log To Console      Decoded Customer Details XML: ${xml_content}
#
#    # Extract EmailID or FirstName from input file
#    ${customer_value}=    Extract Email Or Firstname From Xml    ${CUR_DIR}/Input/${manageCustomerList_Input_file_Name}.xml
#    Log To Console    Extracted Customer Identifier: ${customer_value}
#
#    # Replace the value in the search customer input file
#    ${updated_search_xml}=    Replace Customer Search Value    ${CUR_DIR}/Input/${getCustomerList_Input_file_Name}.xml    ${customer_value}
#    Log To Console    Updated Search Customer XML: ${updated_search_xml}
#
#    # Send Search Request with updated payload
#    ${getCustomerListResp}=    Send Request to a post session    ${updated_search_xml}
#    ${search_response}=    Decode Bytes To String    ${getCustomerListResp.content}    UTF-8
#    Log To Console      Decoded Search Response XML: ${search_response}
#
#    RETURN     ${xml_content}

Item Create V001 Alter
    [Arguments]    ${CUR_DIR}    ${Input_file_Name}
    ${ItemCreateResp}=    Invoke MultiApi2    ${CUR_DIR}    ${manageItem_MultiAPi_Input_file_Name}
    Log To Console    ItemCreateResp: ${ItemCreateResp}

Search Customer V001
    [Arguments]         ${CUR_DIR}    ${Input_file_Name}
    ${getCustomerListResp}=    Invoke MultiApi2    ${CUR_DIR}    ${getCustomerList_Input_file_Name}
    Log To Console   getCustomerListResponse: ${getCustomerListResp}
    ${xml_content}=    Decode Bytes To String    ${getCustomerListResp.content}    UTF-8
    Log To Console      Decoded Customer Details XML: ${xml_content}
    RETURN     ${xml_content}


Ship Depart V001
    [Arguments]    ${CUR_DIR}    ${Input_file_Name}
    ${ShipDepartResponse}=    Invoke MultiApi2    ${CUR_DIR}    ${Input_file_Name}
    ${response_text}=    Decode Bytes To String    ${ShipDepartResponse.content}    UTF-8
    Log To Console    Decoded ShipDepartResponse: ${response_text}
    RETURN    ${response_text}

Update Orderlines V001
    [Arguments]    ${CUR_DIR}    ${Input_file_Name}    ${OrderHeaderKey}    ${order_line_keys}    ${indices}       ${OrderNo}
    ${updated_xml}=    Prepare Update Orderline Input    ${CUR_DIR}    ${Input_file_Name}    ${OrderHeaderKey}    ${order_line_keys}    ${indices}    ${OrderNo}
    Log To Console    ${updated_xml}
    ${UpdateOrderLinesResp}=     Send Request to a post session    ${updated_xml}
    ${response_text}=    Decode Bytes To String    ${UpdateOrderLinesResp.content}    UTF-8
    Log To Console      Decoded UpdateOrderlinessFromRoutingResponse: ${response_text}
    RETURN    ${response_text}

Send OrderLineList For Routing
    [Arguments]    ${CUR_DIR}    ${Input_file_Name}
    ${SendOrderLineResponse}=    Invoke MultiApi2    ${CUR_DIR}    ${SendOrderLine_Input_file_Name}
    ${response_text}=    Decode Bytes To String    ${SendOrderLineResponse.content}    UTF-8
    Log To Console    Decoded SendOrderlinesForRoutingResponse: ${response_text}
    RETURN    ${response_text}

Should Contain Any
    [Arguments]    ${text}    @{expected_list}
    FOR    ${expected}    IN    @{expected_list}
        ${found}=    Run Keyword And Return Status    Should Be Equal As Strings    ${text}    ${expected}
        Run Keyword If    ${found}    RETURN
    END
    Fail    '${text}' did not match any of: ${expected_list}


Schedule And Release Order V001
    [Arguments]    ${CUR_DIR}    ${OrderNo}    ${DocumentType}
    Log To Console    --- START: Schedule And Release Order for ${OrderNo} ---
    Log    Starting Schedule and Release Order for OrderNo=${OrderNo}

    Log To Console    Step 1: Invoking Schedule API using file: ${scheduleOrder_Input_file_Name}
    ${request_body}=    generic_input_file_ord    ${CUR_DIR}    scheduleOrder    ${OrderNo}
#    ${request_body}=     Generic Input File Ordno Doctype    ${CUR_DIR}    scheduleOrder    ${OrderNo}    ${DocumentType}

    Log To Console    Updated XML: ${request_body}
    Log To Console    ==== Schedule API Request ====
    ${scheduleOrderResp}=     Send Request to a post session    ${request_body}
    ${xml_content}=    Decode Bytes To String    ${scheduleOrderResp.content}    UTF-8
    Log To Console      Decoded Order Details XML: ${xml_content}

    ${getOrderDetailResp}=    Get Order Details With DocType    ${CUR_DIR}      ${OrderNo}    ${DocumentType}
#    Log To Console    get Order Details Response    ${getOrderDetailResp}
    Log To Console    Step 2 Completed: Order details fetched.



    Log To Console    Step 3-4: Extracting <Order> element
    ${order_element}=    XML.Get Element    ${getOrderDetailResp}    API[@Name="getOrderDetails"]/Output/Order
    Log To Console  Extracted Order Element: ${order_element}
    Log To Console    Step 3-4 Completed.

    Log To Console    Step 5: Fetching Order Status attribute
    ${actual_status}=    XML.Get Element Attribute    ${order_element}    Status
    Log To Console    Actual Order Status: ${actual_status}
    Log To Console    Order Status Retrieved: ${actual_status}

    Log To Console    Step 6: Extracting Order Status Lines
    ${order_status_elements}=    XML.Get Elements    ${getOrderDetailResp}    API[@Name="getOrderDetails"]/Output/Order/OrderStatuses/OrderStatus
    Log To Console    Order Status Elements Found: ${order_status_elements}
    Log To Console    Step 6 Completed.

    Log To Console    Step 7: Extracting Line Keys & Release Keys from status elements
    ${order_line_keys}=    Create List
    ${release_keys}=      Create List
    FOR    ${status_elem}    IN    @{order_status_elements}
        ${line_key}=    XML.Get Element Attribute    ${status_elem}    OrderLineKey
        ${release_key}=    XML.Get Element Attribute    ${status_elem}    OrderReleaseKey
        Append To List    ${order_line_keys}    ${line_key}
        Append To List    ${release_keys}    ${release_key}
    END
    Log To Console    OrderLineKeys: ${order_line_keys}
    Log To Console    OrderReleaseKeys: ${release_keys}
    Log To Console    Actual Status: ${actual_status}
    Run Keyword If    '${actual_status}' == 'Scheduled' or '${actual_status}' == 'Released' or '${actual_status}' == 'Partially Released'    Log To Console    Status validation passed: ${actual_status}    ELSE    Fail    Order status invalid â€” expected Scheduled or Released but got ${actual_status}
    Set Test Message    Test completed: OrderNo=${OrderNo}, Status=${actual_status}
    RETURN    ${actual_status}    ${order_line_keys}    ${release_keys}


Change Order Status V001 New
    [Arguments]    ${CUR_DIR}    ${OrderHeaderKey}    ${order_line_keys}    ${TransactionId}    ${BaseDropStatus}    ${Status}    ${OrderNo}    ${DocumentType}    ${line_numbers}
    ${output_dir}=    Replace String    ${CUR_DIR}    \Test    \Input
    ${output_file}=   Set Variable    ${output_dir}\\changeOrderStatus_input.xml
    Create Directory    ${output_dir}

    ${xml_content_1}=    Build Order Status Change Xml    ${OrderHeaderKey}    ${TransactionId}    ${BaseDropStatus}    ${order_line_keys}    ${output_file}    line_numbers=${line_numbers}
#    line_numbers=1,2
    Log To Console    Generated ChangeOrderStatus XML is:
    Log To Console    ${xml_content_1}

    ${ChangeOrderResp}=     Send Request to a post session    ${xml_content_1}
    ${xml_content_2}=    Decode Bytes To String    ${ChangeOrderResp.content}    UTF-8
    Log To Console      Decoded Order Details XML: ${xml_content_2}

#    ${getOrderDetailResp}=    Get Order Details    ${CUR_DIR}      ${OrderNo}
#    Log To Console    get Order Details Response    ${getOrderDetailResp}
#    Log To Console    ${xml_content}
#    
#    ${resp}=    Invoke MultiApi2    ${CUR_DIR}    ${output_file}
#    ${getOrderDetailResp}=    Get Order Details    ${CUR_DIR}    ${OrderNo}
    ${getOrderDetailResp}=    Get Order Details With DocType    ${CUR_DIR}      ${OrderNo}    ${DocumentType}
    Log To Console    get Order Details Response: ${getOrderDetailResp}

    ${order_node}=    XML.Get Element    ${getOrderDetailResp}    .//Order
    ${actual_status}=    XML.Get Element Attribute    ${order_node}    Status
    ${actual_status}=    Strip String    ${actual_status}
    Log To Console    Actual Status: ${actual_status}

    Run Keyword If    '${actual_status}' == 'Ready To Route' or '${actual_status}' == 'Partially Ready To Route'
    ...    Validate Order Status    ${getOrderDetailResp}    ${actual_status}
    ...    ELSE
    ...    Fail    Unexpected status received: ${actual_status}

    Set Test Message    Test completed: OrderHeaderKey=${OrderHeaderKey} OrderNo=${OrderNo}

GetDeliveryOptions For Fulfillment
    [Arguments]    ${CUR_DIR}    ${Input_file_Name}
    ${GetDeliveryOptionsResponse}=    Invoke MultiApi2    ${CUR_DIR}    ${Input_file_Name}
    ${response_text}=    Decode Bytes To String    ${GetDeliveryOptionsResponse.content}    UTF-8
#    Log To Console    Decoded GetDeliveryOptionsResponse: ${response_text}
    RETURN    ${response_text}

CTOrderRouting New
    [Arguments]    ${CUR_DIR}    ${Input_file_Name}    ${OrderNo}    ${OrderHeaderKey}    ${DocumentType}    ${ReqDeliveryDate}
    ${request_body}=    Generic Input File Ord Headerkey
    ...    ${CUR_DIR}
    ...    ${Input_file_Name}
    ...    ${OrderNo}
    ...    ${OrderHeaderKey}
    ...    ${DocumentType}
    ...    ${ReqDeliveryDate}
    Log To Console    Updated XML: ${request_body}
#    ${SendOrderLineResponse}=    Invoke MultiApi2   ${CUR_DIR}    ${Input_file_Name}
    ${SendOrderLineResponse}=    Send Request to a post session    ${request_body}
    ${response_text}=    Decode Bytes To String
    ...    ${SendOrderLineResponse.content}
    ...    UTF-8
    ${getOrderDetailResp}=    Get Order Details With DocType    ${CUR_DIR}      ${OrderNo}    ${DocumentType}
#    Log To Console    get Order Details Response    ${getOrderDetailResp}
    Log To Console    Step 2 Completed: Order details fetched.

    Log To Console    Step 3-4: Extracting <Order> element
    ${order_element}=    XML.Get Element    ${getOrderDetailResp}    API[@Name="getOrderDetails"]/Output/Order
    Log To Console  Extracted Order Element: ${order_element}
    Log To Console    Step 3-4 Completed.

    Log To Console    Step 5: Fetching Order Status attribute
    ${actual_status}=    XML.Get Element Attribute    ${order_element}    Status
    Log To Console    Actual Order Status: ${actual_status}
    Log To Console    Order Status Retrieved: ${actual_status}
    Log To Console    Decoded SendOrderlinesForRoutingResponse: ${response_text}
    Set Test Message    Test completed: OrderNo=${OrderNo}, Status=${actual_status}
    RETURN    ${response_text}    ${actual_status}