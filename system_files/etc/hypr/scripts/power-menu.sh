#!/bin/bash

SELECTION=$(echo -e "  Shutdown\n  Reboot\n  Logout\n  Lock\n  Suspend" | wofi --dmenu --conf /etc/wofi/config --style /etc/wofi/style.css --width 250 --height 210 --prompt "Power Menu")

case "$SELECTION" in
	"  Shutdown")
		systemctl poweroff
		;;
	"  Reboot")
		systemctl reboot
		;;
	"  Logout")
		hyprctl dispatch exit
		;;
	"  Lock")
		hyprlock
		;;
	"  Suspend")
		systemctl suspend
		;;
esac
