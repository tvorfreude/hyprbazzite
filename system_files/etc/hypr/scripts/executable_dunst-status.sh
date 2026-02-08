#!/usr/bin/env bash
set -euo pipefail

if ! command -v dunstctl >/dev/null 2>&1; then
  printf '{"text":"N","class":"missing","tooltip":"dunstctl not found"}'
  exit 0
fi

paused="$(dunstctl is-paused 2>/dev/null || echo false)"

if [ "$paused" = "true" ]; then
  printf '{"text":"","class":"paused","tooltip":"Notifications paused"}'
  exit 0
fi

count="$(dunstctl count waiting 2>/dev/null || echo 0)"
printf '{"text":"","class":"active","tooltip":"Notifications: %s"}' "$count"
