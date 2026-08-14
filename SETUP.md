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

## Important: Configuration Updates for Existing Users

On an immutable (bootc) image, system defaults in `/etc/skel/` are only applied when
a new user account is created. **Existing users do not automatically receive configuration
updates** shipped in newer image builds.

This means if you rebase to a newer HyprBazzite image that ships updated Hyprland configs,
Waybar layouts, or other dotfiles, your existing `~/.config/` will remain unchanged.

### How to stay up to date

1. **Chezmoi (recommended)**: If you use chezmoi to manage your dotfiles, run
   `chezmoi update` after rebasing. Your dotfiles repo is the source of truth.

2. **Manual sync**: Compare your local config against the shipped defaults:
   ```bash
   diff -r ~/.config/hypr /usr/share/hyprbazzite/config/hypr
   ```
   Then selectively copy any changes you want.

3. **Nuclear option**: Remove your local config and let the skel defaults re-apply
   on next login (you'll lose any personal customizations):
   ```bash
   rm -rf ~/.config/hypr ~/.config/waybar ~/.config/wofi
   # Log out and back in — symlinks from /etc/skel will be recreated
   ```

### Why this happens

Bootc images are immutable — the system partition is read-only and atomically
swapped on updates. User home directories persist across updates by design.
This is a feature (your customizations survive reboots and updates), but it
means you must actively pull in new defaults when desired.

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
