-- Autostart necessary processes
hl.on("hyprland.start", function ()
    -- CORE SERVICES
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user import-environment DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("/usr/libexec/lxqt-policykit-agent")
    hl.exec_cmd("gnome-keyring-daemon --start --components=pkcs11,secrets,ssh,gpg")

    -- UI ELEMENTS
    hl.exec_cmd("waybar --config /etc/waybar/config.jsonc --style /etc/waybar/style.css")
    hl.exec_cmd("swaync -c /etc/swaync/config.json -s /etc/swaync/style.css")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("fcitx5")
    
    -- WALLPAPER & AUTOMATION
    hl.exec_cmd("swww-daemon")
    hl.exec_cmd("wallpaper-cycle")
    hl.exec_cmd("/usr/libexec/hyprbazzite-ctl automation dnd")
    hl.exec_cmd("/usr/libexec/hyprbazzite-ctl automation osk")

    -- UTILITIES
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("cursor-clip --daemon")
    hl.exec_cmd("sh -c 'pgrep -x nm-applet >/dev/null || nm-applet --indicator'")
    hl.exec_cmd("flatpak run com.bitwarden.desktop")
    hl.exec_cmd("kitty --class scratchpad")

    -- HARDWARE SPECIFIC LOGIC (Lua Native)
    -- This checks for IIO devices (OXP/Handheld rotation)
    if os.execute("test -d /sys/bus/iio/devices") == 0 then
        hl.exec_cmd("iio-hyprland")
    end

    -- This checks for ASUS/ROG hardware
    if os.execute("test -d /sys/module/asus_nb_wmi") == 0 then
        hl.exec_cmd("rog-control-center")
    end
end)