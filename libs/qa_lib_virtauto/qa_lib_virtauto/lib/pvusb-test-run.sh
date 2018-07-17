function test_usbctrl-attach_command() {
    local vm=$1
    local version=$2
    local ports=$3
    echo -e "\nExecuting xl usbctrl-attach $vm version=$version ports=$ports\n"
    #execute command
    xl usbctrl-attach $vm version=$version ports=$ports
    if [ $? -ne 0 ];then
        echo "Create usb controller command line return non-zero."
        return 1
    fi
    #check output
    result=`xl usb-list $vm`
    echo "$result"
    outputVersion=`echo "$result" | sed -n '2p' | gawk '{print $5;}'`
    outputPorts=`echo "$result" | sed -n '2p' | gawk '{print $6;}'`
    if [ $outputVersion -eq $version ] && [ $outputPorts -eq $ports ] &&  [[ "$result" =~ Port[[:blank:]]*$ports:$ ]];then
        echo "The created usb controller is correct."
        return 0
    else
        echo "The created usb controller is wrong."
        return 1
    fi
}

function test_usbdev-attach_command() {
    local vm=$1
    local busID=$2
    local devID=$3
    echo -e "\nExecuting xl usbdev-attach $vm hostbus=$busID hostaddr=$devID\n"
    
    # global portIDofUSBController and devIDofUSBController

    #do the usbdev-attach
    xl usbdev-attach $vm hostbus=$busID hostaddr=$devID
    local ret=$?
    #check the attach result
    if [ $ret -eq 0 ];then
        result=`xl usb-list $vm`
        echo "$result"
        if echo $result | grep -q "Bus $busID Device $devID";then
            echo "Attach usb device is successful."
            #get the port id on attached controller
            if [[ $result =~ [[:blank:]]*Port[[:blank:]]*([0-9]*):[[:blank:]]*Bus[[:blank:]]*$busID[[:blank:]]*Device[[:blank:]]*$devID* ]];then
                portIDofUSBController=${BASH_REMATCH[1]}
            fi
            #get the dev id of the attached controller
            devIDofUSBController=`echo "$result" | sed -n "/Devid/{n;h};/Bus $busID Device $devID/{x;p;q}" | gawk '{print $1;}'`
            #print result
            echo "The usb device is attached to controller $devIDofUSBController port $portIDofUSBController !"
            return 0
        
        else
            echo "Attach usb device failed."
            return 1
        fi
    else
        echo "Attach usb device command line return non-zero."
        return $ret
    fi
}

function test_usbdev-detach_command() {
    local vm=$1
    local controllerDeviceID=$2
    local controllerPortID=$3
    local usbDeviceBusID=$4
    local usbDeviceDevID=$5
    echo -e "\nExecuting xl usbdev-detach $vm $controllerDeviceID $controllerPortID\n"
    
    #execute command
    xl usbdev-detach $vm $controllerDeviceID $controllerPortID
    if [ $? -ne 0 ];then
        echo "Detach usb device command line return non-zero!"
        return 1
    else
        result=`xl usb-list $vm`
        echo "$result"
        if echo $result | grep -q "Bus $usbDeviceBusID Device $usbDeviceDevID";then
            echo "Detach usb device failed!"
            return 1
        else
            echo "Detach usb device is successful! "
            return 0
        fi
    fi
    
}

pushd `dirname ./` >/dev/null

# get config
WHICH_USB=$1
if [ -z "$WHICH_USB" ];then
    WHICH_USB="Optical Wheel Mouse"
fi
#get the bus id and dev id of the usb device you want to attach to guest
echo "Debug info: all usb devices on host are:"
lsusb

busID=`lsusb | grep "$WHICH_USB" | grep -Eo "[0-9]+" | sed -n "1p"`
devID=`lsusb | grep "$WHICH_USB" | grep -Eo "[0-9]+" | sed -n "2p"`
if [ -z "$busID" -o -z "$devID" ];then
    echo "Error: there is no usb device with key word: $WHICH_USB! Skip test!"
    exit 1
fi

echo -e "\nThe USB device to passthrough to guest is: busID $busID, devID $devID.\n"

# add qa repo
echo -e "\nExecuting install qa repo on host...\n"
zypper --non-interactive  --no-gpg-checks ar http://dist.nue.suse.com/ibs/QA:/Head/SLE-12-SP2/ qa-auto
zypper --non-interactive  --no-gpg-checks ref qa-auto
zypper --non-interactive  --no-gpg-checks in qa_lib_virtauto

cd /usr/share/qa/virtautolib/lib
source ./virtlib
source ./vh-update-lib.sh

