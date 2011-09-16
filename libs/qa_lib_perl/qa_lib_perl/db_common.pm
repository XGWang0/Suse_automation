package db_common;
# See man 1 perlmod for the perl module template used here

use strict;
use POSIX qw/ :termios_h strftime /;
use File::Temp qw/ tempfile tempdir /;
use File::Basename qw/basename dirname/;
use warnings;
# Perl mySQL API
use DBI;
BEGIN { push @INC, '/usr/share/qa/lib'; }
use log;
use qaconfig('%qaconf','&get_qa_config');

# module template pretext:  START
# 
BEGIN {
    use Exporter   ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

    # Here: RCS; the q$...$ from RCS act as a quote here(!)
    $VERSION = sprintf "%d.%02d", q$Revision: 1.1 $ =~ /(\d+)/g;

    @ISA	= qw(Exporter);

    # What is exported by default upon the simple "use THISMODULE"
    # (See: camel book, p. 288)
    # It's good manners to have only functions here, no other variables 
    # (putting variables into @EXPORT_OK instead)
    @EXPORT	= qw( &sql_get_connection );
    %EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],

    # What can be additionally exported, if it's specifically required
    # by means of a "use THISMODULE qw/list_of_requested_exports/"
    # (See: camel book, p. 288)
    # In particular, all exported package global _variables_ should go here.
    # _Note_: exporting non-function variables is dangerous and should
    #         be carried out carefully and with restraint.
    @EXPORT_OK	= qw( 
    		$dbc
		$nodb
		$batchmode
		$delete_on_failure
		$die_on_sql_failure
		$cleanup_callback
		$check_locking
		$isolation_level
		$permit_locking
		$transaction_max_ms
		);
}
our @EXPORT_OK;
our $nodb=0;			# no DB writes
our $die_on_sql_failure=1;	# die using &die_cleanly() when a SQL query fails
our $delete_on_failure=0;	# &die_cleanly() will delete inserted data
our $check_locking=0;		# check for locked tables on DB writes
our $isolation_level="READ COMMITTED";	# transaction isolation level, 'READ UNCOMMITTED' | 'READ COMMITTED' | 'REPEATABLE READ' | 'SERIALIZABLE'
our $cleanup_callback;		# function to be called at the end
our $dbc;			# database connection object
our $batchmode=0;
our $permit_locking=1;		# zero to switch off transactions in a thread - for debugging
our $transaction_max_ms=200;	# will warn if a transaction takes miliseconds; set to undef for switching off

sub sql_get_connection() {
    if (!$dbc)	{
	    $dbc=db_common->new();
	    $dbc->validate_account();
    }
    return $dbc->{'dbh'};
}

sub new {	# proto, module
	my ($proto,$module) = @_;
	my $class = ref($proto) || $proto;
	my $self = {};
	#%qaconf=&get_qa_config('',$module) if $module;
	$module .= '_' if $module;

	foreach my $param ( map {"sql_$_"} qw(user pwd host port db) )	{
		#my $key = $module . $param;
		my $key = $param;
		$self->{$param} = ( defined $qaconf{$key} ? $qaconf{$key} : '' );
	}

	&log(LOG_INFO,"qadb settings (read from configuration files): ".
			  ($self->{'sql_host'} ? "host: ".$self->{'sql_host'}.", " : '').
			  ($self->{'sql_db'} ? "database: ".$self->{'sql_db'}.", " : '').
			  "user: ".$self->{'sql_user'}.", password: ***undisclosed***");

	bless($self, $class);
	return $self;
}

#	uses $_->{'sql_db','sql_host','sql_user','sql_pwd'}
#	sets $_->{'dsn','dbh'}
sub validate_account {
	my $self=shift;
	$self->{'dsn'} = "DBI:mysql:".$self->{'sql_db'}.':'.$self->{'sql_host'};
	$self->connect();
}

