#!/bin/bash
# vim: set et ts=4 sw=4 ai si:
#
# hamsta.sh -- copy directory to temporary directory and prepare to be
#              submitted with submitpac
#
# (C) 2007 Patrick Kirsch
if [ -z $1 ]; then
    echo "I need a parameter for HAMSTA"
fi
cd /usr/share/hamsta
perl Slave/run_job.pl $1



