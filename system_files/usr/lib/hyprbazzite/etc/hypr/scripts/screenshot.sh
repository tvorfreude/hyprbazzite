#!/bin/bash
set -euo pipefail

# Path Configuration
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
OUTPUT_DIR="${OMARCHY_SCREENSHOT_DIR:-${XDG_PICTURES_DIR:-$HOME/Pictures}}"

if [[ ! -d "$OUTPUT_DIR" ]]; then
    notify-send "Screenshot directory does not exist: $OUTPUT_DIR" -u critical -t 3000
    exit 1
fi

mode="${1:-region}"

if command -v hyprshot &>/dev/null; then
    pkill slurp || true
    if [[ "$mode" == "clipboard" ]]; then
        hyprshot -m region --raw | wl-copy
        notify-send "Screenshot copied to clipboard"
    else
        hyprshot -m region --raw |
            satty --filename - \
                --output-filename "$OUTPUT_DIR/screenshot-$(date +'%Y-%m-%d_%H-%M-%S').png" \
                --early-exit \
                --actions-on-enter save-to-clipboard \
                --save-after-copy \
                --copy-command 'wl-copy'
    fi
elif command -v slurp &>/dev/null && command -v grim &>/dev/null && command -v swappy &>/dev/null; then
    region=$(slurp)
    if [[ "$mode" == "clipboard" ]]; then
        grim -g "$region" - | wl-copy
        notify-send "Screenshot copied to clipboard"
    else
        grim -g "$region" /tmp/screenshot.png && swappy -f /tmp/screenshot.png && mv /tmp/screenshot.png "$OUTPUT_DIR/screenshot-$(date +'%Y-%m-%d_%H-%M-%S').png"
    fi
else
    notify-send "No screenshot tool (hyprshot or slurp/grim/swappy) found!" -u critical -t 3000
    exit 1
fi
