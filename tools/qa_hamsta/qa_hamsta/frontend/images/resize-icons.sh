#!/bin/bash

# Resizes Hamsta frontend icons to proper size. Meant to be used only
# for Hamsta frontend icons.
#
# Author: pkacer@suse.com
# 2013-03-05

IMG_DIR=$1
SIZE=27
COMMAND=/usr/bin/convert
PARAMS="-resize $SIZE"

if [ $PWD != $IMG_DIR ]; then
    cd $IMG_DIR;
fi

IMAGES="icon-*.png exclamation*.png qmark.png xml_green.png\
 gear-cog_blue.png"

# Check environment sanity.
if [ ! -x ${COMMAND} ]; then
    echo "$0 ERROR: It seems you do not have an ImageMagick(1)\
 installed. Exiting." >&2;
    exit 1;
fi

for FL in ${IMAGES}; do
    FL_EXT="${FL: -3}";
    NEW_FL="${FL%.${FL_EXT}}-${SIZE}x${SIZE}.${FL_EXT}"
    EXEC="${COMMAND} ${PARAMS} ${FL} ${NEW_FL}";
    echo "${EXEC}";
    $EXEC
done
