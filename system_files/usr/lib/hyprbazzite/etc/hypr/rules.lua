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

hl.window_rule({
    match = { class = "^(code-url-handler|vscode|cursor|Slack|discord|WebCord|spotify)$" },
    opacity = "1 1",
    tile = true
})


-- Picture-in-Picture (PiP) Logic
hl.window_rule({ 
    match = { title = "^Picture[- ]in[- ][Pp]icture$" },
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

-- ==========================================
-- GAMING & STEAM
-- ==========================================

-- Gaming & RetroArch
hl.window_rule({
    match = { class = "com.libretro.RetroArch" },
    fullscreen = true,
    opacity = "1 1"
})

-- Consolidated Steam Rules
hl.window_rule({
    match = { class = "steam" },
    float = true,
    center = true
})
hl.window_rule({
    match = { class = "steam", title = "^(Steam)$" },
    float = false,
    opacity = "1 1"
})
hl.window_rule({
    match = { class = "steam", title = "^(Steam Input On-screen Keyboard)$" },
    float = true,
    stay_focused = false,
    pin = true,
    size = { 800, 300 },
    center = true
})


-- ==========================================
-- UTILITIES, DIALOGS & PORTALS
-- ==========================================

-- Handheld / System Utilities
hl.window_rule({
    match = { class = "^(blueberry.py|Impala|Wiremix|org.gnome.NautilusPreviewer|About)$" },
    float = true,
    center = true
})
hl.window_rule({
    match = { class = "^(blueberry.py|Impala|Wiremix|org.gnome.NautilusPreviewer|com.gabm.satty)$" },
    size = { 800, 600 }
})
hl.window_rule({ match = { class = "About" }, size = { 700, 520 } })

-- Dialogs & Portals
hl.window_rule({
    match = { class = "(xdg-desktop-portal-gtk|org.freedesktop.impl.portal.desktop.kde)", title = "^(Open.*Files?|Save.*Files?|All Files|Save|Select a File)" },
    float = true,
    center = true,
    size = { 900, 650 }
})

-- Polkit Authentication Agents
hl.window_rule({
    match = { 
        class = "^(polkit-gnome-authentication-agent-1|lxqt-policykit-agent|lxpolkit|org.kde.polkit-kde-authentication-agent-1)$",
        title = "^(Authentication Required)$" 
    },
    float = true,
    center = true,
    size = { 550, 280 },
    stay_focused = true
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

-- Special Workspaces (Scratchpads)
hl.window_rule({
    match = { class = "scratchpad" },
    workspace = "special:scratchpad",
    float = true,
    size = { "80%", "80%" },
    center = true
})

-- Layer Rules
hl.layer_rule({ match = { namespace = "selection" }, no_anim = true })
hl.layer_rule({ match = { namespace = "swaync-control-center" }, blur = true })
hl.layer_rule({ match = { namespace = "swaync-notification-window" }, blur = false })
hl.layer_rule({ match = { namespace = "walker" }, no_anim = true })
hl.layer_rule({ match = { namespace = "^(wofi)$" }, no_anim = true, blur = true })