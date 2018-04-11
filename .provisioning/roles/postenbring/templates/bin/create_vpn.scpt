#!/usr/bin/osascript
tell application "System Preferences"
  reveal pane "com.apple.preference.network"
  activate
  tell application "System Events"
    tell process "System Preferences"
      tell window 1
        click button 1 -- "Add Service"
        tell sheet 1
          -- set location type
          click pop up button 1
          click menu item "VPN" of menu 1 of pop up button 1
          delay 1

          -- set connection type
          click pop up button 2
          click menu item "Cisco IPSec" of menu 1 of pop up button 2
          delay 1

          -- set name of the service
          -- for some reason the standard 'set value of text field 1' would not work
          set value of attribute "AXValue" of text field 1 to "Grunnmur Posten"
          delay 1
          click button 2 -- "Create"
        end tell
        -- click pop up button 1 -- "OK"
        set value of text field 2 to "aksess.posten.no"
        set value of text field 3 to "grunnmur_jorgensen-dahlk"
        click button 4 -- Authentication settings



        delay 1
        -- click pop up button 3 -- "Apply"
      end tell
    end tell
  end tell

end tell
