#!/bin/sh

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
CONFIG_FILE=~/.continue/config.json
OLD_CONFIG_FILE=~/.continue/config.json.old

# Check if the config file exists before attempting to move it
if [ -f "$CONFIG_FILE" ]; then
  # Check if the old config file already exists
  if [ -f "$OLD_CONFIG_FILE" ]; then
    rm "$OLD_CONFIG_FILE"
  fi
  mv "$CONFIG_FILE" "$OLD_CONFIG_FILE"
fi

# Create a symbolic link to the config.json in the current directory
# This will overwrite any existing file with the same name
ln -sf $SCRIPT_DIR/config.json ~/.continue/config.json

