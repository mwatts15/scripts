#!/bin/sh
#Graphical wrapper for journal
xterm -e sh -c "~/bin/journal \"`zenity --entry \"Title\" 10 43 2>&1`\""
