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
use POSIX;
use Clone qw(clone);
use Getopt::Std;
use File::Path;
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


sub _check_dir
{
    my $dir_name = shift;
    
    unless ( -e $dir_name )
    {
        mkpath $dir_name or die "Can't create directory $dir_name";
    }

    unless ( -d $dir_name )
    {
        die "$dir_name is not directory\n";
    }
    return $dir_name;
}

sub _create_role_xml_file
{
    my ($roleid, $outdir, $xml) = @_;

    my $file_path = $outdir ."/$JOB_NAME" . "-" . $roleid . ".xml";
    my $ob = new XML::Bare( file => $file_path, text => $xml );
    $ob->parse();
    $ob->save();
}

sub _extract_part_job
{
    my ($root, $role_id, $part_id) = @_;
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
        $r{'name'} = $name;
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
    my $name = tmpnam();
    $ob->{file} = $name;
    
    # first round parse 
    my $parsed_ret = &parse_xml_file($ob);
    
    # create dirs for individual part
    my $parts = $parsed_ret->{parts};
    foreach ( keys $parts)
    {
        my $dir = $DEST . "/" . $_;
        &_check_dir($dir);
    }

    my $roles = $parsed_ret->{roles};
    foreach my $role (@$roles)
    {
        my $role_id   = $role->{id};
        my $role_name = $role->{name};
        my $cmds = $role->{cmds};

        foreach my $part_id (@$cmds)
        {
            my $r = clone($root);
            my $t =  &_extract_part_job($r, $role_id, $part_id);
            my $txt = $ob->xml($r);
            my $output_dir = "$DEST/$part_id";
            &_create_role_xml_file($role_id, $output_dir, $txt);
        }
    }

    #clean temporary file
    if ( -e $name )
    {
        unlink $name or die "Can't remove temp file $name";
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
    $DEST = &_check_dir($opt_o);
    print "DEST= $DEST \n";
}

if ($#ARGV != 0) 
{
    &usage ();
    exit 1;
}

my $mm_job_file = $ARGV[0];
&process_xml($mm_job_file);
