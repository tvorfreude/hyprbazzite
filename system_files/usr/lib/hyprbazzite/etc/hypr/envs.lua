hl.config({
    env = {
        "CLUTTER_BACKEND,wayland",
        "QT_AUTO_SCREEN_SCALE_FACTOR,1",
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1",
        "QT_QPA_PLATFORMTHEME,qt5ct",
        "QT_PLUGIN_PATH,/usr/lib64/qt6/plugins:/usr/lib64/qt5/plugins",
        "QT_SCALE_FACTOR,1",
        "GTK_THEME,Dracula",
        "QT_STYLE_OVERRIDE,",
        "XCURSOR_SIZE,24",
        "HYPRCURSOR_SIZE,24",
        "GDK_BACKEND,wayland,x11,*",
        "QT_QPA_PLATFORM,wayland;xcb",
        "SDL_VIDEODRIVER,wayland",
        "MOZ_ENABLE_WAYLAND,1",
        "OZONE_PLATFORM,wayland",
        "XDG_CURRENT_DESKTOP,Hyprland",
        "XDG_SESSION_DESKTOP,Hyprland",
        "XDG_SESSION_TYPE,wayland",
        "GDK_SCALE,1",
        "HYPRCURSOR_THEME,Bibata-Modern-Ice",
        "ELECTRON_OZONE_PLATFORM_HINT,auto",
        "XCOMPOSEFILE,~/.XCompose",
    },

    xwayland = {
        force_zero_scaling = true,
    },

    ecosystem = {
        no_update_news = true,
    },
})