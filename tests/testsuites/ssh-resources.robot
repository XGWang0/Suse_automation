*** Variables ***
${CONFIG_FILE}   config.robot

*** Settings ***
Library          SSHLibrary
Resource         ssh-resources.robot
Resource         ${CONFIG_FILE}

*** Keywords ***
Open Connection And Login
    Open Connection  ${HAMSTA_HOST}
    Login   ${ROOT_USER}  ${ROOT_PASSWORD}

Start Hamsta Master Service
    ${rc}            Execute Command    which systemctl    return_stdout=False    return_rc=True
    Run Keyword If   ${rc} == 0    Execute Command    systemctl start hamsta-master.service
    Run Keyword Unless    ${rc} == 0      Execute Command    service hamsta-master start

Stop Hamsta Master Service
    ${rc}            Execute Command    which systemctl    return_stdout=False    return_rc=True
    Run Keyword If   ${rc} == 0    Execute Command    systemctl stop hamsta-master.service
    Run Keyword Unless  ${rc} == 0         Execute Command    service hamsta-master stop

Restart Hamsta Master Service
    ${rc}            Execute Command    which systemctl    return_stdout=False    return_rc=True
    Run Keyword If   ${rc} == 0    Execute Command    systemctl restart hamsta-master.service
    Run Keyword Unless   ${rc} == 0   Execute Command    service hamsta-master restart

Check Hamsta Master Is Active
    [Documentation]  Checks that hamsta-master service is active
    ${rc}            Execute Command    which systemctl    return_stdout=False    return_rc=True
    Run Keyword If   ${rc} == 0    Check Hamsta Master Is Active Systemd
    Run Keyword Unless   ${rc} == 0   Check Hamsta Master Is Active Sysv

Check Hamsta Master Is Active Sysv
    ${output}               Execute Command    service hamsta-master status
    Should Contain          ${output}    running

Check Hamsta Master Is Active Systemd
    ${rc}            Execute Command    systemctl is-active hamsta-master.service  return_stdout=False  return_rc=True
    Should Be Equal As Integers    ${rc}    0

Check Hamsta Master Is Not Active Sysv
    ${output}               Execute Command    service hamsta-master status
    Should Contain          ${output}    unused

Check Hamsta Master Is Not Active Systemd
    ${rc}            Execute Command    systemctl is-active hamsta-master.service  return_stdout=False    return_rc=True
    Should Not Be Equal As Integers    ${rc}    0

Check Hamsta Master Is Not Active
    [Documentation]  Checks that hamsta-master service is not active
    ${rc}            Execute Command    which systemctl    return_stdout=False    return_rc=True
    Run Keyword If   ${rc} == 0    Check Hamsta Master Is Not Active Systemd
    Run Keyword Unless   ${rc} == 0    Check Hamsta Master Is Not Active Sysv
