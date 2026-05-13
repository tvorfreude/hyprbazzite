-- Global Rules
hl.window_rule({
    match = { class = ".*" },
    suppress_event = "maximize",
    opacity = "0.97 0.9"
})

-- Fix for ghost/XWayland focus issues
hl.window_rule({
    match = { 
        class = "^$", 
        title = "^$", 
        xwayland = true, 
        float = true, 
        fullscreen = false, 
        pin = false 
    },
    no_focus = true
})

-- Browsers & Chromium
hl.window_rule({ match = { class = "Chromium" }, tile = true })
hl.window_rule({
    match = { class = "^(Chromium|chromium|google-chrome|google-chrome-unstable|zen-browser)$" },
    opacity = "1 0.97"
})
hl.window_rule({ match = { initial_title = "youtube.com_/" }, opacity = "1 1" })

-- Picture-in-Picture (PiP) Logic
hl.window_rule({ 
    match = { title = "Picture.*[Pp]icture" }, 
    tag = "+pip" 
})
hl.window_rule({
    match = { tag = "pip" },
    float = true,
    pin = true,
    size = { 600, 338 },
    keep_aspect_ratio = true,
    opacity = "1 1",
    move = { "100%-w-40", "4%" }
})

-- Gaming & RetroArch
hl.window_rule({
    match = { class = "com.libretro.RetroArch" },
    fullscreen = true,
    opacity = "1 1"
})

-- Steam
hl.window_rule({
    match = { class = "steam" },
    float = true,
    opacity = "1 1"
})
hl.window_rule({
    match = { class = "steam", title = "Steam" },
    center = true
})

-- Handheld / System Utilities
hl.window_rule({
    match = { class = "^(blueberry.py|Impala|Wiremix|org.gnome.NautilusPreviewer|Omarchy|About)$" },
    float = true,
    center = true
})
hl.window_rule({
    match = { class = "^(blueberry.py|Impala|Wiremix|org.gnome.NautilusPreviewer|com.gabm.satty)$" },
    size = { 800, 600 }
})
hl.window_rule({ match = { class = "Omarchy" }, size = { 600, 470 } })
hl.window_rule({ match = { class = "About" }, size = { 700, 520 } })

-- Dialogs & Portals
hl.window_rule({
    match = { class = "xdg-desktop-portal-gtk", title = "^(Open.*Files?|Save.*Files?|All Files|Save)" },
    float = true,
    center = true
})

-- Media & Fullscreen Overrides
hl.window_rule({ match = { class = "Screensaver" }, fullscreen = true })
hl.window_rule({
    match = { class = "^(zoom|vlc|mpv|org.kde.kdenlive|com.obsproject.Studio|com.github.PintaProject.Pinta|imv|org.gnome.NautilusPreviewer)$" },
    opacity = "1 1"
})
hl.window_rule({
    match = { fullscreen = true },
    opacity = "1.0 override 1.0 override"
})

-- Layer Rules (Waybar, SwayNC, etc.)
hl.layer_rule({ match = { namespace = "selection" }, no_anim = true })
hl.layer_rule({ match = { namespace = "swaync-control-center" }, blur = true })
hl.layer_rule({ match = { namespace = "swaync-notification-window" }, blur = false })
hl.layer_rule({ match = { namespace = "walker" }, no_anim = true })