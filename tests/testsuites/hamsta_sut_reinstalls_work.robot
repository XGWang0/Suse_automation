*** Settings ***
Documentation     Test that various reinstall scenarios work as expected
Suite Setup       Create Hamsta Host
Suite Teardown    Delete Hamsta Host
Force Tags        hamsta    web    reinstall
Resource          web-resources.robot
Library           lib/TestNetwork.py    ${NETWORK_ID}

*** Variables ***

*** Test Cases ***
Reinstall SLES-11-SP3 as SLES-11-SP3
    Reinstallation Test    sles-11-sp3    SLES-11-SP3-GM    SLES-11-SP3

Reinstall SLES-11-SP3 as SLES-12-LATEST
    Reinstallation Test    sles-11-sp3    SLE-12-Server-LATEST    SLES-12-SP0

Reinstall SLES-12-LATEST as SLES-12-LATEST
    Comment    This should work, but it does not because we do not yet build kiwi in lxc. When we do, delete the workaround code and use just following line
    Comment    Reinstallation Test    sles-12    SLE-12-Server-LATEST    SLES-12-SP0
    Comment    This is workaround code:
    ${SUT}=    Set Variable
    ${SUT}=    Add Host    sles-11-sp3    sut
    Sleep    60
    Reserve Machine    ${SUT}
    Reinstall Machine    ${SUT}    SLE-12-Server-LATEST    SLES-12-SP0
    Comment    Here we workarounded inability to create sle12 image by installing sle12 SUT by hamsta. Now we can start the test
    Reinstall Machine    ${SUT}    SLE-12-Server-LATEST    SLES-12-SP0
    Unreserve Machine    ${SUT}
    [Teardown]    Run Keyword If    '${SUT}' != ''    Delete Host    ${SUT}

Reinstall SLES-12 as SLES-11-SP3
    Comment    This should work, but it does not because we do not yet build kiwi in lxc. When we do, delete the workaround code and use just following line
    Comment    Reinstallation Test    sles-12    SLES-11-SP3-GM    SLES-11-SP3
    Comment    This is workaround code:
    ${SUT}=    Set Variable
    ${SUT}=    Add Host    sles-11-sp3    sut
    Sleep    60
    Reserve Machine    ${SUT}
    Reinstall Machine    ${SUT}    SLE-12-Server-LATEST    SLES-12-SP0
    Comment    Here we workarounded inability to create sle12 image by installing sle12 SUT by hamsta. Now we can start the test
    Reinstall Machine    ${SUT}    SLES-11-SP3-GM    SLES-11-SP3
    Unreserve Machine    ${SUT}
    [Teardown]    Run Keyword If    '${SUT}' != ''    Delete Host    ${SUT}

*** Keywords ***
Create Hamsta Host
    ${HAMSTA}=    Add Host    sles-11-sp3    hamsta
    ${HAMSTA_HOST}=    Get FQDN    ${HAMSTA}
    Set Suite Variable    ${HAMSTA}
    Set Suite Variable    ${HAMSTA_HOST}
    Set Suite Variable    ${HAMSTA_BASE_URL}    http://${HAMSTA_HOST}/hamsta/
    Sleep    60s    Wait for hosts to start
    Open Browser    ${HAMSTA_BASE_URL}
    Log In to Hamsta

Delete Hamsta Host
    Comment    Close Browser
    Comment    Delete Host    ${HAMSTA}

Reinstallation Test
    [Arguments]    ${KIWI_OS_TYPE_FROM}    ${REPOSITORY_PRODUCT}    ${HAMSTA_PRODUCT}
    [Documentation]    Run the basic reinstallation (all default) values on newly created host.
    ...
    ...    Arguments are:
    ...    ${KIWI_OS_TYPE_FROM} - kiwi (virttest.py) os description to use for creating the host for test.
    ...    ${REPOSITORY PRODUCT} - Name of product in repository -> how it is seen in reinstall page list
    ...    ${HAMSTA_PRODUCT} - Name of product how it is shown in hamsta
    ${SUT}=    Set Variable
    ${SUT}=    Add Host    ${KIWI_OS_TYPE_FROM}    sut
    Sleep    60
    Reserve Machine    ${SUT}
    Reinstall Machine    ${SUT}    ${REPOSITORY_PRODUCT}    ${HAMSTA_PRODUCT}
    Unreserve Machine    ${SUT}
    [Teardown]    Run Keyword If    '${SUT}' != ''    Delete Host    ${SUT}
