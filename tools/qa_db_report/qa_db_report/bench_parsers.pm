# ****************************************************************************
# Copyright © 2011 Unpublished Work of SUSE. All Rights Reserved.
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

package bench_parsers;
# This package contains benchmark parsers.
# This should change in the future, and individual parsers should go to the ctcs2 stubs, making this library obsolete.
# But at the moment they are still here.

# See man 1 perlmod for the perl module template used here


use strict;
use warnings;

BEGIN {
    use Exporter();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
    $VERSION = sprintf "%d.%02d", q$Revision: 1.1 $ =~ /(\d+)/g;
    @ISA         = qw(Exporter);
    @EXPORT      = qw(
        &parse_openssl
        &parse_dbench
        &parse_bonnie
        &parse_siege
        &parse_libmicro
        &parse_specweb
        &parse_sysbench
        &parse_interbench
        &parse_reaim
        &parse_aim7
        &parse_lmbench
        &parse_tiobench
        &parse_kernbench
	&parse_hazard
    );
    %EXPORT_TAGS = ( );
    @EXPORT_OK   = ();
}

our @EXPORT_OK;
our %part_id = ();


###############################################################################################################################

# benchmark parser section
# one parser section per benchmark
# arguments: open filehandle with data
# returns: array ( $key1, $number1, $key2, $number2, ... )
# key conventions: semicolon-separated strings, 
#  first one is used to make X axis and should start with a number for line graphs

