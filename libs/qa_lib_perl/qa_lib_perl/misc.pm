package misc;

use strict;
use warnings;
use log;

BEGIN {
	push @INC,"/usr/share/qa/lib",'.';
	use Exporter();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
	@ISA	= qw(Exporter);
	@EXPORT	= qw(
		&filter_hwinfo
		&get_filtered_hwinfo
		&filter_hwinfo_file
	);
	%EXPORT_TAGS	= ();
	@EXPORT_OK	= ();
}

sub filter_hwinfo # @hwinfo_lines ; returns @filtered_hwinfo_lines
{
	my @result;
	for (@_) {
		next if /Clock:/;
		next if /Memory Range:/;
		next if / events?\)/;

		push @result, $_;
	}
	@result;
}

sub get_filtered_hwinfo # [$path_to_hwinfo_file], returns @filtered_hwinfo_lines
{
	my $file = shift @_;
	if ($file and -r $file) {
		$file = "<$file";
	} else {
		$file = "/usr/sbin/hwinfo --all|";
	}
	open HWINFO, $file;
	my @lines = <HWINFO>;
	close HWINFO;
	filter_hwinfo @lines;
}

# overwrite hwinfo file with its "filtered" content
sub filter_hwinfo_file # $path_to_hwinfo_file
{
	my $file = shift @_;
	return 0 unless $file and -r $file and -w $file;
	
	my @hwinfo = get_filtered_hwinfo($file);
	open HWINFO, ">", $file;
	print HWINFO @hwinfo;
	close HWINFO;
	1;
}

1;
