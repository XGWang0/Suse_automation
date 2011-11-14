#!/usr/bin/perl -w
# ****************************************************************************
# Copyright (c) 2011 Unpublished Work of SUSE. All Rights Reserved.
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

# script to set /boot/initrd and /boot/vmlinuz symlinks
# can optionally run mkinitrd to (re)create initrd

use strict;

our $run_mkinitrd=shift @ARGV if $ARGV[0] eq '-m';

die "Usage: $0 [-m] <version>\n\t-m\truns mkinitrd" unless $ARGV[0];

our $version=$ARGV[0];

our $kernel="/boot/vmlinuz-$version";

die "Cannot find kernel $kernel" unless -f $kernel;

our $initrd="/boot/initrd-$version";

if( $run_mkinitrd )
{
    my $grub_conf='/boot/grub/menu.lst';
    my $grub_conf_bak='/boot/grub/menu.lst.bak_mkinitrd';
    die "Cannot find $grub_conf" unless -f $grub_conf;
    unless( -f $grub_conf_bak )
    {
        system "cp $grub_conf $grub_conf_bak" and die "Cannot copy $grub_conf";
    }
    system "mkinitrd -k $kernel -i $initrd" and die "mkinitrd failed";
    system "cp $grub_conf_bak $grub_conf" and die "Cannot restore $grub_conf";
}
else
{    
    die "Cannot find $initrd (you can create it with '-m' option)" unless -f $initrd;   
}

foreach my $f (map {"/boot/$_"} ('initrd','vmlinuz'))
{
    if( -f $f )
    {   unlink $f or die "Cannot unlink $f: $!";    }
}

symlink $kernel,'/boot/vmlinuz' or die "Cannot link $kernel: $!";
symlink $initrd,'/boot/initrd' or die "Cannot link $initrd: $!";