sub parse_openssl
{
    my ($file)=@_;
    my @results=();

    my ($size, $test, $frame, $val, $optype);
    while( my $row=<$file> )      {
        if ($row =~ /Doing (.+?)('s)?\W+for (\d+)s: (\d+) (.+?)\W+/) {
            ($test,$frame,$val)=($1,$3,$4);
            $test =~ s/[ '()-]+/ /g;
            if ($test =~ /(\d+) (\w+)? (\w+)? (\w+)?/) {
                $test="$4";
                $size="$1";
                $optype="$3";
                $optype =~ s/(private|sign)/signs/;
                $optype =~ s/(public|verify)/verifs/;
            } elsif ($test =~ /(\d+) (\w+)? (\w+)?/) {
                $test="$3";
                $size="$1";
                $optype="ops";
            }
            $test =~ s/\W+/_/g;

            push @results, "keysize:$size;algorithm:$test;$optype/s";
            push @results, sprintf "%.2f", $val/$frame;
        } elsif ($row =~ /^Doing (.+?)('s)?\W+for (\d+)s on (\d+) size blocks: (\d+)/) {
            ($test,$frame,$size,$val)=($1,$3,$4,$5);
            $test =~ s/[ '()-]+/_/g;

            push @results, "blocksize:$size;algorithm:$test;kB/s";
            push @results, sprintf "%.2f", ($val/$frame*$size)/1024;
        }
    }

    return @results;
}


sub parse_dbench
{
    my ($file)=@_;
    my @results=();

    while( my $row=<$file> )
    {
#        print "Row.\n";
        next unless $row =~ /Throughput\s+([\d\.]+)\s*MB\/sec(\s*\(sync open\)\s*)?\s+(\d+)\s+procs/;
        my ($mbps,$sync,$procs)=($1,$2,$3);
        $sync = $sync ? 1 : 0;
        my $header = "processes=$procs; sync=$sync; MB/s";
        push @results, $header, $mbps;
    }
    return @results;
}

sub parse_bonnie
{
    my ($file)=@_;
    my @results=();
    while( my $row=<$file> )
    {
#        print "1 $row\n";
        next unless $row =~ s/^<TR>//;
#       print "2\n";
        my @data = map { $row =~ s#<TD>(.+?)</TD>##i; $1 } (0 .. 13);
        $data[1] =~ /(.+?) \* (.+?)/;
        splice @data, 1, 1, $1, $2;
        my( $host, $dbsize, $volumes, $putc, $putc_cpu, $blockwrite, $blockwrite_cpu, $rewrite, $rewrite_cpu, $getc, $getc_cpu, $blockread, $blockread_cpu, $seeks, $seeks_cpu ) = @data;
        my $prefix=$dbsize*$volumes." MB;";
        push @results, "$prefix putc; kB/s", $putc;
        push @results, "$prefix putc CPU; %", $putc_cpu;
        push @results, "$prefix blockwrite; kB/s", $blockwrite;
        push @results, "$prefix blockwrite CPU; %", $blockwrite_cpu;
        push @results, "$prefix rewrite; kB/s", $rewrite;
        push @results, "$prefix rewrite CPU; %", $rewrite_cpu;
        push @results, "$prefix getc; kB/s", $getc;
        push @results, "$prefix getc CPU; %", $getc_cpu;
        push @results, "$prefix blockread; kB/s", $blockread;
        push @results, "$prefix blockread CPU; %", $blockread_cpu;
        push @results, "$prefix seeks; 1/s", $seeks;
        push @results, "$prefix seeks CPU; %", $seeks_cpu;
    }
    return @results;
}

sub parse_siege
{
    my ($file)=@_;
    my @results=();
    my $threads='?';
    my @keywords=( 'Availability', 'Transaction rate', 'Response time' );
    my $lnr=0;
    while( my $row=<$file> )
    {
	    $lnr++;
        chomp($row);
        if( $row =~ /^\*\* Preparing (\d+) concurrent users for battle.$/ )
        {
            $threads=$1;
            next;
        }
        foreach my $keyword (@keywords)
        {
            next unless $row =~ /^$keyword:\s+([\d\.]+) ([\w\/%]*)/;
	    print STDERR "$lnr: '$1' '$2' '$row'\n";
            push @results, "$threads threads; ".(lc $keyword).($2 ? "; $2" : ''), $1;
        }
    }
    return @results;
}

sub parse_libmicro
{
    my ($file)=@_;
    my @results=();
    my @keywords=( 'mean', 'median', 'stddev' );
    my $name;

    while( my $row=<$file> )
    {
	if ( $row =~ /([\w]+) +\d+ +\d+ +[\d.]+ +\d+ +\d+ +\d+/ )
	{
	    $name = $1;
	    next;
	}
        foreach my $keyword (@keywords)
        {
            next unless $row =~ /# *$keyword *([\d.]+).*/;
#             print "HEADER: test=$name; value=$keyword; usecs/call\n";
#             print "VALUE: $1\n";
            push @results, "test=$name; $keyword; usecs/call", $1;
        }
    }
    return @results;
}

sub parse_specweb
{
    my ($file)=@_;
    my @results=();
    my ($connections, $conforming, $SPECweb99, $opspsec, $opspsecploadgen, $msecpop) = (0, 0, 0, 0, 0.0, 0.0);

    while( my $row=<$file> )
    {
	if ( !$SPECweb99 && $row =~ /RESULTS +\| +(\d+) +\| +(\d+) +\| +([\d.]+) +\| +([\d.]+)/ )
	{
	    $SPECweb99 = $1;
	    $opspsec = $2;
	    $opspsecploadgen = $3;
	    $msecpop = $4;
	}
	if ( !$connections && $row =~ /SIMULTANEOUS.+\| +(\d+) +\| +\d+ +\| +\d+ +\| +\d+ +\( *([\d.]+)\%\)/ )
	{
	    $connections = $1;
	    $conforming = $2;
	}
	if ( $SPECweb99 && $connections ) { # found everything?
	    push @results, "connections=$connections; ; SPECweb99", $SPECweb99;
	    push @results, "connections=$connections; ; ops/sec", $opspsec;
	    push @results, "connections=$connections; ; ops/sec/loadgen", $opspsecploadgen;
	    push @results, "connections=$connections; ; msec/op", $msecpop;
	    push @results, "connections=$connections; ; % conforming", $conforming;
# 	    print "@results\n";
            $SPECweb99 = 0; # next...
	    $connections = 0;
	}
    }
    return @results;
}

sub parse_sysbench
{
    my ($file)=@_;
    my @results=();
    my @keywords=( 'min', 'max', 'avg', 'total time', 'total number of events', 'total time taken by event execution' );
    my @sqlkeywords=( 'transactions', 'deadlocks', 'read/write requests', 'other operations' );
    my $threads=0;
    my $mysqltest=0;

    while( my $row=<$file> )
    {
	if ( $row =~ /Performing (\w+) test/ )
        {
            $mysqltest = ($1 =~ "oltp");
        }
	if ( $row =~ /Number of threads: +(\d+)/ )
	{
	    $threads = $1;
	    next;
	}

        foreach my $keyword (@keywords)
        {
            next unless $row =~ / +$keyword: +([\d.]+)+(s|$)/;
            push @results, "threads=$threads; $keyword; s", $1;
        }
        if ( $mysqltest == 1 )
        {
            foreach my $keyword (@sqlkeywords)
            {
                next unless $row =~ / +$keyword: + \d+ +\(([\d.]+) per sec.\)/;
                push @results, "threads=$threads; $keyword; per sec.", $1;
            }
        }
    }
    return @results;
}

sub parse_interbench
{
    my ($file)=@_;
    my @results=();
    my $loadname;

    while( my $row=<$file> )
    {
	if ( $row =~ /--- Benchmarking simulated cpu of (\w+) in the presence of simulated ---/ )
	{
	    $loadname = $1;
	    next;
	}
        if ( $row =~ /^([\w]+)\s+[\.\d]+\s+\+\/-\s+[\.\d]+\s+([\.\d]+)\s+([\.\d]+)\s+([\.\d]+)\s*$/ )
        {
            if ( !$loadname )
            {
                $loadname = "unknown";
            }
            push @results, "$1; $loadname; Latency (ms)", $2;
            push @results, "$1; $loadname; % CPU", $3;
            push @results, "$1; $loadname; % Deadlines", $4;
        }
    }
    return @results;
}

sub parse_reaim
{
    my ($file)=@_;
    my @results=();

    while( my $row=<$file> )
    {
        if ( $row =~ /([\d]+) +([.\d]+) +([.\d]+) +([.\d]+) +([.\d]+) +([.\d]+) +([.\d]+) +([.\d]+) +(\d+)/ )
        {
            push @results, "numforked=$1; ; Parent time", $2;
            push @results, "numforked=$1; ; Child sysTime", $3;
            push @results, "numforked=$1; ; Child UTime", $4;
            push @results, "numforked=$1; ; Jobs per minute", $5;
            push @results, "numforked=$1; ; Jobs/min/child", $6;
            push @results, "numforked=$1; ; Std_dev time", $7;
            push @results, "numforked=$1; ; Std_dev percent", $8;
            push @results, "numforked=$1; ; JTI", $9;
        }
    }
#     print @results;
    return @results;
}

sub parse_aim7
{
    my ($file)=@_;
    my @results=();

    while( my $row=<$file> )
    {
        if ( $row =~ /^(\d+)\s+(\d+\.\d+)\s+(\d+)\s+(\d+.\d+)\s+(\d+.\d+)\s+(\d+.\d+)/ )
        {
            push @results, "Tasks=$1; ; Jobs/Minute", $2;
            push @results, "Tasks=$1; ; Job Timing Index", $3;
            push @results, "Tasks=$1; ; Real Time(sec)", $4;
            push @results, "Tasks=$1; ; CPU Time(sec)", $5;
            push @results, "Tasks=$1; ; Jobs/Second/Task", $6;
        }
        elsif ( $row =~ /^\s+(\d+)\s+(\d+\.\d+)\s+(\d+)\s+(\d+.\d+)\s+(\d+.\d+)\s+(\d+.\d+)\s+(\w+)/ )
        {
            push @results, "Tasks=$1; ; Jobs/Minute", $2;
            push @results, "Tasks=$1; ; Job Timing Index", $3;
            push @results, "Tasks=$1; ; Jobs/Minute/Task", $4;
            push @results, "Tasks=$1; ; Real Time(sec)", $5;
            push @results, "Tasks=$1; ; CPU Time(sec)", $6;
        }

    }
#   print @results;
    return @results;
}


sub parse_lmbench
{
    my @headers  = ( undef, 'Processor, Processes', 'Context switching', '\*Local\* Communication latencies in microseconds', 'File & VM system latencies in microseconds',
        '\*Local\* Communication bandwidths in MB\/s', 'Memory latencies in nanoseconds' );
    my @sections = ( undef, 'processor / processes', 'context switching', 'communication latencies', 'system latencies', 'communication bandwidth', 'memory latencies');
    my @units    = ( undef, 'us', 'us', 'us', 'us', 'MB/s', 'ns' );
    my @columns  = ( undef,
                    [ map { $_.'; times'} ('MHz', 'null call', 'null I/O', 'stat', 'open/close', 'select TCP', 'signal install', 'signal catch', 'fork/exit', 'fork/execve', 'fork/sh') ],
                    [ map { 'processes='.$_->[0].', size='.$_->[1].'k; ctxsw times' } ([2,0],[2,16],[2,64],[8,16],[8,64],[16,16],[16,64]) ],
                    [ map { $_.'; latency' } ('ctxsw','pipe','socket','UDP','RPC/UDP','TCP','RPC/TCP','connect') ],
                    [ map { $_.'; latency' } ('create 0K','delete 0K','create 10K','delete 10K','mmap','protection fault','page fault') ],
                    [ map { $_.'; bandwidth' } ('pipe','socket','TCP','file reread','mmap reread','bcopy libc','bcopy hand','mem read','mem write')],
                    [ map { $_.'; latency' } ('MHz', 'L1', 'L2', 'main mem') ] );
    my (@first,@last);
    my ($file)=@_;
    my @results=();
    my ($section,$subsec,$column)=(0,0,0);
    my $rowcount;
    my @data;
    my $number_re='[\d\.\+\-e]';

    while( my $row=<$file> )
    {
        my $finish=0;

        # detect section headers
        for( my $i=1; $i<@headers; $i++ )
        {   
            if( $row =~ ('^'.$headers[$i].'.*') )
            {
                $section=$i;
                ($subsec,$column)=(0,0);
                $finish=1;
                last;
            }
        }
        next if $finish or !$section;
        if( $subsec==0 )
        {
            # table headers - skip, use hardcoded values instead
            $subsec=1 if $row=~/^-+\s*$/;
        }
        elsif( $subsec==1 )
        {
            if( $row =~ /^(\-+\s*)+$/ )
            {
                # detect field begins & ends
                my @chars = split //, $row;
                my $flag=0;
                (@first,@last)=();
                for( my $i=0; $i<@chars; $i++ )
                {
                    if($flag==0 and $chars[$i] eq '-')
                    {
                        $flag=1;
                        push @first,$i;
                    }
                    elsif($flag==1 and $chars[$i] eq ' ')
                    {
                        $flag=0;
                        push @last,$i;
                    }
                    last if @last>=(2+@{$columns[$section]});
                }
                push @last,0+@chars if $flag==1;
                $subsec=2;
                $rowcount=0;
                @data=();
            }
        }
        elsif( $subsec==2 )
        {
            if( $rowcount>=3 )
            {
                # insert key + average of values to the results
                for( my $i=0; $i<@data; $i++ )
                {
                    next unless @{$data[$i]};
                    my @numbers = map { $_ =~ "($number_re+)" ? $1 : () } @{$data[$i]};
                    next if $columns[$section]->[$i] =~ /\WMHz/;
                    push @results,$columns[$section]->[$i].'; '.$units[$section];
                    if( @numbers )
                    {
                        my ($prec1,$prec2,$sum)=(0,0,0);
                        foreach my $num (@numbers)
                        {
                            next unless $num =~ /(\d+)((e[+-]|\.)(\d+))/;
                            $sum += $num;
                            $prec1 = length($1) if length($1)>$prec1;
                            $prec2 = length($4) if length($4)>$prec2;
                        }
                        push @results, sprintf( "%*.*f",$prec1,$prec2,(eval( join '+',@numbers ) / @numbers));    
                    }
                    else
                    {   push @results, $data[$i]/$rowcount; }
                }
                $subsec=3;
            }
            else
            {
                # count row number + sum of column values (for the average)
                $rowcount++;

                # well, because of broken result tables (mainly the last one), we try to look a few characters around
                if( $rowcount==1 )
                {
                    my @chars = split //, $row;
                    for( my $i=2; $i<@last; $i++ )
                    {
                        while($first[$i]>0 and ($chars[$first[$i]-1] =~ $number_re))
                        {   
                            $first[$i]--;
                            $last[$i-1]-- if $i>0 and $last[$i-1]>=$first[$i];
                        }
                    }
                }
                my @row=map {substr $row,$first[$_],$last[$_]-$first[$_]} (2 .. (@last-1));

                # now, finally, the data for average...
                for( my $i=0; $i<@row; $i++)
                {
                    if( defined $data[$i] )
                    {   push @{$data[$i]}, $row[$i];    }
                    else
                    {   $data[$i] = [ $row[$i] ];   }
                }
            }
        }
    }


#    print join "\n",@results;
    return @results;
}

sub parse_tiobench
{
    my ($file)=@_;
    my @results=();
    my $name;

    while( my $row=<$file> )
    {
        if ( $row =~ /(Sequential Reads|Random Reads|Sequential Writes|Random Writes)/ )
        {
          $name = $1;
        }
        if ( $row =~ /\S+ +([\d]+) +([\d]+) +([\d]+) +(\S+) +\S+ +([\d.]+) +([\d.]+) +([\d.]+) +([\d.]+).+/ )
        {
            push @results, "threads=$3; $name size=$1 blocksize=$2; rate (MB/s)", $4;
            push @results, "threads=$3; $name size=$1 blocksize=$2; avglat (ms)", $5;
            push @results, "threads=$3; $name size=$1 blocksize=$2; maxlat (ms)", $6;
            push @results, "threads=$3; $name size=$1 blocksize=$2; % >2 sec", $7;
            push @results, "threads=$3; $name size=$1 blocksize=$2; % >10 sec", $8;
        }
    }
# print @results;
    return @results;
}

sub parse_kernbench
{
    my ($file)=@_;
    my $flag=0;
    my @results=();
    my %k = ( 
        'Elapsed Time' => 'elapsed time; kernbench;',
        'User Time' => 'user time; kernbench;',
        'System Time' => 'system time; kernbench;',
        'Percent CPU' => 'CPU percent; kernbench;',
        'Context Switches' => 'context switches; kernbench;',
        'Sleeps' => 'sleeps; kernbench;'
        );
    while( my $row=<$file> )
    {
        chomp $row;
        $flag=1 if $row =~ /^Elapsed Time/;
        next unless $flag;
        $flag=0 if $row =~ /^\s*$/;
        next unless $row =~ /([\w\s]+) ([\d\.+-]+) \(([\d\.+-]+)\)\s*$/;
        my ($v1,$v2)=($k{$1},$2);
        next unless $v1;
        push @results,$v1,$v2;
    }
    return @results;
}

sub remove_spaces
{
    $_=$_[0];
    s/^\s+//;
    s/\s+$//;
    return $_;
}

# benchmark parser for hazard
sub parse_hazard
{
	my(@hazard_b_result,$logfile);
	$logfile = shift;
	while(<$logfile>) {
		if(/ (\d+) CHO /){
			my $tag_hour = $1;
			my $corrs_crits = <$logfile>;
			my $errors_diags = <$logfile>;
			#print $corrs_crits,"\n","$errors_diags","\n";
			my($corrs,$crits) = $corrs_crits =~ /\s(\d+\scorrs);\s+(\d+\scrits)/;
			my($errors,$diags) = $errors_diags =~ /\s(\d+\serrors);\s+(\d+\sdiags)/;
			map { push @hazard_b_result,"hours=".$tag_hour.";".(split(/ /,$_))[1],(split(/ /,$_))[0] } ($corrs,$crits,$errors,$diags);
		}
	}
	push @hazard_b_result,"hours=0;running",0 if not @hazard_b_result;
	close $logfile;
	return @hazard_b_result;
}
1;

