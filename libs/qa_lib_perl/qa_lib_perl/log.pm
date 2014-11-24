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

=head1 NAME

log - Perl logging module

=head1 AUTHOR

Vilem Marsik <vmarsik@suse.cz>

=head1 EXPORTS

Symbolic constants for log levels LOG_CRIT, LOG_CRITICAL, LOG_ERR, LOG_ERROR, LOG_WARN, LOG_WARNING, LOG_NOTICE, LOG_INFO, LOG_DETAIL, LOG_DEBUG, LOG_STDOUT, LOG_STDERR

Functions &log, &log_set_output, &log_add_output, &caller_info

=head1 SYNOPSIS

 # Initialization - by default the log outputs to STDERR

 &log_set_output( path=>'/var/log/test.log', gzip=>1 );

 open HANDLE, ">/tmp/log" or die "Cannot open log: $!";
 &log_add_output( handle=>*HANDLE, close=>1 );

 # logging
 &log( LOG_INFO, "This is a log entry" );
 &log( LOG_DETAIL, "1+1=%i", 1+1);

=head1 DEFAULT SETTINGS

By default, the output goes to STDERR. Verbosity is set to LOG_INFO and above. Log entries consist of timestamp and message level name, info about process and caller function is not displayed. STDOUT and STDERR are logged.

=head1 LOGGING OPTIONS

All the logging options can be set per-output. Some can also be set globally. 

The global value is used, when there is no per-output value. You can change the global values on-the-fly, and existing outputs that do not override them are affected.

=head2 Global options 
- see below for the description:

	$log::loglevel
	$log::loglevelnames
	$log::logtime
	$log::logcaller
	$log::loginfo
	$log::logstdout
	$log::logstderr


=head2 Description

=over 4

=item level, $log::loglevel

maximal verbosity level of messages that are still logged. More detailed messages (e.g. LOG_DEBUG) are dropped.

=item names, $log::loglevelnames

true if you want to have the verbosity level name in the output. This is required, if you intend to parse your messages later.

=item time, $log::logtime

true if you want to have date and time of the messages logged

=item info, $log::loginfo

set some process info here (e.g "[$$]") to log an additional field helping to identify different processes, keep to 0 or '' otherwise

=item caller, $log::logcaller

true if you want to log the method name, package name and line number of the current method

=item stdout, $log::stdout

true if you want to log messages with LOG_STDOUT

=item stderr, $log::stderr

true if you want to log messages with LOG_STDERR

=item handle

pass an open handle here to add it as a logging output. Either this or 'path' are mandatory.

=item path

path to the log file.  If you do not specify the handle as well, module will try to open it for append, unless 'overwrite' is used.

=item overwrite

when opening a file, truncate it instead of appending

=item close

close the handle on exit ( in the section END ). This will be automatically set for files opened by the module itself.

=item gzip

gzip the file after closing.

=item bzip2

bzips the file after closing.

=item unlink

removes the file after closing.

=back

=head2 Option dependency

 'handle', 'path' - at least one is required.
 'overwrite' - only effective if 'path' set and 'handle' not set.
 'close' - automatically set if 'path' set and 'handle' not set.
 'gzip', 'bzip2', 'unlink' - require 'path' and 'close'; use only one of them per output, otherwise you get an error.

=cut

package log;
# See man 1 perlmod for the perl module template used here

use strict;
no strict "refs";

use POSIX qw/ :termios_h strftime /;
use File::Temp qw/ tempfile tempdir /;
use File::Basename qw/basename dirname/;
use warnings;
# Perl mySQL API

use constant {
	LOG_CRIT	=> 0,
	LOG_CRITICAL	=> 0,
	LOG_ERR		=> 1,
	LOG_ERROR	=> 1,
	LOG_WARN	=> 2,
	LOG_WARNING	=> 2,
	LOG_NOTICE	=> 3,
	LOG_INFO	=> 4,
	LOG_DETAIL	=> 5,
	LOG_DEBUG	=> 6,

	LOG_STDOUT	=> 7,
	LOG_STDERR	=> 8,
	LOG_RETURN	=> 9,
};

# module template pretext:  START
# 
BEGIN {
    use Exporter   ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    # Here: RCS; the q$...$ from RCS act as a quote here(!)
    $VERSION = sprintf "%d.%02d", q$Revision: 1.1 $ =~ /(\d+)/g;

    @ISA         = qw(Exporter);

    # What is exported by default upon the simple "use THISMODULE"
    # (See: camel book, p. 288)
    # It's good manners to have only functions here, no other variables 
    # (putting variables into @EXPORT_OK instead)
    @EXPORT      = qw(  
			LOG_CRIT
			LOG_CRITICAL
			LOG_ERR	
			LOG_ERROR
			LOG_WARN
			LOG_WARNING
			LOG_NOTICE
			LOG_INFO
			LOG_DETAIL
			LOG_DEBUG
			LOG_STDOUT
			LOG_STDERR
			LOG_RETURN
			&synclog
			&log
			&log_set_output
			&log_add_output
			&caller_info
			&parse_log
		);
    %EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],

    # What can be additionally exported, if it's specifically required
    # by means of a "use THISMODULE qw/list_of_requested_exports/"
    # (See: camel book, p. 288)
    # In particular, all exported package global _variables_ should go here.
    # _Note_: exporting non-function variables is dangerous and should
    #         be carried out carefully and with restraint.
    @EXPORT_OK   = qw(
			$loglevel
			$loglevelnames
			$logtime
			$logcaller
			$loginfo
			$logstdout
			$logstderr
			$logreturn
			$levels_regexp
			@outs
			@levels
		);
}
our @EXPORT_OK;
our $loglevel=LOG_INFO;	# default loglevel (0..6)
our $loglevelnames=1;	# log the loglevel names ?
our $logtime=1;		# log current timestamp ?
our $logcaller=0;	# log caller file and line
our $loginfo=0;		# ( $0 =~ /([^\/]+)$/ ? $1:'').'['.$$.']'; # current process info
our $logstdout=1;	# log STDOUT
our $logstderr=1;	# log STDERR
our $logreturn=1;

