#!/usr/bin/perl -w
#****************************************************************************
# Copyright (c) 2014 Unpublished Work of SUSE. All Rights Reserved.
# 
# THIS IS AN UNPUBLISHED WORK OF SUSE.  IT CONTAINS SUSE'S
# CONFIDENTIAL, PROPRIETARY, AND TRADE SECRET INFORMATION.  SUSE
# RESTRICTS THIS WORK TO SUSE EMPLOYEES WHO NEED THE WORK TO PERFORM
# THEIR ASSIGNMENTS AND TO THIRD PARTIES AUTHORIZED BY SUSE IN WRITING.
# THIS WORK IS SUBJECT TO U.S. AND INTERNATIONAL COPYRIGHT LAWS AND
# TREATIES. IT MAY NOT BE USED, COPIED, DISTRIBUTED, DISCLOSED, ADAPTED,
# PERFORMED, DISPLAYED, COLLECTED, COMPILED, OR LINKED WITHOUT SUSE'S
# PRIOR WRITTEN CONSENT. USE OR EXPLOITATION OF THIS WORK WITHOUT
# AUTHORIZATION COULD SUBJECT THE PERPETRATOR TO CRIMINAL AND   CIVIL
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

use strict;
use Getopt::Std;
use XML::Simple;
use XML::Bare;

our ($opt_h, $opt_o, $opt_f) = ("", "", "");
our $DEST = ".";
our $JOB_NAME = "Role";

$0 =~ m/([^\/]*)\.pl$/;
our $programe = $1;
our $version= "2.7.2";

sub usage()
{
    print <<"EOF";

    $programe Version $version

    Description :
        
        $programe is a utility to split multimachine job xml file into  a set of individual jobs

    which are sent out as normal sigle machine job.

    $programe [OPTIONS] xml_file

    Options:
            -o | set the output directory to which results are dump
            -h | print this usage message;

EOF
}


sub _check_destdir
{
    my ($dest, $rest) = @_;
    unless ( -e $dest)
    {
        mkdir $dest or die "Can't create directory $dest";
    }

    unless ( -d $dest) 
    {
        die "$dest is not directory\n";
    }

    $DEST = $dest;
}

sub _create_part_dir
{
    my $part_name = shift;
    my $part_dir = $DEST . "/" . $part_name;
    unless ( -e $part_dir )
    {
        mkdir $part_dir or die "Can't create directory $part_dir";
    }

    unless ( -d $part_dir )
    {
        die "$part_dir is not directory\n";
    }
}

sub _create_role_xml_file
{
    my ($roleid, $outdir, $xml) = @_;

    my $file_path = $outdir ."/$JOB_NAME".$roleid.'.xml';
    my $ob = new XML::Bare( file => $file_path, text => $xml );
    $ob->parse();
    $ob->save();
}

sub _extract_part_job
{
    my ($ob, $root, $role_id, $part_id) = @_;
    my $roles = $root->{job}->{roles}->{role};


    for (my $j=0; $j<=$#$roles; $j++)
    {
        my $r = $roles->[$j];
        delete $roles->[$j] if ($r->{id}->{value} != $role_id)
    }

    foreach (@$roles)
    {
        my $cmds = $_->{commands};
        for (my $i=0; $i<=$#$cmds; $i++)
        {
            my $c = $cmds->[$i];
            delete $cmds->[$i] if ($c->{part_id}->{value} != $part_id)
        }
    }
}

sub parse_xml_file
{
    my $ob = shift;
    my $root = $ob->{'xml'};
    my $parse_ret;

    my $parts = $root->{job}->{parts}->{part};
    my $roles = $root->{job}->{roles}->{role};

    if (!$parts || !$roles)
    {
        print "\nBad xml file feeded. Please give the correct one! \n\n";
        exit 1;
    }
    
    my %parse_parts;
    my @parse_roles;
    foreach (@$parts)
    {
        my $name = $_->{name}->{value};
        my $id   = $_->{id}->{value};
        $parse_parts{$id} = $name;
    }
    $parse_ret->{parts} = \%parse_parts;
    delete $root->{job}->{parts};
    $ob->save();


    foreach (@$roles)
    {
        my %r;
        my $name = $_->{name}->{value};
        my $role_id = $_->{id}->{value};
        $r{'id'} = $role_id;
        push @parse_roles, \%r;

        my @parse_cmds;
        my $commands = $_->{commands};
        foreach (@$commands)
        {
            my $c = $_;
            my $part_id = $c->{part_id}->{value};
            push @parse_cmds, $part_id;
        }
        $r{'cmds'} = \@parse_cmds
    }
    $parse_ret->{roles} = \@parse_roles;

    return $parse_ret;
}


sub process_xml
{

    my $xml = shift;
    my $ob = new XML::Bare( file => $xml );
    my $root = $ob->parse();

    # first round parse 
    my $parsed_ret = &parse_xml_file($ob);
    
    # create dirs for individual part
    my $parts = $parsed_ret->{parts};
    foreach ( keys $parts)
    {
        &_create_part_dir($_);
    }

    my $roles = $parsed_ret->{roles};
    foreach my $role (@$roles)
    {
        my $role_id = $role->{id};    
        my $cmds = $role->{cmds};

        foreach my $part_id (@$cmds)
        {
            my $ob = new XML::Bare( file => $xml );
            my $root = $ob->parse();
            my $t =  &_extract_part_job($ob, $root, $role_id, $part_id);
            my $txt = $ob->xml($root);
            my $output_dir = "$DEST/$part_id";
            &_create_role_xml_file($role_id, $output_dir, $txt);
        }
    }

}

my $opt_help        = 0;
my $dest_dir        = "";
my $mm_jobs         = "";

#parse command line options

unless (&getopts("ho:"))
{
    &usage();
    exit 1;
}

if ($opt_h)
{
    &usage; 
    exit 0;
}

if ($opt_o)
{
    &_check_destdir($opt_o);
}

if ($#ARGV != 0) 
{
    &usage ();
    exit 1;
}

my $mm_job_file = $ARGV[0];
&process_xml($mm_job_file);
