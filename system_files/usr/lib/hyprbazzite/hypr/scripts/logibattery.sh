#!/bin/bash
set -euo pipefail

BIN="/usr/bin/headsetcontrol"
if ! command -v "$BIN" &>/dev/null; then
    exit 1
fi

out=$($BIN -b 2>/dev/null) || exit 1
low_out=$(printf "%s" "$out" | tr '[:upper:]' '[:lower:]')

if printf "%s" "$low_out" | grep -E -q "not found|no headset|not connected|disconnected|power: *off|state: *off|status: *off"; then
    printf "%s\n" "-1"
    exit 0
fi

level_field=$(printf "%s" "$out" | awk -F'Level:' '/Level:/ {print $2; exit}' | tr -d ' \t')
if [ -z "$level_field" ]; then
    exit 1
fi

pct_signed=$(printf "%s" "$level_field" | sed -n 's/^\([+-]\?[0-9]\+\).*/\1/p')
if [ -z "$pct_signed" ] || [[ "$pct_signed" =~ ^- ]]; then
    exit 1
fi

printf "%s\n" "${pct_signed#+}"
