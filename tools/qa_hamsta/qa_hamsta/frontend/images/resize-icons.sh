#!/bin/bash

# Resizes Hamsta frontend icons to proper size. Meant to be used only
# for Hamsta frontend icons.
#
# Author: pkacer@suse.com
# 2013-03-05

IMG_DIR=frontend/images

CONVERT_IMAGES="$IMG_DIR/icon-*.png $IMG_DIR/exclamation*.png\
 $IMG_DIR/qmark.png $IMG_DIR/xml_green.png"

# Check environment sanity.
if [ ! -x /usr/bin/convert ]; then
    echo "$0 ERROR: It seems you do not have an ImageMagick(1)\
 installed. Exiting." >&2;
    exit 1;
fi

for FL in $CONVERT_IMAGES; do
    convert -resize 27 "$FL" "$FL";
done
