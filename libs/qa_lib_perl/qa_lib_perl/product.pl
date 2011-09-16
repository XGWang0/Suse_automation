#!/usr/bin/perl -w

BEGIN {
# extend the include path to get our modules found
push @INC,"/usr/share/qa/lib",'.';
}


use strict;
use Getopt::Std;
use detect;
use log qw(:DEFAULT $loglevel);
$log::loginfo='product.pl';

our %opts;

sub HELP_MESSAGE
{
    print <<EOF;
$0 [-v] [-n]
    -v  verbose mode
    -n  disable network QADB lookup (use hardcoded products / releases instead)
EOF
}

sub VERSION_MESSAGE
{
    print "$0 version 1.1\n";
}

$Getopt::Std::STANDARD_HELP_VERSION=1;
getopts('vn',\%opts);
$log::loglevel = $opts{'v'} ? LOG_DEBUG : LOG_ERR;

my ($type,$version,$subversion,$release,$arch,$product)=&detect_product('net'=>!$opts{'n'});


print "$product-$release\n";

sub nz
{    return $_[0] ? $_[0]:'';	}

