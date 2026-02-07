#!/bin/bash
# Power Menu Script for Wofi

# Wofi menu options
options="Shutdown\nReboot\nSuspend\nCancel"

# Show wofi menu
chosen=$(echo -e "$options" | wofi --show dmenu --conf /etc/wofi/config --style /etc/wofi/style.css --prompt "Power")

case "$chosen" in
    "Shutdown")
        systemctl poweroff
        ;;
    "Reboot")
        systemctl reboot
        ;;
    "Suspend")
        systemctl suspend
        ;;
    *)
        exit 0
        ;;
esac
