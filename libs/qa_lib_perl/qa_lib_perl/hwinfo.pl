#!/usr/bin/perl -w

BEGIN {
# extend the include path to get our modules found
push @INC,"/usr/share/qa/lib",'.';
}


use strict;
use misc;

print &get_filtered_hwinfo;
