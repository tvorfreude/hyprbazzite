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

### Setup shell-based Hyprland auto-launch (no display manager)
mkdir -p /etc/profile.d
cat > /etc/profile.d/hyprland-autostart.sh << 'PROFILE'
#!/bin/bash
# Auto-launch Hyprland on first TTY login
if [[ -z "$DISPLAY" && -z "$WAYLAND_DISPLAY" && "$XDG_VTNR" == "1" ]]; then
  exec Hyprland
fi
PROFILE
chmod +x /etc/profile.d/hyprland-autostart.sh

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

### Enable necessary services
systemctl enable podman.socket

### Setup provisioning script and systemd service
mkdir -p /usr/local/bin
install -Dm755 /ctx/chezmoi-provision.sh /usr/local/bin/chezmoi-provision

# Create systemd user service directory structure
mkdir -p /etc/systemd/user
install -Dm644 /ctx/chezmoi-provision.service /etc/systemd/user/chezmoi-provision.service

### Setup default Hyprland configuration for fallback
mkdir -p /etc/skel/.config/hypr
install -Dm644 /ctx/hyprland.conf /etc/skel/.config/hypr/hyprland.conf

# Create placeholder for hyprpaper wallpaper
mkdir -p /etc/skel/.config/hypr
echo "preload = /usr/share/pixmaps/backgrounds/hyprland/hyprland.png" > /etc/skel/.config/hypr/hyprpaper.conf
echo "wallpaper = ,/usr/share/pixmaps/backgrounds/hyprland/hyprland.png" >> /etc/skel/.config/hypr/hyprpaper.conf

echo "✓ Hyprland setup complete. Dotfiles will be provisioned on first login via chezmoi."
