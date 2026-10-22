-- ═══════════════════════════════════════════════════════════════════════════════
-- HyprBazzite Autostart
-- ═══════════════════════════════════════════════════════════════════════════════
-- All processes are guarded against duplicates so that a `hyprctl reload`
-- doesn't spawn second instances.

local function exec_once(cmd, process_name)
    process_name = process_name or cmd:match("^(%S+)")
    hl.exec_cmd(string.format("pgrep -x %s >/dev/null 2>&1 || %s", process_name, cmd))
end

hl.on("hyprland.start", function()
    -- CORE SERVICES (session bus, polkit, keyring)
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user import-environment DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    exec_once("/usr/libexec/lxqt-policykit-agent", "lxqt-policykit")
    exec_once("gnome-keyring-daemon --start --components=pkcs11,secrets,ssh,gpg", "gnome-keyring-d")

    -- UI ELEMENTS
    -- Stylesheets come from hyprbazzite-accent: the shipped CSS plus the accent
    -- override (falls back to the plain /etc file if rendering ever fails).
    exec_once("waybar --config /etc/waybar/config.jsonc --style \"$(/usr/libexec/hyprbazzite-accent style waybar)\"", "waybar")
    exec_once("swaync -c /etc/xdg/swaync/config.json -s \"$(/usr/libexec/hyprbazzite-accent style swaync)\"", "swaync")
    exec_once("hypridle -c /etc/hypr/hypridle.conf", "hypridle")
    exec_once("fcitx5", "fcitx5")

    -- WALLPAPER
    exec_once("awww-daemon", "awww-daemon")
    -- No name guard: it runs as "bash", so `pgrep -x wallpaper-cycle` never
    -- matched; the script keeps itself to one instance per Hyprland instance.
    hl.exec_cmd("wallpaper-cycle")

    -- AUTOMATION (hyprbazzite-ctl long-running services)
    -- workspace rebind is a one-shot (not a daemon, so no exec_once guard);
    -- automation_dnd's monitor add/remove listener keeps it up to date after
    -- this. Lid state is handled separately by hyprbazzite-lid.service
    -- (systemd --user, reacts to logind directly) - not here, so starting a
    -- session with the lid already closed is covered by that service's own
    -- startup sync instead of a second one racing it from this hook.
    hl.exec_cmd("/usr/libexec/hyprbazzite-ctl workspace rebind init")
    -- No name guards: they used generic names ("socat", "udevadm") that other
    -- things here also run. The daemons hold a per-instance lock themselves.
    hl.exec_cmd("/usr/libexec/hyprbazzite-ctl automation dnd")
    hl.exec_cmd("/usr/libexec/hyprbazzite-ctl automation osk")

    -- UTILITIES
    exec_once("wl-paste --watch cliphist store", "wl-paste")
    exec_once("blueman-applet", "blueman-applet")
    exec_once("nm-applet --indicator", "nm-applet")
    -- Bitwarden's own "Start automatically on login" setting can't work on
    -- this image: it requires the xdg-desktop-portal Background interface,
    -- which neither installed portal backend (gtk, hyprland) implements
    -- here (confirmed: org.freedesktop.portal.Background isn't registered
    -- at all on the session bus). Autostarting it directly instead, with a
    -- short delay so the flatpak sandbox doesn't race gnome-keyring-daemon's
    -- startup above it - this also provides its SSH agent for the terminal.
    exec_once("sh -c 'sleep 3 && flatpak run com.bitwarden.desktop'", "bitwarden-app")

    -- OPTIONAL (only start if binary exists)
    if os.execute("command -v cursor-clip >/dev/null 2>&1") == 0 then
        exec_once("cursor-clip --daemon", "cursor-clip")
    end

    -- HARDWARE-SPECIFIC
    if os.execute("test -d /sys/bus/iio/devices") == 0 then
        exec_once("iio-hyprland", "iio-hyprland")
    end
    if os.execute("test -d /sys/module/asus_nb_wmi") == 0 then
        exec_once("rog-control-center", "rog-control-ce")
    end
end)
