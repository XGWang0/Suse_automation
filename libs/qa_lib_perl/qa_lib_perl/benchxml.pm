# ****************************************************************************
# Copyright (c) 2012 Unpublished Work of SUSE. All Rights Reserved.
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

package benchxml;

use strict;
use warnings;
use log;

use XML::Simple;

BEGIN {
	push @INC,"/usr/share/qa/lib",'.';
	use Exporter();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
	@ISA	= qw(Exporter);
	@EXPORT	= qw(
		&read_bench_results_from_xml_file
		&write_bench_results_to_xml_file
	);
	%EXPORT_TAGS	= ();
	@EXPORT_OK	= ();
}

sub read_bench_results_from_xml_file # $path_to_file.bench.xml ; returns hash reference
{
	my $file = shift;
	XMLin($file, ForceArray => [ 'values', 'axis', 'graphs' ], KeyAttr => { attribute => '+name' , axis => 'id' }, GroupTags => { attributes => 'attribute' }, ValueAttr => {axis => 'attribute'});
}

sub write_bench_results_to_xml_file # $path_to_file.bench.xml $hashref
{
	if (open FILE, '>', $_[0]) {
		print FILE XMLout($_[1], RootName => 'benchmark', KeyAttr => {attribute => '+name', axis => 'id'}, GroupTags => { attributes => 'attribute' }, ValueAttr => {axis => 'attribute'});
		close FILE;
		return 1;
	} else {
		log(LOG_ERR, "Unable to open file $_[0] for writing");
		return 0;
	}
}

1;
