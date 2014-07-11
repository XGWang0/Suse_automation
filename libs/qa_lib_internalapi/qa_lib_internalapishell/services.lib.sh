# Internal function for accessing the service actions. Don't use this
# function in your testscripts !!!
#
serviceFunction()
{
    SERVICE=$1
    ACTION=$2

    if [ -z "$SERVICE" ]; then
        if [ "$ACTION" = "status" ]; then
            echo "Usage: checkService <serviceName>"
        else
            echo "Usage: ${ACTION}Service <serviceName>"
        fi
        return $FAILED
    fi

    if [ -z "$ACTION" ]; then
        return $FAILED
    fi

    SCRIPT_UID=`id -u`
    if [ "$SCRIPT_UID" != "0" ]; then
        echo "You must be root to run this function!"
        return $FAILED
    fi

    if service $SERVICE $ACTION; then
        return $PASSED
    else
        return $FAILED
    fi
}

# Start the service.
#
# NOTE: you must be root to use this function.
#
# Usage: startService <serviceName>

function startService() {
  serviceFunction "$1"  "start" 
  return $?
}

# Stop the service.
#
# NOTE: you must be root to use this function.
#
# Usage: stopService <serviceName>

function stopService() {
    sleep 1
    serviceFunction "$1"  "stop" 
    return $?
}



# Check if the service is running.
#
# This is equivalent to executing "/etc/init.d/SERVICE status".
# NOTE: you must be root to use this function
#
# Usage: checkService <serviceName>
function checkService() {
    serviceFunction "$1" "status"
    return $?
}

# Restart the service
#
# NOTE: you must be root to use this function.
#
# Usage: restartService <serviceName>

function restartService() {
    serviceFunction "$1" "restart"
    return $?
}

# Reload the service
#
# NOTE: you must be root to use this function.
#
# Usage: reloadService <serviceName>

function reloadService() {
    serviceFunction "$1" "reload"
    return $?
}


function openPortsOfService() {
    exit $FAILED
# ls -la /proc/20987/fd | sed -n 's/.*socket:\[\([0-9]*\)\]/\1/p'    
#    PIDS=/sbin/pidofproc path
#    for pid in $PIDS; do 
#        /proc/$pid/fd
#    done
}
