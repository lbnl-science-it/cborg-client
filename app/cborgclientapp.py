import os
import sys
import re
import threading
import proxy
import json

import rumps

rumps.debug_mode(True)  # turn on command line logging information for development - default is off

from cborgclient import CBorgNetworkMonitor
from cborgclient import CBorgProxyPlugin
from cborgclient import cborg_client_on_lblnet

class CBorgClientMenuBarApp(rumps.App):

    def __init__(self, name, icon=None):
        super(CBorgClientMenuBarApp, self).__init__(name, icon=icon, quit_button=None)
        self.menu = [
            rumps.MenuItem('Status', self.about),
            rumps.MenuItem('Quit', self.quit)
        ]

    def about(self, sender):
        global cborg_client_on_lblnet
        window = rumps.Window('CBorg Client 0.1', 'hohum')
        window.title = 'CBorg Client 0.1'
        window.message = 'LBL-Net Status: ' + 'CONNECTED' if cborg_client_on_lblnet.is_set() else 'NOT CONNECTED'
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

    import signal

    def before_quit_handler(*args, **kwargs):
        global cborg_client_app
        cborg_client_monitor.stop_monitor()
        cborg_client_proxy.shutdown()

    cborg_client_monitor = CBorgNetworkMonitor()

    sys.argv[0] = re.sub(r'(-script\.pyw|\.exe)?$', '', sys.argv[0])
    cborg_client_proxy = proxy.Proxy(sys.argv[1:])
    cborg_client_proxy.setup()

    cborg_client_app = CBorgClientMenuBarApp('CBorg Client 0.1', icon='cborg-mini-icon-16x16.png')

    # respond to quit event
    rumps.events.before_quit.register(before_quit_handler)

    cborg_client_app.run()

