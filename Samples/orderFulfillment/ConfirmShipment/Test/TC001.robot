*** Settings ***
Resource    ../../../../Library/Robots/keywords.robot
Test Setup
Library  xmltodict
Library         Collections
Library         RequestsLibrary
Library         XML
#Library    SeleniumLibrary
*** Variables ***
${CUR_DIR}     ${CURDIR}

*** Test Cases ***

#Create Order TC001
#    [Documentation]    This test case validates the Create Order
#    [Tags]      SMOKE    CREATEORDER
#    Log To Console    Starting Create Order Test Case
#    ${createOrderResp}=    Invoke MultiApi2        ${CUR_DIR}    ${createOrder_Input_file_Name}
#    Log To Console   createOrderResp: ${createOrderResp}
#    ${OrderNo}=    Fetch Order No    ${createOrderResp}
##    ${OrderNo}=    Set Variable    CITY-VJ-20250424_333
#    Log To Console    OrderNo: ${OrderNo}
#    ${getOrderDetailResp}=    Get Order Details    ${CUR_DIR}      ${OrderNo}
#    Log To Console    getOrderDetailResp: ${getOrderDetailResp}
#    Validate Order Status    ${getOrderDetailResp}    Created
#    Set Test Message    Test completed: OrderNo is : ${OrderNo}

Create Order TC_001
    [Documentation]    This test case validates the Create Order
    [Tags]      SMOKE    CREATEORDER
    ${OrderNo}    ${OrderHeaderKey}=    Create Order V001 Alter    ${CUR_DIR}    ${createOrder_Input_file_Name}
    Set Suite Variable    ${OrderNo}
    Set Suite Variable    ${OrderHeaderKey}
    Log To Console    OrderHeaderKey: ${OrderHeaderKey}    OrderNo: ${OrderNo}

Create And Schedule Order TC_001
    [Documentation]    This test case validates the Schedule Order
    [Tags]      SMOKE    SCHEDULEORDER
    Log To Console    Starting Create Order Test Case
    ${OrderNo}    ${OrderHeaderKey}=    Create Order V001 Alter    ${CUR_DIR}    ${createOrder_Input_file_Name}
    Schedule Order V001 Alter    ${CUR_DIR}  ${OrderNo}

Create And Schedule And Release Order TC_001
    [Documentation]    This test case validates the Release Order
    [Tags]      SMOKE    RELEASEORDER
    ${OrderNo}    ${OrderHeaderKey}=    Create Order V001 Alter    ${CUR_DIR}    ${createOrder_Input_file_Name}
    Schedule Order V001 Alter      ${CUR_DIR}    ${OrderNo}
    Release Order V001 Alter   ${CUR_DIR}  ${OrderNo}
Create And Schedule And Release And Change Order to Ready For Ship TC_001
    [Documentation]    This test case validates the Ready For Shipment
    [Tags]    SMOKE    READYFORSHIP
    ${OrderNo}    ${OrderHeaderKey}=    Create Order V001 Alter    ${CUR_DIR}    ${createOrder_Input_file_Name}
    ${OrderNo}=    Set Variable    CITY-VJ-20250424_347
    Schedule Order V001 Alter      ${CUR_DIR}    ${OrderNo}
    Release Order V001 Alter   ${CUR_DIR}  ${OrderNo}
    Change Order Status V001    ${CUR_DIR}  ${OrderNo}

Create Shipment TC_001
    [Documentation]    This test case validates the Included In Shipment
    [Tags]    SMOKE    IncludedInShipment
    ${OrderNo}    ${OrderHeaderKey}=    Create Order V001 Alter    ${CUR_DIR}    ${createOrder_Input_file_Name}
#    ${OrderNo}=    Set Variable    CITY-Order-20250612_16
    Schedule Order V001 Alter      ${CUR_DIR}    ${OrderNo}
    Release Order V001 Alter   ${CUR_DIR}  ${OrderNo}
    Change Order Status V001    ${CUR_DIR}  ${OrderNo}
    Create Shipment V001    ${CUR_DIR}  ${OrderNo}
    
Confirm Shipment TC_001
    [Documentation]    This test case validates the Confirm Shipment
    [Tags]      SMOKE    CONFIRMSHIPMENT
#    ${createOrderResp}=    Invoke MultiApi2    ${CUR_DIR}    ${createOrder_Input_file_Name}
#    ${OrderNo}=    Fetch Order No    ${createOrderResp}
#    ${OrderNo}=    Set Variable    CITY-VJ-20250509_101
    ${OrderHeaderKey}=    Set Variable    202505091145192315245
#    ${OrderHeaderKey}=    Fetch OrderHeaderKey    ${createOrderResp}
    ${getOrderDetailResp}=    Get Order Details    ${CUR_DIR}      ${OrderNo}
#    Validate Order Status    ${getOrderDetailResp}    Created
#    Schedule Order V001 Alter    ${CUR_DIR}  ${OrderNo}
#    Release Order V001 Alter   ${CUR_DIR}  ${OrderNo}
#    Change Order Status V001    ${CUR_DIR}  ${OrderNo}
#    Create Shipment V001    ${CUR_DIR}  ${OrderNo}
    Confirm Shipment V001 Alter    ${CUR_DIR}   ${OrderNo}    ${OrderHeaderKey}
