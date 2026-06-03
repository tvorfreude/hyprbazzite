-- ==========================================
-- GLOBAL RULES
-- ==========================================

-- Default window behavior: suppress maximize event, set opacity
hl.window_rule({
    match = { class = ".*" },
    suppress_event = "maximize",
    opacity = "1.0 0.9"
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

-- ==========================================
-- BROWSERS & CHROMIUM
-- ==========================================

hl.window_rule({ match = { class = "Chromium" }, tile = true })
hl.window_rule({
    match = { class = "^(Chromium|chromium|google-chrome|google-chrome-unstable|zen-browser|Brave|firefox)$" },
    opacity = "1 0.97"
})
hl.window_rule({ match = { initial_title = "youtube.com_/" }, opacity = "1 1" })

-- ==========================================
-- DEVELOPMENT & COMMUNICATION
-- ==========================================

hl.window_rule({
    match = { class = "^(code-url-handler|vscode|code|cursor|Slack|discord|webcord|spotify|neovide)$" },
    opacity = "1 1",
    tile = true
})

-- ==========================================
-- PICTURE-IN-PICTURE (PiP)
-- ==========================================

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

-- ==========================================
-- GAMING
-- ==========================================

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

-- Lutris (gaming platform)
hl.window_rule({
    match = { class = "lutris" },
    opacity = "1 1"
})
hl.window_rule({
    match = { class = "lutris", title = "^(Lutris)$" },
    float = false,
    tile = true
})

-- ==========================================
-- UTILITIES, DIALOGS & PORTALS
-- ==========================================

-- System Utilities
hl.window_rule({
    match = { class = "^(pavucontrol|blueman-manager|nm-connection-editor|galculator|btop|GParted)$" },
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

-- Bitwarden (password manager)
hl.window_rule({
    match = { class = "com.bitwarden.desktop" },
    float = true,
    center = true,
    size = { 600, 500 }
})

-- ==========================================
-- MEDIA & FULLSCREEN OVERRIDES
-- ==========================================

hl.window_rule({ match = { class = "Screensaver" }, fullscreen = true })
hl.window_rule({
    match = { class = "^(zoom|vlc|mpv|org.kde.kdenlive|com.obsproject.Studio|com.github.PintaProject.Pinta|imv|org.gnome.NautilusPreviewer)$" },
    opacity = "1 1"
})
hl.window_rule({
    match = { fullscreen = true },
    opacity = "1.0 override 1.0 override"
})

-- ==========================================
-- SPECIAL WORKSPACES (SCRATCHPADS)
-- ==========================================

hl.window_rule({
    match = { class = "scratchpad" },
    workspace = "special:scratchpad",
    float = true,
    size = { "80%", "80%" },
    center = true
})

-- ==========================================
-- LAYER RULES
-- ==========================================

hl.layer_rule({ match = { namespace = "selection" }, no_anim = true })
hl.layer_rule({ match = { namespace = "swaync-control-center" }, blur = true })
hl.layer_rule({ match = { namespace = "swaync-notification-window" }, blur = false })
hl.layer_rule({ match = { namespace = "walker" }, no_anim = true })
hl.layer_rule({ match = { namespace = "^(wofi)$" }, no_anim = true, blur = true })