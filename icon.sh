#!/bin/bash

# Create Resources/AppIcon29x29.png, 40x40, 50x50, 57x57, 60x60, 72x72, 76x76 and the 2x and 3x variants of each 
# from a single 1024x1024 PNG file using ffmpeg.

# Check for input file
if [ ! -f "$1" ]; then
    echo "Usage: icon.sh input.png"
    exit 1
fi


# Create the icons
ffmpeg -i "$1" -vf scale=29:29 Resources/AppIcon29x29.png
ffmpeg -i "$1" -vf scale=40:40 Resources/AppIcon40x40.png
ffmpeg -i "$1" -vf scale=50:50 Resources/AppIcon50x50.png
ffmpeg -i "$1" -vf scale=57:57 Resources/AppIcon57x57.png
ffmpeg -i "$1" -vf scale=60:60 Resources/AppIcon60x60.png
ffmpeg -i "$1" -vf scale=72:72 Resources/AppIcon72x72.png
ffmpeg -i "$1" -vf scale=76:76 Resources/AppIcon76x76.png
