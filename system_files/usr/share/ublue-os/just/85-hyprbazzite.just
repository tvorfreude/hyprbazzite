# Hyprbazzite Management Commands

# Reset Hyprland config to image defaults
hypr-reset:
    echo "Resetting Hyprland configuration to defaults..."
    rm -rf ~/.config/hypr
    mkdir -p ~/.config/hypr
    cp -r /usr/lib/hyprbazzite/hypr/* ~/.config/hypr/
    echo "Configuration reset complete. Please restart Hyprland."

# Refresh system configuration links
hypr-refresh-links:
    echo "Refreshing system configuration links..."
    sudo systemd-tmpfiles --create /usr/lib/tmpfiles.d/hyprbazzite.conf
    echo "Links refreshed."

# Quick TDP Profiles
hypr-tdp-eco:
    /usr/libexec/hyprbazzite-ctl tdp set 35

hypr-tdp-balanced:
    /usr/libexec/hyprbazzite-ctl tdp set 54

hypr-tdp-perf:
    /usr/libexec/hyprbazzite-ctl tdp set 65

# Show current TDP status
hypr-tdp-status:
    /usr/libexec/hyprbazzite-ctl tdp get

# Install post-setup applications (Flatpaks, Homebrew tap, VSCode)
# Run: ujust install-apps
install-apps:
    /usr/libexec/hyprbazzite-install-apps
