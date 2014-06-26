#!/usr/bin/python3

import getopt
import sys 
import virttest

def help_func():
    helpstr = """
Usage: {} [-n|--network network_id] qa_repo_base_url

Where:
    network_id - ID of test network to use
    qa_repo_base_url - base url to the repositories that will be tested. 
                       Product abbrev will be added to the end of this to create
                       real URLs. The url must be within some repository defined in
                       config.ini
    
""".format(sys.argv[0])
    sys.stderr.write(helpstr)
    sys.exit(1)

network_id = 1     

opts,args = getopt.gnu_getopt(sys.argv[1:], 'nh', ['network', 'help'])

for o,a in opts:
    if o == '-n':
        network_id = a
    if o == '-h':
        help_func()
    else:
        raise("Unknown argument {}".format(o))

if len(args) > 1:
    sys.stderr.write("Too many arguments: {}\n".format(len(args)))
    sys.exit(1)


if len(args) == 0:
    sys.stderr.write("Too few arguments: repository base url must be specified\n")
    sys.exit(1)    

repobase = args[0]

repositories = {}
# TODO fill repositories

testbox = virttest.TestBox(network_id=network_id, repositories=repositories)

# Yay, we created the testbox!!!
print("Test Prepare completed.")