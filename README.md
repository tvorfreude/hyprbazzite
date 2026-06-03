# 󰣛  HyprBazzite

HyprBazzite is a custom [bootc](https://github.com/bootc-dev/bootc) image based on [Bazzite](https://bazzite.gg/), featuring a pre-configured [Hyprland](https://hyprland.org/) environment. It aims to provide a powerful, gaming-ready atomic desktop experience with a modern tiling window manager.

## 🚀 Features

- **Base**: Built on Fedora-based Bazzite (Stable), inheriting its gaming optimizations and hardware support.
- **Window Manager**: Hyprland (via `sdegler/hyprland` COPR) for a smooth, dynamic Wayland experience.
- **Shell**: Zsh with Starship prompt and JetBrains Mono Nerd Fonts.
- **Theme**: Dracula GTK and Qt themes pre-installed and configured.
- **Gaming**: Includes Steam devices support, Lutris, and LACT for AMD GPU control.
- **Handheld Support**: Integrated `hhd` (Handheld Daemon) for devices like the Legion Go and ROG Ally.
- **Atomic**: Fully compatible with `bootc` for transactional, reliable system updates.

## 📦 Installation

To switch your existing `bootc` compatible system (like Bazzite or Fedora Atomic) to HyprBazzite, run:

```bash
sudo bootc switch ghcr.io/tvorfreude/hyprbazzite:latest
```

### Tags

- `latest`: The most recent stable build from the `main` branch.
- `stable.YYYYMMDD-SHA`: Versioned stable releases.
- `testing`: The most recent build from Pull Requests or development branches.
- `testing.prNO.YYYYMMDD-SHA`: Versioned testing releases.

## 🛠 Customization

### Configuration
System-wide configurations are located in `/usr/lib/hyprbazzite/`. User-specific skeletons are provided in `/etc/skel/`.

### Build System
This image is built using GitHub Actions. The versioning scheme follows a `(tag.YYYYMMDD-SHA)` format, visible in your `PRETTY_NAME` within `/usr/lib/os-release`.

## 🤝 Community & Support

If you encounter issues or have questions:
- **Bazzite Discord**: [discord.gg/bazzite](https://discord.gg/bazzite)
- **Universal Blue Forums**: [Universal Blue Discourse](https://universal-blue.discourse.group/)
- **Hyprland Wiki**: [wiki.hyprland.org](https://wiki.hyprland.org/)

## 📜 License

This project is licensed under the **Apache License 2.0**. See the [LICENSE](LICENSE) file for details.

---
*Built with ❤️ using the Universal Blue image template.*

Thanks (JaKooLit)[https://github.com/JaKooLit]