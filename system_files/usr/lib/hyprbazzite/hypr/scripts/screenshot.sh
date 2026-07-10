#!/bin/bash
set -euo pipefail

# Path Configuration
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
OUTPUT_DIR="${OMARCHY_SCREENSHOT_DIR:-${XDG_PICTURES_DIR:-$HOME/Pictures}}"

if [[ ! -d "$OUTPUT_DIR" ]]; then
    notify-send "Screenshot directory does not exist: $OUTPUT_DIR" -u critical -t 3000
    exit 1
fi

mode="${1:-region}" # region, window, output, clipboard
TIMESTAMP=$(date +'%Y-%m-%d_%H-%M-%S')
FILENAME="screenshot-$TIMESTAMP.png"

# Check for editor
if command -v satty &>/dev/null; then
    EDITOR="satty --filename - --output-filename $OUTPUT_DIR/$FILENAME --early-exit --actions-on-enter save-to-clipboard --save-after-copy --copy-command wl-copy"
elif command -v swappy &>/dev/null; then
    EDITOR="swappy -f - -o $OUTPUT_DIR/$FILENAME"
else
    EDITOR="cat > $OUTPUT_DIR/$FILENAME"
fi

if command -v hyprshot &>/dev/null; then
    pkill slurp || true
    case "$mode" in
        clipboard)
            hyprshot -m region --raw | wl-copy
            notify-send "Screenshot" "Region copied to clipboard" -i camera-photo
            ;;
        window)
            hyprshot -m window --raw | $EDITOR
            ;;
        output)
            hyprshot -m output --raw | $EDITOR
            ;;
        *)
            hyprshot -m region --raw | $EDITOR
            ;;
    esac
elif command -v grim &>/dev/null; then
    pkill slurp || true
    case "$mode" in
        clipboard)
            grim -g "$(slurp)" - | wl-copy
            notify-send "Screenshot" "Region copied to clipboard" -i camera-photo
            ;;
        output)
            grim - | $EDITOR
            ;;
        *)
            grim -g "$(slurp)" - | $EDITOR
            ;;
    esac
else
    notify-send "No screenshot tool (hyprshot or slurp/grim/swappy) found!" -u critical -t 3000
    exit 1
fi
