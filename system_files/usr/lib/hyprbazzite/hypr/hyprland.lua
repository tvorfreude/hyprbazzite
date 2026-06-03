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
    render = { cm_enabled = true, cm_auto_hdr = 2, allow_tearing = true },
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
        split_width_ratio = 0.50,
        pseudotile = true,
        preserve_split = true,
    },

    -- Master Layout Tuning (for windows that use it)
    master = {
        new_status = "master",
        special_scale = 1,
        thirdy = false,
    },

    -- Behaviors
    misc = {
        disable_hyprland_logo = true,
        focus_on_activate = true,
        new_window_when_empty = false,
        cancel_drag_on_edge = true,
        mouse_move_cars_focus = true,
        vim_keybindings = false,
    },

    -- Legacy/Compatibility
    xwayland = { force_zero_scaling = true },
    ecosystem = { no_update_news = true },
    debug = { full_cm_proto = true },
})
