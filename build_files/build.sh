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
mkdir -p /etc/xdg/hypr/scripts
cat > /etc/xdg/hypr/hyprland.conf << 'HYPRCONF'
# Hyprland Configuration - System Default
# Based on user's original comprehensive config
# Users can override by creating ~/.config/hypr/hyprland.conf

debug:disable_logs=false

general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)
    resize_on_border = false
    allow_tearing = false
    layout = dwindle
}

decoration {
    rounding = 0
    shadow {
        enabled = true
        range = 2
        render_power = 3
        color = rgba(1a1a1aee)
    }
    blur {
        enabled = true
        size = 3
        passes = 1
        vibrancy = 0.1696
    }
}

animations {
    enabled = yes, please :)
    bezier = easeOutQuint,0.23,1,0.32,1
    bezier = easeInOutCubic,0.65,0.05,0.36,1
    bezier = linear,0,0,1,1
    bezier = almostLinear,0.5,0.5,0.75,1.0
    bezier = quick,0.15,0,0.1,1
    animation = global, 1, 10, default
    animation = border, 1, 5.39, easeOutQuint
    animation = windows, 1, 4.79, easeOutQuint
    animation = windowsIn, 1, 4.1, easeOutQuint, popin 87%
    animation = windowsOut, 1, 1.49, linear, popin 87%
    animation = fadeIn, 1, 1.73, almostLinear
    animation = fadeOut, 1, 1.46, almostLinear
    animation = fade, 1, 3.03, quick
    animation = layers, 1, 3.81, easeOutQuint
    animation = layersIn, 1, 4, easeOutQuint, fade
    animation = layersOut, 1, 1.5, linear, fade
    animation = fadeLayersIn, 1, 1.79, almostLinear
    animation = fadeLayersOut, 1, 1.39, almostLinear
    animation = workspaces, 0, 0, ease
}

dwindle {
    pseudotile = true
    preserve_split = true
    force_split = 2
}

master {
    new_status = master
}

misc {
    disable_hyprland_logo = true
    disable_splash_rendering = true
    focus_on_activate = true
}

input {
    kb_layout = us
    kb_variant =
    kb_model =
    kb_rules =
    follow_mouse = 1
    sensitivity = 0
    kb_options = compose:caps
    repeat_rate = 40
    repeat_delay = 600
    touchpad {
        natural_scroll = true
        clickfinger_behavior = true
        scroll_factor = 0.4
    }
}

# Window rules
windowrule = suppressevent maximize, class:.*
windowrule = opacity 0.97 0.9, class:.*
windowrule = nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0

# Picture-in-Picture
windowrule = tag +pip, title:(Picture.{0,1}in.{0,1}[Pp]icture)
windowrule = float, tag:pip
windowrule = pin, tag:pip
windowrule = size 600 338, tag:pip
windowrule = keepaspectratio, tag:pip
windowrule = noborder, tag:pip
windowrule = opacity 1 1, tag:pip
windowrule = move 100%-w-40 4%, tag:pip

# File dialogs
windowrule = float, class:xdg-desktop-portal-gtk, title:^(Open.*Files?|Save.*Files?|All Files|Save)
windowrule = center, class:xdg-desktop-portal-gtk, title:^(Open.*Files?|Save.*Files?|All Files|Save)

# Default monitor
monitor=,preferred,auto,auto

# Environment variables
env = CLUTTER_BACKEND,wayland
env = QT_AUTO_SCREEN_SCALE_FACTOR,1
env = QT_STYLE_OVERRIDE,Adwaita-Dark
env = QT_WAYLAND_DISABLE_WINDOWDECORATION,1
env = QT_QPA_PLATFORMTHEME,qt6ct
env = QT_PLUGIN_PATH,/usr/lib64/qt6/plugins:/usr/lib64/qt5/plugins
env = QT_SCALE_FACTOR,1
env = GTK_THEME,Adwaita:dark
env = XCURSOR_SIZE,24
env = HYPRCURSOR_SIZE,24
env = GDK_BACKEND,wayland,x11,*
env = QT_QPA_PLATFORM,wayland;xcb
env = SDL_VIDEODRIVER,wayland
env = MOZ_ENABLE_WAYLAND,1
env = OZONE_PLATFORM,wayland
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_DESKTOP,Hyprland
env = XDG_SESSION_TYPE,wayland
env = GDK_SCALE,1
env = HYPRCURSOR_THEME,Bibata-Modern-Ice
env = ELECTRON_OZONE_PLATFORM_HINT,auto
env = XCOMPOSEFILE,~/.XCompose

