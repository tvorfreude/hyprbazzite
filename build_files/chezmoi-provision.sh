#!/bin/bash
# Provision system with dotfiles from tristanbollard/dotfiles
# This script is called on first user login via systemd user service

set -e

DOTFILES_REPO="https://github.com/tristanbollard/dotfiles.git"
CHEZMOI_DATA="$HOME/.local/share/chezmoi"

# Color output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Hyprland Dotfiles Provisioning ===${NC}"

# Check if already provisioned
if [ -d "$CHEZMOI_DATA" ] && [ -f "$HOME/.config/chezmoi/chezmoi.toml" ]; then
    echo -e "${GREEN}✓ Dotfiles already provisioned, skipping...${NC}"
    exit 0
fi

echo -e "${BLUE}Initializing chezmoi with your dotfiles...${NC}"

# Initialize chezmoi (this will clone the repo)
chezmoi init --apply "$DOTFILES_REPO"

echo -e "${GREEN}✓ Dotfiles provisioned successfully!${NC}"
echo -e "${BLUE}Applying configurations...${NC}"

# Install Bitwarden Flatpak for the user (if not already installed)
if ! flatpak list --app --columns=application 2>/dev/null | grep -q '^com.bitwarden.desktop$'; then
    echo -e "${BLUE}Installing Bitwarden (Flatpak)...${NC}"
    flatpak install -y flathub com.bitwarden.desktop || true
fi

# Ensure session variables are set for the new user session
export DISPLAY=:0
export WAYLAND_DISPLAY=wayland-0

echo -e "${GREEN}✓ Provisioning complete!${NC}"
echo -e "${BLUE}Note: Some settings will take effect on next login.${NC}"
