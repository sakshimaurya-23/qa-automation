*** Settings ***
Resource    ../../../../../Library/Robots/keywords.robot

*** Variables ***
${CUR_DIR}     ${CURDIR}

*** Test Cases ***

Update Regular Item
    [Documentation]    This test case validates the Create Regular Item
    [Tags]      REGRESSION    Catalog
    Log To Console    curDir:${CUR_DIR}
    ${subfolders}=    Check folders    ${CUR_DIR}
    Log To Console    subfolders:${subfolders}
    ${folders}    List Directories In Directory    ${CUR_DIR}
    ${index}=    Set Variable    0  # Initialize the index to 1
    Log To Console    beforeForLoop:${index}
    FOR    ${folder}    IN    @{folders}
        Process All JSON Files    ${CUR_DIR}    ${folder}    ${index}
    END