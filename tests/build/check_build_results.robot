*** Settings ***
Documentation     Verify that all packages has been built successfully
Force Tags        build
Library           build/BuildLogChecker.py    ${BUILDLOG}    build/broken.list

*** Variables ***

*** Test Cases ***
Verify All Packages
    [Documentation]    The packages should build successfully, unless they are known not to build (are not in \ @{BROKEN} list)
    @{packages}    Get Packages
    : FOR    ${package}    IN    @{packages}
    \    Verify Build On All Products    ${package}
    ${EMPTY}

*** Keywords ***
Verify Build On All Products
    [Arguments]    ${package}
    [Documentation]    The packages should not build successfully, if they are known not to build (are in @{BROKEN} list).
    ...
    ...    If they build sucessfully, it meanst that they should be removed from @{BROKEN} list
    @{products}    Get Products
    :FOR    ${product}    IN    @{products}
    \    Check Package Build Build Status    ${package}    ${product}
