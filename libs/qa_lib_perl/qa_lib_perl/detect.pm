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

package detect;

use strict;
use warnings;
use log;
use qaconfig;

BEGIN {
	push @INC,"/usr/share/qa/lib",'.';
	use Exporter();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
	@ISA	= qw(Exporter);
	@EXPORT	= qw(
		&read_http_csv
		&check_version
		&read_qadb_products
		&read_qadb_releases
		&read_qadb_architectures
		&compare_versions
		&get_architecture
		&get_location
		&detect_location
		&get_kernel_version
		&parse_base_product
		&get_install_urls
		&get_zypper_urls
		&detect_product
	);
	%EXPORT_TAGS	= ();
	@EXPORT_OK	= ();
}
our @EXPORT_OK;
our %part_id = ();

# base URL for QADB webservice
our $ws_base=$qaconf{qadb_wwwroot}."/versions.php";

# QADB products and releases
our %qadb_products=( map {lc($_)=>$_} (
	(map {"openSUSE$_"} qw(10.1 10.2 10.3 11.0 11.1 11.2 11.3 11.4 11.5 12.0 12.1)),
	(map {("SLES-$_","SLED-$_","SLERT-$_")} qw(10 10-SP1 10-SP2 10-SP3 11 11-SP1 11-SP2)),
	(map {"SLES4SAP-$_"} qw(11 11-SP1 11-SP2)),
	qw(SLES-8-SP4 SLES-9 SLES-9-SP3 SLES-9-SP4)
	));
our %qadb_releases=( map {lc($_)=>$_} (
	(map {("alpha$_","beta$_","RC$_")} (1..5)),
	qw(GMC GM internal maintained RC6 beta6 beta7 beta8 beta9 beta10)
	));


sub compare_versions # v1, v2
{
	my ($v1,$v2)=@_;
	$v1='0.0' unless defined $v1;
	$v2='0.0' unless defined $v2;
	my @v1=split /\./,$v1;
	my @v2=split /\./,$v2;
	return $v1[0]<=>$v2[0] if $v1[0]<=>$v2[0];
	$v1[1]=0 unless defined $v1[1];
	$v2[1]=0 unless defined $v2[1];
	return $v1[1]<=>$v2[1];
}

sub read_http_csv # $url, $is_list
{
	my ($url,$is_list)=@_;
	my @data=();
	open my $fh, "curl -L --connect-timeout 5 --max-time 5 \"$url\" 2>/dev/null |" or return undef;
	while( my $row = <$fh> )
	{
		chomp $row;
		push @data, $is_list ? $row : [ split /\t/, $row ];	
	}
	close $fh;
	return @data;
}

# checks the script version against server
# warns when newer version exists or error occurs
# quits when the version is older than the oldest allowed
sub check_version # name, version
{
	my ($name,$version)=@_;
	return 0 unless defined $name and defined $version;
	my $warn="Cannot read the version information over network";
	my @data=&read_http_csv("$ws_base?name=$name",0);
	if( @data )
	{
		$warn="Wrong version information read from server";
		if(defined $data[0]->[1])
		{
			my $cmp = &compare_versions($version,$data[0]->[1]);
			&log( 4, "Newer version of the script $name exists, please upgrade" ) if $cmp<0;
			if(defined $data[0]->[2])
			{
				my $cmp = &compare_versions($version,$data[0]->[2]);
				die "Script $name is totally obsoleted and may not be used anymore, please upgrade\n" if $cmp<0;
			}
			return 1;
		}
	}
	&log(3,$warn);
	return 1;
}

# return value: uname -m, cosmetically modified
# see rd-qa-kernel/scripts/helper/query_archs
# for available architectures
sub get_architecture {

	my $xencap="/proc/xen/capabilities";
	my $xen_prefix="";
	my $architecture=`uname -m`;
	chomp($architecture);
	$architecture =~ s/i[346]86/i586/;

	# check if we are running XEN dom0 or domU
	if ( -r $xencap ) {
		# we are running in xen
		$xen_prefix="xenU-";
		open XENCAP, $xencap;
		while (<XENCAP>) {
			# "grep", using $_
			if (m/control_d/) {
				# it's actually the controlling domain (i.e. dom0)
				$xen_prefix="xen0-";
				last;	# one match is enough
			}
		}
		$architecture="${xen_prefix}${architecture}";
	}
	return $architecture;
}


#gets system location from qaconfig, or tries to detect it
sub get_location
{
	my $loc = $qaconf{location};

	return $loc ? $loc : &detect_location;
}



# gets the system location (cz|de|cn|us) from ifconfig output
# returns: cz|de|cn|us
# Only use this directly if you really know what you're doing!!!
sub detect_location
{
	my $loc =`/usr/share/qa/tools/location_detect_impl.pl`;
	chomp $loc;
	$loc = undef unless $loc;

	return $loc;
}

