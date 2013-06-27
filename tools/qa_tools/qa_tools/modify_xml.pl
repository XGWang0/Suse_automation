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

# autoyast XML patcher
# currenlty used for merging results from reinstall script with a template
# can also clone system via autoyast and merge with the result

use XML::Simple;
use Getopt::Std;
use Sys::Hostname;

sub HELP_MESSAGE
{
    print <<EOF;
$0 [options] -m <modfile> <infile> <outfile>
$0 [options] -c -m <modfile> <outfile>
options:
\t-c\t\tclone the system, use the result as <infile>
EOF
    exit;
}

sub VERSION_MESSAGE
{
    print "$0 version 1.1\n";
}

$Getopt::Std::STANDARD_HELP_VERSION=1;
getopts('cm:',\%opts);

$file_mod=$opts{'m'};
if( $opts{'c'} )
{   
    &command( 'yast /usr/share/YaST2/clients/clone_system.ycp' );
    $file_in ='/root/autoinst.xml';
    $file_out=$ARGV[0];
}
else
{
    $file_in =$ARGV[0];
    $file_out=$ARGV[1];
}

# check the arguments, read the input XML
&HELP_MESSAGE() unless $file_in and $file_out;
die "Cannot read input  file '$file_in': $!"  unless -r $file_in;

my $in = XMLin($file_in, ForceArray=>1, ForceContent=>1);

my $mod = undef;
if( $file_mod )
{
    die "Cannot read mod file '$file_mod': $!" unless -r $file_mod;
    $mod = XMLin($file_mod, ForceArray=>1, ForceContent=>1);
}

$ref = &merge( $in, $mod ) if $mod;
$ref->{'xmlns'}="http://www.suse.com/1.0/yast2ns";
$ref->{'xmlns:config'}="http://www.suse.com/1.0/configns";

open $file, ">$file_out" or die "Cannot open $file_out for writing: $!";
print $file '<?xml version="1.0"?>'."\n<!DOCTYPE profile>\n";
XMLout( $ref, OutputFile=>$file, RootName=>'profile' );
close $file;

# merge( $xml1, $xml2 )
# merges $xml1 and $xml2 to a new XML tree
sub merge
{
    my ($xml1,$xml2)=@_;
    my $xml={};
    return $xml1 unless $xml2;
    foreach my $key (keys %{$xml1})
    {   @{$xml->{$key}} = map {&dup($_)} @{$xml1->{$key}};  }
    foreach my $key (keys %{$xml2})
    {
        $xml->{$key}=[] unless $xml->{$key};
        if( @{$xml->{$key}}==1 and @{$xml2->{$key}}==1 )
        {   $xml->{$key}->[0] = &merge($xml->{$key}->[0], $xml2->{$key}->[0] ); }
        else
        {   push @{$xml->{$key}}, map {&dup($_)} @{$xml2->{$key}};  }
    }
    return $xml;
}

# dup( $xml )
# duplicates XML tree
sub dup
{
    my $xml=$_[0];
    my $ret={};
    return $xml unless ref($xml) eq 'HASH';
    foreach my $key( keys %{$xml} )
    {   
        if( ref($xml->{$key}) eq 'ARRAY' )
        {   @{$ret->{$key}}=map { &dup($_) } @{$xml->{$key}};    }
        elsif( ! ref($xml->{$key}) )
        {   $ret->{$key} = $xml->{$key};  }
    }
    return $ret;
}

sub command
{
    my $cmd=$_[0];
    print $cmd,"\n";
    my $ret = system $cmd;
    die "Command failed with code $ret" if $ret>0;
}


