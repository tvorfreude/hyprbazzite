#!/bin/bash
set -euo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
apps=(hypridle mako waybar fcitx5 swaybg)

for app in "${apps[@]}"; do
    pkill "$app" || true
done

hypridle &
mako &
waybar &
fcitx5 &
swaybg -i "$CONFIG_DIR/hypr/wallust/current_wallpaper.jpg" -m fill &
notify-send "TritonCtl" "Session apps refreshed."
