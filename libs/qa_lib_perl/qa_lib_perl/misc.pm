# ****************************************************************************
# Copyright (c) 2013 Unpublished Work of SUSE. All Rights Reserved.
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
		next if /BogoMips:/;

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
