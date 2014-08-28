*** Settings ***
Documentation    Verify that login page works properly
Resource         web-resources.robot
Suite Setup      Create Hamsta Host
Suite Teardown   Delete Hamsta Host
Force Tags	 hamsta  web
Library           lib/TestNetwork.py    ${NETWORK_ID}

*** Variables ***

*** Test Cases ***
Valid Login and Logout Should Work
	[Documentation]    Hamsta valid login and logout test
	Log In to Hamsta	    ${USER_LOGIN}  ${USER_PASSWORD}
	Page Should Contain         Logged in as ${USER_NAME}
	Page Should Contain Link    Logout
	Click Link                  Logout
	Page Should Not Contain     Logged in as ${USER_NAME}
	Page Should Contain Link    Log in

*** Keywords ***
Create Hamsta Host
    ${HAMSTA}=    Add Host    sles-11-sp3    hamsta
    ${HAMSTA_HOST}=    Get FQDN    ${HAMSTA}
    Set Suite Variable  ${HAMSTA}
    Set Suite Variable  ${HAMSTA_HOST}
    Set Suite Variable  ${HAMSTA_BASE_URL}   http://${HAMSTA_HOST}/hamsta/
    Sleep              60s         Wait for hosts to start
    Open Browser      ${HAMSTA_BASE_URL}

Delete Hamsta Host
    Close Browser
    Delete Host    ${HAMSTA}
