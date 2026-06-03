#!/bin/bash
# HyprBazzite Build Verification Script
# This script ensures the image contains all necessary components before deployment.

set -e

echo "🧪 Starting HyprBazzite Image Verification..."

# 1. Critical Package Checks
declare -a REQUIRED_PKGS=("hyprland" "waybar" "wofi" "zsh" "starship")
for pkg in "${REQUIRED_PKGS[@]}"; do
    if ! rpm -q "$pkg" > /dev/null 2>&1; then
        echo "❌ ERROR: Required package '$pkg' is missing from the image."
        exit 1
    fi
done
echo "✅ All critical packages are present."

# 2. Configuration Presence Checks
# These are files that MUST be in the final image for the desktop to be usable
declare -a REQUIRED_FILES=(
    "/usr/lib/hyprbazzite/hypr/hyprland.lua"
    "/usr/lib/hyprbazzite/waybar/config.jsonc"
    "/usr/lib/hyprbazzite/wofi/config"
)
for file in "${REQUIRED_FILES[@]}"
do
    if [ ! -f "$file" ]; then
        echo "❌ ERROR: Critical configuration file '$file' is missing."
        exit 1
    fi
done
echo "✅ Essential configuration files are in place."

# 3. Font Health
if [ ! -d "/usr/share/fonts" ]; then
    echo "❌ ERROR: System font directory is missing."
    exit 1
fi
echo "✅ System font directory exists."

echo "🚀 Verification PASSED: Image is healthy and ready for deployment."
exit 0