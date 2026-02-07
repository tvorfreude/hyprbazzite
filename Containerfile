# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /

# Base Image
FROM ghcr.io/ublue-os/bazzite:stable

# Bazzite-style provisioning (ship defaults in /usr)
COPY system_files /

## Other possible base images include:
# FROM ghcr.io/ublue-os/bazzite:latest
# FROM ghcr.io/ublue-os/bluefin-nvidia:stable
# 
# ... and so on, here are more base images
# Universal Blue Images: https://github.com/orgs/ublue-os/packages
# Fedora base image: quay.io/fedora/fedora-bootc:41
# CentOS base images: quay.io/centos-bootc/centos-bootc:stream10

### [IM]MUTABLE /opt
## Some bootable images, like Fedora, have /opt symlinked to /var/opt, in order to
## make it mutable/writable for users. However, some packages write files to this directory,
## thus its contents might be wiped out when bootc deploys an image, making it troublesome for
## some packages. Eg, google-chrome, docker-desktop.
##
## Uncomment the following line if one desires to make /opt immutable and be able to be used
## by the package manager.

# RUN rm /opt && mkdir /opt

### MODIFICATIONS
## Organize package installation and system configuration into logical RUN blocks

# Remove GNOME and KDE Desktop Environments
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    dnf5 remove -y gnome-shell gnome-desktop gnome-session gnome-settings-daemon \
    gnome-shell-extensions gnome-control-center gnome-terminal \
    kde-workspace kde-plasma-desktop kdebase kde-settings \
    plasma-desktop plasma-workspaces sddm --noautoremove 2>/dev/null || true

# Install Hyprland and dependencies from sdegler COPR
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    dnf5 -y copr enable sdegler/hyprland && \
    dnf5 install -y \
    hyprland \
    hyprlock \
    hypridle \
    hyprpaper \
    waybar \
    dunst \
    wofi \
    xdg-desktop-portal-hyprland && \
    dnf5 -y copr disable sdegler/hyprland

# Install and setup SDDM display manager
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    dnf5 install -y sddm && \
    mkdir -p /usr/share/wayland-sessions && \
    printf '[Desktop Entry]\nName=Hyprland\nExec=start-hyprland\nType=Application\n' > /usr/share/wayland-sessions/hyprland.desktop && \
    chmod 0644 /usr/share/wayland-sessions/hyprland.desktop && \
    systemctl enable sddm.service

# Install essential session, keyring, and authentication packages
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    dnf5 install -y \
    xdg-desktop-portal-gnome \
    lxqt-policykit \
    systemd-devel \
    gnome-keyring \
    seahorse \
    python3-secretstorage \
    libsecret \
    libsecret-devel \
    gcr \
    gcr-devel

# Install development and system utilities
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    dnf5 install -y \
    tmux \
    git \
    chezmoi \
    kitty \
    nix \
    wl-clipboard \
    grim \
    slurp \
    brightnessctl \
    playerctl \
    imv

# Install file manager, thunar, and media support
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    dnf5 install -y \
    thunar \
    tumbler \
    gvfs \
    gvfs-mtp \
    gvfs-gphoto2 \
    network-manager-applet \
    pavucontrol

# Install Zen Browser from sneexy COPR
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    dnf5 -y copr enable sneexy/zen-browser && \
    dnf5 install -y zen-browser && \
    dnf5 -y copr disable sneexy/zen-browser

# Setup Flatpak with flathub remote and retry logic
RUN --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    if ! flatpak remote-list --system --columns=name 2>/dev/null | grep -qx flathub; then \
    for attempt in 1 2 3; do \
    if flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null; then \
    break; \
    fi; \
    sleep 2; \
    done; \
    fi

# Cleanup runtime artifacts from /var that shouldn't persist in image
RUN rm -rf /var/cache/* /var/log/* /var/lib/dnf /var/lib/yum /var/opt

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