xwayland {
    force_zero_scaling = true
}

ecosystem {
    no_update_news = true
}

# Autostart applications
exec-once = uwsm app -- hypridle
exec-once = uwsm app -- dunst
exec-once = uwsm app -- waybar
exec-once = /usr/libexec/polkit-gnome-authentication-agent-1
exec-once = gnome-keyring-daemon --start --components=pkcs11,secrets,ssh,gpg
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = systemctl --user import-environment DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = uwsm app -- nm-applet --indicator
exec-once = uwsm app -- blueman-applet
exec-once = uwsm app -- cursor-clip --daemon
exec-once = uwsm app -- udiskie --no-notify

# Keybindings
$terminal = uwsm app -- kitty
$browser = uwsm app -- zen-browser
$webapp = $browser
$scriptsDir = ~/.config/hypr/scripts

# Close window
bind = SUPER, W, killactive,

# Control tiling
bind = SUPER, J, togglesplit,
bind = SUPER, P, pseudo,
bind = SUPER, V, togglefloating,
bind = SHIFT, F11, fullscreen, 0

# Move focus with SUPER + arrow keys
bind = SUPER, left, movefocus, l
bind = SUPER, right, movefocus, r
bind = SUPER, up, movefocus, u
bind = SUPER, down, movefocus, d

# Switch workspaces with SUPER + [0-9]
bind = SUPER, code:10, workspace, 1
bind = SUPER, code:11, workspace, 2
bind = SUPER, code:12, workspace, 3
bind = SUPER, code:13, workspace, 4
bind = SUPER, code:14, workspace, 5
bind = SUPER, code:15, workspace, 6
bind = SUPER, code:16, workspace, 7
bind = SUPER, code:17, workspace, 8
bind = SUPER, code:18, workspace, 9
bind = SUPER, code:19, workspace, 10

# Move active window to a workspace with SUPER + SHIFT + [0-9]
bind = SUPER SHIFT, code:10, movetoworkspace, 1
bind = SUPER SHIFT, code:11, movetoworkspace, 2
bind = SUPER SHIFT, code:12, movetoworkspace, 3
bind = SUPER SHIFT, code:13, movetoworkspace, 4
bind = SUPER SHIFT, code:14, movetoworkspace, 5
bind = SUPER SHIFT, code:15, movetoworkspace, 6
bind = SUPER SHIFT, code:16, movetoworkspace, 7
bind = SUPER SHIFT, code:17, movetoworkspace, 8
bind = SUPER SHIFT, code:18, movetoworkspace, 9
bind = SUPER SHIFT, code:19, movetoworkspace, 10

# Swap active window with the one next to it with SUPER + SHIFT + arrow keys
bind = SUPER SHIFT, left, swapwindow, l
bind = SUPER SHIFT, right, swapwindow, r
bind = SUPER SHIFT, up, swapwindow, u
bind = SUPER SHIFT, down, swapwindow, d

# Cycle through applications on active workspace
bind = ALT, Tab, cyclenext
bind = ALT, Tab, bringactivetotop

# Resize active window
bind = SUPER, minus, resizeactive, -100 0
bind = SUPER, equal, resizeactive, 100 0
bind = SUPER SHIFT, minus, resizeactive, 0 -100
bind = SUPER SHIFT, equal, resizeactive, 0 100

# Scroll through existing workspaces with SUPER + scroll
bind = SUPER, mouse_down, workspace, e+1
bind = SUPER, mouse_up, workspace, e-1

# Move/resize windows with mainMod + LMB/RMB and dragging
bindm = SUPER, mouse:272, movewindow
bindm = SUPER, mouse:273, resizewindow

# Menus
bind = SUPER, SPACE, exec, pkill wofi || true && wofi --show drun

# Aesthetics
bind = SUPER SHIFT, SPACE, exec, pkill -SIGUSR1 waybar

# Notifications (use SUPER+C to close)
bind = SUPER, C, exec, dunstctl close
bind = SUPER SHIFT, C, exec, dunstctl close-all

