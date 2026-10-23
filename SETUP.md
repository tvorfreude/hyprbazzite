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

Without chezmoi, you get this image's shipped defaults:

- **Hyprland, Waybar and wofi** are system-wide: `/etc/hypr`, `/etc/waybar`
  and `/etc/wofi`, refreshed from the image on every boot. To customize
  Hyprland, put your own `~/.config/hypr/hyprland.lua` (plus the modules it
  `require()`s) in place - the session launcher prefers it.
- **Per-user defaults** (kitty, GTK/Qt theming, Thunar, swappy, starship,
  zsh) are copied from `/etc/skel` into each new home directory when the
  account is created, as normal files you can edit. Accounts created on older
  builds had read-only links into `/usr` instead; the first login on a newer
  build replaces those with writable copies.

## Important: Configuration Updates for Existing Users

On an immutable (bootc) image, `/etc/skel/` is only applied when a user
account is *created*. If you rebase to a newer HyprBazzite build that changes
one of these shipped configs, an **already-existing** user's `~/.config/`
does not get updated automatically - the new default only applies to brand
new accounts. (System-owned files this project needs to always keep
authoritative - like the swaync/XDG defaults - are instead delivered through
a tmpfiles rule that re-applies on every boot; the skel-seeded per-user
config files are intentionally NOT handled that way, since they are yours to
customize from that point on - forcibly overwriting them on every update
would destroy your own changes.)

### How to stay up to date

1. **If you use chezmoi**: your own dotfiles repo is the source of truth for
   whatever you've put under chezmoi's management; `chezmoi apply` after any
   upstream changes to your own repo. This has no relationship to
   HyprBazzite's own shipped skel defaults - it only manages the files you've
   explicitly added to your chezmoi source directory.
2. **Manual diff**: compare your local config against the shipped default and
   selectively copy over what you want:
   ```bash
   diff -r ~/.config/kitty /etc/skel/.config/kitty
   ```
3. **Nuclear option**: replace your local copy with the shipped default (you
   lose any personal customizations to that directory). Nothing re-applies
   `/etc/skel` on login, so copy it yourself:
   ```bash
   rm -rf ~/.config/kitty && cp -r /etc/skel/.config/kitty ~/.config/
   ```

### Why this happens

Bootc images are immutable - the system partition is read-only and atomically
swapped on updates. User home directories persist across updates by design.
This is a feature (your customizations survive reboots and updates), but it
means a config file you've never touched still won't pick up a new shipped
default without one of the steps above.

## Hibernation and Secure Boot

Hibernation (and suspend-then-hibernate, which closing the lid uses) is set
up automatically on the first boot of a btrfs install. With Secure Boot on,
the kernel locks itself down and Linux refuses to hibernate; sleep then
falls back to plain suspend.

To hibernate anyway, run `ujust hypr-hibernate-on-secureboot` and reboot. It
turns off shim's verification of Linux while Secure Boot stays enabled in the
firmware, so Windows and its anti-cheat still see it on. The trade-off: the
Linux kernel and modules are no longer verified at boot. The next boot shows
a blue confirmation screen; the command explains what to press. Undo with
`ujust hypr-secureboot-verify-linux`.

## Update signature verification (maintainer, one-time)

Installed systems only verify this image's signature on update once a
public key is committed; until then CI signs keyless, which can be checked
by hand but not enforced. To turn enforcement on:

1. Generate a key pair (an empty password is fine; otherwise also add the
   password as a `COSIGN_PASSWORD` secret):
   ```bash
   cosign generate-key-pair
   ```
2. Add the contents of `cosign.key` as the repository secret
   `SIGNING_SECRET` (Settings → Secrets and variables → Actions), then store
   `cosign.key` somewhere safe offline. It is gitignored; never commit it.
3. Commit `cosign.pub` at the repository root and push.

CI refuses to build if `SIGNING_SECRET` is missing or doesn't match
`cosign.pub`. From the first image built with `cosign.pub`, installs require
that signature on update, so back up the private key: without it, installs
need a manual `bootc switch`. Rotating keys needs a transition image whose
policy trusts both.

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
