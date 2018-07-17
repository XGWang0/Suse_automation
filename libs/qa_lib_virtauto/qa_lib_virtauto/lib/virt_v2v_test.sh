#!/bin/bash
# ****************************************************************************
# Copyright (c) 2016 Unpublished Work of SUSE. All Rights Reserved.
# 
# THIS IS AN UNPUBLISHED WORK OF SUSE.  IT CONTAINS SUSE'S
# CONFIDENTIAL, PROPRIETARY, AND TRADE SECRET INFORMATION.  SUSE
# RESTRICTS THIS WORK TO SUSE EMPLOYEES WHO NEED THE WORK TO PERFORM
# THEIR ASSIGNMENTS AND TO THIRD PARTIES AUTHORIZED BY SUSE IN WRITING.
# THIS WORK IS SUBJECT TO U.S. AND INTERNATIONAL COPYRIGHT LAWS AND
# TREATIES. IT MAY NOT BE USED, COPIED, DISTRIBUTED, DISCLOSED, ADAPTED,
# PERFORMED, DISPLAYED, COLLECTED, COMPILED, OR LINKED WITHOUT SUSE'S
# PRIOR WRITTEN CONSENT. USE OR EXPLOITATION OF THIS WORK WITHOUT
# AUTHORIZATION COULD SUBJECT THE PERPETRATOR TO CRIMINAL AND  CIVIL
# LIABILITY.
# 
# SUSE PROVIDES THE WORK 'AS IS,' WITHOUT ANY EXPRESS OR IMPLIED
# WARRANTY, INCLUDING WITHOUT THE IMPLIED WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT. SUSE, THE
# AUTHORS OF THE WORK, AND THE OWNERS OF COPYRIGHT IN THE WORK ARE NOT
# LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF, OR IN CONNECTION
# WITH THE WORK OR THE USE OR OTHER DEALINGS IN THE WORK.
# ****************************************************************************
#


#=========================================================
#=== Guest machine migration from xen host to kvm host ===
#=========================================================
pushd `dirname $0` >/dev/null

source ./virtlib
source ./vh-update-lib.sh

trap "echo 'Catch CTRL+C'; do_cleanup 1" SIGINT

function usage() {
    echo "Usage: $0 -s migrateSrcIP [-u migrateSrcUser] [-p migrateSrcPass] [-i vmProducts]"
    echo "This script should be executed on the destination of virt-v2v, that is the kvm host."
    echo "-s: migrateSrcIP, the ip address of xen host"
    echo "-i: vmProducts, it is what kind of product vm should be installed, support regular expression, comma separeted,"
    echo "                format: \"sles-11-sp[34]-64,sles-12\""
    echo "                when not configured, all vm types in config file will be installed."
    exit 1
}

while getopts "s:u:p:i:" OPTIONS
do
    case $OPTIONS in
        s)migrateSrcIP="$OPTARG";;
        u)migrateSrcUser="$OPTARG";;
        p)migrateSrcPass="$OPTARG";;
        i)vmProducts="$OPTARG";;
        \?)usage;;
        *) usage;;
    esac
done

if [ -z "$migrateSrcIP" ];then
    usage
fi
    
function do_settings {
    sshNoPass="sshpass -e ssh -o StrictHostKeyChecking=no"
    getSettings="/usr/share/qa/virtautolib/lib/get-settings.sh"
    getSource="/usr/share/qa/virtautolib/lib/get-source.sh"
    
    if [ -z "$migrateSrcUser" ];then
        migrateSrcUser=`$getSettings migratee.user`
    fi
    
    if [ -z "$migrateSrcPass" ];then
        migrateSrcPass=`$getSettings migratee.pass`
    fi
    
    # Export SSHPASS
    export SSHPASS=$migrateSrcPass
    
    backupRootDir=/tmp/virt-v2v/vm_backup
    backupVmListFile=${backupRootDir}/vm.list
    failedVmListFile=${backupRootDir}/install_fail_vm.list
    backupCfgXmlDir=$backupRootDir/vm-config-xmls
    backupDiskDir=$backupRootDir/vm-disk-files
    backupLogDir=$backupRootDir/logs
    
    [ -d $backupRootDir ] && rm -r $backupRootDir
    mkdir -p $backupRootDir
    mkdir -p $backupLogDir
    
    overallMigrateTestRet=400 #the start of tolerable error number start, if overallMigrateTestRet=400, it means 0
    
    waitIntvl=5
    
    #Detect product
    PRODUCT=`/usr/share/qa/tools/product.pl -n|tr '[A-Z]' '[a-z]'|tail -1|sed 's/-[^-]\+$//'`
    #Only For 64 bit
    PRODUCT="${PRODUCT}-64"

}

