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
    Log To Console    ${resp.headers['Content-Type']}

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
    FOR    ${test_case}    IN    @{data.keys()}
        ${xml_files}=    Get From Dictionary    ${data}    ${test_case}
        FOR    ${xml_file}    IN    @{xml_files}
            ${xml_content}=    Get File    ${xml_file}
            # Fix 1: Extract OrderNo/OrderHeaderKey from any _input.xml response that contains OrderNo=
            ${matchInputXML}=    Run Keyword And Return Status    Should Match Regexp    ${xml_file}    (?i)_input\.xml$
            IF    ${matchInputXML}
                ${alreadyHasOrderNo}=    Run Keyword And Return Status    Variable Should Exist    \${OrderNo}
                IF    not ${alreadyHasOrderNo}
                    # Send the request first WITHOUT substitution to get the response and extract OrderNo
                    ${temp_resp}=    Send XML File    ${xml_content}    ${xml_file}    ${index}
                    ${hasOrderInResp}=    Run Keyword And Return Status    Should Contain    ${temp_resp.text}    OrderNo=
                    IF    ${hasOrderInResp}
                        Extract Order Info    ${temp_resp.text}
                        # Now substitute with the newly extracted OrderNo for subsequent uses
                        ${xml_content}=    Substitute Extracted Variables    ${xml_content}
                        ${resp}=    Send XML File    ${xml_content}    ${xml_file}    ${index}
                    ELSE
                        # No OrderNo in response, just use the original response
                        ${resp}=    Set Variable    ${temp_resp}
                    END
                ELSE
                    # OrderNo already exists, substitute and send
                    ${xml_content}=    Substitute Extracted Variables    ${xml_content}
                    ${resp}=    Send XML File    ${xml_content}    ${xml_file}    ${index}
                END
            ELSE
                # Not an _input.xml file, just substitute and send
                ${xml_content}=    Substitute Extracted Variables    ${xml_content}
                ${resp}=    Send XML File    ${xml_content}    ${xml_file}    ${index}
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
    Log    req:${xml_data}
    Log    resp:${resp}
    Log    respContent:${resp.content}
    Check for MapData    ${xml_data}    ${resp.content}    ${xml_file}
    Check for ValidateData    ${resp.content}    ${xml_file}    ${index}
    RETURN    ${resp}

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
    Log    resp:${resp}
    Log    respContent:${resp.content}
    Check for MapData    ${xml_data}    ${resp.content}    ${xml_file}
    Check for ValidateResponse Content    ${resp}    ${xml_file}    ${index}    ${EXPECTED_ERROR_DESCRIPTION}


Check for MapData
       [Arguments]    ${xml_data}    ${resp.content}    ${xml_file}
       Log    testcase:------------------${xml_file}
       ${folder_path}=    Execute XML    ${xml_file}
       ${mapDataflag}=     Check File Contains MapData       ${xml_file}    mapdata
       Log    mapDataflag:${mapDataflag}
       Log    content:${resp.content}
       ${flag}=    Check Flag If True    ${mapDataflag}
       Log    flag::::::::::::::::::::${flag}
       ${file_name}=    Get Base Filename       ${xml_file}
       Run Keyword If    ${FLAG}    Fecth Response    ${resp.content}     ${folder_path}    ${file_name}
       Get Data Flag    ${folder_path}    ${resp.content}    ${xml_file}


Get Data Flag
       [Arguments]    ${folder_path}    ${resp.content}    ${xml_file}
       ${getDataflag}=     Check File Contains MapData       ${xml_file}    getdata
       Log    mapDataflag:${getDataflag}
       Log    content:${resp.content}
       ${getflag}=    Check Flag If True    ${getDataflag}
       Log   getFlag:${getflag}
       Run Keyword If    ${getflag}  Get Data Flag is true     ${folder_path}    ${resp.content}    ${xml_file}


Get Data Flag is true
       [Arguments]    ${folder_path}    ${resp.content}    ${xml_file}
       ${json_data}=    Load Json Files Output     ${folder_path}${output_foldername}
       Log    jsonData:${json_data}
       Log    xmlfile:${xml_file}
       ${xml_str}=    Replace Variables In Xml    ${xml_file}    ${json_data}
       Log    ${xml_str}
       ${resp}=    Invoke MultiApi by Sending Request    ${xml_str}

Check for ValidateData
       [Arguments]    ${resp.content}    ${xml_file}    ${index}
       ${folder_path}=    Execute XML    ${xml_file}
       ${valDataflag}=     Check File Contains MapData       ${xml_file}    validatedata
       Log    mapDataflag:${valDataflag}
       Log    content:${resp.content}
       ${valDataflag}=    Check Flag If True    ${valDataflag}
       ${index}=    Run Keyword If    ${valDataflag}      Increment Index    ${index}     # Increment index after each iteration
       Run Keyword If    ${valDataflag}  Get Validate Data Flag Is True And Compare Xmls   ${folder_path}    ${resp.content}    ${xml_file}    ${index}

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
       Log To Console    Get Validate Data Flag is true:${folder_path}${actual_result_file}${counter}.xml
        ${xml_string}=    Decode Bytes To String    ${response.content}    UTF-8
        ${description}=    Get Error Description    ${xml_string}
        Should Be Equal    ${description}    ${EXPECTED_ERROR_DESCRIPTION}

