*** Settings ***
Documentation     Verify that Hamsta master service can be managed
Suite Setup       Prepare Hamsta Master Service And Login
Suite Teardown    Restore Environment After Test And Close Connection
Force Tags        hamsta    backend
Resource          ssh-resources.robot
Library           lib/TestNetwork.py    %{NETWORK}

*** Variables ***

*** Test Cases ***
It Should be Possible to Start Hamsta Master Service
    [Documentation]    Check that Hamsta master is started succesfully
    Start Hamsta Master Service
    Check Hamsta Master Is Active

It Should be Possible to Restart Hamsta Master Service
    [Documentation]    Check that Hamsta master is restarted succesfully
    Check Hamsta Master Is Active
    Restart Hamsta Master Service
    Check Hamsta Master Is Active

It Should be Possible to Stop Hamsta Master Service
    [Documentation]    Check that Hamsta master is stopped succesfully
    Stop Hamsta Master Service
    Check Hamsta Master Is Not Active

*** Keywords ***
Prepare Hamsta Master Service And Login
    Open Connection And Login
    Stop Hamsta Master Service

Restore Environment After Test And Close Connection
    Start Hamsta Master Service
    Close All Connections

Prepare Test Network
    [Documentation]    Create Hamsta host
