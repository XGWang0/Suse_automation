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
		&get_kernel_version
		&parse_suse_release
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


# gets the system location (cz|de|cn|us) from ifconfig output
# returns: cz|de|cn|us
sub get_location
{
	my $loc = undef;
	
	if ($qaconf{location} eq '') {
		open IFCONFIG, "/sbin/ifconfig |" or die "Cannot run ifconfig: $!";
		while( my $row=<IFCONFIG> )
		{
#			print $row;
			if( $row =~ /inet addr:(\d+)\.(\d+)\./ )
			{
				if( $1==10 )
				{
					if( $2==10 or $2==11 or $2==0 )
					{   $loc='de'; }
					elsif( $2==20 )
					{   $loc='cz'; }
				}
				elsif( $1==147 ) 
				{   $loc='cn'; }
				elsif( $1==137 or $1==151 ) 
				{   $loc='us'; }
			}
		}
		close IFCONFIG;
	} else {
		$loc = $qaconf{location};
	}

	return $loc;
}

sub get_kernel_version
{	
	my $kern=`uname -r`;	
	chomp($kern);
	return $kern;
}

our $arch_re="(i\\d86|ppc(64)?|s390x?|ia64|x86[_-]64)";

# gets distro info from /etc/SuSE-release
# returns ( type, version, subversion, undef, architecture )
#   type = sles|opensuse
sub parse_suse_release
{
	my( $type, $version, $subversion, $ar ) = ('','','','');
	my $file='/etc/SuSE-release';
	open RELEASE, $file or die "Cannot open $file: $!";
	while( my $row = <RELEASE> )
	{
		if( $row =~ /linux enterprise/i )
		{
			if( $row =~ /desktop/i )
			{	$type = 'SLED';	}
			elsif( $row =~ /RT/i )
			{	$type = 'SLERT';	}	# TODO: check
			else
			{	$type = 'SLES';	}
		}
		elsif( $row =~ /openSUSE/i )
		{   $type = 'openSUSE'; }
		elsif( $row =~ /VERSION\s*=\s*(\d+)(?:\.(\d+))?/i )
		{
			$version = $1;
			$subversion = $2 if defined $2;
		}
		elsif( $row =~ /PATCHLEVEL\s*=\s*(\d+)/i )
		{   $subversion = $1;   }
		elsif( $row =~ /SLES for SAP/ )
		{	$type = 'SLES4SAP';	}

		if( $row =~ /\($arch_re\)/i )
		{   
			$ar = lc $1;
			$ar =~ s/-/_/g;
		}
	}
	close RELEASE;
	&log( LOG_DEBUG, "/etc/SuSE-release reading: type $type, version $version, subversion $subversion, arch $ar" );
	return ( $type, $version, $subversion, '', $ar ); # no release info here
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
	my ($type, $version, $subversion, $release, $arch)=('','','','','');

	# fix mallformed releases - see https://bugzilla.novell.com/show_bug.cgi?id=648959
	$url =~ s/(alpha|beta|RC)[ -_](\d+)/$1$2/ig;

	# SLE(S|D|RT)
	if( 
		$url =~ /\Wsles\W+(\d+)/i or 
		$url =~ /\Wenterprise\W+(?:server|desktop)\W+(\d+)/i or 
		$url =~ /full-sle(\d+)-/ or
		$url =~ /SLES for SAP.* (\d+)/
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
	{	$release = 'buildXXX';	}
#	else
#	{	$release = 'GA';	}
	$arch=$1 if $url =~ /$arch_re/i;
	$release='maintained' if $url =~ /https?:\/\/(you|update).suse.de/;
	&log( LOG_DEBUG, "Parsing $url: type=$type, version=$version, subversion=$subversion, release=$release, arch=$arch" );
	return ($type, $version, $subversion, $release, $arch);
}

# reads QADB products over HTTP
sub read_qadb_products
{	return &read_http_csv("$ws_base?what=products",1);	}

# reads QADB releases over HTTP
sub read_qadb_releases
{	return &read_http_csv("$ws_base?what=releases",1);	}

# reads QADB architectures over HTTP
sub read_qadb_architectures
{	return &read_http_csv("$ws_base?what=architectures",1);	}

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
	my ($type, $version, $subversion, $release, $arch, $product);

	# find possible candidates from different sources
	push @data, [ 'SuSE-release', &parse_suse_release() ];
	foreach my $url ( &get_zypper_urls() )	{	
		push @data, [ 'zypper URLs',  &guess_product_from_url($url) ];
	}
	foreach my $url ( &get_install_urls() ) {
		push @data, [ 'install.inf',  &guess_product_from_url($url) ];
	}
	push @data, [ 'uname', '', '', '', '', `echo -n \$(uname -m)` ];
	push @data, [ '/etc/issue', &guess_product_from_url(`echo -n \$(cat /etc/issue)`) ];
	my @fields = ( '', 'product type', 'product version', 'product subversion', 'product release', 'arch' );

	# find the best candidate
	($type, $version, $subversion, $release, $arch) = map { our $i=$_; &best($fields[$i],map {$_->[$i]} @data) } (1 .. 5);
	map { $release=$_[4] if $_[4] and $_[4] eq 'maintained' } @data;
	$release = 'GA' unless $release;

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
	map { &log( LOG_DEBUG, "Results from %s : type '%s', version '%s', subversion '%s', release '%s', arch '%s'" , @$_ ) } @data;
	&log( LOG_INFO, "Autodetection results: type='$type', version='$version', subversion='$subversion', release='$release', arch='$arch', QADB product = '$product'" );
	return ($type, $version, $subversion, $release, $arch, $product);
}

1;
