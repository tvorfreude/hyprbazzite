#!/bin/bash
set -euo pipefail
# Screenshot script with Actions
# Usage: screenshot.sh [full|area]

MODE="${1:-full}"
FILE="$HOME/Pictures/Screenshots/$(date +'%Y-%m-%d_%H-%M-%S').png"
mkdir -p "$HOME/Pictures/Screenshots"

if [ "$MODE" == "area" ]; then
    grim -g "$(slurp)" "$FILE"
else
    grim "$FILE"
fi

if [ -f "$FILE" ]; then
    # Copy to clipboard
    wl-copy < "$FILE"
    
    # Notify with actions
    # --wait blocks until action is clicked or notification expires/closes
    ACTION=$(notify-send -i "$FILE" "Screenshot Taken" "Saved to clipboard.\nClick 'Edit' to annotate." \
        --action="edit=Edit" \
        --action="show=Show in Folder" \
        --wait)
        
    case "$ACTION" in
        "edit")
            swappy -f "$FILE"
            ;;
        "show")
            # Use xdg-open for universality over thunar
            xdg-open "$HOME/Pictures/Screenshots"
            ;;
    esac
fi
