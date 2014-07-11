*** Settings ***
Documentation    Verify that user can create machine groups
Resource         web-resources.robot
Suite Setup      Open Browser      ${HAMSTA_BASE_URL}
Suite Teardown   Close Browser
Force Tags	 hamsta  web

*** Variables ***


*** Test Cases ***
It Should be Possible to Create Group
	[Documentation]         Valid Group Creation
    ${GROUP_NAME} =   Generate Random String
    Set Suite Variable  ${GROUP_NAME}
    Set Suite Variable  ${GROUP_DESC}  This is group named ${GROUP_NAME}
	Log In to Hamsta	    ${USER_LOGIN}  ${USER_PASSWORD}
	Page Should Contain     Logged in as ${USER_NAME}
    Click Link              Groups
    Page Should Contain Link    Create a new empty group
    Click Link              Create a new empty group
    Input Text              name=name   ${GROUP_NAME}
    Input Text              name=desc   ${GROUP_DESC}
    Click Button            Create group
    Page Should Contain     Group created!
    Table Should Contain    css=table.list  ${GROUP_NAME}
    Table Should Contain    css=table.list  ${GROUP_DESC}

It Should be Possible to Delete Existing Group
    [Documentation]         Group Deletion
    Click Link              Groups
    Table Should Contain    css=table.list  ${GROUP_NAME}
    Click Image             delete ${GROUP_NAME}
    Page Should Contain     Delete Group ${GROUP_NAME}
    Page Should Contain     ${GROUP_DESC}
    Click Link              Confirm delete
    Page Should Not Contain  ${GROUP_NAME}

*** Keywords ***
