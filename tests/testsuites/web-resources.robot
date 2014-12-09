*** Settings ***
Library           OperatingSystem
Library           String
Library           Selenium2Library    timeout=10    implicit_wait=5
Resource          ${CONFIG_FILE}

*** Variables ***
${CONFIG_FILE}    config.robot
${REINSTALL_TIMEOUT}    60

*** Keywords ***
Open Hamsta Login Page
    [Documentation]    Get to login page in Hamsta
    Click Link    Log in
    Title Should Be    Login - HAMSTA

Open Machine Detail Page
    [Arguments]    ${SUT_NAME}
    [Documentation]    Get to machine details page in Hamsta
    Click Link    Machines
    Click Link    ${SUT_NAME}
    Title Should Be    ${SUT_NAME} - HAMSTA

Open Machine Reinstall Page
    [Arguments]    ${SUT_NAME}
    [Documentation]    Get to machine reinstall page in Hamsta.
    Open Machine Detail Page    ${SUT_NAME}
    Mouse Over    css=img[alt="jobs"]
    Comment    Wait Until Element Is Visible    link=Reinstall
    Sleep    1
    Click Link    Reinstall
    Title Should Be    Reinstall - HAMSTA

Log In to Hamsta
    [Arguments]    ${LOGIN}=${USER_LOGIN}    ${PASSWORD}=${USER_PASSWORD}
    [Documentation]    Log in to Hamsta
    Open Hamsta Login Page
    Input Text    name=login    ${LOGIN}
    Input Text    name=password    ${PASSWORD}
    Click Button    Login

Log Out from Hamsta
    [Documentation]    Log out from Hamsta
    Click Link    Logout

Reserve Machine
    [Arguments]    ${SUT_NAME}    ${USAGE}=For Testing
    [Documentation]    Reserve SUT in Hamsta. User must be logged in.
    Open Machine Detail Page    ${SUT_NAME}
    Mouse Over    css=img[alt="edit/reserve"]
    Comment    Wait Until Element Is Visible    link=Edit
    Sleep    1
    Click Link    Edit
    Click Element    name=used_by_1[]
    Input Text    name=usage[1]    ${USAGE}
    Click Button    Change
    Page Should Contain    The requested actions were successfully completed.

Unreserve Machine
    [Arguments]    ${SUT_NAME}
    [Documentation]    Unreserve SUT in Hamsta reserved to currently logged in user.
    Open Machine Detail Page    ${SUT_NAME}
    Mouse Over    css=img[alt="edit/reserve"]
    Comment    Wait Until Element Is Visible    link=Edit
    Sleep    1
    Click Link    Edit
    Click Element    name=used_by_1[]
    Input Text    name=usage[1]    ${EMPTY}
    Click Button    Change
    Page Should Contain    The requested actions were successfully completed.

Reinstall Machine
    [Arguments]    ${SUT_NAME}    ${OS_REPO_NAME}    ${OS_HASMTA_DISPLAY_NAME}
    [Documentation]    Reinstall SUT with given OS. Machine must be reserved by user
    Open Machine Reinstall Page    ${SUT_NAME}
    Select From List By Label    repo_products    ${OS_REPO_NAME}
    Sleep    1
    Click Button    Finish
    Click Button    Submit
    Page Should Contain    Machine ${SUT_NAME} reinstallation has been launched.
    Sleep    90
    Open Machine Detail Page    ${SUT_NAME}
    Element Should Contain    id=status_string    job running
    Element Text Should Be    id=job_overview  reinstall
    : FOR    ${i}    IN RANGE    ${REINSTALL_TIMEOUT}
    \    Reload Page
    \    ${STATUS}=    Get Text    id=status_string
    \    Exit For Loop If    '${STATUS}' == 'up'
    \    Sleep    60s
    Element Text Should Be    id=status_string    up
    Element Text Should Be    id=product    ${OS_HASMTA_DISPLAY_NAME}