function kill_procs {
    pattern=$1
    pattern=`echo $pattern | sed 's/^\(.\)/\[\1\]/'`
    procs=`ps -ef | grep -i "$pattern" | gawk "{print \\\$2;}"`
    for proc in $procs;do
        kill -9 $proc
    done
    
}

function do_cleanup {
    #kill ssh-agent procs
    kill_procs ssh-agent

    LOCATION="`/usr/share/qa/tools/location.pl | awk '{ print $NF; }'`"
    /usr/share/qa/qa_test_virtualization/loc/cleanup.$LOCATION
    $sshNoPass $migrateSrcUser@$migrateSrcIP "/usr/share/qa/qa_test_virtualization/loc/cleanup.$LOCATION"
}

function handle_exit() {
    echo -e "\nExecuting handle_exit...\n"
    exit_code=$1
    error_msg=$2

    echo "Error: $error_msg!" >&2
    do_cleanup
    exit $exit_code
}

function check_validation() {
    echo -e "\nExecuting check validation..."
    if uname -r | grep xen >/dev/null || [ -e /proc/xen/privcmd ];then
        handle_exit 1 "You want to test virt-v2v migration, but destination host is not kvm!"
    fi
    $sshNoPass $migrateSrcUser@$migrateSrcIP "uname -r | grep xen || [ -e /proc/xen/privcmd ]" >/dev/null
    if [ $? -ne 0 ];then
        handle_exit 2 "You want to test virt-v2v migration, but source host is not xen!"
    fi
}

function install_virt-v2v-vmdp() {
    echo -e "\nExecuting install_virt-v2v-vmdp...\n"
    virtDevelRepo=`$getSource source.virtdevel.${PRODUCT}`
    kill_procs zypper
    zypper --non-interactive --gpg-auto-import-keys ar $virtDevelRepo virtDevelRepo
    zypper --non-interactive --gpg-auto-import-keys ref virtDevelRepo
    zypper --non-interactive --gpg-auto-import-keys in virt-v2v-vmdp
    if [ $? -ne 0 ];then
        handle_exit 3 "Can not install virt-v2v-vmdp!"
    fi
    return 0
}

function generate_ssh_rsa_key() {
    echo -e "\nExecuting generate_ssh_rsa_key...\n"
    echo 'y' | ssh-keygen -q -t rsa -N '' -f /root/.ssh/id_rsa
    if [ $? -ne 0 ];then
        handle_exit 4 "Can not generate rsa key!"
    fi
    return 0
}

function add_rsa_key_to_other_host() {
    echo -e "\nExecuting add_rsa_key_to_other_host...\n"
    other_host_ip=$1
    cat /root/.ssh/id_rsa.pub |  $sshNoPass $migrateSrcUser@$migrateSrcIP "cat - >> /root/.ssh/authorized_keys"
    if [ $? -ne 0 ];then
        handle_exit 5 "Can not add rsa key to $other_host_ip!"
    fi
    return 0
}

function start_ssh-agent() {
    echo -e "\nExecuting start_ssh-agent...\n"
    eval `ssh-agent`
    if [ $? -ne 0 ];then
        handle_exit 6 "Can not start ssh-agent!"
    fi
    return 0
}

function add_key_to_ssh-add() {
    echo -e "\nExecuting add_key_to_ssh-add...\n"
    ssh-add /root/.ssh/id_rsa
    if [ $? -ne 0 ];then
        handle_exit 7 "Can not add rsa key to ssh-add!"
    fi
    return 0
}

function create_default_storage_pool() {
    echo -e "\nExecuting create_default_storage_pool...\n"
    local backupRootDir=$1

    if virsh pool-list | grep -q default;then
        return 0
    fi

    default_storage_dir=`get_vm_disk_dir`
    default_storage_xml=$backupRootDir/default_pool.xml
    cat > $default_storage_xml <<EOF
<pool type='dir'>
  <name>default</name>
  <uuid>65818f5e-177c-43c9-858c-e6b389d5d8b4</uuid>
  <capacity unit='bytes'>81249030144</capacity>
  <allocation unit='bytes'>2158063616</allocation>
  <available unit='bytes'>79090966528</available>
  <source>
  </source>
  <target>
    <path>$default_storage_dir</path>
    <permissions>
      <mode>0711</mode>
      <owner>0</owner>
      <group>0</group>
    </permissions>
  </target>
</pool>
EOF
    if [ $? -ne 0 ];then
        handle_exit 8 "Can not create default storage pool configuration file: $default_storage_xml!"
    fi
    echo "Debug info: the default pool xml is:"
    cat $default_storage_xml

    virsh pool-create $default_storage_xml
    if [ $? -ne 0 ];then
        handle_exit 9 "Create default storage pool failed!"
    fi
    return 0
}

