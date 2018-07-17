# This file was automatically generated by SWIG
package libqainternalperl;
require Exporter;
require DynaLoader;
@ISA = qw(Exporter DynaLoader);
package libqainternalperlc;
bootstrap libqainternalperl;
package libqainternalperl;
@EXPORT = qw( );

# ---------- BASE METHODS -------------

package libqainternalperl;

sub TIEHASH {
    my ($classname,$obj) = @_;
    return bless $obj, $classname;
}

sub CLEAR { }

sub FIRSTKEY { }

sub NEXTKEY { }

sub FETCH {
    my ($self,$field) = @_;
    my $member_func = "swig_${field}_get";
    $self->$member_func();
}

sub STORE {
    my ($self,$field,$newval) = @_;
    my $member_func = "swig_${field}_set";
    $self->$member_func($newval);
}

sub this {
    my $ptr = shift;
    return tied(%$ptr);
}


# ------- FUNCTION WRAPPERS --------

package libqainternalperl;

*printInfo = *libqainternalperlc::printInfo;
*printError = *libqainternalperlc::printError;
*printWarning = *libqainternalperlc::printWarning;
*printFailed = *libqainternalperlc::printFailed;
*printPassed = *libqainternalperlc::printPassed;
*print = *libqainternalperlc::print;
*cleanup = *libqainternalperlc::cleanup;
*addUser = *libqainternalperlc::addUser;
*delUser = *libqainternalperlc::delUser;
*addToGroup = *libqainternalperlc::addToGroup;
*getUser = *libqainternalperlc::getUser;
*getGroups = *libqainternalperlc::getGroups;
*createFile = *libqainternalperlc::createFile;
*createFileMinsize = *libqainternalperlc::createFileMinsize;
*createTempFile = *libqainternalperlc::createTempFile;
*removeFile = *libqainternalperlc::removeFile;
*lookupFile = *libqainternalperlc::lookupFile;
*writeBinaryFile = *libqainternalperlc::writeBinaryFile;
*writeTextFile = *libqainternalperlc::writeTextFile;
*readTextFile = *libqainternalperlc::readTextFile;
*readTextlineFile = *libqainternalperlc::readTextlineFile;
*readBinaryFile = *libqainternalperlc::readBinaryFile;
*associateService = *libqainternalperlc::associateService;
*checkService = *libqainternalperlc::checkService;
*startService = *libqainternalperlc::startService;
*stopService = *libqainternalperlc::stopService;
*restartService = *libqainternalperlc::restartService;
*openportsOfService = *libqainternalperlc::openportsOfService;
*md5Compare = *libqainternalperlc::md5Compare;
*strCompare = *libqainternalperlc::strCompare;
*strnCompare = *libqainternalperlc::strnCompare;
*associateCmd = *libqainternalperlc::associateCmd;
*runCmd = *libqainternalperlc::runCmd;
*runCmdAs = *libqainternalperlc::runCmdAs;
*runCmdAsync = *libqainternalperlc::runCmdAsync;
*runCmdAsyncAs = *libqainternalperlc::runCmdAsyncAs;
*pidOfCmd = *libqainternalperlc::pidOfCmd;
*killPid = *libqainternalperlc::killPid;
*copyConfig = *libqainternalperlc::copyConfig;
*removeConfig = *libqainternalperlc::removeConfig;
*checkConfig = *libqainternalperlc::checkConfig;
*printMessage = *libqainternalperlc::printMessage;
*qa_hello = *libqainternalperlc::qa_hello;

# ------- VARIABLE STUBS --------

package libqainternalperl;

*DFLTBUFFERSIZE = *libqainternalperlc::DFLTBUFFERSIZE;
*PASSED = *libqainternalperlc::PASSED;
*FAILED = *libqainternalperlc::FAILED;
*ERROR = *libqainternalperlc::ERROR;
*MSG_WARN = *libqainternalperlc::MSG_WARN;
*MSG_ERROR = *libqainternalperlc::MSG_ERROR;
*MSG_INFO = *libqainternalperlc::MSG_INFO;
*MSG_FAILED = *libqainternalperlc::MSG_FAILED;
*MSG_PASSED = *libqainternalperlc::MSG_PASSED;
*qa_internal_version = *libqainternalperlc::qa_internal_version;
*qa_internal_author = *libqainternalperlc::qa_internal_author;
1;
