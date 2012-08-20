#!/bin/bash

function usage ()
{
	echo "Usage: $0 location; location could be \"cn\", \"cz\", \"de\", \"us\""
	exit 1
}

[ $# -ne 1 ] && usage

LOCATION=$1

## ISOPATH: where your Windows ISO saved
ISOPATH="/mirror_a/VIRT-ISO" # Modify this path according to local environment
JSONFILE="/mirror_a/repo-index/${LOCATION}.win.json"

echo "[" > $JSONFILE
cd $ISOPATH
for file in `ls win*`; do
	echo "  {" >> $JSONFILE
	product=`echo $file | sed 's/-auto.iso//'`
	name=`echo $product`
	echo "    \"product\": \"$product\"," >> $JSONFILE
	echo "    \"name\": \"$name\"" >> $JSONFILE
	echo "  }," >> $JSONFILE
done

echo "]" >> $JSONFILE

line=`grep -n ']' $JSONFILE | cut -d: -f1`
(( line-- ))
sed -i "$line s/,//" $JSONFILE
