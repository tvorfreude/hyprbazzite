#!/usr/bin/env bash
# Disable all wakeup sources except the power button
# Run as root at boot (e.g., via systemd service)

set -euo pipefail

log() { echo "[wakeup-filter] $*" >&2; }

# Guard against non-ACPI systems (VMs, ARM, etc.)
if [[ ! -f /proc/acpi/wakeup ]]; then
    log "No ACPI wakeup file found, skipping."
    exit 0
fi

# Find all wakeup devices
log "Wakeup devices before filtering:"
cat /proc/acpi/wakeup >&2

# Get the power button device (usually PBTN or PWRB)
power_btns=$(awk '/PBTN|PWRB/ {print $1}' /proc/acpi/wakeup)

# Disable all other wakeup devices
grep enabled /proc/acpi/wakeup | awk '{print $1}' | while read -r dev; do
    if ! echo "$power_btns" | grep -q "$dev"; then
        echo "$dev" > /proc/acpi/wakeup
        log "Disabled wakeup for $dev"
    fi
done

log "Wakeup devices after filtering:"
cat /proc/acpi/wakeup >&2
