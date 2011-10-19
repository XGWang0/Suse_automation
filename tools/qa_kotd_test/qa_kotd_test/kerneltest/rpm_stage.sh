#!/bin/sh
# ****************************************************************************
# Copyright © 2011 Unpublished Work of SUSE. All Rights Reserved.
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

#this file should be running by crond
#the qa_lib_keys should be installed for scp the rpm to SUT(stage machine)
#expect shoud install to avoid fresh install prompt

#setup the PATH
PATH="/sbin:/usr/sbin:/usr/local/sbin:/root/bin:/usr/local/bin:/usr/bin:/bin"

###########################Config Start#############################
#monitor dir 
monitor_dir=/tmp/test/

#email for job result/finish info
email=jtang@suse.com

# the build url for reinstall 
reinstall_url="http://147.2.207.242/iso_mnt/SLES-11-SP2-DVD-i586-Beta4-DVD1/"

# the ip of hamsta master

hamst_ipadd=147.2.207.183

# the stage machine from hamsta

host_ip=147.2.207.189

# rpm dir in stage machine

rpm_dir=/home

# required file
first_check_exp=/home/jerry/py/stage/first-check.exp
feed_hamsta=/home/jerry/py/stage/feed_hamsta.pl


###########################Config End################################
#lock file to avoid muti-run
lock_f=/var/run/rpm_stage.pid

if [ -e /var/run/rpm_stage.pid ];then
	echo "The install job is stall running skip this cycle"
fi

echo $$ > $lock_f



e_clean(){
	rm -rf $monitor_dir/nowrunning
	rm /var/run/rpm_stage.pid
	exit
}





#get the current dir name and now dir name
current=`ls -l $monitor_dir|sed -n "/current/{s/.*> //;p;q}"`
now=`ls -l $monitor_dir|sed -n "/now/{s/.*> //;p;q}"`

#check the link 

if [ -z "$current" -o -z "$now" ];then
	echo "missing link ,please check the link"
fi


#check different start

if [ "$current" != "$now" ] ;then

	#new build found start stage process

	#update the link
	rm $monitor_dir/current
	ln -s $now $monitor_dir/current

	#backup the now to nowrunning
	rm -rf $monitor_dir/nowrunning
	cp -ar $monitor_dir/$now $monitor_dir/nowrunning
	if [ $? != 0 ];then
		echo "copy file faied , please check the disk space"
		e_clean
	fi

	# send reinstall job to stage machine

	$feed_hamsta -w -c"send reinstall ip $host_ip $reinstall_url $email $now" $hamst_ipadd

	if [ $? != 0 ];then
		echo "reinstall failed,please check the reinstall job from hamsta"
		e_clean
	fi

	#use expect to avoid prompt from fresh install machine

	expect -f $first_check_exp root@$host_ip

	# scp the "now" rpm to the SUT (stage machine)

	scp -r $monitor_dir/nowrunning root@$host_ip:$rpm_dir/
	if [ $? != 0 ];then
		echo "scp file failed"
		e_clean
	fi


	# Install the rpm package 

	$feed_hamsta -w -c "send one line cmd ip $host_ip echo#rpm#-ivh#$rpm_dir/nowrunning/*;ls#$rpm_dir/nowrunning/* $email $now" $hamst_ipadd
	if [ $? != 0 ];then
		echo "rpm install failed please check the install log from hamsta ";
		e_clean
	fi

	# run some test

	echo "stuff"
	if [ $? != 0 ];then
		echo "test failed"
		e_clean
	fi
	
	#Got here every test passed

	echo "passed"
	#update link to stable
	rm $monitor_dir/stable
	ln -s $now $monitor_dir/stable
	e_clean
fi

e_clean






	