#	uses to $_->{'dsn','sql_user','sql_pwd'}
#	sets $_->{'dbh'}
sub connect
{
	my $self=shift;
	$self->{'dbh'} = DBI->connect( $self->{'dsn'}, $self->{'sql_user'}, $self->{'sql_pwd'}, { RaiseError => 0, AutoCommit=>0, PrintError=>1 } );
	unless ($self->{'dbh'}) {
		die "ERROR: could not connect to: " . $self->{'dsn'} . ":\n"."$DBI::errstr\n";
	}
	&log(LOG_INFO,"Successfully logged ".$self->{'sql_user'}." into \$dsn = ".$self->{'dsn'});
	$self->update_query("SET SESSION TRANSACTION ISOLATION LEVEL $isolation_level") if $isolation_level;
}



# Establish connection to server (login).
# Result value: $sql_user (upon success). (brutally) Aborts upon error
sub set_user # DBI_connect_string
{
	my $self=shift;

	$self->prompt_dbdata;
	$self->prompt_userdata;
	&log(LOG_INFO,"set_user: Attempting to log in ".$self->{'sql_user'}." to database ".$self->{'sql_db'}." on ".$self->{'sql_host'});
	#validate will bail out if something is wrong
	$self->validate_account;
	return $self->{'sql_user'};
}

sub prompt_dbdata 
{
	my $self=shift;
	for( my $i=0; $i<3; $i++ )	{
		return if $self->{'sql_host'} and $self->{'sql_db'};
		$self->die_cleanly("No hostname/dbname set") if $batchmode;
		print "\n\n\n\tPlease enter your database hostname: ";
		chomp( $self->{'sql_host'} = <STDIN> );
		print "\n\n\tPlease enter your database name: ";
		chomp( $self->{'sql_db'} = <STDIN> );
	}
	$self->die_cleanly("Hostname/dbname not set");
}

sub prompt_userdata {
	my $self=shift;
	for( my $i=0; $i<3; $i++ )	{
		return if( $self->{'sql_user'} );
		$self->die_cleanly("No dbuser/dbpassword set") if $batchmode;
		print "\n\n\n\tPlease enter your database username: ";
		chomp( $self->{'sql_user'} = <STDIN> );
		print "\n\n\tPlease enter your database password: ";
		&stdin_echo_off;
		chomp( $self->{'sql_pwd'} = <STDIN> );
		&stdin_echo_on;
		print "\n";
	}
	$self->die_cleanly("DBuser/DBpass not set");
}

# POSIX::Termios (echo off/on)
our $echo     = ECHO | ECHOK | ICANON;
our $fd_stdin = fileno(STDIN);
our $term     = POSIX::Termios->new();
$term->getattr($fd_stdin);
our $oterm     = $term->getlflag();
our $noecho   = $oterm & ~$echo;

sub stdin_echo_on {
    $term->setlflag($oterm);
    $term->setcc(VTIME, 0);
    $term->setattr($fd_stdin, TCSANOW);
    return;
}

sub stdin_echo_off {
    $term->setlflag($noecho);
    $term->setcc(VTIME, 1);
    $term->setattr($fd_stdin, TCSANOW);
    return;
}



###############################################################################
# enums
###############################################################################

# need to set %enum first to use these functions.
# e.g.
#our %enums = (
#	'architectures'		=> ['archID','arch'],
#	'products'		=> ['productID','product'],
#	'releases'		=> ['releaseID','`release`'],
#	'kernel_branches'	=> ['branchID','branch'],
#	'testsuites'		=> ['testsuiteID','testsuite'],
#	'testcases'		=> ['testcaseID','testcase'],
#	'testers'		=> ['testerID','tester'],
#	'bench_parts'		=> ['partID','part'],
#	'rpm_basenames'		=> ['basenameID','basename'],
#	'rpm_versions'		=> ['versionID','version'],
#	'rpmConfig'		=> ['configID','md5sum'],
#	'hosts'			=> ['hostID','host']
#	);

our %enums;

sub eid # tbl
{
	die("No such table : ".$_[0]) unless $enums{$_[0]};
	return '`'.$enums{$_[0]}->[0].'`';
}

sub ename #tbl
{
	die("No such table : ".$_[0]) unless $enums{$_[0]};
	return '`'.$enums{$_[0]}->[1].'`';
}

sub enum_get_val # tbl, id
{
	my ($self,$tbl,$id)=@_;
	return $self->scalar_query('SELECT '.&ename($tbl)." FROM `$tbl` WHERE ".&eid($tbl).'=? LIMIT 1',$id);
}

