#!/bin/bash

function get_grub_version {
 cat > $1 <<EOF
#!/bin/bash
dd if=$GUEST_ROOT_DEV bs=446 count=1 of=$GUEST_BOOT_SECTOR
bytes80_to_81=\`hexdump -v -n 2 -s 0x80 -e '4/1 "%02x"' $GUEST_BOOT_SECTOR \`
rm -rf $GUEST_BOOT_SECTOR
if [ \$bytes80_to_81 == "48b4" -o \$bytes80_to_81 == "7c3c" -o \$bytes80_to_81 == "0020" ];then
  echo 2
else
  echo 1
fi
EOF
sleep 10
sshpass -p $GUEST_PASSWORD ssh $SSH_OPTS -p $GUEST_SSHD_PORT $GUEST_USERNAME@$GUEST_IP "[ ! -d `dirname $1` ] && mkdir -p `dirname $1`" >/dev/null 2>&1
sleep 10
sshpass -p $GUEST_PASSWORD scp $SSH_OPTS -P $GUEST_SSHD_PORT $1 $GUEST_USERNAME@$GUEST_IP:$1 >/dev/null 2>&1
sleep 10
sshpass -p $GUEST_PASSWORD ssh $SSH_OPTS -p $GUEST_SSHD_PORT $GUEST_USERNAME@$GUEST_IP "chmod u+x $1 && $1"
if [ $? != "0" ];then
  echo Failed to get guest grub version.
  cleanup_and_exit 40
fi
}

function install_sshpass() {
 if ! which sshpass >/dev/null 2>&1;then
   zypper --non-interactive --gpg-auto-import-keys in --no-recommends sshpass >/dev/null 2>&1
   if [ $? != "0" ];then
     echo sshpass installing error.
     exit 60
   fi
 fi
}

function generate_mac_addr {
 # generate_mac_addr borrowed from pheldens @ qemu forum
 echo $(echo -n de:ad:be:ef ; for i in `seq 1 2` ;
 do echo -n `echo ":$RANDOM$RANDOM" | cut -n -c -3` ;done)
}

function cold_add_nic {
 virsh attach-interface $GUEST_NAME bridge $BRIDGE --mac $GUEST_IF_MAC --script /etc/xen/scripts/vif-bridge --config
 if [ $? != "0" ];then
   echo Failed to add nic.
   cleanup_and_exit 36
 fi
}

function get_nic_info {
 if virsh domiflist $GUEST_NAME | awk -v rs=1 'NR >= 3 && /bridge/ {rs=0} END {exit rs}';then
   nic_info=(`virsh domiflist $GUEST_NAME | awk 'NR >= 3 && $2=="bridge" {print $3,$5}'`)
   GUEST_IF_SRC_DEV=${nic_info[0]}
   GUEST_IF_MAC=${nic_info[1]}
 fi
}

function get_guest_ip {
 get_nic_info
 if [ "$GUEST_BOOTPROTO" != "dhcp" ];then
   if [ -z $GUEST_IF_MAC ];then
     echo No nic found. If adding a nic to a guest which ip policy is statically assigned ip, The nic cannot get ip before user assigns one explicitly.
     cleanup_and_exit 14
   fi
   if [ "$GUEST_STATE" == "shut off" ] ; then
     virsh start $GUEST_NAME >/dev/null 2>&1
     if [ $? != "0" ];then
       echo Failed to start the guest.
       cleanup_and_exit 11
     fi
   fi
   while true ; do
     if [ "`virsh domstate $GUEST_NAME`" == "idle" ] ; then
       break
     fi
   done
   sleep 60 # Waiting guest in static ip mode.
   ip neigh flush dev $GUEST_IF_SRC_DEV #Clear arp cache.
   bridge_ip=`ifconfig2ip ip $GUEST_IF_SRC_DEV`
   echo Start guest ip detection. `date`
   for ip in $(seq 1 254); do #Assume the subnet mask is 255.255.255.0, This thing takes time if there are too many ip in a subnet.
     ping -c 1 $net_id.$ip>/dev/null
   done
   GUEST_IP=`arp -a | awk -v IGNORECASE=1 "/${GUEST_IF_MAC}/ { gsub(/\(|\)/, \"\"); print \$2; }"`
   echo Finish detection.         `date`
   if [ -z $GUEST_IP ];then
     echo Not found guest ip.
     cleanup_and_exit 13
   fi
   echo Found GUEST_IP $GUEST_IP in static mode.
 else
   if [ "$GUEST_STATE" != "shut off" ] ; then #shutdown the guest, so we can get ip through capturing the dhcp reply packet during the guest start.
     virsh shutdown $GUEST_NAME >/dev/null 2>&1
     if [ $? != "0" ];then
       echo Failed to shutdown the guest.
       cleanup_and_exit 9
     fi
   fi
   while true ; do
     if [ "`virsh domstate $GUEST_NAME`" == "shut off" ] ; then
       break
     fi
   done
   if ! which tcpdump >/dev/null 2>&1;then
     REPO_PATH=`gen_http_repo_path /tmp/repo_path.sh host`
     zypper ar $REPO_PATH $REPO_NAME >/dev/null 2>&1
     zypper --non-interactive in --no-recommends tcpdump >/dev/null 2>&1
     if [ $? != "0" ];then
       echo Failed to install tcpdump in host.
       cleanup_and_exit 10
     fi
   fi
   if [ -z $GUEST_IF_MAC ];then
     GUEST_IF_SRC_DEV=$BRIDGE
     GUEST_IF_MAC=`generate_mac_addr`
     cold_add_nic
   fi
   virsh start $GUEST_NAME >/dev/null 2>&1
   if [ $? != "0" ];then
     echo Failed to start the guest.
     cleanup_and_exit 11
   fi
   echo capturing $GUEST_IF_MAC through $GUEST_IF_SRC_DEV......
   timeout $TCPDUMP_TIMEOUT tcpdump -n -i $GUEST_IF_SRC_DEV arp and ether src $GUEST_IF_MAC -c 5 > /tmp/tmp_packets #Assume no ip collision.
   if [ "$?" == "124" ];then
     echo TCPDUMP_TIMEOUT!
     cleanup_and_exit 12
   fi
##   ip_mac=(`awk 'NR==6 {print $4,$6}' /tmp/tmp_packets`) packet 6 is dhcp reply, But not found this packet sometimes, So can't rely on it.
##   if [ ${ip_mac[1]} == $GUEST_IF_MAC ];then
   ip_mac=(`awk 'NR==5 {print $4,$5}' /tmp/tmp_packets`)
   ip_mac[1]=`echo ${ip_mac[1]} | sed 's/.*(//g;s/).*//g'`
   if [ ${ip_mac[1]} == $GUEST_IF_MAC ];then
     GUEST_IP=${ip_mac[0]}
     echo Found GUEST_IP $GUEST_IP in dhcp mode.
   else
     echo Not found guest ip
     cleanup_and_exit 13
   fi
 fi
}

function get_kvm_guest_ip {
 CLEAR_STAGE3="1"
 if [ "$GUEST_BOOTPROTO" != "dhcp" ];then
   GUEST_STATE=`sshpass -p $KVM_HOST_PASSWORD ssh $SSH_OPTS -p $KVM_HOST_SSHD_PORT $KVM_HOST_USERNAME@$KVM_HOST_IP "virsh domstate v2v-$GUEST_NAME"`
   if [ "$GUEST_STATE" == "shut off" ] ; then
     sshpass -p $KVM_HOST_PASSWORD ssh $SSH_OPTS -p $KVM_HOST_SSHD_PORT $KVM_HOST_USERNAME@$KVM_HOST_IP "virsh start v2v-$GUEST_NAME"
     if [ $? != "0" ];then
       echo Failed to start the kvm guest.
       cleanup_and_exit 33
     fi
     sleep 60 #Waiting guest start in static ip mode.
   fi
   sshpass -p $KVM_HOST_PASSWORD ssh $SSH_OPTS -p $KVM_HOST_SSHD_PORT $KVM_HOST_USERNAME@$KVM_HOST_IP "ip neigh flush dev $KVM_HOST_BRIDGE" >/dev/null 2>&1
   bridge_ip=$KVM_HOST_IP
   net_id=${bridge_ip%.*}
   echo Start kvm guest ip detection.   `date`
   sshpass -p $KVM_HOST_PASSWORD ssh $SSH_OPTS -p $KVM_HOST_SSHD_PORT $KVM_HOST_USERNAME@$KVM_HOST_IP "for ip in \$(seq 1 254); do ping -c 1 $net_id.\$ip >/dev/null; done"
   GUEST_IP=`sshpass -p $KVM_HOST_PASSWORD ssh $SSH_OPTS -p $KVM_HOST_SSHD_PORT $KVM_HOST_USERNAME@$KVM_HOST_IP "arp -a | awk -v IGNORECASE=1 \"/${GUEST_IF_MAC}/ { gsub(/\(|\)/, \\\\\"\\\\\"); print \\\\\\$2; }\""`
   echo Finish kvm guest ip detection.  `date`
   if [ -z $GUEST_IP ];then
     echo Not found kvm guest ip.
     cleanup_and_exit 34
   fi
   echo Found kvm GUEST_IP $GUEST_IP in static mode.
 else
   sshpass -p $KVM_HOST_PASSWORD ssh $SSH_OPTS -p $KVM_HOST_SSHD_PORT $KVM_HOST_USERNAME@$KVM_HOST_IP "which tcpdump">/dev/nul 2>&1
   if [ $? != "0" ];then
     echo Not found tcpdump on kvm host, Add repo and install now.
     REPO_PATH=`gen_http_repo_path /tmp/repo_path.sh kvmhost`
     sshpass -p $KVM_HOST_PASSWORD ssh $SSH_OPTS -p $KVM_HOST_SSHD_PORT $KVM_HOST_USERNAME@$KVM_HOST_IP "zypper ar $REPO_PATH $REPO_NAME ; zypper --non-interactive in --no-recommends tcpdump" >/dev/null 2>&1
     if [ $? != "0" ];then
       echo Failed to install tcpdump in kvm host.
       cleanup_and_exit 31
     fi
   fi
   sshpass -p $KVM_HOST_PASSWORD ssh $SSH_OPTS -p $KVM_HOST_SSHD_PORT $KVM_HOST_USERNAME@$KVM_HOST_IP "virsh start v2v-$GUEST_NAME ; timeout $TCPDUMP_TIMEOUT tcpdump -n -i $KVM_HOST_BRIDGE arp and ether src $GUEST_IF_MAC -c 4 > /tmp/tmp_packets" #Assume no ip collision.
   if [ "$?" == "124" ];then
     echo TCPDUMP_TIMEOUT!
     cleanup_and_exit 32
   fi
   packet_info=`sshpass -p $KVM_HOST_PASSWORD ssh $SSH_OPTS -p $KVM_HOST_SSHD_PORT $KVM_HOST_USERNAME@$KVM_HOST_IP "sed -n 4p /tmp/tmp_packets"`
   ip_mac=(`echo $packet_info | awk '{print $4,$5}'`)
   ip_mac[1]=`echo ${ip_mac[1]} | sed 's/.*(//g;s/).*//g'`
#   if [ ${ip_mac[1]} == $GUEST_IF_MAC ];then
     GUEST_IP=${ip_mac[0]}
     echo Found kvm GUEST_IP $GUEST_IP in dhcp mode.
#   else
#     echo Not found kvm guest ip.
#     cleanup_and_exit X
#   fi
 fi
}

function gen_http_repo_path {
repo_host=147.2.207.240
 cat > $1 <<EOF
#!/bin/bash
if grep -q Desktop /etc/SuSE-release;then
 product_name=sled
else
 product_name=sles
fi
rel_num=\`awk '/VERSION/ {print \$3}' /etc/SuSE-release\`
sp_num=\`awk '/PATCHLEVEL/ {print \$3}' /etc/SuSE-release\`
if [ \$sp_num != "0" ];then
 ver_info=\$rel_num-sp\$sp_num
else
 ver_info=\$rel_num
fi
if [ \`getconf LONG_BIT\` == "32" ];then
 arch=i586
else
 arch=x86_64
fi
repo_url=http://$repo_host/repo/\$product_name-\$ver_info-\$arch/
echo \$repo_url
EOF
 if [ "$2" == "kvmhost" ];then
   sshpass -p $KVM_HOST_PASSWORD ssh $SSH_OPTS -p $KVM_HOST_SSHD_PORT $KVM_HOST_USERNAME@$KVM_HOST_IP "[ ! -d `dirname $1` ] && mkdir -p `dirname $1`" >/dev/null 2>&1
   sshpass -p $KVM_HOST_PASSWORD scp $SSH_OPTS -P $KVM_HOST_SSHD_PORT $1 $KVM_HOST_USERNAME@$KVM_HOST_IP:$1 >/dev/null 2>&1
   sshpass -p $KVM_HOST_PASSWORD ssh $SSH_OPTS -p $KVM_HOST_SSHD_PORT $KVM_HOST_USERNAME@$KVM_HOST_IP "chmod u+x $1 && $1"
   if [ $? != "0" ];then
     echo Failed to generate repo path in kvm host.
     cleanup_and_exit 15
   fi
 elif [ "$2" != "host" ];then
   sleep 10
   sshpass -p $GUEST_PASSWORD ssh $SSH_OPTS -p $GUEST_SSHD_PORT $GUEST_USERNAME@$GUEST_IP "[ ! -d `dirname $1` ] && mkdir -p `dirname $1`" >/dev/null 2>&1
   sleep 10
   sshpass -p $GUEST_PASSWORD scp $SSH_OPTS -P $GUEST_SSHD_PORT $1 $GUEST_USERNAME@$GUEST_IP:$1 >/dev/null 2>&1
   sleep 10
   sshpass -p $GUEST_PASSWORD ssh $SSH_OPTS -p $GUEST_SSHD_PORT $GUEST_USERNAME@$GUEST_IP "chmod u+x $1 && $1"
   if [ $? != "0" ];then
     echo Failed to generate repo path in guest.
     cleanup_and_exit 16
   fi
 else
   chmod u+x $1 && $1
   if [ $? != "0" ];then
     echo Failed to generate repo path in host.
     cleanup_and_exit 17
   fi
 fi
 rm -rf $1
}

function gen_sdk_http_repo_path {
repo_host=147.2.207.240
 cat > $1 <<EOF
#!/bin/bash
if grep -q Desktop /etc/SuSE-release;then
 product_name=sled
else
 product_name=sle
fi
rel_num=\`awk '/VERSION/ {print \$3}' /etc/SuSE-release\`
sp_num=\`awk '/PATCHLEVEL/ {print \$3}' /etc/SuSE-release\`
if [ \$sp_num != "0" ];then
 ver_info=-\$rel_num-sp\$sp_num
else
 ver_info=\$rel_num
fi
if [ \`getconf LONG_BIT\` == "32" ];then
 arch=i586
else
 arch=x86_64
fi
repo_url=http://$repo_host/repo/\$product_name\$ver_info-sdk-\$arch-dvd1/
echo \$repo_url
EOF
 if [ "$2" == "kvmhost" ];then
   sshpass -p $KVM_HOST_PASSWORD ssh $SSH_OPTS -p $KVM_HOST_SSHD_PORT $KVM_HOST_USERNAME@$KVM_HOST_IP "[ ! -d `dirname $1` ] && mkdir -p `dirname $1`" >/dev/null 2>&1
   sshpass -p $KVM_HOST_PASSWORD scp $SSH_OPTS -P $KVM_HOST_SSHD_PORT $1 $KVM_HOST_USERNAME@$KVM_HOST_IP:$1 >/dev/null 2>&1
   sshpass -p $KVM_HOST_PASSWORD ssh $SSH_OPTS -p $KVM_HOST_SSHD_PORT $KVM_HOST_USERNAME@$KVM_HOST_IP "chmod u+x $1 && $1"
   if [ $? != "0" ];then
     echo Failed to generate sdk repo path in kvm host.
     cleanup_and_exit 37
   fi
 elif [ "$2" != "host" ];then
   sleep 10
   sshpass -p $GUEST_PASSWORD ssh $SSH_OPTS -p $GUEST_SSHD_PORT $GUEST_USERNAME@$GUEST_IP "[ ! -d `dirname $1` ] && mkdir -p `dirname $1`" >/dev/null 2>&1
   sleep 10
   sshpass -p $GUEST_PASSWORD scp $SSH_OPTS -P $GUEST_SSHD_PORT $1 $GUEST_USERNAME@$GUEST_IP:$1 >/dev/null 2>&1
   sleep 10
   sshpass -p $GUEST_PASSWORD ssh $SSH_OPTS -p $GUEST_SSHD_PORT $GUEST_USERNAME@$GUEST_IP "chmod u+x $1 && $1" >/dev/null 2>&1
   if [ $? != "0" ];then
     echo Failed to generate sdk repo path in guest.
     cleanup_and_exit 38
   fi
 else
   chmod u+x $1 && $1
   if [ $? != "0" ];then
     echo Failed to generate sdk repo path in host.
     cleanup_and_exit 39
   fi
 fi
 rm -rf $1
}

function devname2uuid_in_guest {
 cat > $1 <<EOF
#!/bin/bash
for i in \`awk '/$GUEST_DEV_NAME/ {print \$1}' /etc/fstab\` ; do
  PARTITION_BY_NAME=\$i
  partition_by_name=\`echo \$PARTITION_BY_NAME | sed 's#\/#\\\\\/#g' | sed 's#\*#\\\\\*#g'\`
  PARTITION_BY_UUID=/dev/disk/by-uuid/\`blkid -s UUID | awk -F\" "/\$partition_by_name/ {print \\\\\$2}"\`
  partition_by_uuid=\`echo \$PARTITION_BY_UUID | sed 's#\/#\\\\\/#g' | sed 's#\*#\\\\\*#g'\`
  sed -i s/\$partition_by_name/\$partition_by_uuid/ /etc/fstab
  if [ "$GUEST_GRUB_VER" == "1" ];then
    sed -i s/\$partition_by_name/\$partition_by_uuid/ $DEVICE_MAP_PATH/menu.lst
  else
    sed -i s/\$partition_by_name/\$partition_by_uuid/ /etc/default/grub
    grub2-mkconfig -o $DEVICE_MAP_PATH/grub.cfg
  fi
done
EOF
 sleep 10
 sshpass -p $GUEST_PASSWORD ssh $SSH_OPTS -p $GUEST_SSHD_PORT $GUEST_USERNAME@$GUEST_IP "[ ! -d `dirname $1` ] && mkdir -p `dirname $1`">/dev/null 2>&1
 sleep 10
 sshpass -p $GUEST_PASSWORD scp $SSH_OPTS -P $GUEST_SSHD_PORT $1 $GUEST_USERNAME@$GUEST_IP:$1 >/dev/null 2>&1
 sleep 10
 sshpass -p $GUEST_PASSWORD ssh $SSH_OPTS -p $GUEST_SSHD_PORT $GUEST_USERNAME@$GUEST_IP "chmod u+x $1 && $1" >/dev/null 2>&1
 if [ $? != "0" ];then
   echo Failed to convert dev name to uuid in guest.
   cleanup_and_exit 18
 fi
 rm -rf $1
}

function is_linux_guest {
 qemu-nbd -c $NBD_DEV $GUEST_BACKEND_NAME
 if [ $? != "0" ];then
   echo Failed to perform qemu-nbd.
   cleanup_and_exit 28
 fi
 declare -i start_pos=`fdisk -l $NBD_DEV | sed -n -e '/Device Boot/='`+1
 partition_type=`fdisk -l /dev/nbd0 | awk -v start_pos=$start_pos 'NR >= start_pos && NR<=FNR && $2=="*" {print $6}'`
 qemu-nbd -d $NBD_DEV >/dev/null 2>&1
 for linux_partition in $LINUX_PARTITION_TYPE_LIST;do
  if [ $partition_type == $linux_partition ] ;then
    KVM_GUEST_NIC_MODEL_TYPE="<model type='virtio'/>"
    return 0
  fi
 done
 return 1
}

function install_nbd {
 if ! which nbd-server >/dev/null 2>&1;then
   zypper --non-interactive --gpg-auto-import-keys in -l --no-recommends nbd >/dev/null 2>&1
   if [ $? != "0" ];then
     echo nbd installing error.
     cleanup_and_exit 8
   fi
 fi
}

function install_nbd_on_kvmhost {
 sshpass -p $KVM_HOST_PASSWORD ssh $SSH_OPTS -p $KVM_HOST_SSHD_PORT $KVM_HOST_USERNAME@$KVM_HOST_IP "which nbd-client">/dev/nul 2>&1
 if [ $? != "0" ];then
   sshpass -p $KVM_HOST_PASSWORD ssh $SSH_OPTS -p $KVM_HOST_SSHD_PORT $KVM_HOST_USERNAME@$KVM_HOST_IP "modprobe nbd && zypper --non-interactive --gpg-auto-import-keys in -l --no-recommends nbd">/dev/nul 2>&1
   if [ $? != "0" ];then
     echo nbd installing error on kvm host.
     cleanup_and_exit 8
   fi
 fi
}

function nfs_export_guest_backend {
 if ! which rcnfsserver >/dev/null 2>&1;then
   REPO_PATH=`gen_http_repo_path /tmp/repo_path.sh host`
   zypper ar $REPO_PATH $REPO_NAME >/dev/null 2>&1
   zypper --non-interactive in --no-recommends nfs-kernel-server
 fi
 NFS_EXPORT_POINT="$GUEST_BACKEND_FOLDER *(rw,no_root_squash,sync,no_subtree_check)"
 echo $NFS_EXPORT_POINT >> /etc/exports
 CLEAR_STAGE1="1"
 rcnfsserver restart >/dev/nul 2>&1
 if [ $? != "0" ];then
   echo Failed to restart nfs server service.
   cleanup_and_exit 26
 fi
}

function nbd_export_phy_guest_backend {
 install_nbd
 modprobe nbd
 nbd-server -p /tmp/nbd_srv.pid $NBD_PORT $GUEST_BACKEND_NAME
 if [ $? != "0" ];then
   echo Failed to perform nbd-server.
   cleanup_and_exit 27
 fi
 CLEAR_STAGE1="1"
}

function export_guest_backend {
 if [ $GUEST_BACKEND_FOLDER == "/dev" ] ;then
   KVM_GUEST_DISK_TYPE=block
   KVM_GUEST_DISK_SOURCE_ARG1=dev
   nbd_export_phy_guest_backend
   sshpass -p $KVM_HOST_PASSWORD ssh $SSH_OPTS -p $KVM_HOST_SSHD_PORT $KVM_HOST_USERNAME@$KVM_HOST_IP "nbd-client $XEN_HOST_IP $NBD_PORT $NBD_DEV">/dev/nul 2>&1
   if [ $? == "1" ];then
     echo export_guest_backend error
     cleanup_and_exit 25
   fi
   CLEAR_STAGE2="1"
   KVM_BACKEND_NAME=$NBD_DEV
 else
   KVM_GUEST_DISK_TYPE=file
   KVM_GUEST_DISK_SOURCE_ARG1=file
   nfs_export_guest_backend
   KVM_MNT_POINT=$GUEST_BACKEND_FOLDER
   sshpass -p $KVM_HOST_PASSWORD ssh $SSH_OPTS -p $KVM_HOST_SSHD_PORT $KVM_HOST_USERNAME@$KVM_HOST_IP "mkdir -p $KVM_MNT_POINT">/dev/nul 2>&1
   sshpass -p $KVM_HOST_PASSWORD ssh $SSH_OPTS -p $KVM_HOST_SSHD_PORT $KVM_HOST_USERNAME@$KVM_HOST_IP "mount $XEN_HOST_IP:$GUEST_BACKEND_FOLDER $KVM_MNT_POINT">/dev/nul 2>&1
   if [ $? == "1" ];then
     echo export_guest_backend error
     cleanup_and_exit 25
   fi
   CLEAR_STAGE2="1"
   KVM_BACKEND_NAME=$KVM_MNT_POINT/`basename $GUEST_BACKEND_NAME`
 fi
}

function define_guest_on_kvm_host {
rm -rf /tmp/v2v-$GUEST_NAME.xml
cat > /tmp/v2v-$GUEST_NAME.xml <<EOF
<domain type='kvm'>
  <name>v2v-$GUEST_NAME</name>
  <uuid>$KVM_GUEST_UUID</uuid>
  <memory>524288</memory>
  <currentMemory>524288</currentMemory>
  <vcpu cpuset='0-3'>1</vcpu>
  <os>
    <type arch='x86_64'>hvm</type>
    <boot dev="hd"/>
  </os>
  <features>
    <acpi/>
    <apic/>
    <pae/>
  </features>
  <clock offset='utc'/>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>restart</on_crash>
  <devices>
    <emulator>/usr/bin/qemu-kvm</emulator>
    <disk type='$KVM_GUEST_DISK_TYPE' device='disk'>
      <driver name='qemu' type="$GUEST_BACKEND_FORMAT"/>
      <source $KVM_GUEST_DISK_SOURCE_ARG1='$KVM_BACKEND_NAME'/>
      <target dev='$KVM_GUEST_DEV_NAME' bus='$KVM_GUEST_DEV_BUS'/>
    </disk>
    <interface type='bridge'>
      <mac address='$GUEST_IF_MAC'/>
      <source bridge='$KVM_HOST_BRIDGE'/>
      $KVM_GUEST_NIC_MODEL_TYPE
    </interface>
    <input type='mouse' bus='usb'/>
    <graphics type='vnc' port='5900' autoport='yes' keymap='en-us'/>
    <memballoon model="virtio"/>
  </devices>
</domain>
EOF
sshpass -p $KVM_HOST_PASSWORD scp $SSH_OPTS -P $KVM_HOST_SSHD_PORT /tmp/v2v-$GUEST_NAME.xml $KVM_HOST_USERNAME@$KVM_HOST_IP:/tmp/
if [ $? != "0" ];then
  echo ERROR while cp the guest configuration xml file to kvm host.
  cleanup_and_exit 29
fi
sshpass -p $KVM_HOST_PASSWORD ssh $SSH_OPTS -p $KVM_HOST_SSHD_PORT $KVM_HOST_USERNAME@$KVM_HOST_IP "virsh destroy v2v-$GUEST_NAME ; virsh undefine v2v-$GUEST_NAME ; virsh define /tmp/v2v-$GUEST_NAME.xml" >/dev/null 2>&1
}

function check_v2v {
 ping $GUEST_IP -c 4 >/dev/null 2>&1
}

function cleanup_and_exit {
 if [ "$KEEP_RUNNING" = "0" -o "$1" != "0" ];then
   if [ "$CLEAR_STAGE3" == "1" ];then
     sshpass -p $KVM_HOST_PASSWORD ssh $SSH_OPTS -p $KVM_HOST_SSHD_PORT $KVM_HOST_USERNAME@$KVM_HOST_IP "[ \`virsh domstate v2v-$GUEST_NAME\` == "running" ] && virsh destroy v2v-$GUEST_NAME">/dev/null 2>&1
   fi
   if [ -z $KVM_MNT_POINT ];then
     if [ "$CLEAR_STAGE2" == "1" ];then
       sshpass -p $KVM_HOST_PASSWORD ssh $SSH_OPTS -p $KVM_HOST_SSHD_PORT $KVM_HOST_USERNAME@$KVM_HOST_IP "nbd-client -d $NBD_DEV">/dev/null 2>&1
     fi
     if [ "$CLEAR_STAGE1" == "1" ];then
       kill -9 `cat /tmp/nbd_srv.pid`
       rm -rf /tmp/nbd_srv.pid
     fi
   else
     if [ $CLEAR_STAGE2 == "1" ];then
       sshpass -p $KVM_HOST_PASSWORD ssh $SSH_OPTS -p $KVM_HOST_SSHD_PORT $KVM_HOST_USERNAME@$KVM_HOST_IP "umount $KVM_MNT_POINT">/dev/null 2>&1
     fi
     if [ $CLEAR_STAGE1 == "1" ];then
       fixed_name=`echo $NFS_EXPORT_POINT | sed 's#\/#\\\/#g' | sed 's#\*#\\\*#g'`
       sed -i -e "/$fixed_name/d" /etc/exports && rcnfsserver restart
     fi
   fi
 fi
 exit $1
}

function show_information()
{
  echo "Information about exit code"
  echo "-------------------------------"
  echo " 0: Success"
  echo " 1: This box is not a xen host"
  echo " 2: This script needs to be run as root"
  echo " 3: No kvm module loaded on kvm host or failed to ssh to kvm host"
  echo " 4: Different processor vendors between xen host and kvm host"
  echo " 5: Libvirtd not running on xen host"
  echo " 6: Libvirtd not running on kvm host"
  echo " 7: Invalid guest name"
  echo " 8: NBD installing error"
  echo " 9: Failed to shutdown the guest in func get_guest_ip"
  echo "10: Failed to install tcpdump in host"
  echo "11: Failed to start the guest in func get_guest_ip"
  echo "12: TCPDUMP timeout"
  echo "13: Not found guest ip"
  echo "14: No nic found in static ip mode"
  echo "15: Failed to generate repo path in kvm host"
  echo "16: Failed to generate repo path in guest"
  echo "17: Failed to generate repo path in host"
  echo "18: Failed to convert dev name to uuid in guest"
  echo "19: Failed to modify the file /etc/sysconfig/kernel in guest"
  echo "20: Failed to add repo in guest"
  echo "21: Failed to install kernel-default in guest"
  echo "22: Failed to modifying device.map in guest"
  echo "23: Failed to modify grub or /etc/inittab or /etc/securetty in guest"
  echo "24: Failed to mkinitrd in guest"
  echo "25: Export_guest_backend error"
  echo "26: Failed to restart nfs server service"
  echo "27: Failed to perform nbd-server on host"
  echo "28: Failed to perform qemu-nbd"
  echo "29: Err while copy the guest configuration xml file to kvm host"
  echo "30: Failed to define kvm guest"
  echo "31: Failed to install tcpdump in kvm host"
  echo "32: TCPDUMP timeout while detecting kvm guest ip"
  echo "33: Failed to start the kvm guest in func get_kvm_guest_ip"
  echo "34: Not found kvm guest ip"
  echo "35: Err while checking the new kvm guest"
  echo "36: Failed to add nic for guest"
  echo "37: Failed to generate sdk repo path in kvm host"
  echo "38: Failed to generate sdk repo path in guest"
  echo "39: Failed to generate sdk repo path in host"
  echo "40: Failed to get guest grub version"
  echo "41: Failed to detect guest root partition"
  echo "60: Other issues"
  echo "-------------------------------"
}

function usage() {
  echo "Usage: `basename $0` GUEST-NAME GUEST-USERNAME GUEST-PASSWORD KVM-HOST-IP KVM-HOST-USERNAME KVM-HOST-PASSWORD [inactive]"
  exit 60
}
if [ $# -lt 6 ]; then
  usage
fi

function add_qa_repo() {
 product_name=SLE
 if [ "$1" != "kvmhost" ];then
  rel_num=`awk '/VERSION/ {print \$3}' /etc/SuSE-release`
  sp_num=`awk '/PATCHLEVEL/ {print \$3}' /etc/SuSE-release`
  if [ $sp_num != "0" ];then
   ver_info=$rel_num-SP${sp_num}_GA
  else
   ver_info=${rel_num}_GA
  fi
  qa_repo_path=http://dist.nue.suse.com/ibs/QA:/Head:/Devel/SUSE_$product_name-$ver_info
  qa_repo_name=qa_repo
  zypper ar -f $qa_repo_path $qa_repo_name >/dev/null 2>&1
 else
  rel_num=`sshpass -p $KVM_HOST_PASSWORD ssh $SSH_OPTS -p $KVM_HOST_SSHD_PORT $KVM_HOST_USERNAME@$KVM_HOST_IP "awk '/VERSION/ {print \\$3}' /etc/SuSE-release"`>/dev/null 2>&1
  sp_num=`sshpass -p $KVM_HOST_PASSWORD ssh $SSH_OPTS -p $KVM_HOST_SSHD_PORT $KVM_HOST_USERNAME@$KVM_HOST_IP "awk '/PATCHLEVEL/ {print \\$3}' /etc/SuSE-release"`>/dev/null 2>&1
  if [ $sp_num != "0" ];then
   ver_info=$rel_num-SP${sp_num}_GA
  else
   ver_info=${rel_num}_GA
  fi
  qa_repo_path=http://dist.nue.suse.com/ibs/QA:/Head:/Devel/SUSE_$product_name-$ver_info
  qa_repo_name=qa_repo
  sshpass -p $KVM_HOST_PASSWORD ssh $SSH_OPTS -p $KVM_HOST_SSHD_PORT $KVM_HOST_USERNAME@$KVM_HOST_IP "zypper ar -f $qa_repo_path $qa_repo_name" >/dev/null 2>&1
 fi
}

show_information
REPO_PATH=""
REPO_NAME="local_http_240"
KVM_HOST_BRIDGE=""
SSH_OPTS="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
NBD_PORT=9911
NBD_DEV=/dev/nbd0
KVM_GUEST_UUID=`uuidgen`
KVM_GUEST_DEV_NAME=""
KVM_GUEST_DEV_BUS=""
KVM_GUEST_DISK_TYPE=""
KVM_GUEST_DISK_SOURCE_ARG1=""
KVM_HOST_IP="$4"
KVM_HOST_USERNAME="$5"
KVM_HOST_PASSWORD="$6"
KVM_HOST_SSHD_PORT=22
KVM_MNT_POINT=""
KVM_BACKEND_NAME=""
LINUX_PARTITION_TYPE_LIST="82 83"
NFS_EXPORT_POINT=""
CLEAR_STAGE1=""
CLEAR_STAGE2=""
CLEAR_STAGE3=""
TCPDUMP_TIMEOUT=180
GUEST_NAME="$1"
GUEST_IP=""
GUEST_IF_SRC_DEV=""
GUEST_IF_MAC=""
GUEST_BOOTPROTO=dhcp
GUEST_USERNAME="$2"
GUEST_PASSWORD="$3"
GUEST_SSHD_PORT=22
BRIDGE=""
KVM_GUEST_NIC_MODEL_TYPE=""
KEEP_RUNNING="1"
if [ "$7" == "inactive" ];then
  KEEP_RUNNING="0"
fi
if [ -z "$BRIDGE" ]; then
  BRIDGE=$(ip route list | awk '/^default / { print $NF }')
fi
XEN_HOST_IP=`ifconfig2ip ip $BRIDGE`

if ! uname -r | grep -q \\-xen ;then
  echo $XEN_HOST_IP is not a xen hypervisor.
  cleanup_and_exit 1
fi

if test `id -u` != 0 ; then
  echo "Error: This script needs to be run as root."
  cleanup_and_exit 2
fi

add_qa_repo
install_sshpass

sshpass -p $KVM_HOST_PASSWORD ssh $SSH_OPTS -p $KVM_HOST_SSHD_PORT $KVM_HOST_USERNAME@$KVM_HOST_IP "lsmod | grep kvm">/dev/null 2>&1
if [ $? == "1" ];then
  echo No kvm module loaded on $KVM_HOST_IP or connection failed
  cleanup_and_exit 3
fi

XEN_HOST_ARCH=`cat /proc/cpuinfo | grep vendor_id | sed -n 1p | cut -d' ' -f2`
KVM_HOST_ARCH=`sshpass -p $KVM_HOST_PASSWORD ssh $SSH_OPTS -p $KVM_HOST_SSHD_PORT $KVM_HOST_USERNAME@$KVM_HOST_IP "cat /proc/cpuinfo | grep vendor_id | sed -n 1p | cut -d' ' -f2"`>/dev/null 2>&1
if [ $XEN_HOST_ARCH != $KVM_HOST_ARCH ];then
  echo Different processor vendor between $XEN_HOST_IP and $KVM_HOST_IP
  cleanup_and_exit 4
fi

if ! rclibvirtd status | grep -q running ; then
  echo --Libvirtd not running on $XEN_HOST_IP
  cleanup_and_exit 5
fi

sshpass -p $KVM_HOST_PASSWORD ssh $SSH_OPTS -p $KVM_HOST_SSHD_PORT $KVM_HOST_USERNAME@$KVM_HOST_IP "rclibvirtd status | grep -q running">/dev/null 2>&1
if [ $? == "1" ];then
  echo Libvirtd not running on $KVM_HOST_IP
  cleanup_and_exit 6
fi

if [ -z "$KVM_HOST_BRIDGE" ]; then
  KVM_HOST_BRIDGE=`sshpass -p $KVM_HOST_PASSWORD ssh $SSH_OPTS -p $KVM_HOST_SSHD_PORT $KVM_HOST_USERNAME@$KVM_HOST_IP "ip route list | sed -n /^default/p | cut -d' ' -f5"`
  echo KVM_HOST_BRIDGE=$KVM_HOST_BRIDGE 
fi

GUEST_DEV_NAME=`virsh domblklist $GUEST_NAME | sed -n 3p | awk '{print $1}'`
GUEST_BACKEND_NAME=`virsh domblklist $GUEST_NAME | sed -n 3p | awk '{print $2}'`
GUEST_BACKEND_FOLDER=`dirname $GUEST_BACKEND_NAME`
GUEST_BACKEND_FORMAT=`qemu-img info $GUEST_BACKEND_NAME | awk 'NR==2 {print $3}'`
GUEST_TYPE=`virsh dominfo $GUEST_NAME | sed -n -e '/OS Type/p' | awk '{print $3}'`
GUEST_STATE=`virsh domstate $GUEST_NAME`
GUEST_BOOT_SECTOR=/tmp/boot_sector
GUEST_ROOT_DEV=""
GUEST_GRUB_VER=""
DEVICE_MAP_PATH=/boot/grub

if [ -z "$GUEST_STATE" ];then
  echo Invalid guest name.
  cleanup_and_exit 7
fi

if [ $GUEST_BACKEND_FOLDER == "/dev" ] ;then
  add_qa_repo kvmhost
  echo [INFO] Installing nbd on kvmhost...
  install_nbd_on_kvmhost
  echo [INFO] Done.
fi

if is_linux_guest;then
  echo [INFO] It is a linux guest.
  KVM_GUEST_DEV_NAME=vda
  KVM_GUEST_DEV_BUS=virtio
  echo [INFO] Detecting guest ip.
  get_guest_ip $GUEST_BOOTPROTO
  echo [INFO] Done.
  echo [INFO] Generating repo in guest.
  REPO_PATH=`gen_http_repo_path /tmp/repo_path.sh`
  #REPO_PATH="http://147.2.207.240/repo/opensuse-13.1-x86_64/"
  echo REPO_PATH=$REPO_PATH, REPO_NAME=$REPO_NAME
  echo [INFO] Done
  sleep 10
  GUEST_ROOT_DEV=`sshpass -p $GUEST_PASSWORD ssh $SSH_OPTS -p $GUEST_SSHD_PORT $GUEST_USERNAME@$GUEST_IP "grep [[:space:]]*/[[:space:]] /etc/fstab | cut -d' ' -f1"` >/dev/null 2>&1
  if [ $? != "0" ];then
    echo Failed to detect guest root partition.
    cleanup_and_exit 41
  fi
  echo [INFO] Detecting grub version in guest.
  GUEST_GRUB_VER=`get_grub_version /tmp/get_grub_version`
  echo guest grub version is $GUEST_GRUB_VER
  if [ "$GUEST_GRUB_VER" == "2" ];then
    DEVICE_MAP_PATH=/boot/grub2
    GRUB2_DEFAULT_ITEM_NAME=""
  fi
  echo [INFO] Done
  echo [INFO] Converting devname to uuid in guest.
  devname2uuid_in_guest /tmp/repl_devname.sh
  echo [INFO] Done
  echo [INFO] Modifing /etc/sysconfig/kernel in guest.
  sshpass -p $GUEST_PASSWORD ssh $SSH_OPTS -p $GUEST_SSHD_PORT $GUEST_USERNAME@$GUEST_IP "sed -i '/^INITRD_MODULES=/s/.*/INITRD_MODULES=\"virtio_blk ata_piix ata_generic virtio_pci\"/g' /etc/sysconfig/kernel" >/dev/null 2>&1
  if [ $? != "0" ];then
    echo Failed to modify the file /etc/sysconfig/kernel.
    cleanup_and_exit 19
  fi
  echo [INFO] Done
  echo [INFO] Adding repo in guest.
  sshpass -p $GUEST_PASSWORD ssh $SSH_OPTS -p $GUEST_SSHD_PORT $GUEST_USERNAME@$GUEST_IP "zypper ar $REPO_PATH $REPO_NAME"
  if [ $? != "0" ];then
    echo Failed to add repo in guest. REPO_PATH=$REPO_PATH, REPO_NAME=$REPO_NAME.
    cleanup_and_exit 20
  fi
  echo [INFO] Done
  if [ ! $GUEST_TYPE == "hvm" ];then
    echo [INFO] PV linux domU detected.
    if [ "$GUEST_GRUB_VER" == "2" ];then
      sleep 10
      sshpass -p $GUEST_PASSWORD ssh $SSH_OPTS -p $GUEST_SSHD_PORT $GUEST_USERNAME@$GUEST_IP "grep \"menuentry '\" $DEVICE_MAP_PATH/grub.cfg > /tmp/ori_grubcfg" >/dev/null 2>&1
      if [ $? != "0" ];then
        cleanup_and_exit 60
      fi
    fi
    echo [INFO] Installing kernel-default in guest.
    sleep 10
    sshpass -p $GUEST_PASSWORD ssh $SSH_OPTS -p $GUEST_SSHD_PORT $GUEST_USERNAME@$GUEST_IP "zypper --non-interactive in --no-recommends kernel-default" >/dev/null 2>&1
    if [ $? != "0" ];then
      echo Failed to install kernel-default in guest.
      cleanup_and_exit 21
    fi
    echo [INFO] Done
    echo [INFO] Modifing device.map in guest.
    sshpass -p $GUEST_PASSWORD ssh $SSH_OPTS -p $GUEST_SSHD_PORT $GUEST_USERNAME@$GUEST_IP "sed -i s/$GUEST_DEV_NAME/$KVM_GUEST_DEV_NAME/ $DEVICE_MAP_PATH/device.map" >/dev/null 2>&1
    if [ $? != "0" ];then
      echo Failed to modifying device.map in guest.
      cleanup_and_exit 22
    fi
    echo [INFO] Done
    echo [INFO] Modifing grub, /etc/inittab and /etc/securetty in guest.
    if [ "$GUEST_GRUB_VER" == "1" ];then
      sshpass -p $GUEST_PASSWORD ssh $SSH_OPTS -p $GUEST_SSHD_PORT $GUEST_USERNAME@$GUEST_IP "sed -i '/default [0-9]/s/.*/default 0/g' $DEVICE_MAP_PATH/menu.lst; sed -i /xvc[0-9]/s/.*//g /etc/inittab; sed -i s/xvc[0-9]/ttyS0/ /etc/securetty" >/dev/null 2>&1
    else
      sshpass -p $GUEST_PASSWORD ssh $SSH_OPTS -p $GUEST_SSHD_PORT $GUEST_USERNAME@$GUEST_IP "sed -i /xvc[0-9]/s/.*//g /etc/inittab; sed -i s/xvc[0-9]/ttyS0/ /etc/securetty; grep \"menuentry '\" $DEVICE_MAP_PATH/grub.cfg > /tmp/new_grubcfg" >/dev/null 2>&1
      if [ $? != "0" ];then
        cleanup_and_exit 23
      fi
      sleep 5
      #PREFIX="Advanced options for openSUSE>"
      PREFIX=`sshpass -p $GUEST_PASSWORD ssh $SSH_OPTS -p $GUEST_SSHD_PORT $GUEST_USERNAME@$GUEST_IP "grep submenu $DEVICE_MAP_PATH/grub.cfg | cut -d\' -f2"`">"
      if [ $? != "0" ];then
        cleanup_and_exit 23
      fi
      sleep 5
      INAME=`sshpass -p $GUEST_PASSWORD ssh $SSH_OPTS -p $GUEST_SSHD_PORT $GUEST_USERNAME@$GUEST_IP "diff /tmp/ori_grubcfg /tmp/new_grubcfg | grep -v recovery | sed -n 2p | cut -d\' -f2"`
      if [ $? != "0" ];then
        cleanup_and_exit 23
      fi
      TITLE=$PREFIX$INAME
      echo [INFO] The TITLE of new boot item is $TITLE.
      sleep 5
      sshpass -p $GUEST_PASSWORD ssh $SSH_OPTS -p $GUEST_SSHD_PORT $GUEST_USERNAME@$GUEST_IP "grub2-set-default \"$TITLE\" && grub2-mkconfig -o $DEVICE_MAP_PATH/grub.cfg"
    fi
    if [ $? != "0" ];then
      echo Failed to modify grub or /etc/inittab or /etc/securetty in guest.
      cleanup_and_exit 23
    fi
    echo [INFO] Done
  else
    echo [INFO] HVM linux domU detected.
    echo [INFO] Modifing device.map in guest.
    sshpass -p $GUEST_PASSWORD ssh $SSH_OPTS -p $GUEST_SSHD_PORT $GUEST_USERNAME@$GUEST_IP "sed -i s/$GUEST_DEV_NAME/$KVM_GUEST_DEV_NAME/ $DEVICE_MAP_PATH/device.map" >/dev/null 2>&1
    if [ $? != "0" ];then
      echo Failed to modify device.map in guest.
      cleanup_and_exit 22
    fi
    echo [INFO] Done
    echo [INFO] Generating initrd in guest.
    sshpass -p $GUEST_PASSWORD ssh $SSH_OPTS -p $GUEST_SSHD_PORT $GUEST_USERNAME@$GUEST_IP "rm -rf /etc/modprobe.d/xen_pvdrivers-default.conf; mkinitrd" >/dev/null 2>&1
    if [ $? != "0" ];then
      echo Failed to mkinitrd in guest.
      cleanup_and_exit 24
    fi
    echo [INFO] Done
  fi
else
  echo [INFO] It is a windows guest, So nothing to do with it.
   get_nic_info
   if [ -z $GUEST_IF_MAC ];then
     GUEST_IF_SRC_DEV=$BRIDGE
     GUEST_IF_MAC=`generate_mac_addr`
     cold_add_nic
   fi
  KVM_GUEST_DEV_NAME=hda
  KVM_GUEST_DEV_BUS=ide
fi

echo [INFO] Shutting down the guest.
virsh shutdown $GUEST_NAME >/dev/null 2>&1
while true ; do
  if [ "`virsh domstate $GUEST_NAME`" == "shut off" ] ; then
    break
  fi
done
echo [INFO] Done

echo [INFO] Clearing var GUEST_IP
GUEST_IP=""
echo [INFO] Done

echo [INFO] Exporting guest backend and mount/connect it.
export_guest_backend
echo [INFO] Done
#echo KVM_GUEST_UUID=$KVM_GUEST_UUID
#echo KVM_HOST_BRIDGE=$KVM_HOST_BRIDGE
#echo KVM_GUEST_DISK_TYPE=$KVM_GUEST_DISK_TYPE
#echo GUEST_BACKEND_FORMAT=$GUEST_BACKEND_FORMAT
#echo KVM_GUEST_DISK_SOURCE_ARG1=$KVM_GUEST_DISK_SOURCE_ARG1
#echo KVM_BACKEND_NAME=$KVM_BACKEND_NAME
#echo KVM_GUEST_DEV_NAME=$KVM_GUEST_DEV_NAME
#echo KVM_GUEST_DEV_BUS=$KVM_GUEST_DEV_BUS
#echo GUEST_IF_MAC=$GUEST_IF_MAC
echo [INFO] Defining the guest on kvm host.
define_guest_on_kvm_host
if [ $? != "0" ];then
  echo Failed to define kvm guest.
  cleanup_and_exit 30
fi
echo [INFO] Done

echo [INFO] Detecting kvm guest ip.
get_kvm_guest_ip $GUEST_BOOTPROTO
echo [INFO] Done
sleep 15
echo [INFO] Checking the kvm guest.
check_v2v
if [ $? != "0" ];then
  echo Check v2v-$GUEST_NAME failed.
  cleanup_and_exit 35
else
  echo [INFO] Done
  echo $GUEST_NAME was migrated successfully from xen to kvm, The new kvm guest is v2v-$GUEST_NAME
fi
echo [INFO] Script gone.
cleanup_and_exit 0
