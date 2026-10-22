require("autostart")
require("envs")
require("monitors")
require("bindings")
require("rules")
require("styles")

-- Essential Variables
-- Accent comes from hyprbazzite-accent (Dracula purple unless the user chose
-- "auto" or a custom colour). Any failure keeps the default. Read the value
-- it last rendered into $XDG_RUNTIME_DIR first: `hyprbazzite-accent hex` runs
-- ImageMagick on the wallpaper in "auto" mode, and this file is evaluated on
-- the compositor's main thread, so every reload froze the screen while it ran.
-- The cached value is only used while it was rendered for the mode chosen now
-- (that can change outside the tool, e.g. a chezmoi pull of accent-mode).
-- The command remains the fallback for that and for a session's first load.
local active_border = "rgba(bd93f9ee)"
do
    local function first_line(path)
        local f = io.open(path, "r")
        if not f then return nil end
        local line = f:read("*l")
        f:close()
        return line
    end
    -- Same normalisation as get_mode in hyprbazzite-accent.
    local function chosen_mode()
        local cfg = os.getenv("XDG_CONFIG_HOME") or ((os.getenv("HOME") or "") .. "/.config")
        local m = (first_line(cfg .. "/hyprbazzite/accent-mode") or ""):gsub("%s", "")
        if m == "auto" or m == "dracula" then return m end
        if m:match("^#%x%x%x%x%x%x$") then return m:lower() end
        return "dracula"
    end

    local hex
    local run = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/hyprbazzite"
    if first_line(run .. "/accent-mode") == chosen_mode() then
        hex = (first_line(run .. "/accent") or ""):match("^#(%x%x%x%x%x%x)$")
    end
    if not hex then
        local ok, pipe = pcall(io.popen, "/usr/libexec/hyprbazzite-accent hex 2>/dev/null")
        if ok and pipe then
            hex = (pipe:read("*l") or ""):match("^#(%x%x%x%x%x%x)$")
            pipe:close()
        end
    end
    if hex then active_border = "rgba(" .. hex .. "ee)" end
end
local inactive_border = "rgba(44475aaa)"

hl.config({
    -- Core Visuals
    general = {
        gaps_in = 5,
        gaps_out = 10,
        border_size = 2,
        ["col.active_border"] = active_border,
        ["col.inactive_border"] = inactive_border,
        layout = "dwindle",
    },

    -- Input & Touchpad
    input = {
        kb_layout = "us",
        kb_options = "compose:ralt",
        follow_mouse = 1,
        repeat_rate = 50,
        repeat_delay = 400,
        touchpad = {
            natural_scroll = true,
            clickfinger_behavior = true,
            tap_to_click = true,
            scroll_factor = 0.4,
        },
    },

    -- Eye Candy & HDR
    render = { cm_enabled = true, cm_auto_hdr = 2 },
    animations = { enabled = true },
    decoration = {
        rounding = 8,
        dim_special = 0.3,
        shadow = { enabled = true, range = 12, color = "rgba(000000dd)" },
        blur = { enabled = true, size = 5, passes = 2, ignore_opacity = true },
    },

    -- Dwindle Layout Tuning
    dwindle = {
        force_split = 0,
        preserve_split = true,
    },

    -- Master Layout Tuning (for windows that use it)
    master = {
        new_status = "master",
    },

    -- Behaviors
    misc = {
        disable_hyprland_logo = true,
        focus_on_activate = true,
    },

    -- Legacy/Compatibility
    xwayland = { force_zero_scaling = true },
    ecosystem = { no_update_news = true },
    debug = { full_cm_proto = true },
})
