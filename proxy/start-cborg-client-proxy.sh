#!/bin/sh

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

pip install -r requirements.txt

python $SCRIPT_DIR/cborgclient.py

