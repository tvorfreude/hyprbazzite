#!/bin/bash

SELECTION=$(echo -e "  Shutdown\n  Reboot\n  Logout\n  Lock\n  Suspend\n⏾  Hibernate" | wofi --dmenu --conf /etc/wofi/config --style /etc/wofi/style.css --width 250 --height 250 --prompt "Power Menu")

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
	"⏾  Hibernate")
		systemctl hibernate
		;;
esac
