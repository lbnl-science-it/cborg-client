#!/bin/sh

SCRIPT_DIR=$(cd "$(dirname '$0')" && pwd)

echo "Checking for updates..."
cd $SCRIPT_DIR && git pull

echo "Activate Virtual Environment"
. $SCRIPT_DIR/venv/bin/activate

echo "Python Version Check: "
python3 -V

echo "Start"
python3 $SCRIPT_DIR/cborgclient.py

echo "Deactivate"
deactivate

echo "Done"


