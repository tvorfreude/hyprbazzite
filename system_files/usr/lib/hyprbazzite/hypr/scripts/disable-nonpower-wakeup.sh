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

# /proc/acpi/wakeup columns: Device  S-state  Status  [Sysfs node]. A device
# with several physical nodes gets one line per node, the extra ones as
# continuation lines that start with whitespace and carry only Status and
# node. Prints "kind dev status node" per line (kind h = header, c =
# continuation; node "-" when there is none).
entries() {
    local line kind dev="" status node
    while IFS= read -r line; do
        status="" node=""
        if [[ "$line" == [[:space:]]* ]]; then
            kind=c; read -r status node <<<"$line"
        else
            kind=h; read -r dev _ status node <<<"$line"
        fi
        [[ -n "$dev" ]] && printf '%s %s %s %s\n' "$kind" "$dev" "$status" "${node:--}"
    done < <(tail -n +2 /proc/acpi/wakeup)
}

# Pass 1: switch every node off through its own power/wakeup attribute
# (idempotent). Writing a device NAME to /proc/acpi/wakeup instead toggles
# only the first entry with that name, and names repeat (several PCIe ports
# can all be GPP0 or PXSX): toggling a repeated name twice flips the first
# entry back on and never reaches the second.
while read -r _ dev status node; do
    [[ "$status" == *enabled && "$node" != "-" ]] || continue
    allowed "$dev" && continue
    wakeup="/sys/bus/${node%%:*}/devices/${node#*:}/power/wakeup"
    if [[ -w "$wakeup" ]]; then
        echo disabled > "$wakeup"
        log "Disabled wakeup for $dev ($node)"
    fi
done < <(entries)

# Pass 2: what still shows enabled is armed through the ACPI device object
# itself (the status column ORs its flag in), or has no node to address.
# Switch those off through the ACPI object's own power/wakeup, found by the
# last component of its ACPI path - which also reaches every device of a
# repeated name. /proc drops the "_" padding of 4-character ACPI names
# (EC0_ is listed as EC0), so strip it here too.
acpi_wakeup_attrs() {
    local d path last
    for d in /sys/bus/acpi/devices/*; do
        [[ -w "$d/power/wakeup" ]] || continue
        path=$(cat "$d/path" 2>/dev/null) || continue
        last=${path##*[.\\]}
        while [[ "$last" == *_ ]]; do last=${last%_}; done
        [[ "$last" == "$1" ]] && echo "$d/power/wakeup"
    done
    return 0
}

declare -A devices=() lines=() still=()
while read -r kind dev status _; do
    [[ "$kind" == h ]] && devices[$dev]=$(( ${devices[$dev]:-0} + 1 ))
    lines[$dev]=$(( ${lines[$dev]:-0} + 1 ))
    [[ "$status" == *enabled ]] && still[$dev]=$(( ${still[$dev]:-0} + 1 ))
done < <(entries)
for dev in "${!still[@]}"; do
    allowed "$dev" && continue
    found=0
    while IFS= read -r attr; do
        found=1
        if [[ "$(cat "$attr")" == enabled ]]; then
            echo disabled > "$attr"
            log "Disabled wakeup for $dev (ACPI ${attr%/power/wakeup})"
        fi
    done < <(acpi_wakeup_attrs "$dev")
    (( found )) && continue
    # Last resort, a name toggle - only for a name that belongs to a single
    # device whose lines all still show enabled; otherwise it would hit
    # another device, or flip already-disabled nodes back on.
    if (( devices[$dev] == 1 && still[$dev] == lines[$dev] )); then
        echo "$dev" > /proc/acpi/wakeup
        log "Disabled wakeup for $dev"
    else
        log "Left $dev enabled: no ACPI wakeup attribute, and its name is shared or only some of its nodes could be switched off."
    fi
done

log "Wakeup devices after filtering:"
cat /proc/acpi/wakeup >&2
