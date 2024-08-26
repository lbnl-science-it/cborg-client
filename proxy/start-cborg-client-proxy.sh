#!/bin/sh

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

pip install -r $SCRIPT_DIR/requirements.txt

python $SCRIPT_DIR/cborgclient.py

