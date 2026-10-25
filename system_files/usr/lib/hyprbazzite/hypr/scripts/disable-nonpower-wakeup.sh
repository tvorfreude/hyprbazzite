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

# /proc/acpi/wakeup as "kind dev status node" lines: kind h = device line,
# c = indented continuation line for a further node; node "-" when none.
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

# Pass 1: each node through its own power/wakeup (writing a name to
# /proc/acpi/wakeup toggles only the first device of that name).
while read -r _ dev status node; do
    [[ "$status" == *enabled && "$node" != "-" ]] || continue
    allowed "$dev" && continue
    wakeup="/sys/bus/${node%%:*}/devices/${node#*:}/power/wakeup"
    if [[ -w "$wakeup" ]]; then
        echo disabled > "$wakeup"
        log "Disabled wakeup for $dev ($node)"
    fi
done < <(entries)

# Pass 2: what still shows enabled is armed via the ACPI object itself:
# disable that, matched by the last ACPI path component (minus the "_"
# padding /proc drops).
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
    # Last resort, a name toggle: only safe for a unique name whose lines
    # are all still enabled.
    if (( devices[$dev] == 1 && still[$dev] == lines[$dev] )); then
        echo "$dev" > /proc/acpi/wakeup
        log "Disabled wakeup for $dev"
    else
        log "Left $dev enabled: no ACPI wakeup attribute, and its name is shared or only some of its nodes could be switched off."
    fi
done

log "Wakeup devices after filtering:"
cat /proc/acpi/wakeup >&2
