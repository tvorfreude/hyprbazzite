#!/usr/bin/env bash
# Disable every wakeup source except the power button and the lid switch.
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

# Power button (usually PBTN/PWRB) and the lid switch (usually LID/LID0) are
# the only two things that should be able to wake the machine: random USB/
# PCIe/Thunderbolt bus noise from being jostled in a bag must not, but
# deliberately opening the lid should - same as a real laptop. Keeping the
# lid enabled also covers waking from hibernate (suspend-then-hibernate's
# eventual fallback for long trips), since it's the state this hardware's
# ACPI tables mark LID as wake-capable for.
allowed_wake=$(awk '/PBTN|PWRB|^LID/ {print $1}' /proc/acpi/wakeup)

# Disable all other wakeup devices
grep enabled /proc/acpi/wakeup | awk '{print $1}' | while read -r dev; do
    if ! echo "$allowed_wake" | grep -qx "$dev"; then
        echo "$dev" > /proc/acpi/wakeup
        log "Disabled wakeup for $dev"
    fi
done

log "Wakeup devices after filtering:"
cat /proc/acpi/wakeup >&2
