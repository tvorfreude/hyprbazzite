# Previously was tblue-bazzite
Move to the new repo with
```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/tristanbollard/ublue-hyprbazzite
```

# Hibernation changes

```bash
# 1) Clear the one-shot marker so service can run again (optional if running script directly)
sudo rm -f /var/lib/tblue/hibernate-setup.done /var/lib/tblue/hibernate-reboot-required

# 2) If you want to migrate from old /var/swapfile to new /var/swap/swapfile layout:
sudo swapoff /var/swapfile 2>/dev/null || true
sudo sed -i '\|/var/swapfile|d' /etc/fstab
sudo rm -f /var/swapfile

# 3) Run setup now
sudo /usr/libexec/tblue-hibernate-setup

# 4) Verify
swapon --show
grep -E '/var/swap/swapfile|/var/swapfile' /etc/fstab
rpm-ostree kargs | grep -E 'resume=|resume_offset='

# 5) Reboot so new kargs and zram changes apply
sudo systemctl reboot

# Test with
loginctl can-hibernate
systemctl hibernate

# Debug
journalctl -b -u tblue-hibernate-setup
journalctl -b -u systemd-hibernate-resume
journalctl -b -u polkit | tail -n 120
```