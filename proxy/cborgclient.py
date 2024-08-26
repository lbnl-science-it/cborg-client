# -*- coding: utf-8 -*-
"""

    CBorg Client - Reverse Proxy Application and proxy.py Plugin

    Copyright Notice
    ================

    Copyright (c) 2024, The Regents of the University of California, 
    through Lawrence Berkeley National Laboratory (subject to receipt 
    of any required approvals from the U.S. Dept. of Energy). All rights reserved.

    If you have questions about your rights to use or distribute this software,
    please contact Berkeley Lab's Intellectual Property Office at
    IPO@lbl.gov.

    NOTICE.  This Software was developed under funding from the U.S. Department
    of Energy and the U.S. Government consequently retains certain rights.  As
    such, the U.S. Government has been granted for itself and others acting on
    its behalf a paid-up, nonexclusive, irrevocable, worldwide license in the
    Software to reproduce, distribute copies to the public, prepare derivative 
    works, and perform publicly and display publicly, and to permit others to do so.

"""

import re
import sys
import os
import time
from typing import TYPE_CHECKING, List, Tuple, Union, Optional, Dict, Any

import os
import fcntl

import proxy

from proxy.http.proxy import HttpProxyBasePlugin
from proxy.http.parser import HttpParser, httpParserTypes
from proxy.common.types import HostPort
from proxy.common.utils import bytes_
from proxy.common.version import __version__

from proxy.http import Url
from proxy.http.server import ReverseProxyBasePlugin
from proxy.common.types import RePattern
from proxy.http.exception.base import HttpProtocolException
from proxy.http.exception import HttpRequestRejected

if TYPE_CHECKING:
    from proxy.core.connection import TcpServerConnection

import netifaces as ni

import ipaddress

import multiprocessing
import signal

class CBorgNetworkMonitor:

    def __init__(self):
        self.exit_signal = multiprocessing.Event()
        self.exit_signal.clear()

    def stop_monitor(self):
        self.exit_signal.set()

    def run_monitor(self):
        global cborg_client_on_lblnet

        while not self.exit_signal.is_set():

            if self.is_on_lblnet():
                cborg_client_on_lblnet.set()
            else:
                cborg_client_on_lblnet.clear()

            time.sleep(1)

    def is_on_lblnet(self):
        """
        Returns True if the computer is connected to the LBL network
        """
        subnets = [
            '128.3.0.0/16',
            '131.243.0.0/16'
        ]

        try:
            for subnet in subnets:
                # Get all network interfaces
                interfaces = ni.interfaces()
                
                # Iterate over all interfaces
                for interface in interfaces:

                    # Get the IP address and netmask for the interface
                    ip = ni.ifaddresses(interface).get(ni.AF_INET, [{}])[0].get('addr')
                    netmask = ni.ifaddresses(interface).get(ni.AF_INET, [{}])[0].get('netmask')
                    
                    # Check if the IP address is in the specified subnet
                    if ip and netmask:
                        ip_int = ipaddress.ip_address(ip)
                        subnet_int = ipaddress.ip_network(subnet, strict=False)
                        if ip_int in subnet_int:
                            return True
        except Exception as e:
            print(f"Error: {e}")
        return False

cborg_client_on_lblnet = multiprocessing.Event()
cborg_client_on_lblnet.clear()

cborg_network_monitor = CBorgNetworkMonitor()
if cborg_network_monitor.is_on_lblnet():
    cborg_client_on_lblnet.set()

import threading
cborg_network_monitor_thread = threading.Thread(target=cborg_network_monitor.run_monitor, daemon=True)
cborg_network_monitor_thread.start()

parent_pid = os.getppid()

cborg_upstream_locks = {
    '8001': open('/tmp/cborg_upstream-' + str(parent_pid) + '-' + str(8001) + '.flock', "w"),
    '8002': open('/tmp/cborg_upstream-' + str(parent_pid) + '-' + str(8002) + '.flock', "w"),
    '8003': open('/tmp/cborg_upstream-' + str(parent_pid) + '-' + str(8003) + '.flock', "w"),
}

def cborg_upstream_acquire(port):
    global cborg_upstream_locks
    fcntl.flock(cborg_upstream_locks[port], fcntl.LOCK_EX)

