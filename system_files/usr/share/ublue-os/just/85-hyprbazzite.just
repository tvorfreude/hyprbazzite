# Hyprbazzite Management Commands

# Reset Hyprland config to image defaults
hypr-reset:
    echo "Resetting Hyprland configuration to defaults..."
    rm -rf ~/.config/hypr
    mkdir -p ~/.config/hypr
    cp -r /usr/lib/hyprbazzite/etc/hypr/* ~/.config/hypr/
    echo "Configuration reset complete. Please restart Hyprland."

# Refresh system configuration links
hypr-refresh-links:
    echo "Refreshing system configuration links..."
    sudo systemd-tmpfiles --create /usr/lib/tmpfiles.d/hyprbazzite.conf
    echo "Links refreshed."

# Quick TDP Profiles
hypr-tdp-eco:
    /usr/lib/hyprbazzite/etc/hypr/scripts/tdp-control.sh profile eco

hypr-tdp-balanced:
    /usr/lib/hyprbazzite/etc/hypr/scripts/tdp-control.sh profile balanced

hypr-tdp-perf:
    /usr/lib/hyprbazzite/etc/hypr/scripts/tdp-control.sh profile performance

# Show current TDP status
hypr-tdp-status:
    /usr/lib/hyprbazzite/etc/hypr/scripts/tdp-control.sh get
