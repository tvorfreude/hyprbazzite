# Hyprland Custom Bazzite Image - Setup Guide

## What's Included

- **Hyprland** - Modern Wayland compositor from `sdegler/hyprland` COPR
- **LightDM** - Lightweight login manager
- **Zen Browser** - Privacy-focused browser from `sneexy/zen-browser` COPR
- **Bitwarden** - Password manager (Flatpak from Flathub)
- **Full keyring support** - System keyring with GNOME Keyring daemon
- **Chezmoi provisioning** - Automatic dotfiles deployment on first login

## First Login Setup

### Automatic Provisioning (Recommended)

When you log in for the first time, a systemd user service will automatically:
1. Clone your dotfiles from `https://github.com/tristanbollard/dotfiles.git`
2. Apply them using Chezmoi
3. Handle device-specific configs (laptop vs desktop)

**No action needed** - just log in and wait. You should see logs in the systemd journal:
```bash
journalctl --user -u chezmoi-provision -f
```

### Manual Provisioning

If the automatic provisioning doesn't run, you can manually trigger it:

```bash
chezmoi-provision
```

Or manually use chezmoi:
```bash
chezmoi init https://github.com/tristanbollard/dotfiles.git
chezmoi apply
```

## Device Detection

Your dotfiles repo includes device-specific configs. Chezmoi will prompt you during initialization to select your device configuration (laptop vs desktop).

## Fallback Configuration

If chezmoi hasn't been provisioned yet, Hyprland will use a minimal default configuration located at:
- `/etc/skel/.config/hypr/hyprland.conf` (applied to new users)
- `~/.config/hypr/hyprland.conf` (in your home directory)

Once chezmoi applies your dotfiles, your custom configurations will override this.

## Services & Daemons

The following services are enabled by default:
- `lightdm.service` - Display/login manager
- `dbus.service` - System message bus (required for Wayland/Hyprland)
- `podman.socket` - Container daemon

## Keybindings (Default/Fallback)

- `Super + Q` - Open terminal (Kitty)
- `Super + C` - Close window
- `Super + M` - Exit Hyprland
- `Super + [1-0]` - Switch workspaces
- `Super + Shift + [1-0]` - Move window to workspace
- `Super + Arrow Keys` - Move focus
- `Super + Mouse Scroll` - Switch workspaces

See your dotfiles for full custom keybindings.

## Updating Your Dotfiles

To pull the latest changes from your dotfiles repo after provisioning:

```bash
chezmoi update
```

## Troubleshooting

### Hyprland won't start
1. Check `lightdm` logs: `journalctl -u lightdm`
2. Verify Wayland support: `echo $WAYLAND_DISPLAY`
3. Check D-Bus: `systemctl --user status dbus`

### Chezmoi didn't provision
1. Check the service: `systemctl --user status chezmoi-provision`
2. View logs: `journalctl --user -u chezmoi-provision`
3. Manually run: `chezmoi-provision`

### Portal/Auth issues
1. Restart the portal: `systemctl --user restart xdg-desktop-portal-hyprland`
2. Check polkit: `systemctl --user status org.freedesktop.PolicyKit1`

## Next Steps

1. Log in and let chezmoi provision your dotfiles
2. Verify your Hyprland config was applied
3. Customize further by editing `~/.local/share/chezmoi/` and running `chezmoi apply`

Enjoy your Hyprland setup!
