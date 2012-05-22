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
		&bench_results_from_xml
		&bench_results_to_xml_file
		&bench_results_to_xml
	);
	%EXPORT_TAGS	= ();
	@EXPORT_OK	= ();
}

our %options = (
	KeyAttr => { attr => '+id' }, 
	GroupTags => { attrs => 'attr', 'graphs'=>'graph', 'values'=>'value' }, 
);
our %out_options = (
	RootName => 'benchmark',
	%options
);
our %in_options = (
	ForceArray => [ 'value', 'axis', 'graph' ], 
	ValueAttr => {axis => 'attr'},
	%options
);


# Parses XML from string or file.
# @param1 XML
# - either a path of a bench XML file
# - or a string containing the XML code
# @returns the parsed bench hashref
sub bench_results_from_xml($) # XML string or file
{
	return XMLin( $_[0], %in_options	);
}

# Formats bench hashref as XML and returns it.
# @param1 bench hashref
# @returns a string with bench XML
sub bench_results_to_xml($) # bench hashref
{
	return XMLout($_[0], %out_options );
}

# Formats bench hashref as XML and writes to a file.
# @param1 path to a bench file to write
# @param2 bench hashref
# @returns 1 on successfull write, 0 on error
sub bench_results_to_xml_file($$) # path, bench hashref
{
	if (open FILE, '>', $_[0]) {
		print FILE bench_results_to_xml($_[1]);
		close FILE;
		return 1;
	} else {
		log(LOG_ERR, "Unable to open file $_[0] for writing");
		return 0;
	}
}



1;
