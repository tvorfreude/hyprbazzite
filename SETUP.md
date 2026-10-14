# HyprBazzite - Setup Guide

## What's Included

- **Hyprland** - Wayland compositor, started via SDDM's `hyprland` session
- **SDDM** - Login manager, themed with the bundled `hyprlockish` theme
- **Zen Browser** - Privacy-focused browser from `sneexy/zen-browser` COPR
- **Bitwarden** - Password manager (Flatpak from Flathub)
- **Full keyring support** - System keyring with GNOME Keyring daemon
- **Chezmoi integration** - optional, manual dotfiles push/pull from your own repo

## Dotfiles (Chezmoi)

HyprBazzite does not clone or provision any dotfiles automatically. Chezmoi
support is a thin, manual convenience wrapper: `hyprbazzite-ctl` (bound in the
app menu as "Chezmoi Push" / "Chezmoi Pull") just runs `chezmoi git -- push`
or `chezmoi git -- pull --rebase --autostash && chezmoi apply` against
whatever chezmoi source directory you've already set up yourself. If you
don't use chezmoi, these menu entries will simply report it's not installed/
not initialized - that's expected, not an error.

To use it, initialize chezmoi against your own dotfiles repo the normal way:
```bash
chezmoi init <your-dotfiles-repo-url>
chezmoi apply
```
Then `hyprbazzite-ctl chezmoi push` / `hyprbazzite-ctl chezmoi pull` (or the
menu entries) manage it going forward.

## Default Configuration (No Dotfiles)

Without chezmoi, you get this image's shipped defaults, seeded into new home
directories via `/etc/skel/.config/` (Hyprland, Waybar, wofi, GTK/Qt theming,
etc.) at the time each user account is created.

## Important: Configuration Updates for Existing Users

On an immutable (bootc) image, `/etc/skel/` is only applied when a user
account is *created*. If you rebase to a newer HyprBazzite build that changes
one of these shipped configs, an **already-existing** user's `~/.config/`
does not get updated automatically - the new default only applies to brand
new accounts. (System-owned files this project needs to always keep
authoritative - like the swaync/XDG defaults - are instead delivered through
a tmpfiles rule that re-applies on every boot; the skel-seeded per-user
config files below are intentionally NOT handled that way, since they are
meant to be freely user-customizable from that point on - forcibly
overwriting them on every update would destroy your own changes.)

### How to stay up to date

1. **If you use chezmoi**: your own dotfiles repo is the source of truth for
   whatever you've put under chezmoi's management; `chezmoi apply` after any
   upstream changes to your own repo. This has no relationship to
   HyprBazzite's own shipped skel defaults - it only manages the files you've
   explicitly added to your chezmoi source directory.
2. **Manual diff**: compare your local config against the shipped default and
   selectively copy over what you want:
   ```bash
   diff -r ~/.config/hypr /usr/share/hyprbazzite/config/hypr
   ```
3. **Nuclear option**: remove your local config and let the skel default
   re-apply on next login (you lose any personal customizations to that
   directory):
   ```bash
   rm -rf ~/.config/hypr ~/.config/waybar ~/.config/wofi
   # Log out and back in - symlinks from /etc/skel will be recreated
   ```

### Why this happens

Bootc images are immutable - the system partition is read-only and atomically
swapped on updates. User home directories persist across updates by design.
This is a feature (your customizations survive reboots and updates), but it
means a config file you've never touched still won't pick up a new shipped
default without one of the steps above.

## Troubleshooting

### Hyprland won't start
1. Check SDDM logs: `journalctl -u sddm`
2. Verify Wayland support: `echo $WAYLAND_DISPLAY`
3. Check D-Bus: `systemctl --user status dbus`

### Portal/Auth issues
1. Restart the portal: `systemctl --user restart xdg-desktop-portal-hyprland`
2. Check polkit: `systemctl --user status org.freedesktop.PolicyKit1`

## Next Steps

1. Log in - Hyprland starts with this image's shipped defaults
2. If you have your own dotfiles, `chezmoi init` them and `chezmoi apply`
3. Customize freely - your home directory is yours and survives updates

Enjoy your Hyprland setup!
