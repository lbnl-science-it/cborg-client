#!/bin/sh

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

source $SCRIPT_DIR/venv/bin/activate

python3 $SCRIPT_DIR/cborgclient.py

deactivate

