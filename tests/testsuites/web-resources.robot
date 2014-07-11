*** Settings ***
Library          OperatingSystem
Library          Selenium2Library  timeout=10  implicit_wait=5

*** Variables ***
${HOST}            localhost
${BASE_URL}        http://${HOST}/hamsta/
${USER_LOGIN}      testuser
${USER_PASSWORD}   testpassword
${USER_NAME}       Test User

*** Keywords ***
Open Hamsta Login Page    [Documentation]   Get to login page in Hamsta
	Click Link                  Log in
	Title Should Be             Login - HAMSTA

Log In to Hamsta
	[Arguments]        ${LOGIN}=${USER_LOGIN}   ${PASSWORD}=${USER_PASSWORD}
        [Documentation]    Log in to Hamsta
	Open Hamsta Login Page	
	Input Text                  name=login       ${LOGIN}
	Input Text                  name=password    ${PASSWORD}
	Click Button                Login

Log Out from Hamsta       [Documentation]    Log out from Hamsta
	Click Link                  Logout
