# ****************************************************************************
# Copyright (c) 2011 Unpublished Work of SUSE. All Rights Reserved.
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

package qaconfig;

use strict;
use warnings;

BEGIN {
	push @INC,"/usr/share/qa/lib",'.';
	use Exporter();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
	@ISA	= qw(Exporter);
	@EXPORT	= qw(
		%qaconf
	);
	%EXPORT_TAGS	= ();
	@EXPORT_OK	= qw(
		&get_qa_config
		&get_system_qa_config
	);
}

# The main qa configuration (no module -> /etc/qa)
our %qaconf = get_system_qa_config();

#
# Returns the hash of qa configuration for given module
# e.g. for /etc/qa/blabla use get_qa_config("blabla")
#
# 1) &get_qa_config('') - reads 
# 2) &get_qa_config('module') - reads only variables prefixed by module_ (and strips the prefix)
#
sub get_qa_config
{
	my %config = ();
	@_=('') unless @_;
	my ($module, undef) = @_;
	$module .= '_' unless $module eq '';
	foreach my $key (keys %qaconf)	{
		if($key =~ /^$module(.*)/) {
			$config{$1} = $qaconf{$key};
		}
	}
	return %config;
}

sub get_system_qa_config
{
	my %config = ();
	open CONF, "source /usr/share/qa/lib/config ''; dump_qa_config|";
	for (<CONF>) {
		chomp;
		/^([^=]+)=(.*)$/;
		$config{$1} = $2;
	}
	close CONF;
	return %config;
}


1;
