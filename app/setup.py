# py2app setup file

from setuptools import setup
from setuptools.command.build_py import build_py

import sys
sys.setrecursionlimit(5000)  # You can adjust the limit as needed

class CustomBuildPy(build_py):
    def run(self):
        # Clone the "proxy" repository
        repo_url = "https://github.com/abhinavsingh/proxy.py.git"
        repo_path = os.path.join(os.path.dirname(__file__), "proxy")
        
        if not os.path.exists(repo_path):
            subprocess.check_call(["git", "clone", repo_url, repo_path])
        else:
            print("Proxy repository already exists. Skipping clone.")
        
        # Add the repo path to Python path
        import sys
        sys.path.insert(0, repo_path)
        
        # Now you can import the module from the cloned repo
        from proxy import some_module
        
        # Call the parent class' run method
        super().run()


APP = ['cborgclientapp.py']
DATA_FILES = [
    'cborg-mini-icon-16x16.png',
    'cacert.pem'
]
OPTIONS = {
    'argv_emulation': False,
    'plist': {
        'LSUIElement': True,
        'CFBundleName': 'CBorg Client 0.1',
        'CFBundleDisplayName': 'Cborg Client 0.1',
        'CFBundleGetInfoString': "LBL Client-side Reverse Proxy",
        'CFBundleIdentifier': "gov.lbl.cborg.client",
        'CFBundleVersion': "0.1.0",
        'CFBundleShortVersionString': "0.1.0",
        'NSHumanReadableCopyright': u"Copyright © 2024, The Regents of the University of California, through Lawrence Berkeley National Laboratory (subject to receipt of any required approvals from the U.S. Dept. of Energy). All rights reserved."
    },
    'includes': ['rumps', 'fastapi', 'uvicorn', 'starlette', 'netifaces', 'collections', 'proxy', 'pyobjc', 'Foundation',
                 'CoreFoundation', 'objc', 'AppKit', 'cborgclient', 'requests', 'certifi'],
    'excludes': [],
    'iconfile': 'cborg-mini-icon.icns',
    'optimize': 2
}

setup(
    name="CBorgClient",
    app=APP,
    data_files=DATA_FILES,
    options={'py2app': OPTIONS},
    setup_requires=['py2app'],
    cmdclass={
        'build_py': CustomBuildPy
    }
)

