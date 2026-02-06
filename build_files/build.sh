#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/43/x86_64/repoview/index.html&protocol=https&redirect=1

### Remove GNOME and KDE Desktop Environments
dnf5 remove -y gnome-shell gnome-desktop gnome-session gnome-settings-daemon \
  gnome-shell-extensions gnome-control-center gnome-terminal \
  kde-workspace kde-plasma-desktop kdebase kde-settings \
  plasma-desktop plasma-workspaces sddm --noautoremove 2>/dev/null || true

### Install greetd as login manager (Wayland-native)
dnf5 install -y greetd greetd-fakegreet

### Configure greetd
mkdir -p /etc/greetd
cat > /etc/greetd/config.toml << 'EOF'
[terminal]
vt = 1

[general]
sessions_dir = "/usr/share/wayland-sessions:/usr/share/xsessions"

[default_session]
command = "fakegreet --cmd Hyprland"
user = "greeter"
EOF

### Fix greetd directory permissions
mkdir -p /var/cache/greetd
mkdir -p /var/lib/greetd
chmod 700 /var/cache/greetd
chown greetd:greetd /var/cache/greetd
chown -R greetd:greetd /var/lib/greetd

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
dnf5 install -y tmux git chezmoi

### Install Zen Browser from sneexy COPR
dnf5 -y copr enable sneexy/zen-browser
dnf5 install -y zen-browser
# Disable COPR so it doesn't end up enabled on the final image
dnf5 -y copr disable sneexy/zen-browser

### Flatpak setup (Bitwarden will be installed on first login)
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

### Configure Hyprland as default session
# Hyprland session file is provided by the hyprland package
mkdir -p /usr/share/wayland-sessions

### Configure LightDM
mkdir -p /etc/lightdm
cat > /etc/lightdm/lightdm.conf << 'EOF'
[General]
greeter-session=lightdm-gtk-greeter
user-session=hyprland
logind-check-graphical=true
EOF

cat > /etc/lightdm/lightdm-gtk-greeter.conf << 'EOF'
[greeter]
theme-name=Adwaita
icon-theme-name=Adwaita
font-name=Noto Sans 12
EOF

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
systemctl enable greetd.service

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
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

