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
# We check if the monitor is NOT disabled
if hyprctl -j monitors all | jq -e ".[] | select(.name == \"$LAPTOP_MONITOR\" and .disabled == false)" > /dev/null; then
    CURRENT_STATE="on"
else
    CURRENT_STATE="off"
fi

# 6. Parse arguments (on, off, toggle, lid-close, lid-open)
ACTION=$1

# Lid-event actions decide between clamshell mode and sleep based on whether
# any EXTERNAL display is connected. Called from the Hyprland Lid Switch binds.
if [ "$ACTION" == "lid-close" ]; then
    # Count enabled monitors that are NOT the internal laptop panel.
    EXT_COUNT=$(hyprctl -j monitors all \
        | jq "[.[] | select(.name != \"$LAPTOP_MONITOR\" and .disabled == false)] | length")
    if [ "${EXT_COUNT:-0}" -gt 0 ]; then
        # Docked: clamshell -- just turn the internal panel off, keep working.
        ACTION="off"
    else
        # Undocked: sleep. Plain S3 suspend is unreliable on this UEFI/TPM box,
        # so use the configured suspend-then-hibernate path (/etc/systemd/sleep.conf).
        # Lock first so the machine is locked on resume.
        loginctl lock-session 2>/dev/null || true
        exec systemctl suspend-then-hibernate
    fi
elif [ "$ACTION" == "lid-open" ]; then
    ACTION="on"
fi

if [ -z "$ACTION" ] || [ "$ACTION" == "toggle" ]; then
    if [ "$CURRENT_STATE" == "on" ]; then
        ACTION="off"
    else
        ACTION="on"
    fi
fi

if [ "$ACTION" == "on" ]; then
    # Re-apply monitors.lua (the single source of truth for mode/scale/position)
    # so the panel comes back exactly as configured rather than at "preferred".
    hyprctl reload
    echo "Successfully turned $LAPTOP_MONITOR ON"
elif [ "$ACTION" == "off" ]; then
    hyprctl eval "hl.monitor({ output = \"$LAPTOP_MONITOR\", disabled = true })"
    echo "Successfully turned $LAPTOP_MONITOR OFF"
else
    echo "Usage: $0 [on|off|toggle|lid-close|lid-open]"
    exit 1
fi