sub get_kernel_version
{	
	my $kern=`uname -r`;	
	chomp($kern);
	return $kern;
}

our $arch_re="(i\\d86|ppc(64)?|s390x?|ia64|x86[_-]64)";

# replacement of subroutine parse_suse_release
# return type,version,subversion,'',arch
sub parse_base_product
{
        use XML::Simple;
        my $baseproduct = "/etc/products.d/baseproduct";
	if( -e $baseproduct ) {
		my $xmlres = XMLin($baseproduct);
		&log( LOG_DEBUG, "/etc/products.d/baseproduct reading: type $xmlres->{'name'}, version $xmlres->{'version'}, subversion $xmlres->{'patchlevel'}, arch $xmlres->{'arch'}" );
	        return ( $xmlres->{'name'}, $xmlres->{'version'}, $xmlres->{'patchlevel'}, '', $xmlres->{'arch'} );
	} 
	return ('','','','','');
}

sub get_install_urls
{	
	my $file="/var/lib/YaST2/install.inf";
	return () unless -r $file;
	my @ret=`grep -i '\\(repourl\\|serverdir\\)' $file|cut -d\\  -f2`;
	@ret = map {s/\?.*$//;$_} @ret;
	&log( LOG_DEBUG, "URLs from /var/lib/YaST2/install.inf: " . join ', ', @ret );
	return @ret;
}

sub get_zypper_urls
{
	my $zypper_u = system("zypper sl -u >/dev/null 2>/dev/null");
	my $command = 'LANG=C zypper sl'.($zypper_u==0 ? ' -u':'').' | sed \'s/$/|/\' | awk \'BEGIN {RS="|"};/:\/\// { print $0 }\'';
	my @urls = `$command`;
	my @ret = ();
	foreach my $url (@urls)
	{
		chomp $url;
		$url =~ s/^\s+//;
		$url =~ s/\s+$//;
		push @ret,$url unless $url =~ /^URI$/;
	}
#	@urls = grep {!/inst.internal|(?:dist|repos|download)\.suse\.de/} @urls;
	&log( LOG_DEBUG, "Zypper URLs detected : ".join(', ',@ret));
	return @ret;
}

# gets URL - from `zypper sl -u` or install.inf or some other source
# returns ( type, version, subversion, release, arch )
sub guess_product_from_url # URL
{
	my $url=shift;
	my ($type, $version, $subversion, $release, $arch, $build_nr)=('','','','','','');

	# fix mallformed releases - see https://bugzilla.novell.com/show_bug.cgi?id=648959
	$url =~ s/(alpha|beta|RC)[ -_](\d+)/$1$2/ig;

	# SLE(S|D|RT)
	if( 
		$url =~ /\Wsles\W+(\d+)/i or 
		$url =~ /\Wenterprise\W+(?:server|desktop)\W+(\d+)/i or 
		$url =~ /full-sle(\d+)-/ or
		$url =~ /SLES for SAP.* (\d+)/ or
		$url =~ /SLE-(\d+)-(?:Server|Desktop)/i
	)
	{
		$version = $1;
		if( $url =~ /SLES for SAP/ )
		{	$type = 'SLES4SAP';	}
		elsif( $url =~ /(?:sle|\W)rt\W/i )
		{	$type = 'SLERT';	}
		elsif( $url =~ /sled|desktop/i )
		{	$type = 'SLED';		}
		else
		{	$type = 'SLES';		}
		$subversion = '';
		$subversion = $1 if $url =~ /sp\s*(\d+)/i or $url =~ /service\s*pack\s*(\d+)/i or $url =~ /[\.\-](\d)\W/;
	}
	# openSuSE
	elsif( $url =~ /\Wopensuse(?:-?(?:CD|DVD))?\W*(\d+)(?:\.(\d+))?/i or $url =~ /full-(\d+)(?:\.(\d+))?-/ )
	{
		$version = $1;
		$subversion = $2 if defined $2;
		$type = 'openSUSE';
	}
	my $releases_regexp = join '|',keys %qadb_releases;
	if( $url =~ /($releases_regexp)/i )
	{	
		my $rel = $1;
		$release = $qadb_releases{lc $rel};
	}
	elsif( $url =~ /build(\d+)/i )
	{	$release = 'buildXXX';
		$build_nr = $1;
	}
#	else
#	{	$release = 'GA';	}
	$arch=$1 if $url =~ /$arch_re/i;
	$release='maintained' if $url =~ /https?:\/\/(you|update).suse.de/;
	&log( LOG_DEBUG, "Parsing $url: type=$type, version=$version, subversion=$subversion, release=$release, arch=$arch" );
	return ($type, $version, $subversion, $release, $arch, $build_nr);
}

# reads QADB products over HTTP
sub read_qadb_products
{	return &read_http_csv("$ws_base?what=product",1);	}

# reads QADB releases over HTTP
sub read_qadb_releases
{	return &read_http_csv("$ws_base?what=release",1);	}

# reads QADB architectures over HTTP
sub read_qadb_architectures
{	return &read_http_csv("$ws_base?what=arch",1);	}

# initializes %qadb_products and %qadb_releases with current data
sub qadb_read_data
{
	my @products = &read_qadb_products();
	unless( @products )	{
		&log( LOG_ERR, "Error fetching QADB products" );
		return;
	}
	my @releases = &read_qadb_releases();
	unless( @releases )
	{
		&log( LOG_ERR, "Error online fetching current QADB releases" );
		return;
	}
	%qadb_products=();
	%qadb_releases=();
	map { $qadb_products{lc $_}=$_; } @products;
	map { $qadb_releases{lc $_}=$_; } @releases;
	&log( LOG_DETAIL, "QADB data read - ".(keys %qadb_products)." products, ".(keys %qadb_releases)." releases." );
}

# selects the most frequent member in the list.
sub best # description, possibilities
{
	my $desc=shift;
	my %votes=();
	foreach my $vote ( grep {length $_} @_)
	{	$votes{$vote} = (defined $votes{$vote} ? $votes{$vote}+1 : 1) if $vote or $vote eq '0';	}
	my @sorted = sort {$votes{$b}<=>$votes{$a}} keys(%votes);
	if( defined $sorted[0] )
	{
		&log( LOG_DEBUG, "Autodetected $desc as ".$sorted[0] );
		return $sorted[0];
	}
	&log( LOG_WARNING, "Not able to find any $desc." );
	return '';
}

# tries to detect product type, version, subversion, release, arch, QADB product
sub detect_product
{
	my %args = (
		'net'=>1,
		@_
		);
	my @data=();
	my ($type, $version, $subversion, $release, $arch, $product, $build_nr);
	my $os_info ;
	my @fields = ( '', 'type', 'version', 'subversion', 'release', 'arch' ,'build_nr');

	# find possible candidates from different sources
	push @data, [ 'SuSE-release', &parse_base_product(), ''];
	push @data, [ '/etc/issue', &guess_product_from_url(`echo -n \$(cat /etc/issue)`) ];
	
	map { our $i=$_; $os_info->{"$fields[$i]"} = &best($fields[$i],map {$_->[$i]} @data) } (1 .. 6);

	my @notfound = @fields;
	map {  $notfound[$_]='' if $os_info->{$fields[$_]} ne '' } (1 .. 6);

	if( join('',@notfound) ne '' ) {
		foreach my $url ( &get_zypper_urls() )	{	
			push @data, [ 'zypper URLs',  &guess_product_from_url($url) ];
		}
		foreach my $url ( &get_install_urls() ) {
			push @data, [ 'install.inf',  &guess_product_from_url($url) ];
		}
		push @data, [ 'uname', '', '', '', '', `echo -n \$(uname -m)` , ''];
		map { our $i=$_; $os_info->{$notfound[$i]} = &best($notfound[$i],map {$_->[$i]} @data) } (1 .. @notfound-1);
	}
	
	($type, $version, $subversion, $release, $arch, $build_nr) = map { $os_info->{$fields[$_]} } (1 .. 6);

	map { $release=$_[4] if $_[4] and $_[4] eq 'maintained' } @data;
	$release = 'GA' unless $release;
	$release = 'buildXXX' if $build_nr;

	# compare with QADB
	my @tries = ();
	if( $type eq 'openSUSE' )
	{	push @tries, $type.$version.(defined $subversion ? ".$subversion":'');	}
	else
	{	push @tries, "$type-$version-SP$subversion", "$type-$version";	}
	&qadb_read_data() if $args{'net'};
	$product='';
	&log( LOG_DEBUG, "QADB products : " . join(', ', keys %qadb_products) );
	&log( LOG_DEBUG, "QADB releases : " . join(', ', keys %qadb_releases) );
	foreach my $try (@tries)
	{	$product=$qadb_products{lc $try} if $qadb_products{lc $try} and !$product;	}
	unless( $product )
	{	
		&log( LOG_ERROR,"No matching product in QADB data for type=$type, version=$version, subversion=$subversion" );
		$product = $tries[0];
	}
	map { &log( LOG_DEBUG, "Results from %s : type '%s', version '%s', subversion '%s', release '%s', arch '%s' ,build_nr '%s'" , @$_ ) } @data;
	&log( LOG_INFO, "Autodetection results: type='$type', version='$version', subversion='$subversion', release='$release', arch='$arch', QADB product = '$product',Build number = '$build_nr'" );
	return ($type, $version, $subversion, $release, $arch, $product,$build_nr) if wantarray;
	return { type=>$type, version=>$version, subversion=>$subversion, release=>$release, arch=>$arch, product=>$product ,build_nr=>$build_nr };
}

1;
