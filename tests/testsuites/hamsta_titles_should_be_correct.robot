*** Settings ***
Documentation	 Verify that all page titles are correct
Resource         web-resources.robot
Suite Setup      Open Browser      ${BASE_URL}
Suite Teardown   Close Browser
Force Tags	 hamsta web

*** Variables ***

*** Test Cases ***
Machines Page Title
	[Documentation]    Testing Selenium 2 Web Driver
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
