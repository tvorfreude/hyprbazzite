require("autostart")
require("envs")
require("monitors")
require("bindings")
require("rules")
require("styles")

-- Essential Variables
local active_border = "rgba(bd93f9ee)"
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
        repeat_rate = 40,
        repeat_delay = 600,
        touchpad = {
            natural_scroll = true,
            clickfinger_behavior = true,
            scroll_factor = 0.4,
        },
    },

    -- Eye Candy & HDR
    render = { cm_enabled = true, cm_auto_hdr = 2 },
    animations = { enabled = true },
    decoration = {
        rounding = 0,
        shadow = { enabled = true, range = 2, color = "rgba(28282aee)" },
        blur = { enabled = true, size = 3, passes = 1 },
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
