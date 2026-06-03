#!/usr/bin/env bash

# 1. Force the runtime directory (Vital for SSH sessions and hotkey daemons)
if [ -z "$XDG_RUNTIME_DIR" ]; then
    export XDG_RUNTIME_DIR="/run/user/$(id -u)"
fi

# 2. Automatically find and expose the Wayland socket for wlr-randr
if [ -z "$WAYLAND_DISPLAY" ]; then
    export WAYLAND_DISPLAY=$(command ls -1 "$XDG_RUNTIME_DIR" | grep -E '^wayland-[0-9]+$' | head -n 1)
fi

# 3. Automatically find and expose the Hyprland instance signature for hyprctl
if [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    HYPR_DIR="$XDG_RUNTIME_DIR/hypr"
    export HYPRLAND_INSTANCE_SIGNATURE=$(command ls -1t "$HYPR_DIR" | head -n 1)
fi

# 4. Find the laptop's internal display name
LAPTOP_MONITOR=$(hyprctl monitors all | awk '/Monitor (eDP|LVDS)/ {print $2}' | head -n 1)

if [ -z "$LAPTOP_MONITOR" ]; then
    echo "Error: No laptop monitor found."
    exit 1
fi

# 5. Check the current monitor state using the hyprctl active list
if hyprctl monitors | grep -q "Monitor $LAPTOP_MONITOR"; then
    CURRENT_STATE="on"
else
    CURRENT_STATE="off"
fi

# 6. Parse arguments (on, off, or toggle)
ACTION=$1

if [ -z "$ACTION" ] || [ "$ACTION" == "toggle" ]; then
    if [ "$CURRENT_STATE" == "on" ]; then
        ACTION="off"
    else
        ACTION="on"
    fi
fi

# 7. Execute the power command using hyprctl dpms dispatch
if [ "$ACTION" == "on" ]; then
    hyprctl dispatch "hl.dsp.dpms({action = 'on', monitor = '$LAPTOP_MONITOR'})"
    echo "Successfully turned $LAPTOP_MONITOR ON"
elif [ "$ACTION" == "off" ]; then
    hyprctl dispatch "hl.dsp.dpms({action = 'off', monitor = '$LAPTOP_MONITOR'})"
    echo "Successfully turned $LAPTOP_MONITOR OFF"
else
    echo "Usage: $0 [on|off|toggle]"
    exit 1
fi
