# [25/5/2026] Change of name and signing
was previously ublue-hyprbazzite and not-signed... NOW **hyprbazzite** and signed

Please run the following in this order
```
rpm-ostree rebase ostree-unverified-registry:ghcr.io/tvorfreude/hyprbazzite:latest
systemctl reboot
# After reboot
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/tvorfreude/hyprbazzite:latest
systemctl reboot
# Migration Complete
```