# Application bindings
bind = SUPER, return, exec, $terminal
bind = SUPER, F, exec, uwsm app -- thunar
bind = SUPER, B, exec, $browser
bind = SUPER, N, exec, $terminal -e nvim
bind = SUPER, T, exec, $terminal -e btop
bind = SUPER, A, exec, $webapp https://gemini.google.com/app
bind = SUPER, C, exec, $webapp https://calendar.google.com/calendar/u/0/r
bind = SUPER, E, exec, $webapp https://gmail.google.com
bind = SUPER, Y, exec, $webapp https://youtube.com/
bind = SUPER ALT, G, exec, $webapp https://messages.google.com/web/conversations

# Zoom cursor
bind = SUPER ALT, mouse_down, exec, hyprctl keyword cursor:zoom_factor "$(hyprctl getoption cursor:zoom_factor | awk 'NR==1 {factor = $2; if (factor < 1) {factor = 1}; print factor * 2.0}')"
bind = SUPER ALT, mouse_up, exec, hyprctl keyword cursor:zoom_factor "$(hyprctl getoption cursor:zoom_factor | awk 'NR==1 {factor = $2; if (factor < 1) {factor = 1}; print factor / 2.0}')"

# Fullscreen modes
bind = SUPER SHIFT, F, fullscreen, 0
bind = SUPER CTRL, F, fullscreen, 1

# Screenshots (with fallbacks)
bind = SUPER, S, exec, grim -g "$(slurp -b 1B1F28CC -c E06B74ff -s C778DD0D -w 2)" - | wl-copy 2>/dev/null || grim -g "$(slurp)" - | wl-copy
bind = SUPER, F6, exec, grim ~/Pictures/Screenshots/Screenshot_$(date +%s).png
bind = SUPER SHIFT, F6, exec, grim -g "$(slurp)" ~/Pictures/Screenshots/Screenshot_$(date +%s).png

# Brightness and volume
binde = , xf86MonBrightnessUp, exec, brightnessctl s +5%
binde = , xf86MonBrightnessDown, exec, brightnessctl s 5%-
binde = , xf86AudioRaiseVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ +5%
binde = , xf86AudioLowerVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ -5%
binde = , xf86AudioMute, exec, pactl set-sink-mute @DEFAULT_SINK@ toggle

# Lid switch
bindl = , switch:on:Lid Switch, exec, loginctl lock-session 2>/dev/null || hyprlock
bindl = , switch:off:Lid Switch, exec, killall hyprlock 2>/dev/null || true
HYPRCONF

### Install essential session/system packages (only what's missing from Bazzite)
dnf5 install -y \
  xdg-desktop-portal-gnome \
  polkit-gnome \
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
  blueman \
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

