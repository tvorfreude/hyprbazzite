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

# Re-enable deep (S3) sleep after two failed resumes turned it off
hypr-deep-sleep-reset:
    sudo rm -f /var/lib/hyprbazzite/deep-sleep-blacklisted /var/lib/hyprbazzite/deep-sleep-failures /var/lib/hyprbazzite/sleep-pending
    sudo systemctl restart hyprbazzite-deep-sleep-setup.service
    echo "Deep sleep re-armed. Reboot to apply."

# Show current TDP status
hypr-tdp-status:
    /usr/libexec/hyprbazzite-ctl tdp get

# Allow hibernation with Secure Boot on (stops shim verifying Linux)
hypr-hibernate-on-secureboot:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! grep -qE '\[(integrity|confidentiality)\]' /sys/kernel/security/lockdown 2>/dev/null; then
        echo "The kernel isn't locked down, so hibernation needs no change."
        exit 0
    fi
    echo "Linux can't hibernate while Secure Boot verifies it: the kernel locks"
    echo "itself down and won't write an unsigned memory image to disk."
    echo
    echo "This turns off shim's verification of Linux. Secure Boot stays on in the"
    echo "firmware (Windows and its anti-cheat still see it), but the kernel and"
    echo "its modules are no longer verified at boot. Undo with:"
    echo "  ujust hypr-secureboot-verify-linux"
    echo
    echo "You'll pick a password (8-16 characters) now. On the next boot a blue"
    echo "\"Shim UEFI key management\" screen appears: press a key, choose"
    echo "\"Change Secure Boot state\", type the characters of that password it"
    echo "asks for, choose \"Yes\", and let it reboot."
    read -rp "Continue? [y/N] " answer
    [[ "$answer" == [yY]* ]] || exit 1
    sudo mokutil --disable-validation
    sudo /usr/libexec/tblue-hibernate-setup --ignore-lockdown
    echo "Done. Reboot and confirm in the blue screen; hibernation works after that."

# Turn shim's verification of Linux back on (no hibernation with Secure Boot)
hypr-secureboot-verify-linux:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "You'll pick a password (8-16 characters). On the next boot, in the blue"
    echo "screen: press a key, \"Change Secure Boot state\", the requested"
    echo "characters of that password, \"Yes\"."
    sudo mokutil --enable-validation
    echo "Done. Reboot and confirm in the blue screen."
# Run: ujust install-apps
install-apps:
    /usr/libexec/hyprbazzite-install-apps
