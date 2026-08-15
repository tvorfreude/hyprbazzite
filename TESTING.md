# Testing HyprBazzite

This document explains how to test HyprBazzite changes: fast local smoke tests,
full VM boots, and how remote (published-image) testing works.

> Test credentials for local VM images are **`test` / `test`** (see
> [Local VM testing](#2-local-vm-testing)). These exist only in
> `disk_config/disk.toml` and are for throwaway test VMs — they are never part
> of the real installer image.

---

## Test levels at a glance

| Level | What it checks | Time | Command |
|-------|----------------|------|---------|
| 1. Container smoke test | Files, packages, scripts exist and are valid | seconds | `podman run --rm ...` |
| 2. Local VM boot | Full desktop actually boots and logs in | ~10–30 min | `just run-vm-qcow2` |
| 3. Image verification | CI-style structural checks | seconds | `scripts/verify-image.sh` |
| 4. Remote / rebase test | Real hardware pulls the published image | varies | `bootc switch` (see below) |

Start at level 1 — it catches most breakage without building a disk image.

---

## 1. Container smoke test (fastest)

Build the container image and inspect it directly. No VM needed. This is the
quickest way to confirm a change didn't break the image.

```bash
# Build the container image (uses the Containerfile)
just build hyprbazzite localtest

# Confirm branding and core packages
podman run --rm hyprbazzite:localtest grep PRETTY_NAME /usr/lib/os-release
podman run --rm hyprbazzite:localtest sh -c 'command -v Hyprland waybar wofi'

# Confirm the control script and shared library are present + valid
podman run --rm hyprbazzite:localtest bash -n /usr/libexec/hyprbazzite-ctl
podman run --rm hyprbazzite:localtest /usr/libexec/hyprbazzite-ctl   # prints usage

# Run the full structural verification (same script CI uses)
podman run --rm -v "$PWD/scripts/verify-image.sh:/tmp/v.sh:ro" \
    hyprbazzite:localtest bash /tmp/v.sh
```

If any of these fail, fix before moving on — a VM build takes far longer.

---

## 2. Local VM testing

This builds a bootable disk image from the container and boots it in a VM so you
can actually log in and use the desktop.

### Prerequisites

VM tooling is required on the host. On an **atomic/bootc host** (Bazzite,
Silverblue, etc.) `qemu` is generally not layered in, so:

- The `just run-vm-*` recipes run QEMU **inside a container** (`qemux/qemu`)
  and expose a web console — this needs `/dev/kvm`.
- Alternatively, `just spawn-vm` uses `systemd-vmspawn`, which is usually
  available out of the box on atomic hosts.

### Build + run (web console)

```bash
# Build the qcow2 and launch the VM (opens a web console on http://localhost:8006)
just run-vm-qcow2 localhost/hyprbazzite localtest
```

Then open <http://localhost:8006> and log in with **`test` / `test`**.

### Build + run (systemd-vmspawn, no container)

```bash
just build-qcow2 localhost/hyprbazzite localtest
just spawn-vm 0 qcow2 6G
```

### Log in

The local test image ships a throwaway user defined in
`disk_config/disk.toml`:

- **Username:** `test`
- **Password:** `test`
- Member of `wheel` (sudo).

Change these in `disk_config/disk.toml` under `[[customizations.user]]` if you
want different test credentials. **Do not** copy this user into
`disk_config/iso.toml` — the real installer creates its user interactively via
Anaconda.

### Troubleshooting

**The VM boots Alpine Linux instead of HyprBazzite.**
This is a `qemux/qemu` fallback: when it can't read a valid bootable disk it
downloads Alpine as a default. It means the qcow2 didn't have a usable
partition table. The usual cause is a filesystem mismatch between the
`--rootfs` flag in the `Justfile` and the `[[customizations.filesystem]]`
entries in `disk_config/disk.toml`. Keep `disk.toml` consistent with
`--rootfs=btrfs` (the current config does this) and rebuild with
`just rebuild-qcow2`.

**`Failed to read the complete GPT partition entry array!`**
Same root cause as above — an inconsistent disk layout. Rebuild the qcow2.

**No login prompt / can't log in.**
The image has no user. Confirm `disk_config/disk.toml` has a
`[[customizations.user]]` block, then `just rebuild-qcow2`.

**Rebuild from scratch.**
`just clean` removes build artifacts; `just rebuild-qcow2` forces a fresh disk.

---

## 3. Image verification script

`scripts/verify-image.sh` runs inside the built image and asserts that critical
packages, config files, scripts, systemd units, and polkit rules are present.
CI runs it automatically after every build; run it locally against any built
image:

```bash
podman run --rm -v "$PWD/scripts/verify-image.sh:/tmp/v.sh:ro" \
    hyprbazzite:localtest bash /tmp/v.sh
```

A non-zero exit means the image is missing something it needs to be usable.

---

## 4. Remote testing (published images)

Local VMs prove the image boots. Remote testing proves it works on real
hardware and through the normal update path. This is how it will work once
images are published to GHCR.

### Branch → tag mapping

CI publishes images per branch (see `.github/workflows/build.yml`):

| Branch / event | Published tag |
|----------------|---------------|
| `main` | `latest`, `stable.YYYYMMDD-<sha>` |
| `testing` | `testing`, `testing.YYYYMMDD-<sha>` |
| Pull request (same-repo, non-draft) | `pr-<number>` (pushed + signed, for testing) |

This lets you keep daily drivers on `latest` while testing risky changes on the
`testing` tag first.

### Rebasing a real machine to a test image

On a machine already running a bootc image, switch to a test tag:

```bash
# Try the testing stream
sudo bootc switch ghcr.io/tvorfreude/hyprbazzite:testing
sudo systemctl reboot

# Or pin an exact dated build for reproducible testing
sudo bootc switch ghcr.io/tvorfreude/hyprbazzite:testing.20260815-abc1234
```

Roll back at any time — bootc keeps the previous deployment:

```bash
sudo bootc rollback
sudo systemctl reboot
```

### Testing a pull request

Every same-repo, non-draft PR publishes a signed `pr-<number>` image. The PR's
auto-generated change-summary comment includes a ready-to-paste snippet:

```bash
sudo bootc switch ghcr.io/tvorfreude/hyprbazzite:pr-42
sudo systemctl reboot
# when done, go back to your normal stream:
sudo bootc rollback   # or: sudo bootc switch ghcr.io/tvorfreude/hyprbazzite:latest
```

These `pr-<number>` images are automatically deleted from the registry when the
PR is closed (see `.github/workflows/pr-cleanup.yml`), so they don't accumulate.

### Verifying image signatures

Published images are signed with cosign (keyless, GitHub OIDC). Verify before
trusting an image:

```bash
cosign verify \
  --certificate-identity-regexp="https://github.com/tvorfreude/" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  ghcr.io/tvorfreude/hyprbazzite:latest
```

### Testing an ISO install

The ISO installer is built by `.github/workflows/build-iso.yml` (manually, or by
commenting `/build-iso` on a PR). It produces a full Anaconda installer that
enrolls Secure Boot keys and switches the installed system to
`ghcr.io/tvorfreude/hyprbazzite:latest`. Download the ISO artifact from the
workflow run (or the GitHub Release) and install it in a VM or on spare
hardware.

Build an ISO locally instead:

```bash
just build-iso localhost/hyprbazzite localtest
# Output lands in ./output/
```

---

## What to test after a change

- **Scripts / `hyprbazzite-ctl`:** container smoke test (level 1) + boot a VM
  and exercise the affected subcommand (screenshot, wallpaper, power menu, etc).
- **Waybar / Wofi / theming:** boot a VM (level 2) and check the bar, launcher,
  and notifications render correctly.
- **Containerfile / packages:** full build + `verify-image.sh` (levels 1 & 3).
- **Hibernate / disk layout:** boot a VM and confirm suspend/hibernate; note
  hibernation needs the btrfs root + runtime swapfile.
- **First-boot services:** boot a *fresh* VM (not a rebooted one) so the
  one-shot provisioning services run against a clean state.
