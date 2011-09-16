# This Modul includes the labor-functions from Master-implementation
# 
package Master;
use strict;
use warnings;
use File::Path; 

use IO::File; 
use Time::HiRes qw(gettimeofday);
use XML::Simple;
use POSIX 'strftime';
#use Math::Round;
BEGIN { push @INC, '.', '/usr/share/hamsta/master', '/usr/share/qa/lib'; }
use log;

# Master->write_to_file
#
# takes a key and a value and writes this to a specific file in the default
# directory
# 
sub write_to_file () {
    my $key = shift @_;
    my $content = shift @_;
    my $time_local = time;

    &change_working_dir($Master::backbone->{'master_root'}."/".$key);
    open FH,'>', $Master::backbone->{'master_root'}."/".$key."/".$time_local."_$key";
    print FH "$content \n";
    close FH;
    
    if ($key=~/hwinfo/) { 
        return $time_local;
    }
}

sub change_working_dir() {                                                                            
    # TODO Do not change cwd anymore but just create the directory if it not
    # exists. Rename this function then.
    
    
    my $dir = shift @_;                                                                                  
    &log(LOG_DETAIL,"mkdir -p $dir");
    if ($dir) {                                                                                          
        eval {                                                                                              
            mkpath($dir,0,0755); 
        };                                                                                            
        if ($@) {                                                                                           
            # Fehlgeschlagen                                                                                   
            &log(LOG_ERR, "Creation of $dir failed $@");
        }                                                                                                   
#        chdir $dir;                                                                                         

    } else {                                                                                             
#        chdir "/tmp";                                                                                       
    }                                                                                                    
}

sub process_product($)
{
	my $prod=shift;
	$prod =~ s/SUSE/;SUSE/;
	$prod =~ s/open;SUSE/;openSUSE/;
	$prod =~ s/;SUSELinuxEnterpriseServer/;SLES/;
	$prod =~ s/;SUSELinuxEnterpriseDesktop/;SLED/;
	$prod =~ s/SLESforSAPApplications/;SLES4SAP/;
	return [(split /;/,$prod)[0],'',''] if( $prod =~ /BRANCH/ );
	if( $prod =~ /^([\w\.-]+);(SLES4SAP|[[:alpha:]]+)([\dSP\.]+)?(\(([\w-]+)\))?VERSION=/ )
	{
		my ($base,$major,$sp,$rel,$dom,$build,$arch)=($2,$3,'','','','','');
		$sp 	="SP$1" if $prod =~ /PATCHLEVEL=(\d+)/;
		$major	= $1 if $major =~ /(\d+)SP/;
		$arch	= $1 if $prod  =~ /\(([^\)]+)\)/;
		$rel	= $1 if $prod  =~ /(Alpha\d+|Beta\d+|GMC?|Build\d+|RC\d+|Internal|Maintained)/i;
		$dom	= "xen$1" if $prod  =~ /Dom([A-Z\d]+)/;
		$build	= $1 if $prod  =~ /(Build\d+)/;
		my $product = join '-', grep /\w/, ($base,$major,$sp);
		my $release = join '-', grep /\w/, ($rel,$build);
		my $p_arch  = join '-', grep /\w/, ($dom,$arch);
#		return [$base,$major,$sp,$rel,$dom,$build,$arch];
		return [$product,$release,$p_arch];
	}
	return [$prod,'',''];
}

sub read_xml($) # filename
{
	my $fname = shift;
	my $ret;
	eval { $ret = XMLin( $fname, ForceContent=>1, ForceArray=>[qw(rpm attachment worker logger monitor)], KeyAttr=>[] ); };
	return $ret if $ret;
	&log( LOG_ERR, "Parsing XML '$fname' : $@" );
	return undef;
}

1;
