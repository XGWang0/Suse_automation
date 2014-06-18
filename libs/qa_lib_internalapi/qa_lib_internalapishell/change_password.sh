#!/bin/bash

#Changes user's password - bash version
#params - username new_password
# we assume that params were already checked!

USER=$1
PASSWORD=$2

if grep -E "SUSE Linux Enterprise (Server|Desktop) 12" /etc/issue;then
        echo "$USER:$PASSWORD" | chpasswd > /dev/null
else
        echo "$PASSWORD" | passwd --stdin $USER > /dev/null
fi

