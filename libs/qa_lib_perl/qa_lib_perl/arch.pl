#!/usr/bin/perl -w

BEGIN {
# extend the include path to get our modules found
push @INC,"/usr/share/qa/lib",'.';
}


use strict;
use detect;

my $loc=&get_architecture();
printf "%s\n", (defined $loc ? $loc : '(unknown)');

