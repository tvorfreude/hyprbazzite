#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist\?path\=free/fedora/updates/43/x86_64/repoview/index.html\&protocol\=https\&redirect\=1

### Remove GNOME and KDE Desktop Environments
dnf5 remove -y gnome-shell gnome-desktop gnome-session gnome-settings-daemon \
  gnome-shell-extensions gnome-control-center gnome-terminal \
  kde-workspace kde-plasma-desktop kdebase kde-settings \
  plasma-desktop plasma-workspaces sddm --noautoremove 2>/dev/null || true

### Install Hyprland and dependencies from sdegler COPR
dnf5 -y copr enable sdegler/hyprland
dnf5 install -y \
  hyprland \
  hyprlock \
  hypridle \
  hyprpaper \
  waybar \
  dunst \
  wofi \
  xdg-desktop-portal-hyprland
# Disable COPR so it doesn't end up enabled on the final image
dnf5 -y copr disable sdegler/hyprland

### Install and configure LightDM display manager
dnf5 install -y lightdm lightdm-gtk-greeter

# Install fallback config to standard locations
mkdir -p /etc/hypr /etc/skel/.config/hypr
install -D -m 0644 /ctx/hyprland.conf /etc/hypr/hyprland.conf
install -D -m 0644 /ctx/hyprland.conf /etc/skel/.config/hypr/hyprland.conf

# Create Hyprland session entry using start-hyprland
mkdir -p /usr/share/wayland-sessions
cat > /usr/share/wayland-sessions/hyprland.desktop << 'SESSION'
[Desktop Entry]
Name=Hyprland
Exec=start-hyprland
Type=Application
SESSION

chmod 0644 /usr/share/wayland-sessions/hyprland.desktop

# Enable LightDM service
systemctl enable lightdm.service

### Install essential session/system packages (only what's missing from Bazzite)
dnf5 install -y \
  xdg-desktop-portal-gnome \
  lxqt-policykit \
  systemd-devel

### Install keyring and authentication packages
dnf5 install -y \
  gnome-keyring \
  seahorse \
  python3-secretstorage \
  libsecret \
  libsecret-devel \
  gcr \
  gcr-devel

### Install additional utilities
dnf5 install -y tmux git chezmoi kitty

### Install Wayland utilities and system tools
dnf5 install -y \
  wl-clipboard \
  cliphist \
  grim \
  slurp \
  brightnessctl \
  playerctl \
  iio-hyprland \
  imv

### Install file manager and support libraries
dnf5 install -y \
  thunar \
  tumbler \
  gvfs \
  gvfs-mtp \
  gvfs-gphoto2

### Install system tray utilities
dnf5 install -y \
  network-manager-applet \
  pavucontrol

### Install Zen Browser from sneexy COPR
dnf5 -y copr enable sneexy/zen-browser
dnf5 install -y zen-browser
# Disable COPR so it doesn't end up enabled on the final image
dnf5 -y copr disable sneexy/zen-browser

### Flatpak setup (Bitwarden will be installed on first login)
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

### Configure XDG Desktop Portal for Hyprland
# Create portal configuration to use Hyprland portal backend
mkdir -p /etc/xdg/xdg-desktop-portal
cat > /etc/xdg/xdg-desktop-portal/hyprland-portals.conf << 'EOF'
[preferred]
default=hyprland
org.freedesktop.impl.portal.Secret=gnome
EOF
