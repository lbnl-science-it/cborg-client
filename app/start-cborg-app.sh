#!/bin/sh

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

pip install -r $SCRIPT_DIR/../proxy/requirements.txt
pip install rumps

PYTHONPATH=$SCRIPT_DIR/../proxy python $SCRIPT_DIR/cborgclientapp.py

