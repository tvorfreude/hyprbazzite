#!/bin/bash

# This script is no longer used during the build process.
# All package installation and system configuration has been migrated to the Containerfile.
#
# The Containerfile now handles:
# - Package removal (GNOME/KDE)
# - Hyprland installation and configuration
# - LightDM setup with Wayland session
# - Essential system packages (keyring, auth, utilities)
# - Development tools and Wayland utilities
# - File manager and media support
# - Zen Browser installation
# - Flatpak configuration
#
# System configuration defaults (configs, tmpfiles, etc.) are shipped via system_files/ directory.
# See the Containerfile for the complete build logic.