#set up config for test
vm="sles-12-sp2-64-pv-def-net"
backupRootDir=/tmp/pvusb/vm_backup
backupVmListFile=${backupRootDir}/vm.list
backupFailedVmListFile=${backupRootDir}/install-fail-vm.list
backupCfgXmlDir=$backupRootDir/vm-config-xmls
backupDiskDir=$backupRootDir/vm-disk-files
exitCode=0
devIDofUSBController=0
portIDofUSBController=0
testInterval=3

if [ -d $backupCfgXmlDir ];then
    rm -r $backupCfgXmlDir
fi
mkdir -p $backupCfgXmlDir
mkdir -p $backupDiskDir

#install sles12sp2 guest
echo -e "\nExecuting install guest...\n"
install_vm_guests '' "$vm"
ret=$?
if [ $ret -ne 0 ];then
    echo "Install guest failed!"
    handle_installation_failed_guests $backupFailedVmListFile
fi
((exitCode+=$ret))

#backup guests
backup_vm_guest_data $backupRootDir $backupVmListFile $backupCfgXmlDir $backupDiskDir
if [ $? -ne 0 ];then
    echo "Backup guest failed!"
    return 2
fi

#start guest
virsh start $vm
sleep 60

############################# Test pvusb start!!!! ###################################
#####################xl tool test#####################3
echo -e "\n###############Starting xl attach/detach usb test for usb passthrough#############\n"
#create the first usb controller
test_usbctrl-attach_command $vm 2 16
((exitCode+=$?))
sleep $testInterval

#attach usb device
#do the attach
test_usbdev-attach_command $vm $busID $devID
((exitCode+=$?))
sleep $testInterval

