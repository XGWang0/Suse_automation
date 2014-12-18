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
use XML::Bare qw/forcearray/;
use Data::Dumper;

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


sub _create_dir
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
    my ($role_name, $outdir, $xml) = @_;

    $role_name = "default" if ( !defined($role_name) );
    my $file_path = $outdir ."/$JOB_NAME" . "-" . $role_name . ".xml";
    my $job_xml_ref = XMLin($xml,
                        ForceArray=>1,
                        KeyAttr=>{ role => 'name'},
                        );
    XMLout($job_xml_ref,
           RootName => 'job',
           XMLDecl => '1',
           KeyAttr=>{ role => 'name'},
      	   OutputFile => $file_path,
          );
}
sub _extract_part_job
{
    my ($cmdroot, $part_id) = @_;
    my $cmds = forcearray($cmdroot->{commands});
    for ( my $i=0; $i<=$#$cmds; $i++ )
    {
        my $c = $cmds->[$i];
        delete $cmds->[$i] if ($c->{part_id}->{value} ne $part_id);
    }
}
sub _extract_role_job
{
    my ($roles, $role_name) = @_;

    $roles = forcearray($roles);
    for (my $i=0; $i<=$#$roles; $i++)
    {
        my $r = $roles->[$i];
        delete $roles->[$i] if ($r->{name}->{value} ne $role_name);
    }
}
sub _extract_role_part_job
{
    my ($root, $role_name, $part_id) = @_;
    my $roles = $root->{job}->{roles}->{role};

    &_extract_role_job($roles,$role_name);

    $roles = forcearray($roles);
    foreach (@$roles)
    {
        &_extract_part_job($_,$part_id) if defined($_);
    }
}

# Sub: _merge_config
#  Merge role config into global config
sub _merge_config
{
    my $root = shift;
    my $config = $root->{job}->{config};
    my $role = forcearray($root->{job}->{roles}->{role});

    foreach (@$role)
    {
        next if !defined($_);

        if (defined($_->{config}->{rpm})) {
	    $_->{config}->{rpm} = forcearray($_->{config}->{rpm});
	    $config->{rpm} = forcearray($config->{rpm});
            push(@{$config->{rpm}}, @{$_->{config}->{rpm}});
	}
        if (defined($_->{config}->{repository})) {
            $_->{config}->{repository} = forcearray($_->{config}->{repository});
            $config->{repository} = forcearray($config->{repository}); 
            push(@{$config->{repository}}, @{$_->{config}->{repository}});
        }
        if (defined($_->{config}->{motd})) {
	    $config->{motd} = $_->{config}->{motd};
	}
	if (defined($_->{config}->{debuglevel})) {
	    $config->{debuglevel} = $_->{config}->{debuglevel};
	}
	delete $_->{config};
    }
}

sub parse_xml_file
{
    my $ob = shift;
    my $root = $ob->{'xml'};
    my $parse_ret;

    my $parts = $root->{job}->{parts}->{part};
    my $roles = $root->{job}->{roles}->{role};
    
    my %parse_parts;
    my @parse_roles;
 
    if ($parts)
    {
	$parts = forcearray($parts); 
        foreach (@$parts)
        {
            my $name = $_->{name}->{value};
            my $id   = $_->{id}->{value};
            $parse_parts{$id} = $name;
        }
        $parse_ret->{parts} = \%parse_parts;
    }
    delete $root->{job}->{parts};
    $ob->save();

    if ($roles)
    {
	$roles = forcearray($roles); 
        foreach (@$roles)
        {
            my %r;
            my $name = $_->{name}->{value};
            $r{'name'} = $name;
            push @parse_roles, \%r;
    
            my @parse_cmds;
            my $commands = forcearray($_->{commands});
            if($parts)
            {
                foreach (@$commands)
                {
                    my $c = $_;
                    my $part_id = $c->{part_id}->{value};
                    push @parse_cmds, $part_id;
                }
                $r{'cmds'} = \@parse_cmds;
            }
        }
        $parse_ret->{roles} = \@parse_roles;
    }
    else
    {
        delete $root->{job}->{roles};
        $ob->save();
        my @parse_cmds;
        my $commands = $root->{job}->{commands};
        if ($parts)
        {
            foreach (@$commands)
            {
                push @parse_cmds, $_->{part_id}->{value};
            }
            $parse_ret->{part_ids} = \@parse_cmds;
        }
	else
        {
            $parse_ret->{commands} = $commands;
        }
    }
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
    if($parts)
    {
        foreach ( keys %$parts)
        {
            my $dir = $DEST . "/" . $_;
            &_create_dir($dir);
        }
    }
    my $roles = $parsed_ret->{roles};
    if($roles)
    {
        foreach my $role (@$roles)
        {
            my $role_name = $role->{name};
            my $cmds = $role->{cmds};

            if($cmds)
            { 
                foreach my $part_id (@$cmds)
                {
                    my $r = clone($root);
                    my $t =  &_extract_role_part_job($r, $role_name, $part_id);
                    &_merge_config($r);
                    my $txt = $ob->xml($r);
                    my $output_dir = "$DEST/$part_id";
                    &_create_role_xml_file($role_name, $output_dir, $txt);
                }
            }
            else
            {
                my $r = clone($root);
                my $t = &_extract_role_job($r->{job}->{roles}->{role}, $role_name);
                &_merge_config($r);
                my $txt = $ob->xml($r);
                &_create_role_xml_file($role_name, $DEST, $txt);
            }
        }
    }
    else  # without roles, have/not have parts.
    {
        if($parts)
        {
            my $ids = $parsed_ret->{part_ids};
            foreach my $part_id (@$ids)
            {
               my $r = clone($root);
               my $t = &_extract_part_job($r->{job},$part_id);
               my $txt = $ob->xml($r);
               my $output_dir = "$DEST/$part_id";
               &_create_role_xml_file(undef, $output_dir, $txt); 
            }
        }
        else # without roles and parts. 
        {
            my $r = clone($root);
            my $txt = $ob->xml($r);
            &_create_role_xml_file(undef, $DEST, $txt);
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
    $DEST = &_create_dir($opt_o);
    #print "DEST= $DEST \n";
}

if ($#ARGV != 0) 
{
    &usage ();
    exit 1;
}

my $mm_job_file = $ARGV[0];
&process_xml($mm_job_file);
