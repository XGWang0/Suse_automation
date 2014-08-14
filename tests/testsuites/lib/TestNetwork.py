import virttest

class TestNetwork:
    """
    """
    ROBOT_LIBRARY_SCOPE = 'TEST SUITE'
    
    def __init__(self, network_id):
        """ Connect to existing Test Network and reinitializes it (delete all hosts, except infrastructure ones).
        The Test Network must be already created!!!
        """
        self._testbox = virttest.TestBox.load(network_id)
        self.reset_test_network()
    
    def reset_test_network(self):
        self._testbox.restart()
    
    def add_host(self, os, host_type, start=True):
        host = self._testbox.add_host(os, host_type, start)
        return host.name()
    
    def delete_host(self, hostname):
        self._testbox.delete_host(hostname)
    
    def start_host(self, hostname):
        self._testbox.get_host(hostname).start()

    def stop_host(self, hostname, force=True):
        self._testbox.get_host(hostname).start(force=force)
    
    def get_mac_address(self, hostname):
        self._testbox.get_host(hostname).mac()
    
    def get_ip_address(self, hostname):
        self._testbox.get_host(hostname).ip()
    
    def get_fqdn(self, hostname):
        self._testbox.get_host(hostname).fqdn()
    
    def get_hosts(self):
        self._testbox.get_hostnames()
    