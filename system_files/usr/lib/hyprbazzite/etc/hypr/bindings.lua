-- ===== VARIABLES =====
local mainMod = "SUPER"
local terminal = "kitty"
local browser = "flatpak run io.github.zen_browser.zen"
local filemanager = "thunar"

-- APPLICATION LAUNCHING
hl.bind(mainMod .. " + return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + B",      hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + F",      hl.dsp.exec_cmd(filemanager))
hl.bind(mainMod .. " + SPACE",  hl.dsp.exec_cmd("wofi --show drun --conf /etc/wofi/config --style /etc/wofi/style.css"))
hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd(terminal .. " -e nvim"))

-- WINDOW MANAGEMENT
hl.bind(mainMod .. " + W",       hl.dsp.window.close())
hl.bind(mainMod .. " + V",       hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + J",       hl.dsp.layout("cyclenext"))
hl.bind(mainMod .. " + P",       hl.dsp.window.pseudo())
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen(0))
hl.bind(mainMod .. " + ALT + F",   hl.dsp.window.fullscreen(1))

-- FOCUS MOVEMENT
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))
hl.bind("ALT + Tab",           hl.dsp.layout("cyclenext"))

-- WORKSPACE NAVIGATION (Looping 1-10)
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,           hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key,   hl.dsp.window.move({ workspace = i }))
end

-- MOUSE WORKSPACE SCROLLING
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- WINDOW MOVING / SWAPPING
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))

-- WINDOW RESIZING
hl.bind(mainMod .. " + minus", hl.dsp.window.resize({ x = -100, y = 0 }))
hl.bind(mainMod .. " + equal", hl.dsp.window.resize({ x = 100, y = 0 }))
hl.bind(mainMod .. " + SHIFT + minus", hl.dsp.window.resize({ x = 0, y = -100 }))
hl.bind(mainMod .. " + SHIFT + equal", hl.dsp.window.resize({ x = 0, y = 100 }))

-- SCREENSHOTS
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("/usr/libexec/hyprbazzite-ctl screenshot area"))
hl.bind(mainMod .. " + CTRL + S",  hl.dsp.exec_cmd("/usr/libexec/hyprbazzite-ctl screenshot full"))

-- SYSTEM
hl.bind(mainMod .. " + ALT + L",   hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + K",         hl.dsp.exec_cmd("/usr/libexec/hyprbazzite-ctl osk toggle"))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.exec_cmd("/etc/hypr/scripts/swap-osk-half.sh"))
hl.bind(mainMod .. " + O",         hl.dsp.exec_cmd("/usr/libexec/hyprbazzite-ctl transparency toggle"))
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("cliphist list | wofi --dmenu | cliphist decode | wl-copy"))

-- MULTIMEDIA (Repeating and Locked)
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),       { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl set +5%"),                        { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"),                        { locked = true, repeating = true })

-- MULTIMEDIA (Standard)
hl.bind("XF86AudioMute",  hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"),                       { locked = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),                             { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),                         { locked = true })

-- MOUSE BINDINGS
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
