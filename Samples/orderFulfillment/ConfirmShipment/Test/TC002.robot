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

Create Order TC_002
    [Documentation]    This test case validates the Create Order
    [Tags]      SMOKE    CREATEORDER
    ${OrderNo}    ${OrderHeaderKey}=    Create Order V001 Alter    ${CUR_DIR}    ${createOrder_Input_file_Name1}
    Set Suite Variable    ${OrderNo}
    Set Suite Variable    ${OrderHeaderKey}
    Log To Console    OrderHeaderKey: ${OrderHeaderKey}    OrderNo: ${OrderNo}