function stop_firewall() {
    echo -e "\nExecuting stop_firewall...\n"
    if rcSuSEfirewall2 status | grep running >/dev/null; then
        rcSuSEfirewall2 stop
        if [ $? -ne 0 ];then
            echo "Error: Can not shutdown firewall on kvm host." >&2
            handle_exit 10
        fi
    fi
    $sshNoPass $migrateSrcUser@$migrateSrcIP "rcSuSEfirewall2 stop"
    if [ $? -ne 0 ];then
        echo "Error: Can not shutdown firewall on xen host." >&2
        handle_exit 11
    fi
    return 0
}

function start_virtualization_standalone_script {
    bash /usr/share/qa/qa_test_virtualization/shared/standalone
    if [ $? -ne 0 ];then
        echo "Error: Can not start standalone script on kvm host." >&2
        handle_exit 13
    fi
    return 0
}

function do_common_prepare() {
    echo -e "\nExecuting common test preparation...\n"
    stop_firewall
    install_virt-v2v-vmdp
    generate_ssh_rsa_key
    add_rsa_key_to_other_host $migrateSrcIP
    start_ssh-agent
    add_key_to_ssh-add
    create_default_storage_pool
    start_virtualization_standalone_script
}

function validate_mode() {
    echo -e "\nExecuting validate_mode...\n"
    local inputMode=$1
    local outputMode=$2

    #We test the real virt-v2v scenarios that input and output are on two different host
    #For input as libvirt and output as libvirt, it is supported
    #For input as libvirtxml, it can only run on source/xen host, and the output can only be local, 
    #because parameter -oc does not support remote. We will not support this mode now.
    if [ $inputMode == "libvirt" -a $outputMode == "libvirt" ];then
        return 0
    else
        return 1
    fi
}

function validate_scenario() {
    echo -e "\nExecuting validate_scenario...\n"
    local vm=$1
    local scenario=$2

    return 0
#    if [[ $vm == *win* && $scenario == *vmdp* ]];then
#        return 0
#    elif [[ $vm == *sle* && $scenario == *xen-kernel* ]];then
#        vm=${vm/fcs/sp0}
#        vmRls=`echo $vm | cut -d- -f 2`
#    	vmSp=`echo $vm | cut -d- -f 3 | sed 's/sp//'`
#        if [ $vmRls -gt 12 ] || [ $vmRls -eq 12 -a $vmSp -ge 2 ];then
#            if [ "$scenario" == "without-xen-kernel" ];then
#                    return 0
#            else
#                return 1
#            fi
#        else
#            return 0
#        fi
#    else
#        return 1
#    fi
}

function ensure_pkg_status() {
    echo -e "\nExecuting ensure_pkg_status...\n"
    local package=$1
    local status=$2
    local vm=$3

    if [ $status == "installed" ];then
        action="in"
        checkCommands="rpm -qa | grep -q $package"
    else
        action="rm"
        checkCommands="! rpm -qa | grep -q $package"
    fi

    kill_zypper_command="kill_procs zypper"
    if [ -n "$vm" ];then
        kill_zypper_command="$(typeset -f kill_procs);$kill_zypper_command"
    fi

    commands="if ! $checkCommands;then  $kill_zypper_command; zypper --non-interactive --gpg-auto-import-keys $action -t package $package;fi;"
    commands+="$checkCommands"
    echo "Debug info: commands are:"
    echo "$commands"


    if [ -n "$vm" ];then
        $sshNoPass $migrateSrcUser@$migrateSrcIP "cd /usr/share/qa/virtautolib/lib;source virtlib;ensure_vm_running $vm virsh"
        if [ $? -ne 0 ];then
            return 1
        fi
        scriptFile=/tmp/ensure_pkg_status_$status-$vm.$$
        cat > $scriptFile << EOF
        $commands
EOF
        cat $scriptFile | $sshNoPass $migrateSrcUser@$migrateSrcIP "cat - > $scriptFile"
        $sshNoPass $migrateSrcUser@$migrateSrcIP "cd /usr/share/qa/virtautolib/lib;source virtlib; source vh-update-lib.sh; run_script_inside_vm $vm $scriptFile no no"
    else
        eval "$commands"
    fi
    return $?
}

