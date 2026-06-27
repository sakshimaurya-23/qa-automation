*** Settings ***
Resource    ../../../../../Library/Robots/keywords.robot

*** Variables ***
${CUR_DIR}     ${CURDIR}
${EXPECTED_ERROR_DESCRIPTION}    Mandatory Parameters for the Operation are missing

*** Test Cases ***

Mandatory Parameters of Item
    [Documentation]    This test case validates the Mandatory Parameters of Item
    [Tags]      REGRESSION    Catalog
    Log To Console    curDir:${CUR_DIR}
    ${subfolders}=    Check folders    ${CUR_DIR}
    Log To Console    subfolders:${subfolders}
    ${folders}    List Directories In Directory    ${CUR_DIR}
    ${index}=    Set Variable    0  # Initialize the index to 1
    Log To Console    beforeForLoop:${index}
    FOR    ${folder}    IN    @{folders}
        Process All JSON Files to Validate Response    ${CUR_DIR}    ${folder}    ${index}    ${EXPECTED_ERROR_DESCRIPTION}
    END