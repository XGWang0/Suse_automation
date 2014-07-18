*** Settings ***
Documentation    Verify that Hamsta master service can be managed
Resource         ssh-resources.robot
Suite Setup      Open Connection And Login
Suite Teardown   Close All Connections
Force Tags	 hamsta  backend

*** Variables ***

*** Test Cases ***
It Should be Possible to Start Hamsta Master Service
    [Documentation]  Check that Hamsta master is started succesfully
	Start Hamsta Master Service
    Check Hamsta Master Is Active

It Should be Possible to Restart Hamsta Master Service
    [Documentation]         Check that Hamsta master is restarted succesfully
	Check Hamsta Master Is Active
	Restart Hamsta Master Service
    Check Hamsta Master Is Active

It Should be Possible to Stop Hamsta Master Service
    [Documentation]         Check that Hamsta master is stopped succesfully
	Stop Hamsta Master Service
	Check Hamsta Master Is Not Active

*** Keywords ***