function pre-scenario_prepare() {
    echo -e "\nExecuting  pre-scenario_prepare...\n"
    local vm=$1
    local scenario=$2

    #virt-v2v-vmdp preparation
    if [ $scenario == "with-vmdp" ];then
        ensure_pkg_status virt-v2v-vmdp installed
    elif [ $scenario == "without-vmdp" ];then
        ensure_pkg_status virt-v2v-vmdp uninstalled
    fi
    if [ $? -ne 0 ];then
        return 1
    fi

    #pv guest : install kernel-default
    if [[ $vm == *sle*pv* ]];then
        ensure_pkg_status kernel-default installed $vm
        return $?
    else
        return 0
    fi

}

function get_result_prefix() {
    echo "inputMode:$inputMode, outputMode:$outputMode, scenario:$scenario, guest:$vm"
}

function generate_virt-v2v_command {
    local inputMode=$1
    local outputMode=$2
    local vm=$3

    if [ "$inputMode" == "libvirt" -a "$outputMode" == "libvirt" ];then
        echo "virt-v2v -v -x  $vm -i $inputMode -ic xen+ssh://$migrateSrcUser@$migrateSrcIP -o $outputMode --bridge br123"
    else
        echo "Not supported input/output mode for test."
    fi
}

function do_single_virt-v2v {
    local inputMode=$1
    local outputMode=$2
    local vm=$3
    local logFile=$4

    echo -e "\nExecuting do_single_virt-v2v $inputMode $outputMode $vm $logFile...\n"
    virt_v2v_command=`generate_virt-v2v_command $inputMode $outputMode $vm`
    
    
    ${virt_v2v_command} > $logFile 2>&1
    retCode=$?
    if [ $retCode -ne 0 ];then
        echo "Error: virt-v2v command return non-zero!"
    fi
    return $retCode
    
}

#verfify the migrated vm is listed on the kvm host and can start/shutdown normally
function post_virt-v2v_verify {
    echo -e "\nExecuting  post_virt-v2v_verify...\n"
    local vm=$1
    local scenario=$2
    local logFile=$3

    echo -e "\nExeucting post_virt-v2v_verify on $vm...\n"

    #list on virsh
    virsh list --all
    if ! (virsh list --all | grep -q $vm);then
        return 1
    else
        if ! virsh start $vm;then
            return 1
        else
            virsh dumpxml $vm > $logFile
            if [[ $vm == *win* && $scenario == with-vmdp && $(grep virtio $logFile | wc -l) < 3 ]]; then
                return 1
            elif [[ $vm == *win* && $scenario == without-vmdp && $(grep virtio $logFile | wc -l) > 1 ]]; then
                return 1
            else
                return 0

            fi
        fi
    fi
}

