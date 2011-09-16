#!/usr/bin/perl -w
# vim: set et ts=4 sw=4 ai si:

die "Usage: $0 <packages...>\n" unless @ARGV;
&check_installed( @ARGV );

sub check_installed
{
    my @build_needed=@_;
    my @install=();
    my ($cmd,$ret);

    print "checking the presence of ".(@build_needed)." packages\n";
    foreach my $package (@build_needed)
    {
        print "processing package $package\n";
        $ret = system("rpm -q \"$package\" >/dev/null") >>8;
        if( $ret == 0 ) {
            next;
        } elsif( $ret != 1 ) {
            die "rpm query failed with code $ret";
        }

        push @install, $package;
    }

    if( @install > 0 )
    {
        &command( "yast2 -i ".join ' ',@install );
    }
}


sub command
{
    my $cmd=$_[0];
    print $cmd,"\n";
    my $ret = system $cmd;
    die "Command failed with code $ret" if $ret>0;
}