### Configure system-wide Waybar
mkdir -p /etc/xdg/waybar
cat > /etc/xdg/waybar/config << 'WAYBAR'
{
    "layer": "top",
    "mode": "dock",
    "exclusive": true,
    "passthrough": false,
    "position": "top",
    "spacing": 5,
    "fixed-center": true,
    "ipc": true,
    "margin-top": 3,
    "margin-left": 8,
    "margin-right": 8,
    
    "modules-left": [
        "idle_inhibitor",
        "tray",
        "clock"
    ],
    
    "modules-center": [
        "hyprland/workspaces"
    ],
    
    "modules-right": [
        "battery",
        "cpu",
        "memory",
        "temperature",
        "pulseaudio",
        "network",
        "backlight"
    ],
    
    "idle_inhibitor": {
        "format": "{icon}",
        "format-icons": {
            "activated": "󰒳",
            "deactivated": "󰒲"
        }
    },
    
    "tray": {
        "icon-size": 18,
        "spacing": 5
    },
    
    "clock": {
        "format": "󰃭 {:%H:%M}",
        "format-alt": "󰃭 {:%a, %b %d, %Y}",
        "tooltip-format": "<tt><big>{calendar}</big></tt>",
        "calendar": {
            "mode": "year",
            "mode-mon-col": 3,
            "weeks-pos": "right",
            "on-scroll": 1,
            "format": {
                "months": "<span color='#ffead3'><b>{}</b></span>",
                "days": "<span color='#ecc6d9'><b>{}</b></span>",
                "weeks": "<span color='#99ffda'><b>W{}</b></span>",
                "weekdays": "<span color='#ffcc6d'><b>{}</b></span>",
                "today": "<span color='#ff6699'><b><u>{}</u></b></span>"
            }
        }
    },
    
    "hyprland/workspaces": {
        "format": "{id}",
        "format-icons": {
            "1": "󰲱",
            "2": "󰲲",
            "3": "󰲳",
            "4": "󰲴",
            "5": "󰲵",
            "6": "󰲶",
            "7": "󰲷",
            "8": "󰲸",
            "9": "󰲹",
            "10": "󰲺"
        },
        "persistent-workspaces": {
            "*": 5
        }
    },
    
    "hyprland/window": {
        "format": "{}",
        "max-length": 50
    },
    
    "battery": {
        "states": {
            "good": 80,
            "warning": 30,
            "critical": 15
        },
        "format": "{icon} {capacity}%",
        "format-charging": "󰂄 {capacity}%",
        "format-plugged": "󰂄{capacity}%",
        "format-alt": "{time} {icon}",
        "format-icons": ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
    },
    
    "cpu": {
        "format": "󰍛 {usage}%",
        "tooltip": true,
        "interval": 5
    },
    
    "memory": {
        "format": " {usage}%",
        "tooltip": true,
        "interval": 5
    },
    
    "temperature": {
        "critical-threshold": 80,
        "format": "{icon} {temperatureC}°C",
        "format-icons": ["", "", ""],
        "tooltip": true
    },
    
    "pulseaudio": {
        "format": "{icon} {volume}%",
        "format-muted": "󰖁 {volume}%",
        "format-icons": {
            "headphone": "",
            "hands-free": "",
            "headset": "",
            "phone": "",
            "portable": "",
            "car": "",
            "default": ["", "", ""]
        },
        "on-click": "pavucontrol",
        "scroll-step": 1
    },
    
    "network": {
        "format-wifi": "󰤨 {essid}",
        "format-ethernet": "󰌐 {ifname}",
        "format-disconnected": "󰌐",
        "format-disabled": "󰌐",
        "tooltip-format": "󰌐 {ifname}: {ipaddr}/{cidr}",
        "on-click": "nm-applet"
    },
    
    "backlight": {
        "format": "{icon} {percent}%",
        "format-icons": ["", "", "", "", "", "", "", "", ""]
    }
}
WAYBAR

mkdir -p /etc/xdg/waybar/colorschemes
cat > /etc/xdg/waybar/style.css << 'WAYBARCSS'
* {
    border: none;
    border-radius: 0;
    font-family: "JetBrainsMono Nerd Font", monospace;
    font-size: 11px;
    min-height: 0;
}

window#waybar {
    background-color: rgba(30, 30, 46, 0.8);
    color: #cdd6f4;
    margin: 0;
    padding: 0;
}

#workspaces {
    margin: 0 10px;
}

#workspaces button {
    padding: 5px 10px;
    margin: 0 3px;
    color: #6c7086;
    background-color: rgba(88, 91, 112, 0.3);
    border-radius: 5px;
}

#workspaces button.active {
    color: #a6e3a1;
    background-color: rgba(166, 227, 161, 0.2);
}

#workspaces button:hover {
    color: #89dceb;
    background-color: rgba(137, 220, 235, 0.2);
}

#clock,
#battery,
#cpu,
#memory,
#temperature,
#network,
#pulseaudio,
#backlight,
#idle_inhibitor,
#tray {
    padding: 0 10px;
    margin: 0 3px;
    color: #cdd6f4;
}

#battery.warning {
    color: #f38ba8;
}

#battery.critical {
    color: #a6e3a1;
    animation: blink 0.5s infinite;
}

@keyframes blink {
    to { color: #fab387; }
}

#temperature.critical {
    color: #f38ba8;
}

#tray > .passive {
    -gtk-icon-effect: dim;
}

#tray > .needs-attention {
    -gtk-icon-effect: highlight;
}
WAYBARCSS

