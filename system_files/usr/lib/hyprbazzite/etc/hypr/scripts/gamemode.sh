#!/bin/bash
set -euo pipefail

NOTIF="$HOME/.config/swaync/images/ja.png"

HYPRGAMEMODE=$(hyprctl getoption animations:enabled | awk 'NR==1{print $2}')
if [ "$HYPRGAMEMODE" = 1 ] ; then
    hyprctl keyword animations:enabled 0
    hyprctl keyword decoration:shadow:enabled 0
    hyprctl keyword decoration:blur:enabled 0
    hyprctl keyword general:gaps_in 0
    hyprctl keyword general:gaps_out 0
    hyprctl keyword general:border_size 1
    hyprctl keyword decoration:rounding 0
    hyprctl keyword decoration:active_opacity 1.0
    hyprctl keyword decoration:inactive_opacity 1.0
    hyprctl keyword "windowrule opacity 1 override 1 override 1 override, ^(.*)$"
    pkill swaybg || true
    notify-send -e -u low -i "$NOTIF" " Gamemode:" " enabled"
else
    hyprctl keyword animations:enabled 1
    hyprctl keyword decoration:shadow:enabled 1
    hyprctl keyword decoration:blur:enabled 1
    hyprctl keyword general:gaps_in 5
    hyprctl keyword general:gaps_out 20
    hyprctl keyword general:border_size 3
    hyprctl keyword decoration:rounding 10
    hyprctl keyword decoration:active_opacity 1.0
    hyprctl keyword decoration:inactive_opacity 1.0
    hyprctl keyword "windowrule opacity 1 override, ^(.*)$"
    swaybg -i "$HOME/.config/hypr/wallust/current_wallpaper.jpg" -m fill &
    sleep 0.5
    notify-send -e -u normal -i "$NOTIF" " Gamemode:" " disabled"
    hyprctl reload
fi
