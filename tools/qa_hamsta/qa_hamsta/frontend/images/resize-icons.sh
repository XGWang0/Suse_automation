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
WD="`pwd`"

function usage
{
    echo "Usage: $0 DIRECTORY";
    echo "   DIRECTORY contains images to process";
}

if [[ -z $IMG_DIR ]]; then
    usage
    exit 1;
elif [[ ! -d $IMG_DIR ]]; then
    usage
    echo "$0 error: The DIRECTORY has to be a directory." >&2;
    exit 1;
elif [[ $WD != $IMG_DIR ]]; then
    cd $IMG_DIR;
fi

IMAGES="icon-*.png exclamation*.png qmark.png gear-cog_blue.png\
    host-collide.png"

MINI_SIZE=15
MINI_IMAGES="icon-info.png"

# Check environment sanity.
if [ ! -x ${COMMAND} ]; then
    echo "$0 ERROR: It seems you do not have an ImageMagick(1)\
 installed. Exiting." >&2;
    exit 1;
fi

function resize
{
    FLS=$1
    SZ=$2

    if [[ ! -d "$SZ" ]]; then
	mkdir "$SZ";
    fi

    for FL in ${FLS}; do
	EXEC="${COMMAND} ${PARAMS} ${FL} ${SZ}/${FL}";
	echo "${EXEC}";
	$EXEC
    done
}

resize "${IMAGES}" "${SIZE}"
resize "${MINI_IMAGES}" "${MINI_SIZE}"

exit 0;
