#!/usr/bin/python3

import getopt
import sys 
import virttest

def help_func():
    helpstr = """
Usage: {} [-n|--network network_id] generated_config_file

Where:
    network_id - ID of test network to use
    reinitialize - when test have been already initialized, running this script 
                   again without this argument makes it immediatelly return with 
                   error. If this argument is specified, the test is instead 
                   reinitialized (all virtual hosts are deleted and recreated)
    generated_config_file - file where the robot configuration should be stored
    
""".format(sys.argv[0])
    sys.stderr.write(helpstr)
    sys.exit(1)

network_id = 1

opts,args = getopt.gnu_getopt(sys.argv[1:], 'nh', ['network', 'help'])

for o,a in opts:
    if o == '-n':
        network_id = a
    elif o == '-h':
        help_func()
    else:
        raise ValueError("Unknown argument {}".format(o))

if len(args) > 1:
    sys.stderr.write("Too many arguments: {}\n".format(len(args)))
    sys.exit(1)


if len(args) == 0:
    sys.stderr.write("Too few arguments: generated_config_file path must be specified\n")
    sys.exit(1)    


file_path = args[0]

testbox = virttest.TestBox.load(network_id)
testbox.export_robot_configuration(file_path)
    

# Yay, we created the testbox!!!
print("TestBox configuration written.")