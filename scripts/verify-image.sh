#!/bin/bash
# HyprBazzite Build Verification Script
# This script ensures the image contains all necessary components before deployment.

set -e

echo "Starting HyprBazzite Image Verification..."

# 1. Critical Package Checks
declare -a REQUIRED_PKGS=(
    "hyprland" "waybar" "wofi" "zsh" "starship" "sddm" "kitty" "awww" "hypridle" "nemo"
    # session-critical: lock screen, notifications/quick settings, portal, and
    # what hyprbazzite-ctl's daemons and waybar modules shell out to
    "hyprlock" "SwayNotificationCenter" "xdg-desktop-portal-hyprland"
    "socat" "jq" "ImageMagick" "libnotify" "cliphist" "wvkbd" "hhd"
)
for pkg in "${REQUIRED_PKGS[@]}"; do
    if ! rpm -q "$pkg" > /dev/null 2>&1; then
        echo "ERROR: Required package '$pkg' is missing from the image."
        exit 1
    fi
done
echo "All critical packages are present."

# 2. Configuration Presence Checks
declare -a REQUIRED_FILES=(
    "/usr/lib/hyprbazzite/hypr/hyprland.lua"
    "/usr/lib/hyprbazzite/hypr/nightlight.frag"
    "/usr/lib/hyprbazzite/hypr/bindings.lua"
    "/usr/lib/hyprbazzite/hypr/autostart.lua"
    "/usr/lib/hyprbazzite/waybar/config.jsonc"
    "/usr/lib/hyprbazzite/waybar/style.css"
    "/usr/lib/hyprbazzite/wofi/config"
    "/usr/lib/hyprbazzite/wofi/style.css"
    "/usr/lib/hyprbazzite/hypr/scripts/lib/common.sh"
)
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "ERROR: Critical configuration file '$file' is missing."
        exit 1
    fi
done
echo "Essential configuration files are in place."

# 3. Critical scripts and services
declare -a REQUIRED_SCRIPTS=(
    "/usr/libexec/hyprbazzite-ctl"
    "/usr/libexec/hyprbazzite-accent"
    "/usr/libexec/hyprbazzite-install-apps"
    "/usr/libexec/hyprbazzite-flatpak-overrides"
    "/usr/libexec/hyprbazzite-user-firstboot"
    "/usr/libexec/tblue-secureboot-firstboot"
    "/usr/libexec/tblue-hibernate-setup"
    "/usr/libexec/tblue-hhd-enable-user"
    "/usr/bin/wallpaper-cycle"
    "/usr/bin/hyprbazzite-session"
)
for script in "${REQUIRED_SCRIPTS[@]}"; do
    if [ ! -x "$script" ]; then
        echo "ERROR: Critical script '$script' is missing or not executable."
        exit 1
    fi
done
echo "All critical scripts are present and executable."

# 4. Systemd unit files
declare -a REQUIRED_UNITS=(
    "/usr/lib/systemd/system/tblue-secureboot-firstboot.service"
    "/usr/lib/systemd/system/tblue-hibernate-setup.service"
    "/usr/lib/systemd/system/tblue-hhd-enable-user.service"
    "/usr/lib/systemd/system/tblue-disable-nonpower-wakeup.service"
    "/usr/lib/systemd/system/hyprbazzite-flatpak-overrides.service"
    "/usr/lib/systemd/user/hyprbazzite-user-firstboot.service"
)
for unit in "${REQUIRED_UNITS[@]}"; do
    if [ ! -f "$unit" ]; then
        echo "ERROR: Systemd unit '$unit' is missing."
        exit 1
    fi
done
echo "All systemd units are present."

