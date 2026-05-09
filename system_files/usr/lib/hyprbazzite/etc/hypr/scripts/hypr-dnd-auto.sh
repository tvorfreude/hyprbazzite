#!/bin/bash
set -euo pipefail
# Monitor Hyprland socket for fullscreen events and toggle SwayNC DND

handle() {
  case $1 in
    fullscreen\>\>1)
        swaync-client --dnd-on
        ;;
    fullscreen\>\>0)
        swaync-client --dnd-off
        ;;
  esac
}

# Ensure the socket exists before attempting to connect
if [ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    echo "Hyprland instance signature not found." >&2
    exit 1
fi

socat -U - UNIX-CONNECT:/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do handle "$line"; done
