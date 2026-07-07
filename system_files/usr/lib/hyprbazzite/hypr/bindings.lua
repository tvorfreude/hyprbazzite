-- ═══════════════════════════════════════════════════════════════════════════════
-- HyprBazzite Keybind Profiles
-- ═══════════════════════════════════════════════════════════════════════════════
-- Two profiles designed for identical muscle memory across macOS + Linux:
--
--   "macos"  - Mirrors AeroSpace exactly. Alt is the WM modifier.
--              keyd remaps Super→Ctrl so Cmd shortcuts (copy/paste/etc) work.
--              System shortcuts match macOS (screenshots, lock, notifications).
--
--   "linux"  - Standard Hyprland. Super is WM modifier, Ctrl for app shortcuts.
--
-- Switch: hyprbazzite-ctl keybinds [macos|linux|toggle]
-- ═══════════════════════════════════════════════════════════════════════════════

-- Read active profile
local profile_file = "/etc/hypr/keybind-profile"
local profile = "linux"
local f = io.open(profile_file, "r")
if f then
    local content = f:read("*l")
    f:close()
    if content and content:match("macos") then
        profile = "macos"
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- VARIABLES
-- ═══════════════════════════════════════════════════════════════════════════════
local terminal = "kitty"
local browser = "flatpak run io.github.zen_browser.zen"
local filemanager = "thunar"

