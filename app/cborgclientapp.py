"""

    CBorg Client MenuBar App for OSX

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


import os
import sys
import re
import threading
import proxy
import json

import rumps

rumps.debug_mode(True)  # turn on command line logging information for development - default is off

from cborgclient import CBorgProxyPlugin, CBorgNetworkMonitor

class CBorgClientMenuBarApp(rumps.App):

    def __init__(self, name, icon=None):
        super(CBorgClientMenuBarApp, self).__init__(name, icon=icon, quit_button=None)
        self.menu = [
            rumps.MenuItem('Status', self.about),
            rumps.MenuItem('Quit', self.quit)
        ]

    def about(self, sender):
        global cborg_network_monitor
        window = rumps.Window('CBorg Client 0.1', 'hohum')
        window.title = 'CBorg Client 0.1'
        window.message = 'LBL-Net Status: ' + ('CONNECTED' if cborg_network_monitor.on_lbl_net else 'NOT CONNECTED')
        window.default_text = os.environ.get('CBORG_API_KEY')
        response = window.run()
        print(response)

    # this gets called if the user quits
    def quit(self, sender):
        # global cborg_client_proxy, cborg_client_monitor
        # cborg_client_monitor.stop_monitor()
        # cborg_client_proxy.shutdown()
        rumps.quit_application()

if __name__ == '__main__':

    print('cborg-client: Start Menubar App')

    sys.argv = [
        './cborgclient.py', 
        '--num-acceptors', '3', 
        '--num-workers', '3', 
        '--enable-reverse-proxy', 
        '--plugins', 'CBorgProxyPlugin', 
        '--timeout', '120',
        '--ca-file', os.path.dirname(os.path.abspath(__file__)) + '/cacert.pem', 
        '--port', '8001', 
        '--ports', '8002', '8003', 
        '--log-level', 'ERROR'
        ]

    import signal

    def before_quit_handler(*args, **kwargs):
        global cborg_network_monitor, cborg_network_monitor_thread, cborg_client_proxy
        cborg_network_monitor.stop_monitor()
        cborg_network_monitor_thread.join()
        cborg_client_proxy.shutdown()

    cborg_network_monitor = CBorgNetworkMonitor(silent=False)
    cborg_network_monitor_thread = threading.Thread(target=cborg_network_monitor.run_monitor)
    cborg_network_monitor_thread.start()

    sys.argv[0] = re.sub(r'(-script\.pyw|\.exe)?$', '', sys.argv[0])
    cborg_client_proxy = proxy.Proxy(sys.argv[1:])
    cborg_client_proxy.setup()

    cborg_client_app = CBorgClientMenuBarApp('CBorg Client 0.1', icon='cborg-mini-icon-16x16.png')

    # respond to quit event
    rumps.events.before_quit.register(before_quit_handler)

    cborg_client_app.run()

