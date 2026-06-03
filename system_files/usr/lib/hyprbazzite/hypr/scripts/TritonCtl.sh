#!/bin/bash
set -euo pipefail

# --- Configuration ---
RUNNER="wofi"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
ROFI_THEME="$CONFIG_DIR/rofi/config-tritonctl.rasi"
SCRIPTS_DIR="/usr/lib/hyprbazzite/hypr/scripts"

# --- Help Function ---
show_help() {
    echo "Usage: $0 [subcommand] [args...]"
    echo ""
    echo "A centralized control script for Hyprland dotfiles."
    echo "It acts as a dispatcher for scripts located in $SCRIPTS_DIR."
    echo ""
    echo "Subcommands (scripts):"
    ls "$SCRIPTS_DIR" | grep '\.sh$' | sed 's/\.sh//' | sort | awk '{print "  " $1}'
    echo ""
    echo "Run '$0' without arguments to show the Rofi menu."
}

# --- Rofi Menu ---
show_menu() {
    local gamemode_status="Gamemode (disabled)"
    local gamemode_enabled=$(hyprctl getoption animations:enabled | awk 'NR==1{print $2}')
    [[ "$gamemode_enabled" == "0" ]] && gamemode_status="Gamemode (enabled)"

    # Generate list from script files, replacing 'gamemode' with current status
    local options=$(ls "$SCRIPTS_DIR" | grep '\.sh$' | sed 's/\.sh//' | sort | sed "s/^gamemode$/$gamemode_status/")

    local rofi_cmd="$RUNNER -dmenu -p '🔱 TritonCtl' -i"
    [[ -f "$ROFI_THEME" ]] && rofi_cmd="$rofi_cmd -config $ROFI_THEME"
    
    local choice=$(echo "$options" | $rofi_cmd)

    if [ -n "$choice" ]; then
        if [[ "$choice" == *"Gamemode"* ]]; then
            "$SCRIPTS_DIR/gamemode.sh"
        else
            # Map the selection back to the script file
            local script_name=$(echo "$choice" | grep -v "Gamemode" | tr '[:upper:]' '[:lower:]')
            # Simple mapping for human-readable names if needed, otherwise use the filename
            if [[ -f "$SCRIPTS_DIR/$script_name.sh" ]]; then
                "$SCRIPTS_DIR/$script_name.sh" "$@"
            fi
        fi
    fi
}

# --- Main Logic ---
main() {
    if [ -z "$1" ]; then
        show_menu
        exit 0
    fi

    local subcommand="$1"
    shift

    if [[ "$subcommand" == "help" || "$subcommand" == "--help" ]]; then
        show_help
    elif [[ -f "$SCRIPTS_DIR/$subcommand.sh" ]]; then
        "$SCRIPTS_DIR/$subcommand.sh" "$@"
    else
        echo "Error: Subcommand '$subcommand' not found in $SCRIPTS_DIR." >&2
        echo "Run '$0 help' for a list of available commands." >&2
        exit 1
    fi
}

main "$@"

