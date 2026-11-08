#!/bin/bash
# Performance profile: PCIe ASPM off and no PCI runtime suspend while it is
# active, put back to what hyprbazzite-power-tuning and the udev rule set when
# the profile is left. Balanced and power-saver leave both alone.
. /usr/lib/tuned/functions

POLICY_FILE=/sys/module/pcie_aspm/parameters/policy

saved_policy() {
    local p=powersave HYPRBAZZITE_ASPM_POLICY=
    [ -r /etc/default/hyprbazzite-power ] && . /etc/default/hyprbazzite-power
    echo "${HYPRBAZZITE_ASPM_POLICY:-$p}"
}

set_pci() {
    local f
    for f in /sys/bus/pci/devices/*/power/control; do
        [ -w "$f" ] && echo "$1" > "$f" 2>/dev/null
    done
    return 0
}

start() {
    [ -w "$POLICY_FILE" ] && echo performance > "$POLICY_FILE" 2>/dev/null
    set_pci on
    return 0
}

stop() {
    [ -w "$POLICY_FILE" ] && echo "$(saved_policy)" > "$POLICY_FILE" 2>/dev/null
    set_pci auto
    return 0
}

process "$@"
