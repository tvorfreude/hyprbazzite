#!/bin/bash
set -euo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
RUNNER="rofi"
ROFI_THEME="$CONFIG_DIR/rofi/config-tritonctl.rasi"

case "${1:-}" in
    "push")
        notify-send "Chezmoi" "Preparing push..."
        if ! command -v chezmoi &>/dev/null; then
            notify-send "Chezmoi" "chezmoi not installed" -u critical
            exit 1
        fi
        if chezmoi git -- status --porcelain | grep -q .; then
            logfile="/tmp/chezmoi-push-$(date +%s).log"
            chezmoi git -- add -A &>>"$logfile"
            chezmoi git -- commit -m "chezmoi: update $(date -u +"%Y-%m-%dT%H:%M:%SZ")" &>>"$logfile" || true
            if chezmoi git -- push &>>"$logfile"; then
                notify-send "Chezmoi" "Changes pushed successfully"
            else
                notify-send "Chezmoi" "Push failed — see $logfile" -u critical
                exit 2
            fi
        else
            notify-send "Chezmoi" "No local changes to push"
        fi
        ;;
    "pull")
        if ! command -v chezmoi &>/dev/null; then
            notify-send "Chezmoi" "chezmoi not installed" -u critical
            exit 1
        fi
        choice=$(echo -e "Yes\nNo" | $RUNNER -dmenu -p "Pull and apply chezmoi changes?" -i -config "$ROFI_THEME")
        if [[ "$choice" != "Yes" ]]; then
            notify-send "Chezmoi" "Pull cancelled"
            exit 0
        fi
        notify-send "Chezmoi" "Pulling and applying dotfiles..."
        logfile="/tmp/chezmoi-pull-$(date +%s).log"
        if chezmoi git -- pull --rebase --autostash &>>"$logfile"; then
            if chezmoi apply &>>"$logfile"; then
                notify-send "Chezmoi" "Pull and apply succeeded"
            else
                notify-send "Chezmoi" "Apply failed — see $logfile" -u critical
                exit 2
            fi
        else
            notify-send "Chezmoi" "Git pull failed — see $logfile" -u critical
            exit 3
        fi
        ;;
    *)
        echo "Usage: $0 {pull|push}"
        exit 1
        ;;
esac
