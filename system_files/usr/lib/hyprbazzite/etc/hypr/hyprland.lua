hl.config({

	general = {
        gaps_in = 5,
        gaps_out = 10,
        border_size = 2,
        ["col.active_border"] = "rgba(bd93f9ee)",
        ["col.inactive_border"] = "rgba(44475aaa)",
        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",
    },

	decoration = {
        rounding = 0,
        shadow = {
            enabled = true,
            range = 2,
            render_power = 3,
            color = "rgba(28282aee)",
        },
        blur = {
            enabled = true,
            size = 3,
            passes = 1,
            vibrancy = 0.1696,
        },
    },

	animations = {
        enabled = true,
        bezier = {
            "easeOutQuint, 0.23, 1, 0.32, 1",
            "easeInOutCubic, 0.65, 0.05, 0.36, 1",
            "linear, 0, 0, 1, 1",
            "almostLinear, 0.5, 0.5, 0.75, 1.0",
            "quick, 0.15, 0, 0.1, 1",
        },
        animation = {
            "global, 1, 10, default",
            "border, 1, 5.39, easeOutQuint",
            "windows, 1, 4.79, easeOutQuint",
            "windowsIn, 1, 4.1, easeOutQuint, popin 87%",
            "windowsOut, 1, 1.49, linear, popin 87%",
            "fadeIn, 1, 1.73, almostLinear",
            "fadeOut, 1, 1.46, almostLinear",
            "fade, 1, 3.03, quick",
            "layers, 1, 3.81, easeOutQuint",
            "layersIn, 1, 4, easeOutQuint, fade",
            "layersOut, 1, 1.5, linear, fade",
            "fadeLayersIn, 1, 1.79, almostLinear",
            "fadeLayersOut, 1, 1.39, almostLinear",
            "workspaces, 0, 0, ease",
        },
    },

	dwindle = {
        preserve_split = true,
        force_split = 2,
    },

	master = {
        new_status = "master",
    },

	misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        focus_on_activate = true,
    },

	windowrule = {
        "suppress_event maximize, match:class .*",
        "opacity 0.97 0.9, match:class .*",
        "no_focus on, match:class ^$, match:title ^$, match:xwayland 1, match:float 1, match:fullscreen 0, match:pin 0",
        "tile on, match:class ^(Chromium)$",
        "opacity 1 0.97, match:class ^(Chromium|chromium|google-chrome|google-chrome-unstable|zen-browser)$",
        "opacity 1 1, match:initial_title ^(youtube.com_/)$",
        "tag +pip, match:title Picture.*[Pp]icture",
        "float on, match:tag pip",
        "pin on, match:tag pip",
        "size 600 338, match:tag pip",
        "keep_aspect_ratio on, match:tag pip",
        "opacity 1 1, match:tag pip",
        "move 100%-w-40 4%, match:tag pip",
        "fullscreen on, match:class com.libretro.RetroArch",
        "opacity 1 1, match:class com.libretro.RetroArch",
        "float on, match:class steam",
        "center on, match:class steam, match:title Steam",
        "opacity 1 1, match:class steam",
        "float on, match:class ^(blueberry.py|Impala|Wiremix|org.gnome.NautilusPreviewer|Omarchy|About)$",
        "center on, match:class ^(blueberry.py|Impala|Wiremix|org.gnome.NautilusPreviewer|Omarchy|About)$",
        "size 800 600, match:class ^(blueberry.py|Impala|Wiremix|org.gnome.NautilusPreviewer|com.gabm.satty)$",
        "size 600 470, match:class Omarchy",
        "size 700 520, match:class About",
        "float on, match:class xdg-desktop-portal-gtk, match:title ^(Open.*Files?|Save.*Files?|All Files|Save)",
        "center on, match:class xdg-desktop-portal-gtk, match:title ^(Open.*Files?|Save.*Files?|All Files|Save)",
        "fullscreen on, match:class Screensaver",
        "opacity 1 1, match:class ^(zoom|vlc|mpv|org.kde.kdenlive|com.obsproject.Studio|com.github.PintaProject.Pinta|imv|org.gnome.NautilusPreviewer)$",
        "opacity 1.0 override 1.0 override, match:fullscreen true",
    },

	layerrule = {
        "no_anim on, match:namespace selection",
        "blur on, match:namespace swaync-control-center",
        "blur off, match:namespace swaync-notification-window",
        "no_anim on, match:namespace walker",
    },

	input = {
        kb_layout = "us",
        kb_variant = "",
        kb_model = "",
        kb_rules = "",
        follow_mouse = 1,
        sensitivity = 0,
        kb_options = "compose:ralt",
        repeat_rate = 40,
        repeat_delay = 600,
        touchpad = {
            natural_scroll = true,
            clickfinger_behavior = true,
            scroll_factor = 0.4,
        },
    },

	source = {
        "/etc/hypr/monitors.lua",
        "/etc/hypr/bindings.lua",
        "/etc/hypr/envs.lua",
        "/etc/hypr/autostart.lua",
    },
})