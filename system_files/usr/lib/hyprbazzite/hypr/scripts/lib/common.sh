#!/usr/bin/env bash
# ==============================================================================
# HyprBazzite Common Shell Library
# Source this file from scripts: source /usr/lib/hyprbazzite/hypr/scripts/lib/common.sh
# ==============================================================================

# Strict mode (scripts should still set this themselves, but this ensures it
# if they only source this library)
set -euo pipefail

# --- Standard Paths ---
export HYPRBAZZITE_SCRIPTS_DIR="/usr/lib/hyprbazzite/hypr/scripts"
export HYPRBAZZITE_LIB_DIR="/usr/lib/hyprbazzite"
export CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
export RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

# --- Wayland/Hyprland Environment Discovery ---
# Ensures WAYLAND_DISPLAY and HYPRLAND_INSTANCE_SIGNATURE are set,
# even in contexts like systemd services or SSH sessions.
ensure_hyprland_env() {
    if [[ -z "${XDG_RUNTIME_DIR:-}" ]]; then
        export XDG_RUNTIME_DIR="/run/user/$(id -u)"
    fi

    if [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
        WAYLAND_DISPLAY=$(command ls -1 "$XDG_RUNTIME_DIR" 2>/dev/null | grep -E '^wayland-[0-9]+$' | head -n 1 || true)
        export WAYLAND_DISPLAY
    fi

    if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        local hypr_dir="$XDG_RUNTIME_DIR/hypr"
        if [[ -d "$hypr_dir" ]]; then
            HYPRLAND_INSTANCE_SIGNATURE=$(command ls -1t "$hypr_dir" 2>/dev/null | head -n 1 || true)
            export HYPRLAND_INSTANCE_SIGNATURE
        fi
    fi
}

# --- Notification Helper ---
# Usage: notify "Title" "Message" [urgency]
# urgency: low, normal (default), critical
notify() {
    local title="${1:-}"
    local msg="${2:-}"
    local urgency="${3:-normal}"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -u "$urgency" "$title" "$msg"
    fi
}

# --- JSON Escape Helper ---
# Usage: json_escape "string with special chars"
json_escape() {
    local s="$1"
    s=${s//\\/\\\\}
    s=${s//\"/\\\"}
    s=${s//$'\n'/\\n}
    printf '%s' "$s"
}

# --- Launcher/Menu Detection ---
# Returns the best available menu runner (wofi, rofi, or dmenu)
detect_runner() {
    if command -v wofi >/dev/null 2>&1; then
        echo "wofi"
    elif command -v rofi >/dev/null 2>&1; then
        echo "rofi"
    elif command -v dmenu >/dev/null 2>&1; then
        echo "dmenu"
    else
        echo ""
    fi
}

# --- Require Commands ---
# Usage: require_commands hyprctl jq notify-send
# Exits with error if any command is missing
require_commands() {
    local missing=()
    for cmd in "$@"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        notify "Missing Dependencies" "Required commands not found: ${missing[*]}" "critical"
        echo "Error: Missing required commands: ${missing[*]}" >&2
        return 1
    fi
}

# --- Laptop Monitor Detection ---
# Returns the name of the internal laptop display (eDP or LVDS)
get_laptop_monitor() {
    hyprctl monitors all 2>/dev/null | awk '/Monitor (eDP|LVDS)/ {print $2}' | head -n 1
}

# --- Log Helper (for system scripts) ---
# Usage: log "message"
log() {
    echo "[$(basename "${BASH_SOURCE[1]:-$0}")] $*" >&2
}
