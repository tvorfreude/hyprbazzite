-- ═══════════════════════════════════════════════════════════════════════════════
-- HyprBazzite Keybind Profiles
-- ═══════════════════════════════════════════════════════════════════════════════
-- Two profiles designed for identical muscle memory across macOS + Linux:
--
--   "macos"  - Mirrors AeroSpace 1:1. ALT (the physical Option key on a Mac
--              keyboard) is the WM modifier — exactly like AeroSpace on macOS.
--              NO keyd remapping is used: every bind fires on the real physical
--              key, so behaviour is identical whether or not keyd is installed.
--              System shortcuts follow macOS conventions (screenshots, lock).
--              Includes "resize" and "service" submaps that mirror AeroSpace's
--              resize-mode and service-mode.
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
local launcher = "wofi -wass"

-- ═══════════════════════════════════════════════════════════════════════════════
-- MACOS PROFILE
-- ═══════════════════════════════════════════════════════════════════════════════
-- Modifier: ALT — the physical Option key on a Mac keyboard, exactly like
--                 AeroSpace on macOS. Works directly on the real key; no keyd.
-- App shortcuts: NOT remapped here (moved away from keyd). Cmd = Super remains
--                free for you to wire up separately if desired.
-- System shortcuts: match macOS conventions (screenshots, lock).
-- ═══════════════════════════════════════════════════════════════════════════════
if profile == "macos" then

    local m = "ALT"

    -- ─── Launch ──────────────────────────────────────────────────────────────
    -- AeroSpace: alt-enter -> new terminal window
    hl.bind(m .. " + return", hl.dsp.exec_cmd(terminal))
    -- Spotlight equivalent (Alt+Space as the physical Option key on Mac hardware)
    hl.bind("ALT + SPACE",       hl.dsp.exec_cmd(launcher))

    -- ─── Window Actions ──────────────────────────────────────────────────────
    hl.bind(m .. " + W", hl.dsp.window.close())            -- alt-w  = close
    hl.bind(m .. " + F", hl.dsp.window.fullscreen(0))      -- alt-f  = fullscreen
    hl.bind(m .. " + V", hl.dsp.window.float({ action = "toggle" })) -- alt-v = layout floating tiling
    -- alt-e = balance-sizes. Hyprland/dwindle has no true balance; reset the
    -- current split to 50/50 as the closest equivalent.
    hl.bind(m .. " + E", hl.dsp.exec_cmd("hyprctl dispatch splitratio exact 0.5"))
    hl.bind(m .. " + SHIFT + F", hl.dsp.window.float({ action = "toggle" })) -- alt-shift-f = layout floating tiling

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
    -- AeroSpace: alt-minus / alt-equal = resize smart -/+50 (both dimensions)
    hl.bind(m .. " + minus", hl.dsp.window.resize({ x = -50, y = -50 }))
    hl.bind(m .. " + equal", hl.dsp.window.resize({ x = 50, y = 50 }))

    -- ─── Layout ──────────────────────────────────────────────────────────────
    -- AeroSpace has tiles/accordion layouts; the closest dwindle equivalents:
    -- alt-slash    = "layout tiles h/v"     -> toggle the split orientation
    hl.bind(m .. " + slash", hl.dsp.exec_cmd("hyprctl dispatch togglesplit"))
    -- alt-comma    = "layout accordion h/v" -> stack windows into a group (tabs)
    hl.bind(m .. " + comma", hl.dsp.exec_cmd("hyprctl dispatch togglegroup"))
    -- alt-shift-a  = "layout accordion tiles" -> cycle through the grouped windows
    hl.bind(m .. " + SHIFT + A", hl.dsp.exec_cmd("hyprctl dispatch changegroupactive f"))

    -- ─── Focus Monitor ───────────────────────────────────────────────────────
    -- alt-period = focus next monitor, alt-semicolon = focus prev monitor
    hl.bind(m .. " + period",    hl.dsp.focus({ monitor = "+1" }))
    hl.bind(m .. " + semicolon", hl.dsp.focus({ monitor = "-1" }))

    -- ─── Move Window to Monitor (focus follows) ──────────────────────────────
    -- alt-shift-period/semicolon = move window to next/prev monitor + follow it
    hl.bind(m .. " + SHIFT + period",    hl.dsp.exec_cmd("hyprctl dispatch movewindow mon:+1"))
    hl.bind(m .. " + SHIFT + semicolon", hl.dsp.exec_cmd("hyprctl dispatch movewindow mon:-1"))

    -- ─── Workspaces ──────────────────────────────────────────────────────────
    for i = 1, 10 do
        local key = i % 10
        hl.bind(m .. " + " .. key,         hl.dsp.focus({ workspace = i }))
        hl.bind(m .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
    end

    -- ─── Workspace Navigation ────────────────────────────────────────────────
    -- alt-tab       = workspace-back-and-forth (jump to last-used workspace)
    hl.bind(m .. " + Tab",         hl.dsp.exec_cmd("hyprctl dispatch workspace previous"))
    -- alt-shift-tab = move-workspace-to-monitor next (whole workspace hops screen)
    hl.bind(m .. " + SHIFT + Tab", hl.dsp.exec_cmd("hyprctl dispatch moveworkspacetomonitor +1"))

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

    -- ─── Modes / Submaps ─────────────────────────────────────────────────────
    -- alt-r           = enter resize mode  (AeroSpace: mode resize)
    -- alt-shift-slash = enter service mode (AeroSpace: mode service)
    hl.bind(m .. " + R",           hl.dsp.submap("resize"))
    hl.bind(m .. " + SHIFT + slash", hl.dsp.submap("service"))

    -- ─── System (matching macOS conventions) ─────────────────────────────────
    -- Cmd+Shift+3/4/5 = screenshot. Bound to physical SUPER (the Cmd key), which
    -- is now free since we no longer remap it via keyd.
    hl.bind("SUPER + SHIFT + 3", hl.dsp.exec_cmd("/usr/libexec/hyprbazzite-ctl screenshot full"))
    hl.bind("SUPER + SHIFT + 4", hl.dsp.exec_cmd("/usr/libexec/hyprbazzite-ctl screenshot area"))
    hl.bind("SUPER + SHIFT + 5", hl.dsp.exec_cmd("/usr/libexec/hyprbazzite-ctl screenshot area"))

    -- Cmd+Ctrl+Q = lock screen (macOS)
    hl.bind("SUPER + CTRL + Q", hl.dsp.exec_cmd("hyprlock"))

    -- Notification center (macOS-style). AeroSpace leaves this to macOS; alt-n here.
    hl.bind(m .. " + N", hl.dsp.exec_cmd("swaync-client -t -sw"))

    -- Transparency toggle (HyprBazzite extra)
    hl.bind(m .. " + O", hl.dsp.exec_cmd("/usr/libexec/hyprbazzite-ctl transparency toggle"))

    -- Clipboard history (Cmd+Shift+V equivalent)
    hl.bind(m .. " + SHIFT + V", hl.dsp.exec_cmd("cliphist list | wofi --dmenu | cliphist decode | wl-copy"))

    -- ─── Mouse Bindings ──────────────────────────────────────────────────────
    -- AeroSpace: alt + left-drag = move, alt + right-drag = resize
    hl.bind(m .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
    hl.bind(m .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

    -- ═══════════════════════════════════════════════════════════════════════════
    -- RESIZE SUBMAP — mirrors AeroSpace [mode.resize.binding]
    -- Enter with alt-r; keys repeat while held; enter/esc exits.
    -- ═══════════════════════════════════════════════════════════════════════════
    hl.define_submap("resize", function()
        -- Fine resize (repeatable — hold the key)
        hl.bind("H",     hl.dsp.window.resize({ x = -30, y = 0 }), { repeating = true })
        hl.bind("L",     hl.dsp.window.resize({ x = 30,  y = 0 }), { repeating = true })
        hl.bind("J",     hl.dsp.window.resize({ x = 0,   y = 30 }), { repeating = true })
        hl.bind("K",     hl.dsp.window.resize({ x = 0,   y = -30 }), { repeating = true })
        hl.bind("left",  hl.dsp.window.resize({ x = -30, y = 0 }), { repeating = true })
        hl.bind("right", hl.dsp.window.resize({ x = 30,  y = 0 }), { repeating = true })
        hl.bind("down",  hl.dsp.window.resize({ x = 0,   y = 30 }), { repeating = true })
        hl.bind("up",    hl.dsp.window.resize({ x = 0,   y = -30 }), { repeating = true })

        -- Coarse resize (shift = bigger jumps)
        hl.bind("SHIFT + H",     hl.dsp.window.resize({ x = -100, y = 0 }), { repeating = true })
        hl.bind("SHIFT + L",     hl.dsp.window.resize({ x = 100,  y = 0 }), { repeating = true })
        hl.bind("SHIFT + J",     hl.dsp.window.resize({ x = 0,    y = 100 }), { repeating = true })
        hl.bind("SHIFT + K",     hl.dsp.window.resize({ x = 0,    y = -100 }), { repeating = true })
        hl.bind("SHIFT + left",  hl.dsp.window.resize({ x = -100, y = 0 }), { repeating = true })
        hl.bind("SHIFT + right", hl.dsp.window.resize({ x = 100,  y = 0 }), { repeating = true })
        hl.bind("SHIFT + down",  hl.dsp.window.resize({ x = 0,    y = 100 }), { repeating = true })
        hl.bind("SHIFT + up",    hl.dsp.window.resize({ x = 0,    y = -100 }), { repeating = true })

        -- Smart resize (both dimensions)
        hl.bind("minus", hl.dsp.window.resize({ x = -30, y = -30 }), { repeating = true })
        hl.bind("equal", hl.dsp.window.resize({ x = 30,  y = 30 }), { repeating = true })

        -- b = balance (reset split 50/50) then exit
        hl.bind("B", function()
            hl.exec_cmd("hyprctl dispatch splitratio exact 0.5")
            hl.dispatch(hl.dsp.submap("reset"))
        end)

        -- Move while in resize mode, then exit (quick repositioning)
        hl.bind("ALT + H", function() hl.dispatch(hl.dsp.window.move({ direction = "left" }));  hl.dispatch(hl.dsp.submap("reset")) end)
        hl.bind("ALT + L", function() hl.dispatch(hl.dsp.window.move({ direction = "right" })); hl.dispatch(hl.dsp.submap("reset")) end)
        hl.bind("ALT + J", function() hl.dispatch(hl.dsp.window.move({ direction = "down" }));  hl.dispatch(hl.dsp.submap("reset")) end)
        hl.bind("ALT + K", function() hl.dispatch(hl.dsp.window.move({ direction = "up" }));    hl.dispatch(hl.dsp.submap("reset")) end)

        -- Exit
        hl.bind("return", hl.dsp.submap("reset"))
        hl.bind("escape", hl.dsp.submap("reset"))
    end)

    -- ═══════════════════════════════════════════════════════════════════════════
    -- SERVICE SUBMAP — mirrors AeroSpace [mode.service.binding]
    -- Enter with alt-shift-/; esc reloads config and exits.
    -- ═══════════════════════════════════════════════════════════════════════════
    hl.define_submap("service", function()
        -- esc = reload config + exit
        hl.bind("escape", function()
            hl.exec_cmd("hyprctl reload")
            hl.dispatch(hl.dsp.submap("reset"))
        end)
        -- r = flatten workspace tree + exit. Dwindle has no flatten; just exit.
        hl.bind("R", hl.dsp.submap("reset"))
        -- f = toggle floating + exit
        hl.bind("F", function()
            hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
            hl.dispatch(hl.dsp.submap("reset"))
        end)
        -- backspace = close all windows on this workspace except the focused one + exit
        hl.bind("backspace", function()
            hl.exec_cmd([[bash -c 'aw=$(hyprctl -j activewindow | jq -r .address); ws=$(hyprctl -j activewindow | jq -r .workspace.id); for a in $(hyprctl -j clients | jq -r --argjson ws "$ws" ".[] | select(.workspace.id==$ws) | .address"); do [ "$a" != "$aw" ] && hyprctl dispatch closewindow address:$a; done']])
            hl.dispatch(hl.dsp.submap("reset"))
        end)
        -- alt-h/j/k/l = join-with direction (merge into a group) + exit
        hl.bind("ALT + H", function() hl.exec_cmd("hyprctl dispatch moveintogroup left");  hl.dispatch(hl.dsp.submap("reset")) end)
        hl.bind("ALT + J", function() hl.exec_cmd("hyprctl dispatch moveintogroup down");  hl.dispatch(hl.dsp.submap("reset")) end)
        hl.bind("ALT + K", function() hl.exec_cmd("hyprctl dispatch moveintogroup up");    hl.dispatch(hl.dsp.submap("reset")) end)
        hl.bind("ALT + L", function() hl.exec_cmd("hyprctl dispatch moveintogroup right"); hl.dispatch(hl.dsp.submap("reset")) end)
    end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- LINUX PROFILE (standard Hyprland)
-- ═══════════════════════════════════════════════════════════════════════════════
else

    local m = "SUPER"

    -- ─── Launch ──────────────────────────────────────────────────────────────
    hl.bind(m .. " + return", hl.dsp.exec_cmd(terminal))
    hl.bind(m .. " + B",      hl.dsp.exec_cmd(browser))
    hl.bind(m .. " + F",      hl.dsp.exec_cmd(filemanager))
    hl.bind(m .. " + SPACE",  hl.dsp.exec_cmd(launcher))
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
