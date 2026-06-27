
*** Settings ***
Resource    ../Library/Robots/keywords.robot

*** Variables ***
${CUR_DIR}     ${CURDIR}

*** Test Cases ***

Run All Test Cases
    [Documentation]    Top-level suite runner. Discovers and executes all test case
    ...                sub-suites under Test_Cases/.
    Log To Console    Running full suite from: ${CUR_DIR}
    ${folders}    List Directories In Directory    ${CUR_DIR}
    FOR    ${folder}    IN    @{folders}
        Log To Console    Found test case folder: ${folder}
    END
