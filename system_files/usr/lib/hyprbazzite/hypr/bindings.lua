-- ═══════════════════════════════════════════════════════════════════════════════
-- HyprBazzite Keybinds
-- ═══════════════════════════════════════════════════════════════════════════════
-- One shared set of bindings drives both layouts; only the genuine differences
-- live in the per-profile branch below.
--
--   Linux (default) - Standard Hyprland. SUPER drives everything.
--   macOS (marker)  - AeroSpace-style. SUPER still drives window management, but
--                     app/system shortcuts move to ALT (the Option key), and
--                     vim focus/move, monitor binds and the resize/service
--                     submaps are added on top of the shared set.
--
-- macOS is active while a marker file exists; toggle it live with
-- `hyprbazzite-ctl keybinds [macos|linux|toggle]`. The marker lives in the
-- per-user runtime dir, so switching needs no root and clears on logout.
-- ═══════════════════════════════════════════════════════════════════════════════

local f = io.open((os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/hyprbazzite-keybinds-macos", "r")
local macos = f ~= nil
if f then f:close() end

local mod    = "SUPER"                     -- primary window-management modifier (both layouts)
local appmod = macos and "ALT" or "SUPER"  -- app/system shortcuts (macOS uses the Option key)

local terminal    = "kitty"
local browser     = "/usr/libexec/hyprbazzite-ctl open browser"
local filemanager = 'xdg-open "$HOME"'
local launcher    = "wofi -wass"

-- ═══════════════════════════════════════════════════════════════════════════════
-- SHARED — identical in both layouts
-- ═══════════════════════════════════════════════════════════════════════════════

-- ─── Launch / app shortcuts ──────────────────────────────────────────────────
hl.bind(mod .. " + return",    hl.dsp.exec_cmd(terminal))
hl.bind(appmod .. " + SPACE",  hl.dsp.exec_cmd(launcher))
hl.bind(appmod .. " + W",      hl.dsp.window.close())

-- ─── Window ──────────────────────────────────────────────────────────────────
hl.bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }))

-- ─── Focus (arrows) ──────────────────────────────────────────────────────────
hl.bind(mod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + down",  hl.dsp.focus({ direction = "down" }))
hl.bind(mod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }))

-- ─── Move window (arrows) ────────────────────────────────────────────────────
hl.bind(mod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))
hl.bind(mod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))

-- ─── Workspaces ──────────────────────────────────────────────────────────────
for i = 1, 10 do
    local key = i % 10
    hl.bind(mod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- ─── System ──────────────────────────────────────────────────────────────────
hl.bind(mod .. " + N",            hl.dsp.exec_cmd("swaync-client -t -sw"))
hl.bind(mod .. " + O",            hl.dsp.exec_cmd("/usr/libexec/hyprbazzite-ctl transparency toggle"))
hl.bind(appmod .. " + SHIFT + V", hl.dsp.exec_cmd("cliphist list | wofi --dmenu | cliphist decode | wl-copy"))

-- ─── Mouse ───────────────────────────────────────────────────────────────────
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ═══════════════════════════════════════════════════════════════════════════════
-- PROFILE-SPECIFIC
-- ═══════════════════════════════════════════════════════════════════════════════
if macos then

    -- ─── Window actions ──────────────────────────────────────────────────────
    hl.bind(mod .. " + F",         hl.dsp.window.fullscreen(0))                             -- alt-f = fullscreen
    hl.bind(mod .. " + E",         hl.dsp.exec_cmd("hyprctl dispatch splitratio exact 0.5")) -- alt-e = balance (50/50)
    hl.bind(mod .. " + SHIFT + F", hl.dsp.window.float({ action = "toggle" }))

    -- ─── Focus / move (vim keys, on top of the shared arrows) ────────────────
    hl.bind(mod .. " + H", hl.dsp.focus({ direction = "left" }))
    hl.bind(mod .. " + J", hl.dsp.focus({ direction = "down" }))
    hl.bind(mod .. " + K", hl.dsp.focus({ direction = "up" }))
    hl.bind(mod .. " + L", hl.dsp.focus({ direction = "right" }))
    hl.bind(mod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
    hl.bind(mod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }))
    hl.bind(mod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
    hl.bind(mod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))

    -- ─── Resize (smart, both dimensions) ─────────────────────────────────────
    hl.bind(mod .. " + minus", hl.dsp.window.resize({ x = -50, y = -50 }))
    hl.bind(mod .. " + equal", hl.dsp.window.resize({ x = 50, y = 50 }))

    -- ─── Layout ──────────────────────────────────────────────────────────────
    hl.bind(mod .. " + slash",     hl.dsp.exec_cmd("hyprctl dispatch togglesplit"))          -- tiles h/v
    hl.bind(mod .. " + comma",     hl.dsp.exec_cmd("hyprctl dispatch togglegroup"))          -- accordion (tabs)
    hl.bind(mod .. " + SHIFT + A", hl.dsp.exec_cmd("hyprctl dispatch changegroupactive f"))  -- cycle group

    -- ─── Monitors ────────────────────────────────────────────────────────────
    hl.bind(mod .. " + period",           hl.dsp.focus({ monitor = "+1" }))
    hl.bind(mod .. " + semicolon",        hl.dsp.focus({ monitor = "-1" }))
    hl.bind(mod .. " + SHIFT + period",    hl.dsp.exec_cmd("hyprctl dispatch movewindow mon:+1"))
    hl.bind(mod .. " + SHIFT + semicolon", hl.dsp.exec_cmd("hyprctl dispatch movewindow mon:-1"))

    -- ─── Workspace navigation ────────────────────────────────────────────────
    hl.bind(mod .. " + Tab",         hl.dsp.exec_cmd("hyprctl dispatch workspace previous"))
    hl.bind(mod .. " + SHIFT + Tab", hl.dsp.exec_cmd("hyprctl dispatch moveworkspacetomonitor +1"))

    -- ─── Special workspaces (scratchpads) ────────────────────────────────────
    hl.bind(mod .. " + S", hl.dsp.workspace.toggle_special())
    hl.bind(mod .. " + SHIFT + S", function()
        local window = hl.get_active_window()
        if window and window.workspace.name:find("^special") then
            hl.dispatch(hl.dsp.window.move({ workspace = "e+0" }))
        else
            hl.dispatch(hl.dsp.window.move({ workspace = "special" }))
        end
    end)
    hl.bind(mod .. " + Q", hl.dsp.workspace.toggle_special("scratchpad"))
    hl.bind(mod .. " + SHIFT + Q", function()
        local window = hl.get_active_window()
        if window and window.workspace.name:find("^special:scratchpad") then
            hl.dispatch(hl.dsp.window.move({ workspace = "e+0" }))
        else
            hl.dispatch(hl.dsp.window.move({ workspace = "special:scratchpad" }))
        end
    end)

    -- ─── Modes / submaps ─────────────────────────────────────────────────────
    hl.bind(mod .. " + R",             hl.dsp.submap("resize"))
    hl.bind(mod .. " + SHIFT + slash", hl.dsp.submap("service"))

    -- ─── macOS-convention system shortcuts (Option key) ──────────────────────
    hl.bind(appmod .. " + SHIFT + 3", hl.dsp.exec_cmd("/usr/libexec/hyprbazzite-ctl screenshot full"))
    hl.bind(appmod .. " + SHIFT + 4", hl.dsp.exec_cmd("/usr/libexec/hyprbazzite-ctl screenshot area"))
    hl.bind(appmod .. " + SHIFT + 5", hl.dsp.exec_cmd("/usr/libexec/hyprbazzite-ctl screenshot area"))
    hl.bind(appmod .. " + CTRL + Q",  hl.dsp.exec_cmd("hyprlock"))

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

