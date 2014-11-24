#!/bin/bash

#Changes user's password - bash version
#params - username new_password
# we assume that params were already checked!

USER=$1
PASSWORD=$2

if which chpasswd >/dev/null 2>&1;then
        echo "$USER:$PASSWORD" | chpasswd > /dev/null
else
        echo "$PASSWORD" | passwd --stdin $USER > /dev/null
fi

