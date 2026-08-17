# Hyprbazzite Management Commands

# Reset Hyprland config to image defaults
hypr-reset:
    echo "Resetting Hyprland to image defaults (removing ~/.config/hypr)..."
    rm -rf ~/.config/hypr
    echo "Done. Your session will now use the system config in /etc/hypr."
    echo "(To customize, place your own config at ~/.config/hypr/hyprland.lua.)"
    echo "Restart Hyprland to apply."

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
# Run: ujust install-apps
install-apps:
    /usr/libexec/hyprbazzite-install-apps
