#! /bin/bash

RESULTS_DIR=results
TESTS_DIR=./
PYBOT_BIN=pybot
SUITE_NAME_OPT="--name Hamsta_Tests"
OUTPUTDIR_OPT="--outputdir $RESULTS_DIR"

# Go to working directory. All paths used in the script are relative
# to that directory.
MY_NAME=`basename $0`
cd `dirname $0`

function help () {
    echo "$MY_NAME -- QA Automation dumb test executor";
    echo -e "Usage: $MY_NAME COMMAND\n";
    echo -e "COMMAND is one of {init | run | clean | help}";
    echo -e "\tinit\tinitializes test environment";
    echo -e "\trun\texecutes all tests in testsuite";
    echo -e "\tclean\tdeletes the results directory";
    echo -e "\thelp\t(or no option) print this help";
    echo -e "\nContact us on <qa-automation@suse.de>.";
}

function init () {
    echo 'Not implemented.'
}

function run () {
    if [ ! -d ${RESULTS_DIR} ]; then
	mkdir ${RESULTS_DIR};
    fi

    if [ -n "${HAMSTA_TEST_HOST}" ]; then
	PYBOT_VARIABLES="--variable HOST:$HAMSTA_TEST_HOST"
    fi
    PYBOT_CMD="$PYBOT_BIN $SUITE_NAME_OPT $PYBOT_VARIABLES $OUTPUTDIR_OPT $TESTS_DIR"
    echo $PYBOT_CMD
    $PYBOT_CMD
}

function clean_logs () {
    if [ -d ${RESULTS_DIR} ]; then
	rm -rf ${RESULTS_DIR};
    fi
}

case $1 in
    'init') init;;
    'run') run;;
    'clean') clean_logs;;
    *) help;;
esac