### Configure system-wide Dunst notifications
mkdir -p /etc/xdg/dunst
cat > /etc/xdg/dunst/dunstrc << 'DUNSTRC'
[global]
    width = 350
    height = 300
    offset = 20x40
    origin = top-right
    transparency = 10
    frame_color = "#89dceb"
    separator_color = "#45475a"
    font = JetBrainsMono Nerd Font 10
    line_height = 4
    padding = 12
    horizontal_padding = 12
    text_icon_padding = 10
    corner_radius = 5
    indicate_hidden = yes
    alignment = left
    show_age_threshold = 60
    word_wrap = yes
    ignore_newline = no
    stack_duplicates = true
    hide_duplicate_count = false
    show_indicators = yes
    icon_position = left
    icon_theme = Papirus
    max_icon_size = 48

[urgency_low]
    background = "#1e1e2e"
    foreground = "#cdd6f4"
    timeout = 10

[urgency_normal]
    background = "#1e1e2e"
    foreground = "#cdd6f4"
    timeout = 10

[urgency_critical]
    background = "#1e1e2e"
    foreground = "#f38ba8"
    frame_color = "#f38ba8"
    timeout = 0
DUNSTRC

### Configure system-wide Kitty terminal
mkdir -p /etc/xdg/kitty
cat > /etc/xdg/kitty/kitty.conf << 'KITTYCONF'
# Kitty Terminal Configuration
font_family JetBrainsMono Nerd Font
font_size 12
line_height 1.4

# Colors - Catppuccin Mocha
foreground #cdd6f4
background #1e1e2e
selection_background #45475a
selection_foreground #f5e0dc

# Black
color0 #45475a
color8 #585b70

# Red
color1 #f38ba8
color9 #f38ba8

# Green
color2 #a6e3a1
color10 #a6e3a1

# Yellow
color3 #f9e2af
color11 #f9e2af

# Blue
color4 #89b4fa
color12 #89b4fa

# Magenta
color5 #f5c2e7
color13 #f5c2e7

# Cyan
color6 #94e2d5
color14 #94e2d5

# White
color7 #bac2de
color15 #a6adc8

# UI
window_padding_width 5
window_margin_width 0
hide_window_decorations yes
confirm_os_window_close 0
bell_on_tab "🔔 "

# Scrollback
scrollback_lines 5000
scrollback_pager less --chop-long-lines --RAW-CONTROL-CHARS +INPUT_LINE_NUMBER

# Copy to clipboard
copy_on_select clipboard

# Mouse
mouse_hide_wait 3

# Keyboard
strip_trailing_spaces smart
KITTYCONF

### Configure system-wide Wofi application launcher
mkdir -p /etc/xdg/wofi
cat > /etc/xdg/wofi/config << 'WOFICONF'
width=600
height=400
orientation=vertical
layout=grid
columns=1
lines=20
matching=contains
allow_markup=true
allow_images=true
image_size=32
css=$HOME/.config/wofi/style.css
exec_search=false
hide_search=false
parse_search=false
insensitive=false
filter_rate=100
term=kitty
WOFICONF

cat > /etc/xdg/wofi/style.css << 'WOFICSS'
* {
    margin: 0;
    padding: 0;
    border: none;
    font-family: "JetBrainsMono Nerd Font", monospace;
    font-size: 14px;
}

window {
    background-color: #1e1e2e;
    border: 2px solid #89dceb;
    border-radius: 5px;
}

#input {
    padding: 12px;
    background-color: #313244;
    color: #cdd6f4;
    border-bottom: 1px solid #45475a;
}

#inner-box {
    padding: 5px;
    background-color: #1e1e2e;
}

#outer-box {
    padding: 5px;
}

#scroll {
    background-color: #1e1e2e;
}

#text {
    color: #cdd6f4;
    padding: 6px 12px;
    background-color: #1e1e2e;
}

#entry {
    padding: 6px 12px;
    margin: 3px 0;
    border-radius: 3px;
    background-color: #313244;
    color: #cdd6f4;
}

#entry:selected {
    background-color: #89dceb;
    color: #1e1e2e;
    font-weight: bold;
}

#entry:hover {
    background-color: #45475a;
}

#img {
    margin-right: 8px;
}
WOFICSS

### Configure XDG Desktop Portal for Hyprland
# Create portal configuration to use Hyprland portal backend
mkdir -p /etc/xdg/xdg-desktop-portal
cat > /etc/xdg/xdg-desktop-portal/hyprland-portals.conf << 'EOF'
[preferred]
default=hyprland
org.freedesktop.impl.portal.Secret=gnome
