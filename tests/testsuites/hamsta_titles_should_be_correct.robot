*** Settings ***
Documentation	 Verify that all page titles are correct
Resource         web-resources.robot
Suite Setup      Create Hamsta Host
Suite Teardown   Delete Hamsta Host
Force Tags	 hamsta  web
Library           lib/TestNetwork.py    ${NETWORK_ID}

*** Variables ***

*** Test Cases ***
Machines Page Title
	Click Link	   Machines
	Title Should Be    Machines - HAMSTA

Groups Page Title
	Click Link         Groups
	Title Should Be    Groups - HAMSTA

Jobs Page Title
	Click Link         Jobs
	Title Should Be    Jobs - HAMSTA

Validation Test Page Title
	Click Link         Validation Test
	Title Should Be    Validation test - HAMSTA

AutoPXE Page Title
	Click Link         AutoPXE
	Title Should Be    AutoPXE - HAMSTA

QA Cloud Page Title
	Click Link         QA Cloud
	Title Should Be    QA Cloud - HAMSTA

About Hamsta Page Title
	Click Link         About Hamsta
	Title Should Be    About Hamsta - HAMSTA

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

