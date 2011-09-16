BACKUP_SUFFIX=".QABACKUP.$$"


#Copy a configuration file and/or directory to a given location. 
#
# This function copies a test config file. It preserves mode, ownership and
# timestamps. It also creates a backup of the original file (removeConfig
# will use this backup to restore the original config file).
#
# Usage: copyConfig <testing_conf> <original_conf>

function copyConfig()
{
    # get rid of the last '/' in case its a directory
    # this means I can not use '/' as a config directory
    CONFIG=$1
    ORIG_CONFIG=`echo $2 |  sed s,/*$,,`     
    RESULT=$FAILED

    if [ -z "$CONFIG" -o -z "$ORIG_CONFIG" ]; then
        echo "Usage: copyConfig <testing_conf> <original_conf>"
        return $INTERNAL_ERROR
    fi

#    if [ -f "${ORIG_CONFIG}${BACKUP_SUFFIX}" -o -d "${ORIG_CONFIG}${BACKUP_SUFFIX}" ]; then
#        echo "Backup Copy already exists!"
#        return $FAILED
#    fi

    # if the config is a directory then copy recursively
    if [ -d "$ORIG_CONFIG" ]; then
        if mv -f "$ORIG_CONFIG" "${ORIG_CONFIG}${BACKUP_SUFFIX}"; then
            if cp -pr $CONFIG $ORIG_CONFIG; then
                RESULT=$PASSED
            fi
        fi
    else 
        if cp -p "$ORIG_CONFIG" "${ORIG_CONFIG}${BACKUP_SUFFIX}"; then
            if cp -p $CONFIG $ORIG_CONFIG; then
                RESULT=$PASSED
            fi
        fi    
    fi
    
    return $RESULT 
}


# Remove the configuration file and/or directory and restore the original one
# from backup
#
# Usage: removeConfig <original_config>
#
function removeConfig() 
{
    ORIG_CONFIG=`echo $1 |  sed s,/*$,,`     
    RESULT=$FAILED

    if [ -z "$ORIG_CONFIG" ]; then
        echo "Usage: removeConfig <original_conf>"
        return $INTERNAL_ERROR
    fi


    # if the config is a directory then copy recursively
    if [ -d "$ORIG_CONFIG" ]; then
        #restore backup
        rm -rf "$ORIG_CONFIG"
        if mv "${ORIG_CONFIG}${BACKUP_SUFFIX}" "$ORIG_CONFIG" ; then
            RESULT=$PASSED
        fi
    else 
        #restore backup
        if mv "${ORIG_CONFIG}${BACKUP_SUFFIX}" "$ORIG_CONFIG" ; then
            RESULT=$PASSED
        fi
    fi
    return $RESULT 
}

