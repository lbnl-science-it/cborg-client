#!/bin/sh

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

pip install -r $SCRIPT_DIR/requirements.txt 1>/dev/null 2>&1

PYTHONPATH=$SCRIPT_DIR/proxy.py python $SCRIPT_DIR/cborgclient.py

