#!/bin/bash

if [ "$1" = status ]; then
  dbus-send --print-reply --session --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:'org.mpris.MediaPlayer2.Player' string:'PlaybackStatus' | tail -n1 | cut -d'"' -f2
elif [ "$1" = song ]; then
  title=`dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:'org.mpris.MediaPlayer2.Player' string:'Metadata'| grep -E -A 1 "title"|cut -b 44-|cut -d '"' -f 1| grep -E -v ^$`
  artist=`dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get string:'org.mpris.MediaPlayer2.Player' string:'Metadata'| grep -E -A 2 "artist"|cut -b 20-|cut -d '"' -f 2| grep -E -v ^$| grep -E -v array| grep -E -v artist`
  echo $artist '|' $title
else
  echo "No argument specified to the script who gets info from Spotify. Try using 'status' or 'song'."
fi
