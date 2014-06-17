#!/usr/bin/python3
from virttest.utils import _prepare_template_data

_config = None



def __init__(configfile = 'config.ini'):
    """ Loads configuration from file
    """
    import configparser

    _config = configparser.ConfigParser()
    # Set option names case sensitive. 
    # See https://docs.python.org/dev/library/configparser.html#configparser-objects
    _config.optionxform = str

    _config.read(configfile)
 

class TestBox:
    """
    
    """
    
    def __init__(self, network_id, repositories = {}):
        """
        repos must use some prefix as specified in config
        """
    
        self.network_id = network_id;
        self.__templdata = _prepare_template_data(network = self.network_id, custom_product_repositories = repositories)
        
        # If we got this far with no exception, all is ready
        self.__closed = False
    
    
    def close(self):
        """
        Release all the resources allocated in the test box (delete images, etc.).
        It is no longer possible to work with this box after the close() has been called.
        """
        self.__closed = True
        pass
    
    def __check_closed(self):
        """ Raise ValueError if we run it on closed TestBox
        """
        if self.__closed:
            raise ValueError('Operation on closed TestBox')
    
    
    def __enter__(self):
        """ Make it possible to work with TestBox in 'with' statement
        
        Entering 'with' statement
        """
        
        self.__check_closed()
        
        return self
    
    
    def __exit__(self, *args):
        """ Make it possible to work with TestBox in 'with' statement
        
        Leaving 'with' statement - close the TestBox
        """
        self.close()


