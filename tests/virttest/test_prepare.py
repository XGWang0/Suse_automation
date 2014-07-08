#!/usr/bin/python3

import getopt
import sys 
import virttest

def help_func():
    helpstr = """
Usage: {} [-n|--network network_id] qa_repo_base_url
       {} [-n|--network network_id] -r|--reinintialize

Where:
    network_id - ID of test network to use
    reinitialize - when test have been already initialized, running this script 
                   again without this argument makes it immediatelly return with 
                   error. If this argument is specified, the test is instead 
                   reinitialized (all virtual hosts are deleted and recreated)
    qa_repo_base_url - base url to the repositories that will be tested. 
                       Product abbrev will be added to the end of this to create
                       real URLs. The url must be within some repository defined in
                       config.ini
    
""".format(sys.argv[0], sys.argv[0])
    sys.stderr.write(helpstr)
    sys.exit(1)

network_id = 1
reinitialize = False   

opts,args = getopt.gnu_getopt(sys.argv[1:], 'nrh', ['network', 'reinitialize', 'help'])

for o,a in opts:
    if o == '-n':
        network_id = a
    elif o == '-r':
        reinitialize = True
    elif o == '-h':
        help_func()
    else:
        raise ValueError("Unknown argument {}".format(o))

if len(args) > 1:
    sys.stderr.write("Too many arguments: {}\n".format(len(args)))
    sys.exit(1)


if len(args) == 0:
    sys.stderr.write("Too few arguments: repository base url must be specified\n")
    sys.exit(1)    




if reinitialize:
    testbox = virttest.TestBox.load(network_id)
    testbox.restart()
    print("TestBox Loaded.")
else:
    repobase = virttest.url_to_config_format(args[0])
    repositories = {}
    
    repositories['QA'] = repobase
    for p in ['SLE-10-SP4', 'SLE-10-SP4-Update', 'SLE-11-SP3', 'SLE-11-SP3-Update', 'SLE-12', 'openSUSE-13.1', 'openSUSE-Factory']:
        repositories['QA-{}'.format(p)] = '{}/{}'.format(repobase, p)

    testbox = virttest.TestBox(network_id, repositories)
    print("TestBox Created.")
    
testbox.add_host('sles-11-sp3', 'hamsta')
testbox.add_host('sles-11-sp3', 'qadb')
testbox.add_host('sles-11-sp3', 'qadbreport')
testbox.add_host('sles-11-sp3', 'sut')

# Yay, we created the testbox!!!
print("Test Prepare completed.")