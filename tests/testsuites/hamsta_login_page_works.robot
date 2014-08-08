*** Settings ***
Documentation    Verify that login page works properly
Resource         web-resources.robot
Suite Setup      Open Browser      ${HAMSTA_BASE_URL}
Suite Teardown   Close Browser
Force Tags	 hamsta  web

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
