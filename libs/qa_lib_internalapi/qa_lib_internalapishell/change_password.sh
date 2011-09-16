#!/bin/bash

#Changes user's password - bash version
#params - username new_password
# we assume that params were already checked!

USER=$1
PASSWORD=$2

echo "$PASSWORD" | passwd --stdin $USER > /dev/null

