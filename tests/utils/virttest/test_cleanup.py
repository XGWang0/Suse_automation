#!/usr/bin/python

import getopt
import sys 
import virttest

def help_func():
    helpstr = """
Usage: {} [-n|--network network_id]

Where:
    network_id - ID of test network to use (default 1)
    
""".format(sys.argv[0])
    sys.stderr.write(helpstr)
    sys.exit(1)

network_id = 1     

opts,args = getopt.gnu_getopt(sys.argv[1:], 'n:h', ['network', 'help'])

for o,a in opts:
    if o == '-n':
        network_id = a
    elif o == '-h':
        help_func()
    else:
        raise("Unknown argument {}".format(o))

if len(args) > 1:
    sys.stderr.write("Too many arguments: {}\n".format(len(args)))
    sys.exit(1)

testbox = virttest.TestBox.load(network_id)
testbox.close()

print("Test Cleanup completed.")