def cborg_upstream_release(port):
    global cborg_upstream_locks
    fcntl.flock(cborg_upstream_locks[port], fcntl.LOCK_UN)

def sig_handler(sig, frame):
    global cborg_network_monitor, cborg_network_monitor_thread
    cborg_network_monitor.stop_monitor()
    cborg_network_monitor_thread.join()

signal.signal(signal.SIGTERM, sig_handler)
signal.signal(signal.SIGINT, sig_handler)

class CBorgProxyPlugin(ReverseProxyBasePlugin):

    # user set the API key in the environment here...
    cborg_api_key = os.environ.get('CBORG_API_KEY')

    current_port = None

    def routes(self) -> List[Union[str, Tuple[str, List[bytes]]]]:
        return [
            # catch all route
            r'/(.*)$'
        ]
    
    def before_routing(self, request: HttpParser) -> Optional[HttpParser]:

        try:

            # Host header is required, with a port
            # request.port does not have correct information, so we extract it from the host header
            assert request.has_header(b'Host')
            self.current_port = str(request.headers[b'host'][1], encoding='utf-8').split(':')[1]
            request.del_header(b'Host')

            # Route the request endpoint depending if we are on VPN / LBLNet or not
            global cborg_client_on_lblnet
            if cborg_client_on_lblnet.is_set():
                request.add_header(
                    b'Host', b'api-local.cborg.lbl.gov'
                )
            else:
                request.add_header(
                    b'Host', b'api.cborg.lbl.gov'
                )

            # VS Code adds this header - it is not needed as we use the Authorization header
            if request.has_header(b'api-key'):
                request.del_header(b'api-key')

            # Due to a bug in proxy.py, Content-Length header can be duplicated if client uses incorrect letter case
            # fix is to delete the header
            # proxy.py will calculate and resend the content length anyway
            if request.has_header(b'Content-Length'):
                request.del_header(b'Content-Length')

            # If Keep-Alive connections are allowed, parallel connection attempts will be forced to wait for first connection to close
            # Simpler to just force all connections to close even though there is a minor performance penalty
            # Proxy.py can use upstream connection pooling anyway
            if request.has_header(b'Connection'):
                request.del_header(b'Connection')

            request.add_header(
                b'Connection',
                b'Close'
            )

            # Add CBorgClient UA
            if request.has_header(b'User-Agent'):
                request.del_header(b'User-Agent')

            request.add_header(
                b"User-Agent",
                b'CBorgClient-0.1'
            )

            # Now inject the API key taken from user environment variable
            if request.has_header(b'Authorization'):
                request.del_header(b'Authorization')

            request.add_header(
                b"Authorization",
                bytes(f"Bearer {self.cborg_api_key}", encoding='utf-8'),
            )

        except Exception as e:
            print('ERROR', str(e))
            return

        cborg_upstream_acquire(self.current_port)
        return request

    def on_client_connection_close(self) -> None:
        """Client has closed the connection, do any clean up task now."""
        print("Connection Closed by Client")
        pass

    def on_access_log(self, context: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        cborg_upstream_release(self.current_port)
        self.current_port = None
        return context

    # will proxy all incoming requests to the remote endpoint...
    def handle_route(
        self,
        request: HttpParser,
        pattern: RePattern,
    ) -> Union[memoryview, Url, 'TcpServerConnection']:
        try:
            global cborg_client_on_lblnet
            if cborg_client_on_lblnet.is_set():
                choice: Url = Url.from_bytes(b'https://api-local.cborg.lbl.gov' + request.path)
            else:
                choice: Url = Url.from_bytes(b'https://api.cborg.lbl.gov' + request.path)
        except Exception as e:
            print('ROUTING ERROR', str(e))
        return choice
    

if __name__ == '__main__':

    sys.argv = [
        './cborgclient.py', 
        '--num-acceptors', '8', 
        '--num-workers', '8', 
        '--enable-reverse-proxy', 
        '--plugins', 'CBorgProxyPlugin', 
        '--timeout', '180', 
        '--port', '8001', 
        '--ports', '8002', '8003', 
        '--log-level', 'INFO'
        ]
    
    m = CBorgNetworkMonitor()

    sys.argv[0] = re.sub(r'(-script\.pyw|\.exe)?$', '', sys.argv[0])
    sys.exit(proxy.entry_point())