our @levels=qw(CRITICAL ERROR WARNING NOTICE INFO DETAIL DEBUG STDOUT STDERR RETURN);	# level names
our @outs = ( { 'handle'=>*STDERR } );	# default log output is STDERR
our $levels_regexp = join('|',@levels); # export up-to-date level names for log parsing

# function to log data
sub log # severity, message, ...
{
	my $msglevel=shift;
	my $format=shift; # buggy Perl sprintf needs format separately
	$format='' unless defined $format;
	my $data;

	# when forwarding log output, it can contain '%' and should not be ran through 'printf'.
	# TODO: can we find a better solution than this one ?
	if( &parse_log($format) )	{	
		$data = $format;	
	}	else	{
		$format =~ s/%3a/%%3a/g; #fix bug#798445
		$data = sprintf $format,@_;
	}
	my @data = split /\n/,$data;
	foreach my $args( @outs )
	{
		my %v = (
			'level' => $loglevel,
			'names' => $loglevelnames,
			'time' => $logtime,
			'info' => $loginfo,
			'caller' => $logcaller,
			'stdout' => $logstdout,
			'stderr' => $logstderr,
			'return' => $logreturn,
			%{$args} 
			);
		if( 	($msglevel == LOG_STDOUT and $v{'stdout'}) or
			($msglevel == LOG_STDERR and $v{'stderr'}) or
			($msglevel == LOG_RETURN and $v{'return'}) or
			($msglevel <= $v{level}) )
		{
			my $oldh = select $v{'handle'};
#			$|=1;
			foreach my $d (@data)
			{
				unless( &parse_log( $d ) )
				{
					print strftime("%Y-%m-%d %H:%M:%S %z\t", localtime) if $v{time};
					print $levels[$msglevel]."\t" if $v{'names'} and $msglevel>=0 and $msglevel<@levels;
					print $v{'info'}."\t" if $v{'info'};
					print((&caller_info(1) || '(root)')."\t") if $v{'caller'};
				}
				print $d;
				print "\n";
			}
			select $oldh;
		}
	}
	return undef;
}

# try to parse a line as log output
sub parse_log
{
	return () unless $_[0] =~ /(?:(\d+\-\d+\-\d+ \d+:\d+:\d+(?: ([+-]\d{4}))?)\t)?(?:($levels_regexp)\t)(.*)$/;
	my %ret=();
	$ret{'time'}=$1 if defined $1;
	$ret{'zone'}=$2 if defined $2;
	$ret{'level'}=$3 if defined $3;
	my $rest = $4;
	my @rest = split /\t/, $rest, 2; # 3;
	$ret{'text'} = pop @rest;
	$ret{'info'}   = shift @rest if @rest;
#	$ret{'caller'} = shift @rest if @rest;
	return %ret;
}

# function to get info about your caller
sub caller_info # depth
{
	my $depth = defined($_[0]) ?  $_[0]+1 : 1;
	my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash) = caller($depth);
	return defined $subroutine ? "$subroutine:$line" : undef;
}

# add another target for logging
sub log_add_output # named args, at least path or handle are mandatory
{
	my %args = @_;
	unless( defined $args{'handle'} or defined $args{'path'} )
	{
		warn &caller_info()." - neither handle nor path specified for &log_add_output()\n";
		return;
	}
	unless( defined $args{'handle'} )
	{
		local *HANDLE;
		unless( open HANDLE, ($args{'overwrite'} ? '>':'>>').$args{'path'} )
		{
			warn "Cannot open ".$args{'path'}." : $!";
			return;
		}
		HANDLE->autoflush(1);
		$args{'handle'} = *HANDLE;
		$args{'close'} = 1;
	}
	push @outs, {%args};
}

# clear outputs and 
sub log_set_output 
{
	return unless @_;
	foreach my $out ( @outs )
	{	
		&__log_close($out);
	}
	@outs=();
	&log_add_output(@_);
}

# private function to properly close a log
sub __log_close # hash
{
	my $out = shift;
	close $out->{'handle'} if( $out->{'close'} );
	if( $out->{'path'} and $out->{'close'} )
	{
		my $p=$out->{'path'};
		system( "gzip -f \"$p\"" ) and warn "Cannot gzip $p\n"	if $out->{'gzip'};
		system( "bzip2 -f \"$p\"" ) and warn "Cannot bzip $p\n"	if $out->{'bzip2'};
		unlink( $p ) or warn "Cannot unlink $p: $!\n"		if($out->{'unlink'} and -e $p);
	}
}
#sync the log,call this function before reboot;

sub synclog
{
        foreach my $out ( @outs )
        {
		select $out->{'handle'} ;
		$| = 1;
        }

}

# close all open logs on exit
END {
	foreach my $out ( @outs )
	{
		&__log_close($out);
	}
}

1;
