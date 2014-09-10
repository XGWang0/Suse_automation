#!/usr/bin/perl
my $ip_num = 0;
my $mask_num = 0;
my $net_addr;
my $dev=(split /\s/, `route -n | grep "^0.0.0.0"`)[-1]; #get the main communication device
my $netinfo = `ifconfig2ip $dev`;
if( $netinfo =~ /inet (\w+):(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3}).*Mask:(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})/ ) {
	$ip_num=($2<<24) | ($3<<16) | ($4<<8) | $5;
	$mask_num = ($6<<24) | ($7<<16) | ($8<<8) | $9;   
	my $net_num = $ip_num & $mask_num;
	$net_addr = ($net_num & 0xFF);
	for( my $i=1; $i<=3; $i++) {
		$net_num = $net_num>>8;
		$net_addr = ($net_num & 0xFF) . "." . $net_addr;
	}
}
print $net_addr;
