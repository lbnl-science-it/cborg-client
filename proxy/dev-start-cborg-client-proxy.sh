#!/bin/sh

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

pip install -r requirements.txt

PYTHONPATH=~/projects/proxy.py:$PYTHONPATH python $SCRIPT_DIR/cborgclient.py

