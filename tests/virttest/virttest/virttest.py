#!/usr/bin/python3

import configparser
from jinja2 import Environment, FileSystemLoader
from urllib.parse import urlsplit, urljoin
import ipaddress
import datetime
import os

config = configparser.ConfigParser()

# Set option names case sensitive. 
# See https://docs.python.org/dev/library/configparser.html#configparser-objects
config.optionxform = str

config.read('config.ini')








def create_vm_from_image(image, vm_details):
  ''' Create VM  from image. The image must be already built

  Keyword arguments:
  image -- the image to deploy as new VM
  vm_details -- Hash containing all the custom information for creation of 
                new VM.
  
  Returns: 
  '''
  

def deploy_image_to_net():
  '''

  '''



#if __name__ == '__main__':
    #process_template_directory('templates/controller', prepare_template_data(), 'test/controller')
    #process_template_directory('templates/kiwi', prepare_template_data(1), 'test/kiwi')

