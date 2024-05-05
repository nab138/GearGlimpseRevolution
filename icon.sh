#!/bin/bash

# Create Resources/AppIcon29x29.png, 40x40, 50x50, 57x57, 60x60, 72x72, 76x76 and the 2x and 3x variants of each 
# from a single 1024x1024 PNG file using ffmpeg.

# Check for input file
if [ ! -f "$1" ]; then
    echo "Usage: icon.sh input.png"
    exit 1
fi


# Create the icons
ffmpeg -y -i "$1" -vf scale=29:29 Resources/AppIcon29x29.png
ffmpeg -y -i "$1" -vf scale=58:58 Resources/AppIcon29x29@2x.png
ffmpeg -y -i "$1" -vf scale=87:87 Resources/AppIcon29x29@3x.png
ffmpeg -y -i "$1" -vf scale=40:40 Resources/AppIcon40x40.png
ffmpeg -y -i "$1" -vf scale=80:80 Resources/AppIcon40x40@2x.png
ffmpeg -y -i "$1" -vf scale=120:120 Resources/AppIcon40x40@3x.png
ffmpeg -y -i "$1" -vf scale=50:50 Resources/AppIcon50x50.png
ffmpeg -y -i "$1" -vf scale=100:100 Resources/AppIcon50x50@2x.png
ffmpeg -y -i "$1" -vf scale=57:57 Resources/AppIcon57x57.png
ffmpeg -y -i "$1" -vf scale=114:114 Resources/AppIcon57x57@2x.png
ffmpeg -y -i "$1" -vf scale=171:171 Resources/AppIcon57x57@3x.png
ffmpeg -y -i "$1" -vf scale=60:60 Resources/AppIcon60x60.png
ffmpeg -y -i "$1" -vf scale=120:120 Resources/AppIcon60x60@2x.png
ffmpeg -y -i "$1" -vf scale=180:180 Resources/AppIcon60x60@3x.png
ffmpeg -y -i "$1" -vf scale=72:72 Resources/AppIcon72x72.png
ffmpeg -y -i "$1" -vf scale=144:144 Resources/AppIcon72x72@2x.png
ffmpeg -y -i "$1" -vf scale=76:76 Resources/AppIcon76x76.png
ffmpeg -y -i "$1" -vf scale=152:152 Resources/AppIcon76x76@2x.png