Get Validate Data Flag is true and compare xmls
       [Arguments]    ${folder_path}    ${resp.content}    ${xml_file}    ${index}
       ${counter}=    Write Actual Result      ${resp.content}     ${actualresult_foldername}     ${folder_path}
       Log To Console   Get Validate Data Flag is true ::::::::counter:${counter}
       Log To Console    expectedResultFile:${folder_path}${expected_result_file}${counter}.xml
       Log To Console    ${folder_path}${actual_result_file}${counter}.xml
       Compare Expected and Actual XML Files By Removing Dynamic Keys    ${folder_path}${expected_result_file}${counter}.xml    ${folder_path}${actual_result_file}${counter}.xml

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
    # Also run structural XML comparison on the NORMALIZED (masked) strings
    Compare Xml    ${normalized_expected_string}    ${normalized_actual_string}

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
    # Also run structural XML comparison on the NORMALIZED (masked) strings
    Compare Xml    ${normalized_expected_string}    ${normalized_actual_string}

#IV related keywords
Initialize Token
    ${token_url}=    Set Variable    https://api.watsoncommerce.ibm.com/inventory/us-1b8d5331/v1/oauth2/token
    ${client_id}=    Set Variable    LDvKQpNiCyr3NU8gEfPvC0gwOzpF0jkw
    ${client_secret}=    Set Variable    X3E2XV9wotpndnfvkipX7sGOqY6CqKpy

    ${token}=    Get Bearer Token    ${token_url}    ${client_id}    ${client_secret}
    Set Suite Variable    ${dev_b_token}    ${token}
    Log    Token initialized: ${dev_b_token}

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


Create Order V001 Alter
    [Arguments]         ${CUR_DIR}    ${Input_file_Name}
    ${createOrderResp}=    Invoke MultiApi2    ${CUR_DIR}    ${createOrder_Input_file_Name}
    Log To Console   createOrderResp: ${createOrderResp}
#    ${OrderNo}=    Set Variable    CITY-VJ-20250424_341
    ${OrderNo}=    Fetch Order No    ${createOrderResp}
    ${getOrderDetailResp}=    Get Order Details    ${CUR_DIR}      ${OrderNo}
    Validate Order Status    ${getOrderDetailResp}    Created
    Set Test Message    Test completed: OrderNo is : ${OrderNo}
    RETURN     ${OrderNo}


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

Search Customer V001
    [Arguments]         ${CUR_DIR}    ${Input_file_Name}
    ${getCustomerListResp}=    Invoke MultiApi2    ${CUR_DIR}    ${getCustomerList_Input_file_Name}
    Log To Console   getCustomerListRequest: ${getCustomerListResp}
    ${xml_content}=    Decode Bytes To String    ${getCustomerListResp.content}    UTF-8
    Log To Console      Decoded Customer Details XML: ${xml_content}
    RETURN     ${xml_content}

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
    ${hasShipNode}    ${ShipNode_Extracted}=    Run Keyword And Ignore Error    XML.Get Element Attribute    ${orderline}    ShipNode
    IF    '${hasShipNode}' == 'PASS' and '${ShipNode_Extracted}' != 'None' and '${ShipNode_Extracted}' != ''
        Log To Console    Extracted ShipNode from OrderLine: ${ShipNode_Extracted}
        Set Test Variable    ${ShipNode_Extracted}
    END
    ${hasReleaseNo}    ${ReleaseNo_Extracted}=    Run Keyword And Ignore Error    XML.Get Element Attribute    ${orderline}    ReleaseNo
    IF    '${hasReleaseNo}' == 'PASS' and '${ReleaseNo_Extracted}' != 'None' and '${ReleaseNo_Extracted}' != ''
        Log To Console    Extracted ReleaseNo: ${ReleaseNo_Extracted}
        Set Test Variable    ${ReleaseNo_Extracted}
    END
    ${hasPrimeLineNo}    ${PrimeLineNo_Extracted}=    Run Keyword And Ignore Error    XML.Get Element Attribute    ${orderline}    PrimeLineNo
    IF    '${hasPrimeLineNo}' == 'PASS' and '${PrimeLineNo_Extracted}' != 'None' and '${PrimeLineNo_Extracted}' != ''
        Log To Console    Extracted PrimeLineNo: ${PrimeLineNo_Extracted}
        Set Test Variable    ${PrimeLineNo_Extracted}
    END


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

    # Substitute ${OrderNo} and ${OrderHeaderKey} extracted from createOrder response
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
    RETURN    ${xml_content}
