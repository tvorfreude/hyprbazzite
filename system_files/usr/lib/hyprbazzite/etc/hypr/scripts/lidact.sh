#!/bin/bash
set -euo pipefail

# --- Configuration ---
# Recommended: Use 'hyprctl monitors' to find your exact internal display name
INTERNAL_MONITOR_NAME="eDP-1"
INTERNAL_MONITOR_DESC="desc:Thermotrex Corporation TL134ADXP01-0"
INTERNAL_MONITOR_MODE="2560x1600@165.0"
INTERNAL_MONITOR_SCALE="1.6"

# Function to check if any monitor OTHER than the internal one is connected
is_external_monitor_connected() {
    local monitor_count=$(hyprctl monitors | grep -c "Monitor")
    # If more than 1 monitor exists, an external one is present
    [[ "$monitor_count" -gt 1 ]]
}

# Since this is called by udev, we need to ensure it runs as the logged-in user
# to interact with the Hyprland socket.
USER=$(whoami)
USER_ID=$(id -u $USER)

# If running as root (udev), switch to the first logged-in user
if [[ "$USER" == "root" ]]; then
    # Find the actual user running the XDG session
    USER=$(loginctl list-users | awk 'NR==2 {print $2}')
    USER_ID=$(id -u $USER)
    
    # Construct the command to run as user
    CMD="sudo -u $USER DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$USER_ID/bus"
else
    CMD=""
fi

case "${1:-}" in
    "close")
        # We use the constructed CMD to execute the logic as the user
        $CMD bash -c "
            if is_external_monitor_connected() {
                # This is a simplified version of the logic for the subshell
                # because bash functions can't be easily exported to sudo
                mon_count=\$(hyprctl monitors | grep -c 'Monitor')
                if [[ \$mon_count -gt 1 ]]; then
                    hyprctl keyword monitor '${INTERNAL_MONITOR_DESC},disable'
                    notify-send 'Lid closed' 'External monitor active, internal screen disabled.' -t 2000
                else
                    dbus-send --system --print-reply --dest=org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager.Suspend boolean:true
                fi
            }
        "
        ;;
    "open")
        $CMD bash -c "
            until hyprctl monitors | grep -q '${INTERNAL_MONITOR_NAME}'; do
                sleep 0.5
            done
            hyprctl keyword monitor '${INTERNAL_MONITOR_DESC},${INTERNAL_MONITOR_MODE},auto,${INTERNAL_MONITOR_SCALE}'
            notify-send 'Lid opened' 'Internal screen restored.' -t 2000
        "
        ;;
    *)
        # udev often passes the device path as $1, we ignore it unless it's open/close
        # but the rule we wrote just runs the script. We need to detect the state.
        # Since udev doesn't tell us 'open' or 'close' in the script args easily,
        # we check the actual state of the switch.
        STATE=$(grep -q "opened" /proc/acpi/button/lid/*/state || echo "closed")
        if [[ "$STATE" == "closed" ]]; then
            $0 close
        else
            $0 open
        fi
        ;;
esac

