#!/bin/bash
set -euo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
WOFI_CONFIG="$CONFIG_DIR/wofi/config"

gtk_mode=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null)
mode_label="(light mode)"
[[ "$gtk_mode" == "'prefer-dark'" ]] && mode_label="(dark mode)"

options="Choose Kitty Terminal Theme\nGTK Settings (nwg-look)\nQT Apps Settings (qt6ct)\nQT Apps Settings (qt5ct)\nSwitch Dark-Light Theme $mode_label"
choice=$(echo -e "$options" | wofi -i -dmenu -config "$WOFI_CONFIG" -p "Configuration")

case "${choice%% *}" in
    "Choose Kitty Terminal Theme")
        kitty_theme_dir="$CONFIG_DIR/kitty/themes"
        if [ ! -d "$kitty_theme_dir" ]; then
            notify-send "QuickSettings" "Kitty themes directory not found."
            exit 1
        fi
        themes=$(ls "$kitty_theme_dir" | grep '\.conf$' | sed 's/\.conf$//')
        selected_theme=$(echo "$themes" | wofi -dmenu -p "Kitty Theme" -i -config "$WOFI_CONFIG")
        if [ -n "$selected_theme" ]; then
            sed -i "/^include themes\//d" "$CONFIG_DIR/kitty/kitty.conf"
            echo "include themes/$selected_theme.conf" >> "$CONFIG_DIR/kitty/kitty.conf"
            pkill -USR1 kitty
            notify-send "QuickSettings" "Kitty theme set to $selected_theme."
        fi
        ;;
    "GTK Settings (nwg-look)")
        command -v nwg-look &>/dev/null && nwg-look || notify-send "QuickSettings" "Install nwg-look first"
        ;;
    "QT Apps Settings (qt6ct)")
        command -v qt6ct &>/dev/null && qt6ct || notify-send "QuickSettings" "Install qt6ct first"
        ;;
    "QT Apps Settings (qt5ct)")
        command -v qt5ct &>/dev/null && qt5ct || notify-send "QuickSettings" "Install qt5ct first"
        ;;
    "Switch Dark-Light Theme")
        gtk_dark="Adwaita-dark"
        gtk_light="Adwaita"
        qt_dark="Adwaita-dark"
        qt_light="Adwaita"
        gtk_mode=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null)
        if [[ "$gtk_mode" == "'prefer-dark'" ]]; then
            gsettings set org.gnome.desktop.interface gtk-theme "$gtk_light"
            gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
            sed -i "s/^theme = .*/theme = $qt_light/" "$CONFIG_DIR/qt5ct/qt5ct.conf" 2>/dev/null
            sed -i "s/^theme = .*/theme = $qt_light/" "$CONFIG_DIR/qt6ct/qt6ct.conf" 2>/dev/null
            notify-send "QuickSettings" "Switched to light mode for GTK and QT apps."
        else
            gsettings set org.gnome.desktop.interface gtk-theme "$gtk_dark"
            gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
            sed -i "s/^theme = .*/theme = $qt_dark/" "$CONFIG_DIR/qt5ct/qt5ct.conf" 2>/dev/null
            sed -i "s/^theme = .*/theme = $qt_dark/" "$CONFIG_DIR/qt6ct/qt6ct.conf" 2>/dev/null
            notify-send "QuickSettings" "Switched to dark mode for GTK and QT apps."
        fi
        hyprctl reload
        ;;
esac
