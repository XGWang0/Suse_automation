MSG_ERROR="E"
MSG_INFO="I"
MSG_WARN="W"
MSG_FAILED="F"
MSG_PASSED="P"
MSG_SKIPPED="S"
MSG_NOFLAG="MSG"
export MSG_ERROR MSG_INFO MSG_WARN MSG_FAILED MSG_PASSED MSG_NOFLAG



# Print message with correct flag.
# This function is used for printing various warn/error/info/passed/failed
# messages
#
# Usage: printMessage <level> <message>
#   level is one of $MSG_INFO, $MSG_ERROR, $MSG_WARN, $MSG_FAILED,
#   $MSG_PASSED
function printMessage() {
    LEVEL=$1
    MSG=$2

    if [ -z "$LEVEL" -o -z "$MSG" ]; then
        echo "Usage: printMessage <level> <message> "
        echo '    level is one of $MSG_INFO, $MSG_ERROR, $MSG_WARN,'
        echo '    $MSG_FAILED,$MSG_PASSED, $MSG_SKIPPED'
        return $FAILED
    fi

    case "$LEVEL" in
    
        $MSG_INFO)
            echo "(I) $MSG"
            ;;
            
        $MSG_ERROR)
            echo "(E) $MSG"
            ;;
            
        $MSG_WARN)
            echo "(W) $MSG"
            ;;
        $MSG_FAILED)
            echo "FAILED: $MSG"
            ;;
        $MSG_PASSED)
            echo "PASSED: $MSG"
            ;;
        $MSG_SKIPPED)
            echo "SKIPPED: $MSG"
            ;;
        $MSG_NOFLAG)
            echo "$MSG"
            ;;
        *)
        echo "NO SUCH LEVEL: $LEVEL (original message: $MSG)"
        return $FAILED
        ;;
    esac

    return $PASSED
}


function printInfo
{
	printMessage $MSG_INFO "$@"
}

function printError
{
	printMessage $MSG_ERROR "$@"
}

function printWarning
{
	printMessage $MSG_WARN "$@"
}

function printFailed
{
	printMessage $MSG_FAILED "$@"
}

function printPassed
{
	printMessage $MSG_PASSED "$@"
}

function printSkipped
{
	printMessage $MSG_SKIPPED "$@"
}

function print
{
	printMessage $MSG_NOFLAG "$@"
}

