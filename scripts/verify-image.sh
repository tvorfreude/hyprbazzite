#!/bin/bash
# HyprBazzite Build Verification Script
# This script ensures the image contains all necessary components before deployment.

set -e

echo "Starting HyprBazzite Image Verification..."

# 1. Critical Package Checks
declare -a REQUIRED_PKGS=("hyprland" "waybar" "wofi" "zsh" "starship" "sddm" "kitty" "awww" "hypridle" "nemo")
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

# 8. Secure boot certificate
if [ ! -f "/etc/pki/secureboot/secureboot.crt" ] && [ ! -f "/usr/share/secureboot/secureboot.crt" ]; then
    echo "WARNING: Secure boot certificate not found in expected locations (non-fatal)."
fi

echo "Verification PASSED: Image is healthy and ready for deployment."
exit 0
