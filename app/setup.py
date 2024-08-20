from setuptools import setup

APP = ['cborgclientapp.py']
DATA_FILES = [
    'cborg-mini-icon-16x16.png'
]
OPTIONS = {
    'argv_emulation': True,
    'plist': {
        'LSUIElement': True,
    },
    'packages': ['rumps', 'fastapi', 'uvicorn', 'starlette', 'proxy.py', 'netifaces'],
    'iconfile': 'cborg-mini-icon.icns'
}

setup(
    app=APP,
    data_files=DATA_FILES,
    options={'py2app': OPTIONS},
    setup_requires=['py2app'],
)