sub enum_get_id # tbl, val
{
	my ($self,$tbl,$val)=@_;
	return $self->scalar_query('SELECT '.&eid($tbl)." FROM `$tbl` WHERE ".&ename($tbl).'=? LIMIT 1',$val);
}

sub enum_insert_id # tbl, val
{
	my ($self,$tbl,$val)=@_;
	$self->update_query("INSERT INTO `$tbl`(".&ename($tbl).') VALUES (?)',$val);
	return $self->get_new_id();
}

sub enum_get_id_cond # tbl, val, insert
{
	my ($self,$tbl,$val,$insert)=@_;
	my $id=$self->enum_get_id($tbl,$val);
	return $id if defined $id or !$insert;
	$id=$self->enum_insert_id($tbl,$val);
	push @{$self->{'inserted_enums'}},[$tbl,$id];
	return $id;
}

sub enum_get_id_or_insert # tbl, val
{	return $_[0]->enum_get_id_cond($_[1],$_[2],1);	}

sub enum_delete_id # tbl, id
{	
	my ($self,$tbl,$id)=@_;
	$self->update_query("DELETE FROM `$tbl` WHERE ".&eid($tbl).'=? LIMIT 1',$id);
}

sub enum_list_vals # tbl
{	return $_[0]->vector_query('SELECT DISTINCT '.&ename($_[1]).' FROM `'.$_[1].'`');	}

sub enum_undo_all_inserts
{
	my $self=shift;
	return unless $self->{'inserted_enums'};
	&log( LOG_INFO, 'Deleting '.(0+@{$self->{'inserted_enums'}})." newly inserted enums" );
	my @enums = @{$self->{'inserted_enums'}};
	my %tables = map { ${$_->[0]} => 1 } @enums;
	$self->TRANSACTION(keys %tables);
	foreach my $i (@enums)
	{
		my ($tbl, $id) = @$i;
		&log( LOG_INFO, "\tDeleting $id from $tbl");
		$self->enum_delete_id($tbl,$id);
	}
	$self->TRANSACTION_END;
}

###############################################################################
# lowlevel DB stuff, cleanup
###############################################################################

use Time::HiRes('gettimeofday');
our ($t1,$t2);
sub TRANSACTION
{
	my $self=shift;
	&log(LOG_ERROR,"Previous transaction not finished") if $self->{'locks'};
	$check_locking=1;
	$self->{'locks'} = { map {lc($_)=>1} @_ };
	my $ret;
	$ret=$self->update_query('LOCK TABLES '.join(',',map { "`$_` WRITE"} @_)) if $permit_locking;
	($t1,$t2)=gettimeofday;
	$self->{'transaction_queries'}=[];
	return $ret;
}

sub TRANSACTION_END
{	
	my $self=shift;
	my @tbl = keys %{$self->{'locks'}};
	$self->commit();
	my($s1,$s2)=gettimeofday;
	$self->update_query('UNLOCK TABLES') if $permit_locking;
	my $delta = 1000*($s1-$t1)+0.001*($s2-$t2);
	if( $transaction_max_ms and @tbl and $delta > $transaction_max_ms )	{
		&log(LOG_WARN,"Transaction on %s finished after $delta ms, queries: %s",
			join(',',@tbl),
			join(' | ',@{$self->{'transaction_queries'}}) );
	}
}

sub get_new_id
{	return $_[0]->{'dbh'}->last_insert_id(undef,undef,undef,undef);	}

sub insert_query
{
	my $self=shift;
	return 1 if $nodb;
	my $rows=$self->exec_statement(@_);
	return $rows ? $self->get_new_id() : undef;
}

sub update_query
{
	my $self=shift;
	return 1 if $nodb;
	my $stat=$self->exec_statement(@_);
	return $stat ? $stat->rows : undef;
}

sub matrix_query
{
	my $self=shift;
	my $stat=$self->exec_statement(@_);
	return $stat ? $stat->fetchall_arrayref() : undef;
}

