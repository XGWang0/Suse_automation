#!/usr/bin/perl -w

use strict;
use warnings;
use bench_parsers;

my $file;
open $file, $ARGV[0] or die "Cannot open '".$ARGV[0]."' : $!";
my @result = &parse_kernbench($file);
close $file;
while( @result )
{
    my $a1 = shift @result;
    my $a2 = shift @result;
    print "'$a1'\t'$a2'\n";
}
