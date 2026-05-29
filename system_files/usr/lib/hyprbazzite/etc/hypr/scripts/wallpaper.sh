#!/bin/bash
set -euo pipefail

# --- Configuration ---
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
WALL_DIR="$HOME/Pictures/wallpapers"
WALLUST_DIR="$CONFIG_DIR/hypr/wallust"
WALLUST_CURRENT_WALL="$WALLUST_DIR/current_wallpaper.jpg"
ROFI_THEME="$CONFIG_DIR/rofi/config-wallpaper.rasi"
RUNNER="rofi"

if ! command -v jq &>/dev/null || ! command -v bc &>/dev/null; then
    notify-send "TritonCtl" "Missing dependency: jq or bc"
    exit 1
fi

handle_selection() {
    local wall_path="$1"
    if [ -z "$wall_path" ]; then return; fi

    if [ "$wall_path" = "Random" ]; then
        mapfile -d '' wall_files < <(find "$WALL_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.bmp" -o -iname "*.webp" \) -print0)
        if [ ${#wall_files[@]} -eq 0 ]; then
            notify-send -u critical "Error" "No wallpapers found in $WALL_DIR"
            return
        fi
        wall_path="${wall_files[$((RANDOM % ${#wall_files[@]}))]}"
    fi

    mkdir -p "$WALLUST_DIR"
    local wallust_png="$WALLUST_DIR/current_wallpaper.png"
    magick convert "$wall_path" "$wallust_png"
    cp "$wall_path" "$WALLUST_CURRENT_WALL"

    wallust run "$WALLUST_CURRENT_WALL" -s
    hyprctl reload
    swaybg -i "$WALLUST_CURRENT_WALL" -m fill &
    notify-send "Wallpaper and Theme Changed" "$(basename "$wall_path")"
}

mapfile -d '' wall_files < <(find "$WALL_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.bmp" -o -iname "*.webp" \) -print0)
if [ ${#wall_files[@]} -eq 0 ]; then
    notify-send -u critical "TritonCtl" "No wallpapers found in $WALL_DIR"
    exit 1
fi

random_wall="${wall_files[$((RANDOM % ${#wall_files[@]}))]}"

generate_list() {
    echo -e "Random\x00icon\x1f$random_wall"
    for wall in "${wall_files[@]}"; do
        local filename=$(basename "$wall")
        local label="${filename%.*}"
        printf "%s\x00icon\x1f%s\n" "$label" "$wall"
    done | sort
}

choice=$(generate_list | $RUNNER -dmenu -p "🖼️ Wallpaper" -i -config "$ROFI_THEME")

if [ -n "$choice" ]; then
    if [ "$choice" = "Random" ]; then
        handle_selection "Random"
    else
        selected_path=$(find "$WALL_DIR" -type f -name "$choice.*" -print -quit)
        if [ -n "$selected_path" ]; then
            handle_selection "$selected_path"
        fi
    fi
fi