#do necessary cleanup after one virt-v2v test, which will impact next round test
function post-scenario_cleanup {
    echo -e "\nExecuting post-scenario_cleanup...\n"
    local vm=$1

    local intvl=5

    sleep $waitIntvl
    virsh destroy $vm
    sleep $waitIntvl
    virsh undefine $vm
    sleep $waitIntvl
    rm $(get_vm_disk_dir)/* -r

}

function do_virt-v2v-tests() {
    echo -e "\nVirt-v2v test rounds start!!!\n"
    echo -e "\nExecuting do_virt-v2v-tests...\n"
    resultArr=("testcase" "result" "reason")
    resultColumnNum=${#resultArr[@]}

    vmList=`virsh -c xen+ssh://root@${migrateSrcIP} list --all --name | sed '/Domain-0/d'`
    inputModes="libvirt" #libvirtxml: only support local host test
    outputModes="libvirt" #local: only support local host test

    #loop virt-v2v tests
    for inputMode in $inputModes;do
        for outputMode in $outputModes;do
            validate_mode $inputMode $outputMode
            if [ $? -ne 0 ];then
                continue
            fi
            scenarios="with-vmdp without-vmdp"
            for scenario in $scenarios;do
                for vm in $vmList;do
                    validate_scenario $vm $scenario
                    if [ $? -ne 0 ];then
                        continue
                    fi
                    echo -e "\nExecuting virt-v2v test on $vm with inputMode:$inputMode outputMode:$outputMode scenario:$scenario\n"
                    #prepare scenario
                    pre-scenario_prepare $vm $scenario
                    if [ $? -ne 0 ];then
                        store_testcase_result "`get_result_prefix`" "fail" "Prepare $scenario fail!"
                        virsh -c xen+ssh://root@${migrateSrcIP} destroy $vm
                        continue
                    fi

                    #special for windows, virsh shutdown it once to close fast recovery function
                    if [[ $vm == *win* ]];then
                        virsh -c xen+ssh://root@${migrateSrcIP} start $vm
                        sleep 60
                        virsh -c xen+ssh://root@${migrateSrcIP} shutdown $vm
                        sleep 60
                    fi
            
                    #ensure vm is off before virt-v2v
                    echo -e "\nDestroy the guest before doing virt-v2v...\n"
                    virsh -c xen+ssh://root@${migrateSrcIP} destroy $vm 2>/dev/null
                    sleep $waitIntvl
                    if ! virsh -c xen+ssh://root@${migrateSrcIP} list --all | grep -q "$vm\s*shut off";then
                        store_testcase_result "`get_result_prefix`" "fail" "Shutdown forcefully $vm before virt-v12v fail!"
                        continue
                    fi

                    #do one round virt-v2v on $vm
                    logFile=$backupLogDir/virt-v2v.$vm.$scenario.$inputMode.$outputMode.log
                    do_single_virt-v2v $inputMode $outputMode $vm $logFile
                    if [ $? -ne 0 ];then
                        store_testcase_result "`get_result_prefix`" "fail" "VIRT-V2V command returns non-zero!"
                    else
                        #virt-v2v post verify
                        logFile=$backupLogDir/virt-v2v.$vm.$scenario.$inputMode.$outputMode.post-xml-on-kvm
                        post_virt-v2v_verify $vm $scenario $logFile
                        if [ $? -ne 0 ];then
                            store_testcase_result "`get_result_prefix`" "fail" "VIRT-V2V post command verification on kvm fail!"
                        else
                            store_testcase_result "`get_result_prefix`" "pass"
                        fi
                    fi

                    #cleanly remove the guest from kvm host
                    post-scenario_cleanup $vm
                done
            done
        done
    done

}

function get_remote_logs {
    $sshNoPass $migrateSrcUser@$migrateSrcIP "tar cvf /tmp/logs-on-xen.tar -C $(dirname $backupCfgXmlDir) $(basename $backupCfgXmlDir) -C $(dirname $failedVmListFile) $(basename $failedVmListFile) -C /var/log/qa/ ctcs2; gzip -f /tmp/logs-on-xen.tar;" >/dev/null
    scp $migrateSrcUser@$migrateSrcIP:/tmp/logs-on-xen.tar.gz  $backupRootDir
    tar xzvf $backupRootDir/logs-on-xen.tar.gz -C $backupRootDir >/dev/null
    rm $backupRootDir/logs-on-xen.tar.gz
}

function start_virt-v2v_tests() {
    #global settings
    do_settings

    #check test validation for environment
    check_validation
    
    #install vm guests on xen host
    guestCfgFile=/usr/share/qa/virtautolib/data/vm_guest_config_in_virt-v2v
    $sshNoPass $migrateSrcUser@$migrateSrcIP "cd /usr/share/qa/virtautolib/lib;source virtlib; install_vm_guests $guestCfgFile \"$vmProducts\""
    ret=$?
    if [ $ret -ne 0 ];then
        $sshNoPass $migrateSrcUser@$migrateSrcIP "cd /usr/share/qa/virtautolib/lib;source virtlib;handle_installation_failed_guests $failedVmListFile"
        ((overallMigrateTestRet+=$ret))
    fi

    #change the on_crash behavior to coredump
    $sshNoPass $migrateSrcUser@$migrateSrcIP "cd /usr/share/qa/virtautolib/lib;source virtlib;change_vm_on_crash"

    #backup vm data to backup directory
    $sshNoPass $migrateSrcUser@$migrateSrcIP "cd /usr/share/qa/virtautolib/lib;source virtlib;backup_vm_guest_data $backupRootDir $backupVmListFile $backupCfgXmlDir $backupDiskDir"
    if [ $? -ne 0 ];then
        handle_exit 12 "Backup guests failed after guest installation!"
    fi

    #make common preparations for virt-v2v tests
    do_common_prepare

    #main loop for virt-v2v tests
    do_virt-v2v-tests

    #overall migration cleanup
    do_cleanup

    #copy useful logs from ctcs2 and backupdir on source xen host to this kvm host
    get_remote_logs

    #print migration test result
    print_migration_result $resultColumnNum

    #show the failed guests during guest installation phase
    $sshNoPass $migrateSrcUser@$migrateSrcIP "cd /usr/share/qa/virtautolib/lib;source virtlib;show_guest_installation_failures $failedVmListFile"

}

start_virt-v2v_tests

if [ $overallMigrateTestRet -eq 400 ];then
    overallMigrateTestRet=0
fi

exit $overallMigrateTestRet
