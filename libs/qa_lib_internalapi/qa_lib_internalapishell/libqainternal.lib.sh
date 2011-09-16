PASSED=0
FAILED=1
ERROR=11
SKIPPED=22
export PASSED FAILED INTERNAL_ERROR SKIPPED



DEFAULT_PASSWORD=linux
DEFAULT_PASSWORD_CRYPTED=QAofMIJLkd5Hc #linux
export DEFAULT_PASSWORD DEFAULT_PASSWORD_CRYPTED



LIBQAINTERNAL_PATH=/usr/share/qa/qa_internalapi/sh
export LIBQAINTERNAL_PATH

. $LIBQAINTERNAL_PATH/services.lib.sh
. $LIBQAINTERNAL_PATH/log.lib.sh
. $LIBQAINTERNAL_PATH/user.lib.sh
. $LIBQAINTERNAL_PATH/config.lib.sh

#Just a "ping" function
#Usage: qa_hello
function qa_hello() {
    echo "libqainternal says hello to the world"
}
