-- ===== VARIABLES =====
local terminal = "kitty"
local browser = "flatpak run io.github.zen_browser.zen"
local filemanager = "thunar"
local scriptsDir = "/etc/hypr/scripts"

hl.config({
    -- ===== KEYBINDINGS WITH DESCRIPTIONS (bindd) =====
    bindd = {
        -- APPLICATION LAUNCHING
        "SUPER, return, Terminal, exec, " .. terminal,
        "SUPER, B, Browser, exec, " .. browser,
        "SUPER, F, File manager, exec, " .. filemanager,
        "SUPER, SPACE, App launcher, exec, wofi --show drun --conf /etc/wofi/config --style /etc/wofi/style.css",
        "SUPER, E, Text editor, exec, " .. terminal .. " -e nvim",

        -- WINDOW MANAGEMENT
        "SUPER, W, Close window, killactive",
        "SUPER, V, Toggle float, togglefloating",
        "SUPER, J, Cycle next, layoutmsg, cyclenext",
        "SUPER, P, Pseudo fullscreen, pseudo",
        "SUPER SHIFT, F, Fullscreen, fullscreen",
        "SUPER ALT, F, Fullscreen fake, fullscreen, 1",

        -- FOCUS MOVEMENT
        "SUPER, left, Focus left, movefocus, l",
        "SUPER, right, Focus right, movefocus, r",
        "SUPER, up, Focus up, movefocus, u",
        "SUPER, down, Focus down, movefocus, d",
        "ALT, Tab, Cycle next, cyclenext",

        -- WORKSPACE NAVIGATION
        "SUPER, 1, Workspace 1, workspace, 1",
        "SUPER, 2, Workspace 2, workspace, 2",
        "SUPER, 3, Workspace 3, workspace, 3",
        "SUPER, 4, Workspace 4, workspace, 4",
        "SUPER, 5, Workspace 5, workspace, 5",
        "SUPER, 6, Workspace 6, workspace, 6",
        "SUPER, 7, Workspace 7, workspace, 7",
        "SUPER, 8, Workspace 8, workspace, 8",
        "SUPER, 9, Workspace 9, workspace, 9",
        "SUPER, 0, Workspace 10, workspace, 10",

        "SUPER SHIFT, 1, Move to workspace 1, movetoworkspace, 1",
        "SUPER SHIFT, 2, Move to workspace 2, movetoworkspace, 2",
        "SUPER SHIFT, 3, Move to workspace 3, movetoworkspace, 3",
        "SUPER SHIFT, 4, Move to workspace 4, movetoworkspace, 4",
        "SUPER SHIFT, 5, Move to workspace 5, movetoworkspace, 5",
        "SUPER SHIFT, 6, Move to workspace 6, movetoworkspace, 6",
        "SUPER SHIFT, 7, Move to workspace 7, movetoworkspace, 7",
        "SUPER SHIFT, 8, Move to workspace 8, movetoworkspace, 8",
        "SUPER SHIFT, 9, Move to workspace 9, movetoworkspace, 9",
        "SUPER SHIFT, 0, Move to workspace 10, movetoworkspace, 10",

        "SUPER, mouse_down, Next workspace, workspace, e+1",
        "SUPER, mouse_up, Previous workspace, workspace, e-1",

        -- WINDOW MOVING/SWAPPING
        "SUPER SHIFT, left, Swap left, swapwindow, l",
        "SUPER SHIFT, right, Swap right, swapwindow, r",
        "SUPER SHIFT, up, Swap up, swapwindow, u",
        "SUPER SHIFT, down, Swap down, swapwindow, d",

        -- WINDOW RESIZING
        "SUPER, minus, Resize minus, resizeactive, -100 0",
        "SUPER, equal, Resize plus, resizeactive, 100 0",
        "SUPER SHIFT, minus, Resize minus height, resizeactive, 0 -100",
        "SUPER SHIFT, equal, Resize plus height, resizeactive, 0 100",

        -- SCREENSHOTS
        "SUPER SHIFT, S, Screenshot region, exec, /usr/libexec/hyprbazzite-ctl screenshot area",
        "SUPER CTRL, S, Screenshot full, exec, /usr/libexec/hyprbazzite-ctl screenshot full",

        -- SYSTEM
        "SUPER ALT, L, Lock screen, exec, hyprlock",
        "SUPER, K, Toggle on-screen keyboard, exec, /usr/libexec/hyprbazzite-ctl osk toggle",
        "SUPER SHIFT, K, Swap keyboard half, exec, /etc/hypr/scripts/swap-osk-half.sh",
    },

    -- ===== REPEATABLE BINDINGS (binde) =====
    binde = {
        ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+",
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-",
        ", XF86MonBrightnessUp, exec, brightnessctl set +5%",
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-",
    },

    -- ===== STANDARD BINDINGS (bind) =====
    bind = {
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",
        ", XF86AudioPlay, exec, playerctl play-pause",
        ", XF86AudioNext, exec, playerctl next",
        ", XF86AudioPrev, exec, playerctl previous",
        "SUPER, O, exec, /usr/libexec/hyprbazzite-ctl transparency toggle",
        "SUPER SHIFT, V, exec, cliphist list | wofi --dmenu | cliphist decode | wl-copy",
    },

    -- ===== MOUSE BINDINGS (bindmd for mouse + description) =====
    bindmd = {
        "SUPER, mouse:272, Move window, movewindow",
        "SUPER, mouse:273, Resize window, resizewindow",
    },

    -- ===== SWITCHES (bindl) =====
    bindl = {
        ", switch:on:Lid Switch, exec, /usr/libexec/hyprbazzite-ctl lid close",
        ", switch:off:Lid Switch, exec, /usr/libexec/hyprbazzite-ctl lid open",
    },
})