else

    -- ─── Launch ──────────────────────────────────────────────────────────────
    hl.bind(mod .. " + B", hl.dsp.exec_cmd(browser))
    hl.bind(mod .. " + F", hl.dsp.exec_cmd(filemanager))

    -- ─── Window management ───────────────────────────────────────────────────
    hl.bind(mod .. " + J",         hl.dsp.window.cycle_next())
    hl.bind(mod .. " + P",         hl.dsp.window.pseudo())
    hl.bind(mod .. " + SHIFT + F", hl.dsp.window.fullscreen(0))
    hl.bind(mod .. " + ALT + F",   hl.dsp.window.fullscreen(1))
    hl.bind("ALT + Tab",           hl.dsp.window.cycle_next())

    -- ─── Mouse workspace scrolling ───────────────────────────────────────────
    hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
    hl.bind(mod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

    -- ─── Window resizing ─────────────────────────────────────────────────────
    hl.bind(mod .. " + minus",         hl.dsp.window.resize({ x = -100, y = 0 }))
    hl.bind(mod .. " + equal",         hl.dsp.window.resize({ x = 100, y = 0 }))
    hl.bind(mod .. " + SHIFT + minus", hl.dsp.window.resize({ x = 0, y = -100 }))
    hl.bind(mod .. " + SHIFT + equal", hl.dsp.window.resize({ x = 0, y = 100 }))

    -- ─── Scratchpads ─────────────────────────────────────────────────────────
    hl.bind(mod .. " + Q",         hl.dsp.workspace.toggle_special())
    hl.bind(mod .. " + SHIFT + Q", function()
        local window = hl.get_active_window()
        if window and window.workspace.name:find("^special") then
            hl.dispatch(hl.dsp.window.move({ workspace = "e+0" }))
        else
            hl.dispatch(hl.dsp.window.move({ workspace = "special" }))
        end
    end)
    hl.bind(mod .. " + ALT + Q", hl.dsp.workspace.toggle_special("scratchpad"))

    -- ─── Screenshots ─────────────────────────────────────────────────────────
    hl.bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd("/usr/libexec/hyprbazzite-ctl screenshot area"))
    hl.bind(mod .. " + CTRL + S",  hl.dsp.exec_cmd("/usr/libexec/hyprbazzite-ctl screenshot full"))

    -- ─── System ──────────────────────────────────────────────────────────────
    hl.bind(mod .. " + ALT + L",   hl.dsp.exec_cmd("hyprlock"))
    hl.bind(mod .. " + K",         hl.dsp.exec_cmd("/usr/libexec/hyprbazzite-ctl osk toggle"))
    hl.bind(mod .. " + SHIFT + K", hl.dsp.exec_cmd("/usr/libexec/hyprbazzite-ctl osk swap-anchor"))

end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SHARED (hardware + input, both profiles)
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
hl.bind("switch:on:Lid Switch",  hl.dsp.exec_cmd("/usr/libexec/hyprbazzite-ctl lid close"), { locked = true })
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("/usr/libexec/hyprbazzite-ctl lid open"),  { locked = true })

-- ─── Gestures ────────────────────────────────────────────────────────────────
hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})
