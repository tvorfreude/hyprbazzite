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
    echo "[tblue-bazzite] Initializing dotfiles on first login..."
    if chezmoi init --apply github.com/tristanbollard/dotfiles 2>&1; then
      echo "[tblue-bazzite] Dotfiles initialized successfully"
      # Install Bitwarden Flatpak after initial dotfiles setup
      echo "[tblue-bazzite] Installing Bitwarden..."
      flatpak install -y --noninteractive flathub com.bitwarden.desktop 2>/dev/null || echo "[tblue-bazzite] Bitwarden install skipped (optional)"
    else
      echo "[tblue-bazzite] Warning: Dotfiles init failed, continuing without custom config"
    fi
  else
    # Update dotfiles on subsequent logins (silent, non-blocking)
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
  waybar \
  dunst \
  wofi \
  uwsm \
  xdg-desktop-portal-hyprland
# Disable COPR so it doesn't end up enabled on the final image
dnf5 -y copr disable sdegler/hyprland

### Install system-wide Hyprland configuration
mkdir -p /etc/xdg/hypr
cat > /etc/xdg/hypr/hyprland.conf << 'HYPRCONF'
# Hyprland Configuration - System Default
# This config is used for all users unless overridden by ~/.config/hypr/hyprland.conf
# Customize your own setup by creating a config in your home directory

# See https://wiki.hyprland.org/Configuring/Monitors/
monitor=,preferred,auto,auto

# Execute your favorite apps at launch
exec-once = waybar
exec-once = dunst
exec-once = cursor-clip --daemon
exec-once = udiskie --no-notify
exec-once = lxqt-policykit-agent

# Some default env vars
env = XCURSOR_SIZE,24
env = XCURSOR_THEME,Adwaita

# For all categories, see https://wiki.hyprland.org/Configuring/Variables/
input {
    kb_layout = us
    kb_variant =
    kb_model =
    kb_options =
    kb_rules =
    follow_mouse = 1
    mouse_refocus = true
    touchpad {
        natural_scroll = false
    }
    sensitivity = 0
}

general {
    gaps_in = 5
    gaps_out = 20
    border_size = 2
    col.active_border = rgba(89dcebff)
    col.inactive_border = rgba(45475aff)
    layout = dwindle
    allow_tearing = false
}

decoration {
    rounding = 10
    blur {
        enabled = true
        size = 3
        passes = 1
    }
}

animations {
    enabled = true
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    animation = windows, 1, 10, myBezier
    animation = windowsOut, 1, 10, default, popin 80%
    animation = border, 1, 10, default
    animation = borderangle, 1, 10, default
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, default
}

dwindle {
    pseudotile = true
    preserve_split = true
}

master {
}

# Keybinds
$mainMod = SUPER

# Core applications
bind = $mainMod, Q, exec, kitty
bind = $mainMod, E, exec, thunar
bind = $mainMod, B, exec, zen-browser
bind = $mainMod SHIFT, B, exec, flatpak run com.bitwarden.desktop

# Window management
bind = $mainMod, C, killactive,
bind = $mainMod, M, exit,
bind = $mainMod, V, exec, cursor-clip
bind = $mainMod SHIFT, V, togglefloating,
bind = $mainMod, P, pseudo,
bind = $mainMod, J, togglesplit,

# System utilities
bind = $mainMod SHIFT, I, exec, fastfetch
bind = $mainMod SHIFT, M, exec, kitty --class btop -e btop
bind = $mainMod SHIFT, S, exec, grim -g "$(slurp)" - | wl-copy
bind = SHIFT, Print, exec, grim - | wl-copy

# Move focus with mainMod + arrow keys
bind = $mainMod, left, movefocus, l
bind = $mainMod, right, movefocus, r
bind = $mainMod, up, movefocus, u
bind = $mainMod, down, movefocus, d

# Switch workspaces with mainMod + [0-9]
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
bind = $mainMod, 6, workspace, 6
bind = $mainMod, 7, workspace, 7
bind = $mainMod, 8, workspace, 8
bind = $mainMod, 9, workspace, 9
bind = $mainMod, 0, workspace, 10

# Move active window to a workspace with mainMod + SHIFT + [0-9]
bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5
bind = $mainMod SHIFT, 6, movetoworkspace, 6
bind = $mainMod SHIFT, 7, movetoworkspace, 7
bind = $mainMod SHIFT, 8, movetoworkspace, 8
bind = $mainMod SHIFT, 9, movetoworkspace, 9
bind = $mainMod SHIFT, 0, movetoworkspace, 10

# Scroll through existing workspaces with mainMod + scroll
bind = $mainMod, mouse_down, workspace, e+1
bind = $mainMod, mouse_up, workspace, e-1

# Move/resize windows with mainMod + LMB/RMB and dragging
bindm = $mainMod, mouse:272, movewindow
bindm = $mainMod, mouse:273, resizewindow
HYPRCONF

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

### Install additional utilities and shells
dnf5 install -y \
  tmux \
  git \
  chezmoi \
  kitty \
  zsh

### Install Nix package manager
dnf5 install -y nix

### Install Wayland utilities and system tools
# Note: wl-clipboard, grim, slurp, playerctl, fastfetch, btop already included in Bazzite base
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

### Remove build-only dependencies for Cursor Clip
dnf5 remove -y rust cargo gtk4-devel libadwaita-devel gtk4-layer-shell-devel pkgconf-pkg-config --noautoremove 2>/dev/null || true

### Install media applications
# Note: ffmpeg, pipewire-pulseaudio already included in Bazzite base
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
