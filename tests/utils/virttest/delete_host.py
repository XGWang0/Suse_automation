#!/usr/bin/python

import getopt
import sys 
import virttest

def help_func():
    helpstr = """
Usage: {} [-n|--network network_id] host_name 

Where:
    network_id - ID of test network to use
    host_name  - name of host to delete
    
""".format(sys.argv[0])
    sys.stderr.write(helpstr)
    sys.exit(1)

network_id = 1
hostname = ''


opts,args = getopt.gnu_getopt(sys.argv[1:], 'n:h', ['network', 'help'])

for o,a in opts:
    if o == '-n':
        network_id = int(a)
    elif o == '-h':
        help_func()
    else:
        raise ValueError("Unknown argument {}".format(o))

if len(args) > 1:
    sys.stderr.write("Too many arguments: {}\n".format(len(args)))
    sys.exit(1)

if len(args) == 0:
    sys.stderr.write("Too few arguments: host_name must be specified\n")
    sys.exit(1)    

hostname = args[0]

testbox = virttest.TestBox.load(network_id)
    
testbox.delete_host(hostname)
