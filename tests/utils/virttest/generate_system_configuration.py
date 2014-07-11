#!/usr/bin/python3

import getopt
import sys 
import virttest

def help_func():
    helpstr = """
Usage: {} [path]

Where:
    path - where to store the generated config
    
""".format(sys.argv[0])
    sys.stderr.write(helpstr)
    sys.exit(1)
    

opts,args = getopt.gnu_getopt(sys.argv[1:], 'h', ['help'])

for o,a in opts:
    if o == '-h':
        help_func()
    else:
        raise("Unknown argument {}".format(o))

if len(args) > 1:
    sys.stderr.write("Too many arguments: {}\n".format(args.len))
    sys.exit(1)

# Where to store the configuration - defined in config.ini[global][workdir] + '/system_config'
confpath = None 

if len(args) > 0:
    # Where to store the configuration defined by user
    confpath = args[0]

virttest.create_systemwide_configuration(confpath)

