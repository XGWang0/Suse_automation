#!/usr/bin/perl -w
# script to list/grep distros from CML

$url='http://cml.suse.cz/cgi-bin/find-iso2?filter=';

open LIST, "curl $url 2>/dev/null |" or die "Cannot read '$url': $!";
while( my $row=<LIST> )
{
    next unless $row =~ /((http|ftp):\/\/([\w\d\.]+)(.+))'>\[B\]/;
    my $link=$1;
    if( $link =~ /(CD|DVD)(\d+)/ )
    {   next if $2>1;    }
    my $match=1;
    foreach my $arg (@ARGV)
    {   
        if($link !~ /$arg/i)
        {
            $match=0;
            last;
        }
    }
    next unless $match;
    print $link,"\n";
}
close LIST;

