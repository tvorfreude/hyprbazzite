#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist\?path\=free/fedora/updates/43/x86_64/repoview/index.html\&protocol\=https\&redirect\=1

### Remove GNOME and KDE Desktop Environments
dnf5 remove -y gnome-shell gnome-desktop gnome-session gnome-settings-daemon \
  gnome-shell-extensions gnome-control-center gnome-terminal nautilus \
  kde-workspace kde-plasma-desktop kdebase kde-settings dolphin \
  plasma-desktop plasma-workspaces sddm kdeconnect kdeconnectd kde-connect \
  kdebugger kdebugtools kdebug --noautoremove 2>/dev/null || true

### Remove Firefox and redundant Flatpak apps (replaced with Zen Browser and alternatives)
flatpak uninstall -y \
  org.mozilla.firefox \
  org.gnome.Totem \
  org.gnome.eog \
  org.gnome.Evince \
  org.gnome.gedit \
  org.gnome.Calculator \
  org.gnome.TextEditor \
  org.gnome.Maps \
  org.gnome.Weather \
  org.gnome.Music \
  org.gnome.Photos \
  org.gnome.Cheese \
  org.kde.okular \
  org.kde.kate \
  org.kde.gwenview \
  org.kde.dolphin \
  org.kde.ark \
  org.kde.elisa 2>/dev/null || true

### Remove redundant GNOME/KDE RPM packages (replaced with better alternatives)
dnf5 remove -y \
  totem mpv \
  eog gwenview \
  evince okular \
  gedit kate kwrite \
  gnome-calculator kcalc \
  gnome-text-editor \
  konsole \
  ark file-roller \
  gnome-music elisa \
  gnome-photos \
  cheese \
  rhythmbox \
  gnome-maps \
  gnome-weather --noautoremove 2>/dev/null || true

### Setup shell-based Hyprland auto-launch with dotfiles provisioning (no display manager)
mkdir -p /etc/profile.d
cat > /etc/profile.d/hyprland-autostart.sh << 'PROFILE'
#!/bin/bash
# Auto-launch Hyprland with UWSM and dotfiles provisioning on first TTY login
if [[ -z "$DISPLAY" && -z "$WAYLAND_DISPLAY" && "$XDG_VTNR" == "1" ]]; then
  # Initialize dotfiles on first login if not already done
  if [[ ! -d "$HOME/.local/share/chezmoi" ]]; then
    chezmoi init --apply github.com/tristanbollard/dotfiles 2>/dev/null || true
    # Install Bitwarden Flatpak after initial dotfiles setup
    flatpak install -y flathub com.bitwarden.desktop 2>/dev/null || true
  else
    # Update dotfiles on subsequent logins
    chezmoi update 2>/dev/null || true
  fi
  
  # Launch Hyprland with UWSM for proper session management
  exec uwsm start hyprland
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
  uwsm \
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

### Install disk encryption tools (LUKS)
dnf5 install -y \
  cryptsetup \
  clevis \
  clevis-luks \
  clevis-systemd \
  tpm2-tools

### Install additional utilities
dnf5 install -y tmux git chezmoi kitty

### Install Nix package manager
dnf5 install -y nix

### Install Wayland utilities and system tools
# Note: wl-clipboard, grim, slurp, playerctl already included in Bazzite base
dnf5 install -y \
  brightnessctl \
  imv

### Install Cursor Clip dependencies (runtime + build)
dnf5 install -y \
  gtk4 \
  libadwaita \
  gtk4-layer-shell \
  gtk4-devel \
  libadwaita-devel \
  gtk4-layer-shell-devel \
  pkgconf-pkg-config \
  rust \
  cargo

### Build and install Cursor Clip
git clone --depth 1 https://github.com/Sirulex/cursor-clip /tmp/cursor-clip
pushd /tmp/cursor-clip
cargo build --release
install -m 0755 target/release/cursor-clip /usr/local/bin/cursor-clip
popd
rm -rf /tmp/cursor-clip

### Install media applications
dnf5 install -y vlc

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

### Install automount utility for removable drives
dnf5 install -y udiskie

### Install Zen Browser from sneexy COPR
dnf5 -y copr enable sneexy/zen-browser
dnf5 install -y zen-browser
# Disable COPR so it doesn't end up enabled on the final image
dnf5 -y copr disable sneexy/zen-browser

### Flatpak setup (Bitwarden will be installed on first login)
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

### Configure default applications via XDG MIME associations
mkdir -p /etc/xdg
cat > /etc/xdg/mimeapps.list << 'MIMEAPPS'
[Default Applications]
# Web Browser - Zen Browser
text/html=zen-browser.desktop
x-scheme-handler/http=zen-browser.desktop
x-scheme-handler/https=zen-browser.desktop
x-scheme-handler/about=zen-browser.desktop
x-scheme-handler/unknown=zen-browser.desktop

# File Manager - Thunar
inode/directory=thunar.desktop

# Terminal - Kitty
x-scheme-handler/terminal=kitty.desktop

# Images - imv
image/png=imv.desktop
image/jpeg=imv.desktop
image/jpg=imv.desktop
image/gif=imv.desktop
image/webp=imv.desktop
image/svg+xml=imv.desktop
image/bmp=imv.desktop

# Text Files - Kitty with default editor
text/plain=kitty.desktop
text/x-readme=kitty.desktop
MIMEAPPS

### Configure XDG Desktop Portal for Hyprland
# Create portal configuration to use Hyprland portal backend
mkdir -p /etc/xdg/xdg-desktop-portal
cat > /etc/xdg/xdg-desktop-portal/hyprland-portals.conf << 'EOF'
[preferred]
default=hyprland
org.freedesktop.impl.portal.Secret=gnome
