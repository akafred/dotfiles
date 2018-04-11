#!/usr/bin/osascript
tell application "System Events"
    do shell script "scutil --nc stop 'Grunnmur Posten'"
    do shell script "scutil --nc stop 'Selvdrift Posten'"
    do shell script "scutil --nc start 'Selvdrift Posten'"
    delay 1

    -- repeat until exists window "Save" of process "Evernote"
    -- end repeat

    tell application id "com.apple.systemevents"
        delay 1
        keystroke "{{ selvdrift_pwd }}"
        keystroke (key code 36) -- enter
    end tell
end tell