# 4b. Enablement. Our own units must be enabled by the build, and the base
# image's update/rollback machinery must survive it: a `systemctl preset-all`
# once silently disabled all of the latter (no automatic updates, no greenboot
# rollback) and nothing noticed, because only unit files were checked above.
# SYSTEMD_OFFLINE=1: there is no running systemd in the verification container.
mapfile -t OUR_UNITS < <(awk '$1 == "enable" {print $2}' /usr/lib/systemd/system-preset/50-hyprbazzite.preset)
for unit in "${OUR_UNITS[@]}"; do
    if ! SYSTEMD_OFFLINE=1 systemctl is-enabled --quiet "$unit"; then
        echo "ERROR: Unit '$unit' is listed in 50-hyprbazzite.preset but not enabled."
        exit 1
    fi
done
declare -a BASE_UNITS=(
    "uupd.timer"
    "greenboot-healthcheck.service"
    "greenboot-set-rollback-trigger.service"
    "bazzite-hardware-setup.service"
    "bazzite-flatpak-manager.service"
)
for unit in "${BASE_UNITS[@]}"; do
    if [ ! -e "/usr/lib/systemd/system/$unit" ]; then
        echo "WARNING: Base unit '$unit' no longer exists (renamed upstream?); not checked."
    elif ! SYSTEMD_OFFLINE=1 systemctl is-enabled --quiet "$unit"; then
        echo "ERROR: Base image unit '$unit' was disabled by this build."
        exit 1
    fi
done
echo "Our units are enabled and the base image's update/rollback units are intact."

# 5. Polkit rules
declare -a REQUIRED_POLKIT=(
    "/usr/lib/hyprbazzite/polkit-1/rules.d/10-tdp-control.rules"
)
for rule in "${REQUIRED_POLKIT[@]}"; do
    if [ ! -f "$rule" ]; then
        echo "ERROR: Polkit rule '$rule' is missing."
        exit 1
    fi
done
echo "Polkit rules are in place."

# 5b. Config sanity: the UI configs must parse, and the control script must be
# valid bash. Catches things like an unsupported date specifier or a stripped
# glyph/quote before a broken bar ships.
python3 - <<'PY'
import json, re, sys
for path in ("/usr/lib/hyprbazzite/waybar/config.jsonc",
             "/usr/lib/hyprbazzite/xdg/swaync/config.json"):
    txt = open(path, encoding="utf-8").read()
    txt = re.sub(r"^\s*//.*$", "", txt, flags=re.M)
    try:
        json.loads(txt)
    except Exception as e:
        print(f"ERROR: {path} is not valid JSON: {e}")
        sys.exit(1)
PY
if ! bash -n /usr/libexec/hyprbazzite-accent; then
    echo "ERROR: /usr/libexec/hyprbazzite-accent has a bash syntax error."
    exit 1
fi
if ! bash -n /usr/libexec/hyprbazzite-ctl; then
    echo "ERROR: /usr/libexec/hyprbazzite-ctl has a bash syntax error."
    exit 1
fi
echo "UI configs and hyprbazzite-ctl parse cleanly."

# 6. Font Health
if [ ! -d "/usr/share/fonts" ]; then
    echo "ERROR: System font directory is missing."
    exit 1
fi
echo "System font directory exists."

# 7. SDDM theme
if [ ! -f "/usr/share/sddm/themes/hyprlockish/Main.qml" ]; then
    echo "ERROR: SDDM theme Main.qml is missing."
    exit 1
fi
echo "SDDM theme is present."

# 7b. Update signature policy: once cosign.pub is committed, the key is
# installed and every pull of this image must be signed by it.
if [ -f /etc/pki/containers/hyprbazzite.pub ]; then
    for policy in /etc/containers/policy.json /usr/etc/containers/policy.json; do
        [ -f "$policy" ] || continue
        if ! jq -e '[.transports.docker[][] | select(.keyPath? == "/etc/pki/containers/hyprbazzite.pub")] | length > 0' "$policy" >/dev/null; then
            echo "ERROR: hyprbazzite.pub is installed but $policy does not require it."
            exit 1
        fi
    done
    echo "Update signature policy requires the hyprbazzite key."
fi

echo "Verification PASSED: Image is healthy and ready for deployment."
exit 0
