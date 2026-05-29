#!/bin/bash
set -euo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
THEME="$CONFIG_DIR/rofi/config-powermenu.rasi"
OPTIONS="  Shutdown\n  Reboot\n  Suspend\n⏾  Hybrid Sleep\n  Lock\n  Logout"

choice=$(echo -e "$OPTIONS" | rofi -dmenu -p "⏻ Power Menu" -i -config "$THEME")

case "$choice" in
    *Shutdown*) systemctl poweroff ;;
    *Reboot*) systemctl reboot ;;
    *Suspend*) systemctl suspend ;;
    *Hybrid\ Sleep*) systemctl suspend-then-hibernate ;;
    *Lock*) hyprlock ;;
    *Logout*) hyprctl dispatch exit ;;
esac