#verify device is listed in guest
commands="
result=\`lsusb\`
if echo \$result | grep \"$WHICH_USB\";then
    exit 0
else
    exit 1
fi
"
echo "$commands" > /tmp/verify-usb-on-guest-$$.sh
echo "Debug: /tmp/verify-usb-on-guest-$$.sh content is:"
cat /tmp/verify-usb-on-guest-$$.sh

run_script_inside_vm $vm /tmp/verify-usb-on-guest-$$.sh no no
ret=$?
if [ $ret -ne 0 ];then
    echo "Error: The attached usb is not listed on guest."
    ((exitCode+=$ret))
else
    echo "The attached usb is listed on guest."
fi

sleep $testInterval

#detach usb device
test_usbdev-detach_command $vm $devIDofUSBController $portIDofUSBController $busID $devID
((exitCode+=$?))
sleep $testInterval

#detach usb controller
echo -e "\nExecuting xl usbctrl-detach $vm $devIDofUSBController\n"
xl usbctrl-detach $vm $devIDofUSBController
ret=$?
((exitCode+=$ret))
if [ $ret -ne 0 -o -n "$(xl usb-list $vm)" ];then
    echo "Detach usb controller failed!"
    ((exitCode+=$ret))
else
    echo "Detach usb controller is successful!"

fi
sleep $testInterval

#Verify guest is still alive
sleep 3
commands="echo $vm is alive."
echo "$commands" > /tmp/verify-guest-alive-$$.sh
echo "Debug: /tmp/verify-guest-alive-$$.sh content is:"
cat /tmp/verify-guest-alive-$$.sh

run_script_inside_vm $vm /tmp/verify-guest-alive-$$.sh no no
ret=$?
((exitCode+=$ret))

sleep $testInterval


#recover guest
virsh destroy $vm
sleep $testInterval

#xl creation check
echo -e "\n###############Starting xl create xl-with-usb.config test for passthrough#############\n"
devIDofUSBController=1
portIDofUSBController=8

usbXL="
usbctrl=['version=2,ports=32', 'version=1, ports=8', ]
usbdev=['hostbus=$busID, hostaddr=$devID, controller=$devIDofUSBController,port=$portIDofUSBController', ] 
"
guestXML=${backupCfgXmlDir}/${vm}.xml
guestXLwithUSB=${backupCfgXmlDir}/${vm}-with-usb.xl
virsh dumpxml $vm > $guestXML
virsh domxml-to-native xen-xl $guestXML >> ${backupCfgXmlDir}/${vm}.xl
cp ${backupCfgXmlDir}/${vm}.xl $guestXLwithUSB
echo "$usbXL" >> $guestXLwithUSB
sed -i '/^$/d' $guestXLwithUSB
echo "Debug info: xl config file $guestXLwithUSB content is:"
cat $guestXLwithUSB

echo -e "\nExecuting command: xl create $guestXLwithUSB...\n"
xl create $guestXLwithUSB
if [ $? -ne 0 ];then
    echo "Create guest with passthrough usb using 'xl create' failed, command line return non-zero!"
    ((exitCode+=1))
else
    if ! (xl list | grep -q $vm);then
        echo  "Create guest with passthrough usb using 'xl create' failed, command line return 0, but guest is not listed in xl list."
        ((exitCode+=1))
    else
        #verify by xl usb-list
        echo -e "\nExecuting command: xl usb-list $vm...\n"
        output=`xl usb-list $vm`
        echo "$output"
        if echo "$output" | grep -q "Port $portIDofUSBController: Bus $busID Device $devID";then
            echo "Create guest with passthrough via 'xl create' is successful!"
        else
            echo "Create guest with passthrough usb using 'xl create' failed, command line return 0, but 'xl usb-list' is wrong!"
            ((exitCode+=1))
        fi
    fi
fi

sleep $testInterval

#recover guest
xl destroy $vm
sleep $testInterval

###########################libvirt stack test#################
echo -e "\n###############Starting libvirt(virsh) test for usb passthrough#############\n"

#verify virsh define xml-with-usb-device
usbXML=${backupCfgXmlDir}/${vm}-usb.xml
USBPart="    <hostdev mode='subsystem' type='usb'>
    <source startupPolicy='optional'>
    <address bus=\"$busID\" device=\"$devID\"/>
    </source>
    </hostdev>"
echo "$USBPart" > $usbXML
echo "Debug info: usb xml $usbXML content is"
cat $usbXML

guestXML=${backupCfgXmlDir}/${vm}.xml
guestXMLwithUSB=${backupCfgXmlDir}/${vm}-with-usb.xml
virsh dumpxml $vm > $guestXML
cp $guestXML $guestXMLwithUSB
sed -i "/<devices>/r $usbXML" $guestXMLwithUSB
echo "Debug: the guestXMLwithUSB is:"
cat $guestXMLwithUSB

#undefine the guest from virsh
virsh undefine $vm
sleep $testInterval

#verify virsh define/create with xml with usb
echo -e "\nExecuting command: virsh define $guestXMLwithUSB \n"
virsh define $guestXMLwithUSB
((exitCode+=$?))
echo -e "\nExecuting command: virsh create $guestXMLwithUSB\n"
virsh create $guestXMLwithUSB
if [ $? -ne 0 ];then
    echo "Create guest with usb device directly via virsh failed! Command line return non-zero!"
    ((exitCode+=1))
else
    #verify by xl usb-list
    echo -e "\nExecuting command: xl usb-list $vm...\n"
    output=`xl usb-list $vm`
    echo "$output"
    if echo "$output" | grep -q "Bus $busID Device $devID";then
        echo "Create guest with usb device directly via virsh is successful!"
    else
        echo "Create guest with usb device directly via virsh failed, command line return 0, but 'xl usb-list' is wrong!"
        ((exitCode+=1))
    fi
fi

sleep $testInterval

#recover guest
virsh destroy $vm
virsh undefine $vm
virsh define $guestXML


#start vm with virsh tool
virsh start $vm
sleep 60


#verify virsh attach-device
echo -e "\nExecuting command: virsh attach-device $vm $usbXML\n"
virsh attach-device $vm $usbXML
if [ $? -ne 0 ];then
    echo "Attach usb device to $vm via 'virsh attach-device' failed! Command line return non-zero!"
    ((exitCode+=1))
else
    #verify by xl usb-list
    echo -e "\nExecuting command: xl usb-list $vm...\n"
    output=`xl usb-list $vm`
    echo "$output"
    if echo "$output" | grep -q "Bus $busID Device $devID";then
        echo "Attach usb device to $vm via 'virsh attach-device' is successful!"
    else
        echo "Attach usb device to $vm via 'virsh attach-device' failed, command line return 0, but 'xl usb-list' is wrong!"
        ((exitCode+=1))
    fi
fi
sleep $testInterval

#verify virsh detach-device
echo -e "\nExecuting command: virsh detach-device $vm $usbXML\n"
virsh detach-device $vm $usbXML
if [ $? -ne 0 ];then
    echo "Detach usb device from $vm via 'virsh detach-device' failed! Command line return non-zero!"
    ((exitCode+=1))
else
    #verify by xl usb-list
    echo -e "\nExecuting command: xl usb-list $vm...\n"
    output=`xl usb-list $vm`
    echo "$output"
    if echo "$output" | grep -q "Bus $busID Device $devID";then
        echo "Detach usb device from $vm via 'virsh detach-device' failed, command line return 0, but 'xl usb-list' is wrong!"
        ((exitCode+=1))
    else
        echo "Detach usb device from $vm via 'virsh detach-device' is successful!"
    fi
fi
sleep 90

#recover guest
virsh destroy $vm
virsh undefine $vm
virsh define $guestXML

########################Final test result show################
echo -e "\n###################Final Result###############\n"
#print the failed guests during guest installation
show_guest_installation_failures $backupFailedVmListFile

popd >/dev/null

if [ $exitCode -eq 0 ];then
    echo -e "\nCongratulations! All test is successful!\n"
else
    echo -e "\nTest failed! Please check details for further reason!\n"
fi

exit $exitCode
