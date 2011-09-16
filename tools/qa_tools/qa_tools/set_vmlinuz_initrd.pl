#!/usr/bin/perl -w
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

