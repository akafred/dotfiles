#!/usr/bin/osascript
tell application "System Events"
    do shell script "scutil --nc stop 'Grunnmur Posten'"
    -- do shell script "scutil --nc stop 'Selvdrift Posten'"
end tell
