#!/usr/bin/python

import getopt
import sys 
import virttest

def help_func():
    helpstr = """
Usage: {} [-n|--network network_id] -o|--os os_version -v|--variant variant [-s|--start] 

Where:
    network_id - ID of test network to use
    os_version - version to install (sles-11-sp3, sles-12, etc.)
    variant    - variant of OS (pure, sut, hamsta, qadb, server)
    --start    - start the host
    
""".format(sys.argv[0])
    sys.stderr.write(helpstr)
    sys.exit(1)

network_id = 1
start = False
os = ''
variant = ''


opts,args = getopt.gnu_getopt(sys.argv[1:], 'n:o:v:sh', ['network', 'os', 'variant', 'start', 'help'])

for o,a in opts:
    if o == '-n':
        network_id = int(a)
    elif o == '-o':
        os = a
    elif o == '-v':
        variant = a
    elif o == '-s':
        start = True
    elif o == '-h':
        help_func()
    else:
        raise ValueError("Unknown argument {}".format(o))

if len(args) > 0:
    sys.stderr.write("Too many arguments: {}\n".format(len(args)))
    sys.exit(1)

if os == '' or variant == '':
    sys.stderr.write("Argument --os or --variant not present\n")
    sys.exit(1)

testbox = virttest.TestBox.load(network_id)

    
host = testbox.add_host(os, variant, start)

print(host.name())
