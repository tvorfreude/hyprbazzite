#!/bin/bash
# Install desired Flatpaks on first boot

FLATPAKS=(
  com.visualstudio.code
  com.discordapp.Discord
  org.prismlauncher.PrismLauncher
  com.bitwarden.desktop
  org.openrgb.OpenRGB
  com.surfshark.Surfshark
)

# Ensure flathub is added
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

for pkg in "${FLATPAKS[@]}"; do
  flatpak install -y flathub "$pkg"
done

# Flatpak overrides for zen-browser

# Set Dracula theme for zen-browser Flatpak
flatpak override --system --env=GTK_THEME=Dracula io.github.zen_browser.zen


exit 0
