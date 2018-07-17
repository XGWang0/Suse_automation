#!/bin/bash

#dissable the autoballoon 
. /usr/share/qa/virtautolib/lib/virtlib
virt_log_switch

sed -i '/autoballoon=1/s/.*/autoballoon=0/;/autoballoon="/s/.*/autoballoon="off"/' /etc/xen/xl.conf

#get the grub config file.

grub="`find /boot/ -name 'grub.cfg'`"
g_v=2

if [ -z "$grub" ];then
	grub="`find /boot/ -name 'menu.lst'`"
	g_v=1
fi

#get the xen index
index=`grep -i '^menuentry\|^submenu\|^title' $grub|grep -ni 'xen'|head -1|awk -F: '{print $1}'`

#set the xen option
if [ -n "$index" ];then
	index=$((index - 1));
	

	#for grub 1
	if [ $g_v -eq 1 ];then

		sed -i "s/^default .*/default $index/;s/set default=.*/set default=$index/" $grub
		sed -i '/boot\/xen/{s/dom0_mem=.*guest_loglvl=all// ;s/$/ dom0_mem=2048M,max:2048M loglvl=all guest_loglvl=all/}' $grub
		sed -i 's/^timeout [0-9]/timeout 0/' $grub

	fi
	#for grub 2
	if [ $g_v -eq 2 ];then

		echo 'GRUB_CMDLINE_XEN="dom0_mem=2048M,max:2048M loglvl=all guest_loglvl=all " ' >>/etc/default/grub
		grub2-mkconfig -o $grub
		grub2-set-default $index
	fi

	shutdown -r 1
else
	echo "Can NOT find xen kernle in the grub config"
	exit 1
fi

