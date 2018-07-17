# create a new user (with homedir in tmp)
# param - username
# Usage: addUser <userName>
function addUser()
{
    USER="$1"
    MAIN_GROUP="$2"
    TESTHOME="/tmp/home"
    if [ -z "$USER" ]; then
        echo "Usage: addUser: <userName> [mainGroup]"
        return $FAILED 
    fi
    
    if id "$USER" > /dev/null 2> /dev/null; then
            return $FAILED
    fi

    group=""
    if ! test -z "$MAIN_GROUP"; then  
        group="-g $MAIN_GROUP"
    fi
    
    if ! test -d $TESTHOME ; then
        mkdir -p $TESTHOME
	echo "$TESTHOME created"
    fi

    if ! useradd -m "$USER" -d "$TESTHOME/$USER" $group -p "$DEFAULT_PASSWORD_CRYPTED" > /dev/null 2> /dev/null; then
            return $FAILED
    fi

    return $PASSED
}

# delete user and remove home
# param - username
# Usage: delUser <userName>
function delUser()
{
    USER="$1"
    if [ -z "$USER" ]; then
        echo "Usage: delUser: <userName>"
        return $FAILED 
    fi
 
    if ! id "$USER" > /dev/null 2> /dev/null; then
            return $FAILED
    fi

    if ! userdel -r -f "$USER" > /dev/null 2> /dev/null; then
            return $FAILED
    fi

    return $PASSED
}


# add User to group
#
# Usage: addToGroup <user> <group>
function addToGroup()
{
    USER=$1
    GROUP=$2
    
    if [ -z "$USER" -o -z "$GROUP" ]; then
        echo "Usage: addToGroup <user> <group>"
        return $FAILED
    fi
    
    if /usr/sbin/groupmod -A  "$USER"  "$GROUP"; then
        return $PASSED
    else
        return $FAILED
    fi
}

# remove User from group
#
# Usage: removeFromGroup <user> <group>
function removeFromGroup()
{
    USER=$1
    GROUP=$2
    
    if [ -z "$USER" -o -z "$GROUP" ]; then
        echo "Usage: removeFromGroup <user> <group>"
        return $FAILED
    fi
    
    if /usr/sbin/groupmod -R  "$USER"  "$GROUP"; then
        return $PASSED
    else
        return $FAILED
    fi
}

# get all the Groups the user is member of as CSV list
#
# Usage: getGroups <user>
#
function getGroups() 
{
    USER=$1
    if [ -z "$USER" ]; then
        echo "Usage: getGroups <user>"
        return $FAILED
    fi
    
    if id -Gn "$USER" | sed 's/ /,/'g; then
        return $PASSED
    fi
    
    return $FAILED
}

#Changes user's password
#params - username new_password
function changePassword()
{
    USER=$1
    PASSWORD=$2
    if [ -z "$USER" -o -z "$PASSWORD" ]; then
        echo "Usage: changePassword <user> <password>"
        return $FAILED
    fi
 
    if ! id $1 > /dev/null 2> /dev/null; then
        printError "User '$USER' doesn't exist"
        return $FAILED
    fi

    if ! /usr/share/qa/qa_internalapi/sh/change_password "$USER" "$PASSWORD" > /dev/null ; then
        printError "Unable to change password for user '$USER'"
        return $FAILED
    fi

    return $PASSED
}
