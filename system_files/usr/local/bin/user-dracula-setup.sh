#!/bin/bash
# User-level Dracula theme and Flatpak setup

export GTK_THEME=Dracula



# Set Qt5ct Dracula color scheme
mkdir -p ~/.config/qt5ct
cat > ~/.config/qt5ct/qt5ct.conf <<EOF
[Appearance]
custom_palette=true
color_scheme_path=/usr/share/qt5ct/colors/Dracula.conf
EOF

# Apply Dracula settings to dconf for user
if command -v dconf >/dev/null; then
  dconf write /org/gnome/desktop/interface/gtk-theme "'Dracula'"
  dconf write /org/gnome/desktop/interface/icon-theme "'Dracula'"
  dconf write /org/gnome/desktop/interface/cursor-theme "'Dracula'"
fi

# Install Flatpaks for user if not present
flatpaks=(
  com.visualstudio.code
  com.discordapp.Discord
  org.prismlauncher.PrismLauncher
  com.bitwarden.desktop
  org.openrgb.OpenRGB
  com.surfshark.Surfshark
)
for pkg in "${flatpaks[@]}"; do
  flatpak install -y flathub "$pkg"
done

# Set Dracula theme for zen-browser Flatpak
flatpak override --user --env=GTK_THEME=Dracula io.github.zen_browser.zen

exit 0
