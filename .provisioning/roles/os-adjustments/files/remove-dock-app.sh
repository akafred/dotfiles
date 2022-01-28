#! /usr/bin/env bash
dloc=$(defaults read com.apple.dock persistent-apps | grep file-label | awk "/$1/  {printf NR}")
if [ "$dloc" != "" ] ;
then
   dloc=$[$dloc-1]
   /usr/libexec/PlistBuddy -c "Delete persistent-apps:$dloc" ~/Library/Preferences/com.apple.dock.plist
   sleep 3
   osascript -e 'delay 3' -e 'tell Application "Dock"' -e 'quit' -e 'end tell'
   echo $1 removed from Dock
else
   echo $1 not in Dock
fi
