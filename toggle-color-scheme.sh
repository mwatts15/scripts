#!/bin/sh

dynamic-colors cycle
colorscheme=$(cat ~/.dynamic-colors/colorscheme)
if [ "$colorscheme" = "solarized-dark" ] ; then
    feh --bg-fill "$HOME/pictures/wp/solarized-dark-bg.png" &
    cp ~/.xmobarrc-dark ~/.xmobarrc
    cp ~/.xmobarrc_bottom-dark ~/.xmobarrc_
else
    feh --bg-fill "$HOME/pictures/wp/solarized-light-bg.png" &
    cp ~/.xmobarrc-light ~/.xmobarrc
    cp ~/.xmobarrc_bottom-light ~/.xmobarrc_
fi
echo > ~/.last_dynamic_colors
pkill -9 xmobar
xmobar < "/tmp/${USER}-dynamic-log-pipe" &
xmobar "$HOME/.xmobarrc_" &
