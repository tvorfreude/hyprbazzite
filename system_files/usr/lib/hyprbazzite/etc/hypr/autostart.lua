hl.config({
    ["exec-once"] = {
        "hypridle",
        "swaync",
        -- "dunst", (Using SwayNotificationCenter instead)
        "waybar --config /etc/waybar/config --style /etc/waybar/style.css",
        "fcitx5",
        "swww-daemon & wallpaper-cycle &",
        "/usr/libexec/hyprbazzite-ctl automation dnd &",
        "/usr/libexec/lxqt-policykit-agent",
        "wl-paste --watch cliphist store",
        "gnome-keyring-daemon --start --components=pkcs11,secrets,ssh,gpg",
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
        "systemctl --user import-environment DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
        "sh -c 'pgrep -x nm-applet >/dev/null || nm-applet --indicator'",
        "blueman-applet",
        "cursor-clip --daemon",
        "/usr/libexec/hyprbazzite-ctl automation osk",
        "flatpak run com.bitwarden.desktop &",
        "sh -c '[ -d /sys/bus/iio/devices ] && exec iio-hyprland'",
        "sh -c '[ -d /sys/module/asus_nb_wmi ] && exec rog-control-center'",
    },
})