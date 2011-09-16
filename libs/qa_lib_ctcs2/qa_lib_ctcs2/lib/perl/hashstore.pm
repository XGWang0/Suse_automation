#!/usr/bin/perl

#
# VA-CTCS's custom hash storage routine.
# Woof.  We should replace this.
#

#
# Modified save_hash to be thread safe. It always writes to temporary file and 
# than replaces target file with the temp file.
#
# Lukas Lipavsky <llipavsky@suse.cz>
#

use File::Temp qw(tempfile);

sub load_hash {
        my $hashref = shift;
        my $filename = shift;
        my $key;
        open (HASH, $filename) or return 0; #false
        while (<HASH>) {
                s/\n//gs;
                $key = $_;
                if (defined ($_ = <HASH>)) {
                        s/\n//gs;
                        if ( $_ =~ /\S+\s+\S+/ ) {
                                my @list;
                                @list = split ' ',$_ ;
                                $hashref->{$key} = \ @list;
                        } else {
                                s/\s//gs;
                                $hashref->{$key} = $_;
                        }
                }
        }
        close HASH;
        return 1; # true
}

#
# args:
#   1. hash reference
#   2. file where to store the hash
#   3. optional array which tells in which order to store records from hash
#      it must be either missing or have same ammount of elements as hash keys!
sub save_hash {
        my $hashref = shift;
        my $filename = shift;
	my @order = @_;
        my $key;
        my $item;

	my ( $tmp_fh, $tmp_filename ) = tempfile( "$filename.XXXXXX", UNLINK => 0 ) or return 0; # false

	if (@order and ( scalar @order != scalar keys %$hashref ) ) {
		die '@order provided but has different size than the hash!';
	}

	@order = keys(%$hashref) unless @order;

        foreach $key (@order) {
                print $tmp_fh "$key\n";
                if (ref($hashref->{$key}) eq "ARRAY") {
                        print $tmp_fh join ' ',@{$hashref->{$key}};
                } else {
                        print $tmp_fh "$hashref->{$key}";
                }
                print $tmp_fh "\n";
        }
        close $tmp_fh;
	
	chmod 0644, $tmp_filename;

	rename $tmp_filename, $filename;
        return 1;
}

1;
