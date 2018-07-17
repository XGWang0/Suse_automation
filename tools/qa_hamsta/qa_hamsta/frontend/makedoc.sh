#!/bin/bash

# makedoc.sh
#
# Author: Pavel Kacer <pkacer@suse.com>
# Time-stamp: <2012-09-11 10:18:40 draculus>
# Version: 1.0.0
#
# Use this script to generate phpdoc documentation for your library.
#
# To run this script you need a `phpdoc' program. You can get it from
# `http://phpdoc.org/'.

# ****************************************************************************
# Copyright (c) 2013 Unpublished Work of SUSE. All Rights Reserved.
# 
# THIS IS AN UNPUBLISHED WORK OF SUSE.  IT CONTAINS SUSE'S
# CONFIDENTIAL, PROPRIETARY, AND TRADE SECRET INFORMATION.  SUSE
# RESTRICTS THIS WORK TO SUSE EMPLOYEES WHO NEED THE WORK TO PERFORM
# THEIR ASSIGNMENTS AND TO THIRD PARTIES AUTHORIZED BY SUSE IN WRITING.
# THIS WORK IS SUBJECT TO U.S. AND INTERNATIONAL COPYRIGHT LAWS AND
# TREATIES. IT MAY NOT BE USED, COPIED, DISTRIBUTED, DISCLOSED, ADAPTED,
# PERFORMED, DISPLAYED, COLLECTED, COMPILED, OR LINKED WITHOUT SUSE'S
# PRIOR WRITTEN CONSENT. USE OR EXPLOITATION OF THIS WORK WITHOUT
# AUTHORIZATION COULD SUBJECT THE PERPETRATOR TO CRIMINAL AND  CIVIL
# LIABILITY.
# 
# SUSE PROVIDES THE WORK 'AS IS,' WITHOUT ANY EXPRESS OR IMPLIED
# WARRANTY, INCLUDING WITHOUT THE IMPLIED WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT. SUSE, THE
# AUTHORS OF THE WORK, AND THE OWNERS OF COPYRIGHT IN THE WORK ARE NOT
# LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF, OR IN CONNECTION
# WITH THE WORK OR THE USE OR OTHER DEALINGS IN THE WORK.
# ****************************************************************************

# Title of generated documentation, default is 'Generated Documentation'.
TITLE="Hamsta Web Frontend Documentation"

# Name to use for the default package. If not specified, uses 'default'.
DEFAULT_PACKAGE="Hamsta"

# Name of a directory(s) to parse directory1,directory2
# $PWD is the working directory where makedoc.sh starts.
PATH_PROJECT=$PWD/lib

# Path of PHPDoc executable.
PATH_PHPDOC=/usr/bin/phpdoc

# Where documentation will be put.
PATH_DOCS=$PWD/doc/lib

# Template to use.
TEMPLATE='new-black'

# Check if phpdoc is available.
if [ ! -x $PATH_PHPDOC ]; then
    echo "$0: Error: The 'phpdoc' package is not properly installed.";
    exit 1;
fi

# Make documentation.
$PATH_PHPDOC -d $PATH_PROJECT -t $PATH_DOCS --title "$TITLE" \
    --defaultpackagename "$DEFAULT_PACKAGE" --template $TEMPLATE;