-- ═══════════════════════════════════════════════════════════════════════════════
-- MACOS PROFILE
-- ═══════════════════════════════════════════════════════════════════════════════
-- Modifier: ALT (same physical key as macOS Option, same as AeroSpace)
-- App shortcuts: handled by keyd (Super/Cmd → Ctrl remap)
-- System shortcuts: match macOS conventions exactly
-- ═══════════════════════════════════════════════════════════════════════════════
if profile == "macos" then

    local m = "ALT"

    -- ─── Launch ──────────────────────────────────────────────────────────────
    hl.bind(m .. " + return", hl.dsp.exec_cmd(terminal))
    hl.bind(m .. " + SPACE",  hl.dsp.exec_cmd("wofi -wass"))  -- Spotlight equivalent

    -- ─── Window Actions ──────────────────────────────────────────────────────
    hl.bind(m .. " + W", hl.dsp.window.close())
    hl.bind(m .. " + F", hl.dsp.window.fullscreen(0))
    hl.bind(m .. " + V", hl.dsp.window.float({ action = "toggle" }))
    hl.bind(m .. " + E", hl.dsp.exec_cmd("hyprctl dispatch splitratio exact 0.5"))
    hl.bind(m .. " + SHIFT + F", hl.dsp.window.float({ action = "toggle" }))

    -- ─── Focus (vim + arrows) ────────────────────────────────────────────────
    hl.bind(m .. " + H",     hl.dsp.focus({ direction = "left" }))
    hl.bind(m .. " + J",     hl.dsp.focus({ direction = "down" }))
    hl.bind(m .. " + K",     hl.dsp.focus({ direction = "up" }))
    hl.bind(m .. " + L",     hl.dsp.focus({ direction = "right" }))
    hl.bind(m .. " + left",  hl.dsp.focus({ direction = "left" }))
    hl.bind(m .. " + down",  hl.dsp.focus({ direction = "down" }))
    hl.bind(m .. " + up",    hl.dsp.focus({ direction = "up" }))
    hl.bind(m .. " + right", hl.dsp.focus({ direction = "right" }))

    -- ─── Move Windows (vim + arrows) ────────────────────────────────────────
    hl.bind(m .. " + SHIFT + H",     hl.dsp.window.move({ direction = "left" }))
    hl.bind(m .. " + SHIFT + J",     hl.dsp.window.move({ direction = "down" }))
    hl.bind(m .. " + SHIFT + K",     hl.dsp.window.move({ direction = "up" }))
    hl.bind(m .. " + SHIFT + L",     hl.dsp.window.move({ direction = "right" }))
    hl.bind(m .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
    hl.bind(m .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))
    hl.bind(m .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
    hl.bind(m .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))

    -- ─── Resize ──────────────────────────────────────────────────────────────
    hl.bind(m .. " + minus", hl.dsp.window.resize({ x = -50, y = -50 }))
    hl.bind(m .. " + equal", hl.dsp.window.resize({ x = 50, y = 50 }))

    -- ─── Layout ──────────────────────────────────────────────────────────────
    hl.bind(m .. " + slash", hl.dsp.exec_cmd("hyprctl keyword dwindle:force_split 0"))
    hl.bind(m .. " + comma", hl.dsp.window.pseudo())

    -- ─── Focus Monitor ───────────────────────────────────────────────────────
    hl.bind(m .. " + period",    hl.dsp.focus({ monitor = "+1" }))
    hl.bind(m .. " + semicolon", hl.dsp.focus({ monitor = "-1" }))

    -- ─── Move Window to Monitor ──────────────────────────────────────────────
    hl.bind(m .. " + SHIFT + period",    hl.dsp.exec_cmd("hyprctl dispatch movewindow mon:+1"))
    hl.bind(m .. " + SHIFT + semicolon", hl.dsp.exec_cmd("hyprctl dispatch movewindow mon:-1"))

    -- ─── Workspaces ──────────────────────────────────────────────────────────
    for i = 1, 10 do
        local key = i % 10
        hl.bind(m .. " + " .. key,         hl.dsp.focus({ workspace = i }))
        hl.bind(m .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
    end

    -- ─── Workspace Navigation ────────────────────────────────────────────────
    hl.bind(m .. " + Tab",         hl.dsp.exec_cmd("hyprctl dispatch workspace previous"))
    hl.bind(m .. " + SHIFT + Tab", hl.dsp.exec_cmd("hyprctl dispatch movewindow mon:+1"))

    -- ─── Special Workspaces (Scratchpads) ────────────────────────────────────
    hl.bind(m .. " + S", hl.dsp.workspace.toggle_special())
    hl.bind(m .. " + SHIFT + S", function()
        local window = hl.get_active_window()
        if window and window.workspace.name:find("^special") then
            hl.dispatch(hl.dsp.window.move({ workspace = "e+0" }))
        else
            hl.dispatch(hl.dsp.window.move({ workspace = "special" }))
        end
    end)

    hl.bind(m .. " + Q", hl.dsp.workspace.toggle_special("scratchpad"))
    hl.bind(m .. " + SHIFT + Q", function()
        local window = hl.get_active_window()
        if window and window.workspace.name:find("^special:scratchpad") then
            hl.dispatch(hl.dsp.window.move({ workspace = "e+0" }))
        else
            hl.dispatch(hl.dsp.window.move({ workspace = "special:scratchpad" }))
        end
    end)

    -- ─── System (matching macOS conventions) ─────────────────────────────────
    -- Cmd+Shift+3/4 = screenshot (keyd sends Super as Ctrl, so we bind SUPER directly
    -- since Hyprland grabs these before keyd's remap applies to Wayland clients)
    hl.bind("SUPER + SHIFT + 3", hl.dsp.exec_cmd("/usr/libexec/hyprbazzite-ctl screenshot full"))
    hl.bind("SUPER + SHIFT + 4", hl.dsp.exec_cmd("/usr/libexec/hyprbazzite-ctl screenshot area"))
    hl.bind("SUPER + SHIFT + 5", hl.dsp.exec_cmd("/usr/libexec/hyprbazzite-ctl screenshot area"))

    -- Cmd+Ctrl+Q = lock screen (macOS)
    hl.bind("SUPER + CTRL + Q", hl.dsp.exec_cmd("hyprlock"))

    -- Cmd+Space = Spotlight → already alt+space above for WM launcher
    -- But also add Super+Space as secondary (Cmd+Space on physical keyboard)
    hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("wofi -wass"))

    -- Notification center (matches macOS: click top-right, or we use alt+n)
    hl.bind(m .. " + N", hl.dsp.exec_cmd("swaync-client -t -sw"))

    -- Transparency toggle
    hl.bind(m .. " + O", hl.dsp.exec_cmd("/usr/libexec/hyprbazzite-ctl transparency toggle"))

    -- Clipboard history (Cmd+Shift+V equivalent)
    hl.bind(m .. " + SHIFT + V", hl.dsp.exec_cmd("cliphist list | wofi --dmenu | cliphist decode | wl-copy"))

    -- ─── Mouse Bindings ──────────────────────────────────────────────────────
    hl.bind(m .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
    hl.bind(m .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
    hl.bind(m .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
    hl.bind(m .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- ═══════════════════════════════════════════════════════════════════════════════
-- LINUX PROFILE (standard Hyprland)
-- ═══════════════════════════════════════════════════════════════════════════════
else

    local m = "SUPER"

    -- ─── Launch ──────────────────────────────────────────────────────────────
    hl.bind(m .. " + return", hl.dsp.exec_cmd(terminal))
    hl.bind(m .. " + B",      hl.dsp.exec_cmd(browser))
    hl.bind(m .. " + F",      hl.dsp.exec_cmd(filemanager))
    hl.bind(m .. " + SPACE",  hl.dsp.exec_cmd("wofi -wass"))
    hl.bind(m .. " + E",      hl.dsp.exec_cmd(terminal .. " -e nvim"))

    -- ─── Window Management ───────────────────────────────────────────────────
    hl.bind(m .. " + W",         hl.dsp.window.close())
    hl.bind(m .. " + V",         hl.dsp.window.float({ action = "toggle" }))
    hl.bind(m .. " + J",         hl.dsp.window.cycle_next())
    hl.bind(m .. " + P",         hl.dsp.window.pseudo())
    hl.bind(m .. " + SHIFT + F", hl.dsp.window.fullscreen(0))
    hl.bind(m .. " + ALT + F",   hl.dsp.window.fullscreen(1))

    -- ─── Focus Movement ──────────────────────────────────────────────────────
    hl.bind(m .. " + left",  hl.dsp.focus({ direction = "left" }))
    hl.bind(m .. " + right", hl.dsp.focus({ direction = "right" }))
    hl.bind(m .. " + up",    hl.dsp.focus({ direction = "up" }))
    hl.bind(m .. " + down",  hl.dsp.focus({ direction = "down" }))
    hl.bind("ALT + Tab",     hl.dsp.window.cycle_next())

    -- ─── Workspaces ──────────────────────────────────────────────────────────
    for i = 1, 10 do
        local key = i % 10
        hl.bind(m .. " + " .. key,           hl.dsp.focus({ workspace = i }))
        hl.bind(m .. " + SHIFT + " .. key,   hl.dsp.window.move({ workspace = i }))
    end

    -- ─── Mouse Workspace Scrolling ───────────────────────────────────────────
    hl.bind(m .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
    hl.bind(m .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

    -- ─── Window Moving ───────────────────────────────────────────────────────
    hl.bind(m .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
    hl.bind(m .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
    hl.bind(m .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
    hl.bind(m .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))

    -- ─── Window Resizing ─────────────────────────────────────────────────────
    hl.bind(m .. " + minus", hl.dsp.window.resize({ x = -100, y = 0 }))
    hl.bind(m .. " + equal", hl.dsp.window.resize({ x = 100, y = 0 }))
    hl.bind(m .. " + SHIFT + minus", hl.dsp.window.resize({ x = 0, y = -100 }))
    hl.bind(m .. " + SHIFT + equal", hl.dsp.window.resize({ x = 0, y = 100 }))

    -- ─── Scratchpads ─────────────────────────────────────────────────────────
    hl.bind(m .. " + Q",         hl.dsp.workspace.toggle_special())
    hl.bind(m .. " + SHIFT + Q", function()
        local window = hl.get_active_window()
        if window and window.workspace.name:find("^special") then
            hl.dispatch(hl.dsp.window.move({ workspace = "e+0" }))
        else
            hl.dispatch(hl.dsp.window.move({ workspace = "special" }))
        end
    end)
    hl.bind(m .. " + ALT + Q", hl.dsp.workspace.toggle_special("scratchpad"))

    -- ─── Screenshots ─────────────────────────────────────────────────────────
    hl.bind(m .. " + SHIFT + S", hl.dsp.exec_cmd("/usr/libexec/hyprbazzite-ctl screenshot area"))
    hl.bind(m .. " + CTRL + S",  hl.dsp.exec_cmd("/usr/libexec/hyprbazzite-ctl screenshot full"))

    -- ─── System ──────────────────────────────────────────────────────────────
    hl.bind(m .. " + N",         hl.dsp.exec_cmd("swaync-client -t -sw"))
    hl.bind(m .. " + ALT + L",   hl.dsp.exec_cmd("hyprlock"))
    hl.bind(m .. " + K",         hl.dsp.exec_cmd("/usr/libexec/hyprbazzite-ctl osk toggle"))
    hl.bind(m .. " + SHIFT + K", hl.dsp.exec_cmd("/etc/hypr/scripts/swap-osk-half.sh"))
    hl.bind(m .. " + O",         hl.dsp.exec_cmd("/usr/libexec/hyprbazzite-ctl transparency toggle"))
    hl.bind(m .. " + SHIFT + V", hl.dsp.exec_cmd("cliphist list | wofi --dmenu | cliphist decode | wl-copy"))

    -- ─── Mouse Bindings ──────────────────────────────────────────────────────
    hl.bind(m .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
    hl.bind(m .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SHARED (both profiles)
-- ═══════════════════════════════════════════════════════════════════════════════

-- ─── Multimedia (hardware keys) ──────────────────────────────────────────────
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),       { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl set +5%"),                        { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"),                        { locked = true, repeating = true })
hl.bind("XF86AudioMute",  hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"),                       { locked = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),                             { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),                         { locked = true })

-- ─── Lid Switch ──────────────────────────────────────────────────────────────
hl.bind("switch:on:Lid Switch",  hl.dsp.exec_cmd("/etc/hypr/scripts/lidact.sh off"), { locked = true })
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("/etc/hypr/scripts/lidact.sh on"),  { locked = true })

-- ─── Gestures ────────────────────────────────────────────────────────────────
hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})
