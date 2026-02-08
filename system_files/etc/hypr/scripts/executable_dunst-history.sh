#!/usr/bin/env bash
set -euo pipefail

if ! command -v dunstctl >/dev/null 2>&1; then
  printf '%s\n' "dunstctl not found" | wofi --show dmenu --prompt "Notifications" --conf /etc/wofi/config --style /etc/wofi/style.css
  exit 0
fi

history_json="$(dunstctl history 2>/dev/null || true)"

if [ -z "$history_json" ]; then
  printf '%s\n' "No notifications" | wofi --show dmenu --prompt "Notifications" --conf /etc/wofi/config --style /etc/wofi/style.css
  exit 0
fi

if command -v jq >/dev/null 2>&1; then
  entries="$(printf '%s' "$history_json" | jq -r '.data[]? | .[]? | "\(.appname.data // "App") | \(.summary.data // "") - \(.body.data // "")"' | sed 's/[[:space:]]\+/ /g' | sed 's/[[:space:]]$//')"
else
  entries="Install jq to view notifications"
fi

if [ -z "$entries" ]; then
  entries="No notifications"
fi

printf '%s\n' "$entries" | wofi --show dmenu --prompt "Notifications" --conf /etc/wofi/config --style /etc/wofi/style.css
