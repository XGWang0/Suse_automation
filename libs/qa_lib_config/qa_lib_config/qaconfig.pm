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
