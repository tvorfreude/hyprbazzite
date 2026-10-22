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

# Deep sleep is turned off automatically after two hung resumes in a row (two
# power cuts while suspended look the same).
# Re-enable deep (S3) sleep after it was turned off automatically
hypr-deep-sleep-reset:
    sudo rm -f /var/lib/hyprbazzite/deep-sleep-blacklisted /var/lib/hyprbazzite/deep-sleep-failures /var/lib/hyprbazzite/sleep-pending
    sudo systemctl restart hyprbazzite-deep-sleep-setup.service
    echo "Deep sleep re-armed. Reboot to apply."

# Show current TDP status
hypr-tdp-status:
    /usr/libexec/hyprbazzite-ctl tdp get
# Run: ujust install-apps
install-apps:
    /usr/libexec/hyprbazzite-install-apps
