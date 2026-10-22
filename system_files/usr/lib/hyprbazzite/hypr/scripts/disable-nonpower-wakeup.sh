#!/usr/bin/env bash
# Disable every wakeup source except the power button and the lid switch.
# Run as root at boot on laptops (tblue-disable-nonpower-wakeup.service)

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
# lid enabled also covers waking from whatever sleep state the machine
# actually ended up in - suspend, or hibernate on hardware where that's
# available (see _sleep_best_effort() / HandleLidSwitch=sleep) - since it's
# the state this hardware's ACPI tables mark LID as wake-capable for.
allowed() { [[ "$1" == LID* || "$1" == *PBTN* || "$1" == *PWRB* ]]; }

# Columns: Device  S-state  Status  [Sysfs node]. Writing a device NAME to
# /proc/acpi/wakeup toggles only the first entry with that name, and names
# repeat (several PCIe ports can all be GPP0 or PXSX): toggling a repeated
# name twice flips the first entry back on and never reaches the second. So
# PCI devices are switched off through their own power/wakeup attribute
# (idempotent), and the name toggle is only used for names listed once.
declare -A name_count=()
while read -r dev _; do
    name_count[$dev]=$(( ${name_count[$dev]:-0} + 1 ))
done < <(tail -n +2 /proc/acpi/wakeup)

while read -r dev _ status node; do
    [[ "$status" == *enabled ]] || continue
    allowed "$dev" && continue
    pci_wakeup="/sys/bus/pci/devices/${node#pci:}/power/wakeup"
    if [[ "$node" == pci:* && -w "$pci_wakeup" ]]; then
        echo disabled > "$pci_wakeup"
        log "Disabled wakeup for $dev (${node#pci:})"
    elif (( name_count[$dev] == 1 )); then
        echo "$dev" > /proc/acpi/wakeup
        log "Disabled wakeup for $dev"
    else
        log "Left $dev enabled: its name is not unique and it has no PCI node to address directly."
    fi
done < <(tail -n +2 /proc/acpi/wakeup)

log "Wakeup devices after filtering:"
cat /proc/acpi/wakeup >&2