sub vector_query
{
	my $self=shift;
	my $stat=$self->exec_statement(@_);
	return undef unless $stat;
	my $ret=$stat->fetchall_arrayref([0]);
	return map {$_->[0]} @$ret;
}

sub row_query
{
	my $self=shift;
	my $stat=$self->exec_statement(@_);
	return undef unless $stat;
	my @ret=$stat->fetchrow_array();
	$stat->finish();
	return @ret;
}

sub scalar_query
{	
	my $self=shift;
	return ($self->row_query(@_))[0];	
}

sub sql_error
{
	my ($self,$message)=@_;
	&log($die_on_sql_failure ? LOG_CRIT : LOG_ERR, '%s', ($self->{'dbh'}->errstr)."\n$message");
	$self->die_cleanly() if $die_on_sql_failure;
}

sub exec_statement
{
	my $self=shift;
	my $sql=shift;
	if( $check_locking )	{
		if( $sql =~ /(update|insert into|delete from)\s+(\w+)/i )	{
			&log(LOG_ERROR, "Table $2 not locked for '%s'",$sql) unless $self->{'locks'}->{lc $2};
		}
		# log transaction queries
		push @{$self->{'transaction_queries'}}, $sql;
	}
	my $message='SQL: '.join(' | ',$sql,map {defined $_ ? $_:'<NULL>'} @_);
	&log(LOG_DEBUG, "%s", $message);
	for(my $reconnect = 0; $reconnect<2; $reconnect++)	{
		$self->{'stat'}=undef;
		if( $self->{'dbh'} )	{
			$self->{'stat'}=$self->{'dbh'}->prepare_cached($sql);
		}
		if( $self->{'stat'} and $self->{'stat'}->execute(@_) )	{
			return $self->{'stat'};
		}
		if( $self->{'dbh'} and $self->{'dbh'}->{'mysql_errno'} != 2006 )	{
			$self->sql_error($message);
			return undef;
		}
		&log(LOG_WARN, "Connection lost, trying to reconnect.");
		$self->{'dbh'}->disconnect() if $self->{'dbh'};
		sleep 1;
		$self->connect();
	}
	$self->die_cleanly("Reconnect failed, giving up");
	return undef;
}


sub commit
{	
	my $self=shift;
	delete $self->{'locks'};
	return unless $self->{'dbh'};
	&log(LOG_DEBUG,"COMMIT");
	unless($self->{'dbh'}->commit())	{
		unless( $self->{'dbh'}->{'mysql_errno'} == 2006 )	{
			$self->sql_error('Cannot commit');
		}
		&log(LOG_ERROR, "Connection lost before transaction committed");
		$self->{'dbh'}->disconnect();
		sleep 1;
		$self->connect();
	}
}

sub rollback
{	
	my $self=shift;
	return unless $self->{'dbh'};
	&log(LOG_WARNING,"ROLLBACK");
	unless( $self->{'dbh'}->rollback() )	{
		unless( $self->{'dbh'}->{'mysql_errno'} == 2006 )	{
			&log(LOG_CRITICAL, "Cannot rollback: %s", $self->{'dbh'}->errstr);
			die;
		}
		&log(LOG_WARN, "Connection lost, trying to reconnect.");
		$self->{'dbh'}->disconnect();
		sleep 1;
		$self->connect();
	}
	delete $self->{'locks'};
}

sub tidy_up {
	my $dbh = $_[0]->{'dbh'};
	if( $dbh )
	{
		$dbh->disconnect();
		delete $_[0]->{'dbh'};
	}
}

sub die_cleanly
{
	my $self=shift;
	&log(LOG_CRIT,@_) if @_;
	$self->{'stat'}->finish() if $self->{'stat'};
	if( $self->{'dbh'} && $delete_on_failure )
	{
		$self->rollback();
		$cleanup_callback->($self) if $cleanup_callback;
		$self->enum_undo_all_inserts();
	}
	$self->tidy_up();
#	$self->remove_tmp_files();
	die;
}

sub md5sum # filename
{
	my ($self,$fname) = @_;
	return undef unless -r $fname;
	my $md5sum = `md5sum "$fname" | cut -d\\  -f1`;
	chomp $md5sum;
	return $md5sum;
}



1;
# EOF
