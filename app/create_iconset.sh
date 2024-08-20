#!/bin/bash

INPUT_FILE=cborg-mini-icon.png
OUTPUT_DIR=icon.iconset

if [ -z "$INPUT_FILE" ] || [ -z "$OUTPUT_DIR" ]; then
  echo "Usage: $0 <input_file> <output_dir>"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

magick "$INPUT_FILE" -resize 16x16 "$OUTPUT_DIR/icon_16x16.png"
magick "$INPUT_FILE" -resize 32x32 "$OUTPUT_DIR/icon_32x32.png"
magick "$INPUT_FILE" -resize 128x128 "$OUTPUT_DIR/icon_128x128.png"
magick "$INPUT_FILE" -resize 256x256 "$OUTPUT_DIR/icon_256x256.png"
magick "$INPUT_FILE" -resize 512x512 "$OUTPUT_DIR/icon_512x512.png"


iconutil -c icns -o cborg-mini-icon.icns icon.iconset

rm -rf "$OUTPUT_DIR"


