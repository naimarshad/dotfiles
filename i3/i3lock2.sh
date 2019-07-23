T#!/bin/bash
#depends on: imagemagick, i3lock, scrot
 
IMAGE=/tmp/lockscreen.png
TEXT=/tmp/locktext.png
ICON=/home/naeem/Pictures/screenlock.png
 
scrot $IMAGE
convert $IMAGE -scale 5% -scale 2000% -fill black -colorize 25% $IMAGE
[ -f $TEXT ] || {
    convert -size 1500x60 xc:white -font 'System San Francisco Display Regular' -pointsize 40 -fill black -gravity center -annotate +0+0 'Type password to unlock' $TEXT;
    convert $TEXT -alpha set -channel A -evaluate set 50% $TEXT;
}
convert $IMAGE $TEXT -gravity center -geometry +0+200 -composite $IMAGE
convert $IMAGE $ICON -gravity center -geometry +0-200 -composite -matte $IMAGE
i3lock -u -i $IMAGE
