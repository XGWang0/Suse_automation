#!/usr/bin/perl 

use libqainternalperl;

my $str1="foo";
my $str2="foo";
my $str3="bar";
my $str_tmp="";
my $result=$libqainternalperl::FAILED;

libqainternalperl::qa_hello();

#strCompare
if (libqainternalperl::strCompare($str1,$str2)) {
    libqainternalperl::printMessage($libqainternalperl::MSG_PASSED, "comparison with strCompare of $str1 and $str2 returned true");
	print("\n");
    $result=$libqainternalperl::PASSED;
} else {
	libqainternalperl::printMessage($libqainternalperl::MSG_FAILED, "comparison with strCompare of $str1 and $str2 returned false");
}

#strCompare 
if (libqainternalperl::strCompare($str1,$str3)) {
        libqainternalperl::printMessage($libqainternalperl::MSG_FAILED,"comparison with strCompare of $str1 and $str3 returned true\n");
} else {
        libqainternalperl::printMessage($libqainternalperl::MSG_PASSED, "comparison with strCompare of $str1 and $str3 returned false\n");
    $result=$libqainternalperl::PASSED;
}


#createTempFile
if (libqainternalperl::createTempFile(\$str_tmp)) {
	libqainternalperl::printMessage($libqainternalperl::MSG_PASSED,"createTempFile returned true with filehandle >$str_tmp<\n");
    $result=$libqainternalperl::PASSED;
} else {
	libqainternalperl::printMessage($libqainternalperl::MSG_FAILED, "createTempFile returned false and arg has value $str_tmp\n");
}

exit($result);
