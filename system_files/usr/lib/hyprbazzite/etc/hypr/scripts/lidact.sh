#!/bin/bash
LAPTOP_MONITOR=$(hyprctl monitors all | awk '/Monitor (eDP|LVDS)/ {print $2}' | head -n 1)

# Handling for missing instance signature
if [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    # Point to the modern Hyprland socket directory
    HYPR_DIR="/run/user/$(id -u)/hypr"
    export HYPRLAND_INSTANCE_SIGNATURE=$(command ls -1t "$HYPR_DIR" | head -n 1)
fi

if [ -z "$LAPTOP_MONITOR" ]; then
    echo "Error: No laptop monitor found."
    exit 1
fi

# Check current state using wlr-randr. 
# We look for the monitor name, then check if the very next lines contain "Enabled: yes"
if wlr-randr | grep -A 2 "^$LAPTOP_MONITOR" | grep -q "Enabled: yes"; then
    CURRENT_STATE="on"
else
    CURRENT_STATE="off"
fi

# Determine what action to take based on arguments ($1)
ACTION=$1

# If no argument is passed (or if 'toggle' is explicitly passed), flip the state
if [ -z "$ACTION" ] || [ "$ACTION" == "toggle" ]; then
    if [ "$CURRENT_STATE" == "on" ]; then
        ACTION="off"
    else
        ACTION="on"
    fi
fi

# Execute the wlr-randr commands you requested
if [ "$ACTION" == "on" ]; then
    wlr-randr --output "$LAPTOP_MONITOR" --on
    echo "Turned $LAPTOP_MONITOR ON"
elif [ "$ACTION" == "off" ]; then
    wlr-randr --output "$LAPTOP_MONITOR" --off
    echo "Turned $LAPTOP_MONITOR OFF"
else
    echo "Usage: $0 [on|off|toggle]"
    exit 1
fi