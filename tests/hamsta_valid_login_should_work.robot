*** Settings ***
Resource         web-resources.txt
Suite Setup      Open Browser      ${BASE_URL}
Suite Teardown   Close Browser
Force Tags	 hamsta web

*** Variables ***

*** Test Cases ***
Login and logout
	[Documentation]    Hamsta login and logout test
	Log In to Hamsta	    ${USER_LOGIN}  ${USER_PASSWORD}
	Page Should Contain         Logged in as ${USER_NAME}
	Page Should Contain Link    Logout
	Click Link                  Logout
	Page Should Not Contain     Logged in as ${USER_NAME}
	Page Should Contain Link    Log in

*** Keywords ***
