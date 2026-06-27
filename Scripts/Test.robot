*** Settings ***
Resource    ${CURDIR}/../../Library/Robots/keywords.robot

*** Variables ***
${CUR_DIR}     ${CURDIR}

*** Test Cases ***

Process All XML Files
    [Documentation]    Processes all input XML files in the Data/Input folder,
    ...                sends them to the OMS API, and validates responses against
    ...                expected results in Data/ExpectedResult.
    [Tags]    REGRESSION
    Log To Console    curDir:${CUR_DIR}
    
    # Pre-process XML/JSON files to generate updated_setup/ and updated_input/
    ${suite_exists}=    Run Keyword And Return Status    Directory Should Exist    ${CUR_DIR}
    Run Keyword If    ${suite_exists}    Process Suite    ${CUR_DIR}
    
    ${subfolders}=    Check folders    ${CUR_DIR}
    Log To Console    subfolders:${subfolders}
    ${folders}    List Directories In Directory    ${CUR_DIR}
    ${index}=    Set Variable    0
    Log To Console    beforeForLoop:${index}
    FOR    ${folder}    IN    @{folders}
        Process All JSON Files    ${CUR_DIR}    ${folder}    ${index}
    END
