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
	# expected $prod is:
	#    3.0.58-0.9-default;SLES11(x86_64)VERSION=11PATCHLEVEL=3
	#    3.7.1-1-desktop;openSUSE12.3Beta1(x86_64)VERSION=12.3CODENAME=DartmouthBeta1-Kernel\r
	if( $prod =~ /^([\w\.\-\+_]+);(SLES4SAP|[[:alpha:]]+|openSUSE[\d\.]+\w*)([\dSP\.]+)?(\(([\w\-]+)\))?VERSION=/ )
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
