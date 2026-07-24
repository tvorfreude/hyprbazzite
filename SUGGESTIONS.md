# Suggestions & Improvement Roadmap

This document is a comprehensive review of the **hyprbazzite** project — a Universal Blue /
Bazzite–based custom `bootc` OCI image that ships a Hyprland desktop. It covers everything from
immediate quick-wins to long-term architectural evolution: the container build and CI/CD, image
infrastructure and security, the Hyprland compositor config and its helper scripts, and the full
theming stack (SDDM, Waybar, Wofi, SwayNC, terminal/shell, GTK/Qt).

It is organized by domain (Parts A–C) and, within each part, roughly ordered by priority. Each
suggestion includes a rationale, implementation notes, and — where relevant — example code or
configuration. Every item is grounded in a specific file in this repository; file paths are cited
inline so you can jump straight to the source.

> This is a *roadmap*, not a changelog. Nothing here has been applied to the repo. Treat it as a
> backlog to triage: pull items into issues/PRs at your own pace. Priorities are the reviewer's
> opinion — adjust to your own goals (a personal daily-driver image weights ergonomics differently
> than a widely-consumed public image).

## How to use this document

1. **Skim the Priority legend below**, then read the **Top-priority summary** for the P0/P1 items
   that are worth doing first regardless of domain.
2. Jump to the domain **Part** you're working on via the Table of Contents.
3. Each suggestion has a stable-ish heading you can link to or reference in a commit/PR.

## Priority legend

| Tag | Meaning | Rough guidance |
|-----|---------|----------------|
| **P0** | Critical — correctness, security, or "the feature is broken" | Do first; may be a bug or a real risk |
| **P1** | High — significant robustness, security-hardening, or UX win | Schedule soon |
| **P2** | Medium — quality, maintainability, consistency | Do opportunistically |
| **P3** | Nice-to-have — polish, ergonomics, future-proofing | Backlog |

## Top-priority summary (P0 / notable P1 across all parts)

These are the items to look at first. See the linked sections for full detail.

- **Secure Boot key handling** (Part A) — confirm only the *public* `.crt` is committed and no
  private key ever lands in git history; document the enrollment flow. → *Secure Boot Key Handling*
- **CI permissions & signing hardening** (Part A) — pin `permissions:` to least-privilege, verify
  cosign signing + provenance/attestation, add `concurrency:` groups, avoid `pull_request_target`
  footguns. → *GitHub Actions CI/CD*, *Workflow Concurrency & Scheduling*
- **`install-apps` / first-boot service robustness** (Part A) — `set -euo pipefail`, network
  retries, and idempotency so a transient failure doesn't brick first boot. → *Install-Apps Script
  Robustness*, *First-Boot Services & Idempotency*
- **Polkit rule breadth** (Part A) — audit `ResultActive`/`ResultAny` grants for TDP/hibernate so
  they don't over-authorize. → *Polkit Rule Safety*
- **Lid handling is doubly wired and half-broken** (Part B) — a root `udev` rule and the Hyprland
  `switch:` binding both fire; the udev path runs as uid 0 with no session env. Pick one. →
  *Lid Switch Handling*
- **`executable_`-prefixed script filenames** (Part B) — leftover chezmoi source-state naming that
  ships binaries under the wrong name; verify references and rename. → *Chezmoi & `executable_`
  Filename Prefix Issue*
- **Shell-script hardening across all helper scripts** (Part B) — missing `set -euo pipefail`,
  unquoted expansions, fragile `ls`/`awk` parsing, and duplicated env-detection that belongs in one
  sourced helper. → *Shell Script Robustness*
- **Skel-vs-live config drift** (Part C) — `/etc/skel` only seeds *new* users; on an immutable image
  this silently strands config changes for existing users. Decide on a real config-delivery
  strategy. → *Skel vs Live Config Drift (Immutable Image Gotcha)*
- **Theme source-of-truth conflict** (Part C) — a static Dracula palette and dynamic `wallust`
  colors both claim ownership of the same surfaces; pick one authority or define precedence. →
  *Theme Consistency & Color Source-of-Truth*

---

## Table of Contents

### Part A — Build, CI/CD, Image Infrastructure, Security & Repo Hygiene
- Containerfile Layering, Caching & Pinning
- GitHub Actions CI/CD
- Renovate Configuration
- Secure Boot Key Handling
- First-Boot Services & Idempotency
- Polkit Rule Safety
- Udev Rules
- Install-Apps Script Robustness
- Justfile Targets
- Verify-Image Script
- Tmpfiles.d Configuration
- Disk Configuration
- Repository Hygiene
- bootc.toml Configuration
- Workflow Concurrency & Scheduling

### Part B — Hyprland, Wayland & Helper Scripts
- Shell Script Robustness
- Chezmoi & `executable_` Filename Prefix Issue
- Lid Switch Handling
- Swayidle / Hyprlock Coordination
- Keybind Ergonomics & Conflicts
- Monitor Configuration
- Portal Configuration
- Keyd Configuration
- Autostart & Session Management
- Path Inconsistency
- Wallust / Theming
- Miscellaneous

### Part C — Theming, Login (SDDM), Bar, Launcher, Notifications, Terminal & Shell
- C1 — Theme Consistency & Color Source-of-Truth
- C2 — SDDM / Login Screen
- C3 — Waybar (Status Bar)
- C4 — Wofi (Application Launcher)
- C5 — SwayNC (Notifications)
- C6 — Terminal & Shell (Zsh, Kitty, Starship)
- C7 — Font Configuration
- C8 — Skel vs Live Config Drift (Immutable Image Gotcha)
- C9 — Mimeapps & Default Applications
- C10 — Wallpaper Theming Integration

---


# Part A -- Build, CI/CD, Image Infrastructure, Security & Repo Hygiene

## Containerfile Layering, Caching & Pinning

### Pin the base image digest for reproducible builds

**Priority:** P1 high

**Rationale:** `FROM ghcr.io/ublue-os/bazzite:stable` uses a mutable tag. If the base image updates between your CI scheduled build check and the actual build step, you can get a different image than the one you validated. Pinning by digest guarantees reproducibility while still allowing scheduled rebuilds to pull new digests intentionally.

**Implementation:** Use a digest reference and let Renovate bump it automatically (see Renovate section).

**File:** `Containerfile` line 30

```dockerfile
# Pin digest, Renovate will update automatically
FROM ghcr.io/ublue-os/bazzite@sha256:<current_digest> AS base
```

Then use `AS base` alias throughout. The workflow's `check_base_image` job already fetches the digest -- feed it as a build-arg or use Renovate's Dockerfile manager.

---

### Pin the assets stage base image

**Priority:** P2 medium

**Rationale:** `FROM fedora:latest` in the assets stage means every build could pull a different Fedora release. While this stage only downloads fonts/themes, a major Fedora bump could change `dnf5` behavior or package availability.

**Implementation:** Pin to a specific Fedora version.

**File:** `Containerfile` line 5

```dockerfile
FROM fedora:41 AS assets
```

---

### Pin NERD_FONTS_VERSION via Renovate regex manager

**Priority:** P2 medium

**Rationale:** `ARG NERD_FONTS_VERSION=v3.4.0` is a manually-bumped version. Renovate can auto-track GitHub releases for this.

**Implementation:** Add a Renovate regex manager (see Renovate section) and annotate the ARG:

**File:** `Containerfile` line 7

```dockerfile
# renovate: datasource=github-releases depName=ryanoasis/nerd-fonts
ARG NERD_FONTS_VERSION=v3.4.0
```

---

### Separate dnf install layers for better cache reuse

**Priority:** P3 nice-to-have

**Rationale:** Step 4 installs ~50+ packages in a single `RUN`. Any package addition/removal invalidates the entire layer cache. Splitting into logical groups (core WM, CLI tools, gaming, theming) would let unchanged groups remain cached.

**Implementation:** Split into 2-3 RUN blocks grouped by change frequency. The `--mount=type=cache,dst=/var/cache` already helps, but layer separation helps remote registry cache hits.

**File:** `Containerfile` Step 4

```dockerfile
# Core WM (rarely changes)
RUN --mount=type=cache,dst=/var/cache \
    dnf5 -y install --skip-unavailable \
    hyprland hyprland-guiutils hyprlock swayidle hyprpaper uwsm hyprland-uwsm \
    swww waybar SwayNotificationCenter wofi wvkbd hhd adjustor hhd-ui lact \
    && dnf5 -y clean all

# CLI + desktop tools (moderate change frequency)
RUN --mount=type=cache,dst=/var/cache \
    dnf5 -y install --skip-unavailable \
    zsh starship lsd git chezmoi kitty tmux fastfetch jq ripgrep \
    thunar tumbler gvfs gvfs-mtp gvfs-gphoto2 \
    network-manager-applet pavucontrol xdg-desktop-portal-hyprland lxqt-policykit \
    keyd gnome-keyring seahorse libsecret libsecret-devel gcr gcr-devel \
    blueman breeze-icon-theme qt5ct \
    && dnf5 -y clean all
```

---

### Remove GPG check disable for terra-mesa repo

**Priority:** P1 high

**Rationale:** Step 6 disables `gpgcheck` and `repo_gpgcheck` for `terra-mesa.repo`. This defeats package integrity verification and opens a supply-chain attack vector. If the GPG key issue is transient, fix it properly by importing the correct key.

**Implementation:** Import the terra-mesa GPG key explicitly, or pin the repo to a known-good mirror. If the repo consistently has key issues, consider removing it entirely and sourcing mesa from Fedora proper.

**File:** `Containerfile` Step 6

```dockerfile
# Instead of disabling gpgcheck, import the key:
RUN rpm --import https://terra.fyralabs.com/terra.pub || true
```

---

### Use multi-stage COPY for system_files to improve cache

**Priority:** P3 nice-to-have

**Rationale:** `COPY system_files/usr/ /usr/` invalidates whenever ANY file under `system_files/usr/` changes. Since this directory contains configs, scripts, themes, and rules, frequent config tweaks bust the cache for everything downstream.

**Implementation:** Split into separate COPY statements for high-churn vs low-churn directories:

```dockerfile
COPY system_files/usr/lib/ /usr/lib/
COPY system_files/usr/libexec/ /usr/libexec/
COPY system_files/usr/share/ /usr/share/
COPY system_files/usr/bin/ /usr/bin/
```

---

## GitHub Actions CI/CD

### Add SBOM generation and attestation

**Priority:** P1 high

**Rationale:** The workflow signs with cosign but doesn't generate a Software Bill of Materials (SBOM) or provenance attestation. SBOM is increasingly required for supply-chain security compliance and helps downstream consumers audit the image contents.

**Implementation:** Add SBOM generation after push, attach as attestation.

**File:** `.github/workflows/build.yml` after the "Sign Images" step

```yaml
      - name: Generate SBOM
        if: github.event_name != 'pull_request'
        uses: anchore/sbom-action@v0
        with:
          image: "${{ env.IMAGE_REGISTRY }}/${{ env.IMAGE_NAME }}@${{ steps.push.outputs.digest }}"
          format: spdx-json
          output-file: sbom.spdx.json

      - name: Attest SBOM
        if: github.event_name != 'pull_request'
        run: |
          cosign attest --yes --predicate sbom.spdx.json \
            --type spdxjson \
            "${{ env.IMAGE_REGISTRY }}/${{ env.IMAGE_NAME }}@${{ steps.push.outputs.digest }}"
```

---

### Harden workflow permissions to least privilege

**Priority:** P1 high

**Rationale:** The `build_push` job requests `id-token: write` (good for keyless cosign) but the top-level workflow has no `permissions` block, meaning all jobs inherit the default token permissions. The `cleanup` job has `packages: write` but also inherits `contents: read` implicitly. Explicit top-level restriction prevents permission creep.

**Implementation:** Add a restrictive top-level permissions block.

**File:** `.github/workflows/build.yml` after `concurrency:`

```yaml
permissions:
  contents: read

jobs:
  lint:
    # ...no permissions override needed, inherits read
  build_push:
    permissions:
      contents: read
      packages: write
      id-token: write
```

---

### Address `pull_request_target` risk in build-iso.yml

**Priority:** P1 high

**Rationale:** `build-iso.yml` uses `issue_comment` trigger with `contains(fromJson('["OWNER","MEMBER","COLLABORATOR"]'), github.event.comment.author_association)` which is good. However, it checks out the PR's head ref (`steps.pr_ref.outputs.ref`) -- this means the workflow runs attacker-controlled code (Containerfile from the PR branch) with `contents: write` and `packages: read` permissions. An external collaborator could submit a malicious Containerfile.

**Implementation:** Either:
1. Remove `contents: write` and only upload as artifact (no release), OR
2. Add a separate approval step before building PR code, OR
3. Only allow `/build-iso` from OWNER/MEMBER (remove COLLABORATOR)

**File:** `.github/workflows/build-iso.yml` line 30

```yaml
    # Tighten to OWNER and MEMBER only -- collaborators can fork
    if: >-
      github.event_name == 'workflow_dispatch' || (
        github.event_name == 'issue_comment' &&
        github.event.issue.pull_request != null &&
        contains(github.event.comment.body, '/build-iso') &&
        contains(fromJson('["OWNER","MEMBER"]'), github.event.comment.author_association)
      )
```

---

### Pin GitHub Actions by SHA, not tag

**Priority:** P2 medium

**Rationale:** Most actions in `build.yml` use version tags (`@v7`, `@v6`, `@v2`). Tags are mutable -- a compromised action maintainer can repoint a tag. The `build-iso.yml` correctly pins some actions by SHA but not all.

**Implementation:** Pin all third-party actions by commit SHA. Renovate's `github-actions` manager will auto-update these.

**File:** `.github/workflows/build.yml`

```yaml
      - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0
      - uses: sigstore/cosign-installer@dc72c7d5c4d10cd6bcb8cf6e3fd625a9e5e537da # v4.1.2
      - uses: docker/metadata-action@8e5442c4ef9f78752691e2d8f8d19755c6f78e81 # v6.0.0
```

---

### Add cosign key verification step for image consumers

**Priority:** P2 medium

**Rationale:** Images are signed with keyless cosign (GitHub OIDC identity) but there's no documented verification command for end users. The `README.md` doesn't mention how to verify image signatures.

**Implementation:** Add verification instructions to README and/or a verify step in CI.

```bash
# Users can verify with:
cosign verify \
  --certificate-identity-regexp="https://github.com/tvorfreude/hyprbazzite" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  ghcr.io/tvorfreude/hyprbazzite:latest
```

---

### Add build matrix for testing branch

**Priority:** P3 nice-to-have

**Rationale:** Currently the workflow builds a single image variant. If you plan to support multiple hardware profiles (e.g., handheld vs desktop), a matrix strategy would enable parallel builds.

**Implementation:** Define a matrix in `build_push`:

```yaml
    strategy:
      fail-fast: false
      matrix:
        variant: [desktop, handheld]
```

---

### Cache buildah layers between CI runs

**Priority:** P2 medium

**Rationale:** The `buildah-build` step uses `--layers=true` but doesn't persist the layer cache between runs. Each CI run rebuilds from scratch. GitHub Actions cache or registry-based caching could cut build times significantly.

**Implementation:** Use `--cache-from` and `--cache-to` with the registry:

**File:** `.github/workflows/build.yml` build step

```yaml
          extra-args: |
            --layers=true
            --cache-from=type=registry,ref=${{ env.IMAGE_REGISTRY }}/${{ env.IMAGE_NAME }}:buildcache
            --cache-to=type=registry,ref=${{ env.IMAGE_REGISTRY }}/${{ env.IMAGE_NAME }}:buildcache,mode=max
```

Note: Verify buildah supports these flags in your runner version; alternatively use `actions/cache` with the local store path.

---

### Add timeout-minutes to long-running jobs

**Priority:** P2 medium

**Rationale:** Neither workflow specifies `timeout-minutes`. A hung build (e.g., stuck dnf download) will consume runner minutes until the 6-hour default kills it.

**Implementation:**

**File:** `.github/workflows/build.yml`

```yaml
  build_push:
    timeout-minutes: 45
    # ...

  build-iso:
    timeout-minutes: 60
```

---

### Verify cosign signature in CI after push

**Priority:** P2 medium

**Rationale:** The workflow signs but never verifies the signature succeeded. A silent signing failure would ship unsigned images.

**Implementation:** Add a verification step after signing.

```yaml
      - name: Verify signature
        if: github.event_name != 'pull_request'
        run: |
          cosign verify \
            --certificate-identity="https://github.com/${{ github.repository }}/.github/workflows/build.yml@${{ github.ref }}" \
            --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
            "${{ env.IMAGE_REGISTRY }}/${{ env.IMAGE_NAME }}@${{ steps.push.outputs.digest }}"
```

---

## Renovate Configuration

### Enable Dockerfile/Containerfile manager

**Priority:** P1 high

**Rationale:** The current `renovate.json5` only extends `config:best-practices` and has package rules for pin/digest actions. It doesn't explicitly enable the Containerfile manager or regex managers for custom ARG versions. Renovate may not auto-detect `Containerfile` (vs `Dockerfile`).

**Implementation:** Add explicit fileMatch for the Containerfile.

**File:** `.github/renovate.json5`

```json5
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:best-practices"],
  "rebaseWhen": "never",

  // Ensure Renovate scans Containerfile
  "dockerfile": {
    "fileMatch": ["(^|/)Containerfile$"]
  },

  "packageRules": [
    {
      "automerge": true,
      "matchUpdateTypes": ["pin", "pinDigest"]
    },
    {
      "enabled": false,
      "matchUpdateTypes": ["digest", "pinDigest", "pin"],
      "matchDepTypes": ["container"],
      "matchFileNames": [".github/workflows/**.yaml", ".github/workflows/**.yml"]
    }
  ]
}
```

---

### Add regex managers for custom version ARGs

**Priority:** P2 medium

**Rationale:** `NERD_FONTS_VERSION`, the Dracula GTK theme (pinned to `master` -- never updates), and `bib_image` in the Justfile are all untracked by Renovate.

**Implementation:** Add `customManagers` for these:

```json5
  "customManagers": [
    {
      "customType": "regex",
      "fileMatch": ["(^|/)Containerfile$"],
      "matchStrings": [
        "# renovate: datasource=(?<datasource>.*?) depName=(?<depName>.*?)\\nARG \\w+=(?<currentValue>.*)"
      ]
    },
    {
      "customType": "regex",
      "fileMatch": ["(^|/)Justfile$"],
      "matchStrings": [
        "# renovate: datasource=(?<datasource>.*?) depName=(?<depName>.*?)\\nexport bib_image.*:=.*\"(?<currentValue>.*)\"" 
      ]
    }
  ]
```

---

### Re-enable digest pinning for container deps in workflows

**Priority:** P2 medium

**Rationale:** The current config explicitly disables digest/pin updates for container deps in workflow files. This means action container references (like `quay.io/centos-bootc/bootc-image-builder:latest` in `build-iso.yml`) will never be pinned or updated. This is a supply-chain risk.

**Implementation:** Remove or narrow the disable rule. If the concern is noise, use `schedule` to batch updates weekly.

**File:** `.github/renovate.json5`

```json5
    // Remove this rule or scope it more narrowly:
    // {
    //   "enabled": false,
    //   "matchUpdateTypes": ["digest", "pinDigest", "pin"],
    //   "matchDepTypes": ["container"],
    //   "matchFileNames": [".github/workflows/**.yaml", ".github/workflows/**.yml"]
    // }
```

---

## Secure Boot Key Handling

### Confirm no private key in repository (STATUS: SAFE)

**Priority:** P0 critical (audit result: PASS)

**Rationale:** The file `secure-boot-keys/secureboot.crt` contains a PEM-encoded X.509 **certificate** (public key only) -- `BEGIN CERTIFICATE` / `END CERTIFICATE`. The `.gitignore` correctly excludes `secure-boot-keys/*.key` and `*.key`. The certificate's CN is `tblue-bazzite Secure Boot Key`, valid 2026-02-09 to 2036-02-07, self-signed RSA 2048-bit.

**Implementation:** No action needed. The private key is correctly excluded. However, add a comment to `.gitignore` explaining this for future contributors:

**File:** `.gitignore`

```gitignore
# Secure Boot private keys -- NEVER commit these
# Only the public certificate (.crt/.pem) should be in the repo
secure-boot-keys/*.key
*.key
!*.pub
```

---

### Add git-secrets or pre-commit hook to prevent accidental key commits

**Priority:** P2 medium

**Rationale:** The `.gitignore` excludes `*.key` but a contributor could bypass gitignore with `git add -f` or rename the key file. A pre-commit hook provides defense-in-depth.

**Implementation:** Add a pre-commit hook or use `git-secrets`:

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: detect-private-key
```

---

### Rotate secure boot key (10-year validity is fine, but document rotation process)

**Priority:** P3 nice-to-have

**Rationale:** The cert expires 2036-02-07 (10-year validity). This is reasonable for a MOK key. However, there's no documented process for key rotation when it eventually expires or if the private key is compromised.

**Implementation:** Add a `SECURITY.md` or section in README documenting:
- Where the private key is stored (offline? encrypted USB?)
- How to generate a new key pair
- How to update the ISO kickstart enrollment password
- How users re-enroll after a rotation

---

## First-Boot Services & Idempotency

### tblue-hibernate-setup.service lacks idempotency guard

**Priority:** P1 high

**Rationale:** Unlike `tblue-secureboot-firstboot.service` and `tblue-hhd-enable-user.service` which use `ConditionPathExists=!/var/lib/tblue/*.done`, the hibernate setup service has no such guard. It runs on every boot (`WantedBy=multi-user.target`, `Type=oneshot`, `RemainAfterExit=yes`) and calls `rpm-ostree kargs --replace` every time. This is wasteful and could cause unnecessary pending-reboot states.

**Implementation:** Add a done-marker check to the service and script.

**File:** `system_files/usr/lib/systemd/system/tblue-hibernate-setup.service`

```ini
[Unit]
Description=TBlue Hibernate first-boot provisioning
After=local-fs.target
DefaultDependencies=no
ConditionPathExists=!/var/lib/tblue/hibernate-setup.done

[Service]
Type=oneshot
ExecStart=/usr/libexec/tblue-hibernate-setup
RemainAfterExit=yes
# ...
```

And add `mark_done` at the end of the script (similar pattern to the other two scripts).

---

### tblue-hibernate-setup assumes btrfs swapfile exists

**Priority:** P2 medium

**Rationale:** The script hardcodes `SWAPFILE_PATH="/var/swap/swapfile"` and exits with error if it doesn't exist. On a fresh install without a pre-created swapfile, this service will fail on every boot, spamming the journal. The service should either create the swapfile or gracefully skip.

**Implementation:** Add swapfile creation or graceful skip with a clear journal message:

**File:** `system_files/usr/libexec/tblue-hibernate-setup`

```bash
if [[ ! -f "$SWAPFILE_PATH" ]]; then
    log "Swapfile $SWAPFILE_PATH does not exist. Skipping hibernate setup."
    log "To enable hibernate: create a swapfile and re-run this service."
    mark_done  # Don't retry every boot
    exit 0
fi
```

---

### tblue-hhd-enable-user exits without mark_done on failure

**Priority:** P2 medium

**Rationale:** If `systemctl enable --now "hhd@${target_user}.service"` fails, the script exits 1 without creating the done marker. This means it will retry on every boot -- which is correct behavior IF the failure is transient. But if the failure is permanent (e.g., hhd package removed), it creates perpetual boot noise.

**Implementation:** Add a retry counter or max-attempts guard:

**File:** `system_files/usr/libexec/tblue-hhd-enable-user`

```bash
ATTEMPT_FILE="/var/lib/tblue/hhd-enable-user.attempts"
attempts=$(cat "$ATTEMPT_FILE" 2>/dev/null || echo 0)
if (( attempts >= 5 )); then
    log "Failed to enable hhd after 5 attempts. Giving up."
    mark_done
    exit 0
fi
echo $((attempts + 1)) > "$ATTEMPT_FILE"
```

---

### Systemd preset should use ConditionFirstBoot for one-shot services

**Priority:** P3 nice-to-have

**Rationale:** The preset file (`50-hyprbazzite.preset`) enables `hhd.service`, `sddm.service`, and `tblue-hibernate-setup.service` unconditionally. For persistent services this is fine, but the one-shot services already have their own guards. Consider whether the preset is the right mechanism vs. `systemctl preset-all` behavior on image boot.

**Implementation:** Document that the preset is for image-level enablement (applied during `bootc switch`) and the `ConditionPathExists` guards handle runtime idempotency. No code change needed, but add a comment:

```ini
# These presets are applied at image switch time by systemd-preset-all.
# One-shot services use ConditionPathExists guards for runtime idempotency.
```

---

## Polkit Rule Safety

### 10-tdp-control.rules is dangerously overly broad

**Priority:** P0 critical

**Rationale:** The TDP control polkit rule grants `polkit.Result.YES` for **any** `org.freedesktop.policykit.exec` action by wheel group members. This action ID is used by `pkexec` -- meaning ANY `pkexec` command runs without authentication for wheel users. This effectively gives passwordless root to all wheel users for ALL pkexec-wrapped commands, not just TDP control.

**Implementation:** Scope the rule to only the specific commands needed for TDP control:

**File:** `system_files/usr/lib/hyprbazzite/polkit-1/rules.d/10-tdp-control.rules`

```javascript
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.policykit.exec" &&
        subject.isInGroup("wheel") &&
        action.lookup("program") &&
        (action.lookup("program") == "/usr/sbin/ryzenadj" ||
         action.lookup("program") == "/usr/bin/amdctl")) {
        return polkit.Result.YES;
    }
});
```

Alternatively, create a dedicated polkit action for TDP control rather than hijacking the generic pkexec action.

---

### 49-tblue-logind-hibernate.rules is correctly scoped

**Priority:** N/A (audit result: PASS)

**Rationale:** This rule only allows specific `org.freedesktop.login1.suspend-then-hibernate*` actions for root or wheel users. This is correctly scoped and follows least-privilege principles.

**Implementation:** No change needed.

---

## Udev Rules

### OpenRGB udev rules are duplicated with the RPM package

**Priority:** P2 medium

**Rationale:** The Containerfile installs `openrgb-udev-rules` RPM package AND ships a massive `60-openrgb.rules` file (900+ lines) in `system_files/usr/lib/hyprbazzite/udev/rules.d/`. The tmpfiles.d conf comments say "OpenRGB udev rules now provided by openrgb-udev-rules RPM" but the file still exists in the repo. This creates potential conflicts and maintenance burden.

**Implementation:** Remove the bundled `60-openrgb.rules` file and rely solely on the RPM package. If custom additions are needed, create a smaller supplementary rules file.

**File:** Delete `system_files/usr/lib/hyprbazzite/udev/rules.d/60-openrgb.rules`

```bash
git rm system_files/usr/lib/hyprbazzite/udev/rules.d/60-openrgb.rules
```

---

### 99-lid-action.rules runs a script without absolute path validation

**Priority:** P3 nice-to-have

**Rationale:** The rule calls `RUN+="/usr/lib/hyprbazzite/hypr/scripts/lidact.sh %s"`. The `%s` substitution passes the kernel device path. Ensure `lidact.sh` validates its input to prevent injection if udev ever passes unexpected strings.

**Implementation:** Verify `lidact.sh` exists and sanitizes input. The risk is low since udev controls the substitution, but defense-in-depth is good practice.

---

## Install-Apps Script Robustness

### Add set -euo pipefail (already present) -- verify subcommand failures are caught

**Priority:** P2 medium

**Rationale:** The script has `set -euo pipefail` at the top (good), but uses `|| log "Failed to install $app"` which swallows failures. If a critical Flatpak fails to install, the script continues and reports success. Consider whether any Flatpaks are truly critical.

**Implementation:** Add a summary of failures at the end:

**File:** `system_files/usr/libexec/hyprbazzite-install-apps`

```bash
FAILED_APPS=()
for app in "${FLATPAKS[@]}"; do
    if flatpak list --app --columns=application | grep -q "^${app}$"; then
        log "  $app already installed, skipping..."
    else
        log "  Installing $app..."
        if ! flatpak install --system -y flathub "$app"; then
            log "  Failed to install $app"
            FAILED_APPS+=("$app")
        fi
    fi
done

if [[ ${#FAILED_APPS[@]} -gt 0 ]]; then
    notify "Install Apps" "Failed to install: ${FAILED_APPS[*]}" "critical"
fi
```

---

### Add network retry logic for Flatpak installs

**Priority:** P2 medium

**Rationale:** The script checks internet connectivity once at the start (`check_internet`) but doesn't retry individual Flatpak installs on transient network failures. On first boot with unstable WiFi, installs may fail intermittently.

**Implementation:** Add retry wrapper:

```bash
install_with_retry() {
    local app="$1"
    local attempts=3
    for ((i=1; i<=attempts; i++)); do
        if flatpak install --system -y flathub "$app"; then
            return 0
        fi
        log "  Attempt $i/$attempts failed for $app, retrying in 5s..."
        sleep 5
    done
    return 1
}
```

---

### Homebrew installation runs as root context risk

**Priority:** P2 medium

**Rationale:** The `install-apps` script runs via `ujust install-apps` which may be invoked with elevated privileges. The Homebrew installer (`/bin/bash -c "$(curl -fsSL ...)"`) should never run as root. There's no explicit UID check before the Homebrew section.

**Implementation:** Add a root guard:

```bash
if [[ $EUID -eq 0 ]]; then
    log "ERROR: Homebrew section must not run as root. Run 'ujust install-apps' as your regular user."
    # Skip Homebrew section
else
    # ... existing Homebrew code
fi
```

---

## Justfile Targets

### Add a `verify` target for local pre-push validation

**Priority:** P2 medium

**Rationale:** The `lint` target only runs shellcheck. There's no local equivalent of the CI `verify-image.sh` step. Developers should be able to run a full local validation before pushing.

**Implementation:**

**File:** `Justfile`

```just
# Run full local verification (lint + build + verify)
[group('CI')]
verify $target_image=("localhost/" + image_name) $tag=default_tag: (build target_image tag)
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Running image verification..."
    podman run --rm --pull=never \
        -v "$(pwd)/scripts/verify-image.sh:/tmp/verify-image.sh:ro" \
        "${target_image}:${tag}" \
        bash /tmp/verify-image.sh
    echo "Verification passed!"
```

---

### Lint target should also run hadolint

**Priority:** P3 nice-to-have

**Rationale:** CI runs both shellcheck and hadolint, but the local `lint` target only runs shellcheck. Parity between local and CI linting catches issues earlier.

**Implementation:**

```just
lint:
    #!/usr/bin/env bash
    set -eoux pipefail
    if command -v shellcheck &> /dev/null; then
        /usr/bin/find . -iname "*.sh" -type f -exec shellcheck "{}" ';'
    else
        echo "shellcheck not found, skipping"
    fi
    if command -v hadolint &> /dev/null; then
        hadolint Containerfile
    else
        echo "hadolint not found, skipping"
    fi
```

---

### Format target error message references wrong tool

**Priority:** P3 nice-to-have

**Rationale:** The `format` target's error message says "shellcheck could not be found" when it should say "shfmt could not be found."

**File:** `Justfile` format target

```just
format:
    #!/usr/bin/env bash
    set -eoux pipefail
    if ! command -v shfmt &> /dev/null; then
        echo "shfmt could not be found. Please install it."
        exit 1
    fi
```

---

## Verify-Image Script

### Expand verification to cover critical scripts and services

**Priority:** P2 medium

**Rationale:** `scripts/verify-image.sh` only checks 5 packages and 3 config files. It doesn't verify that systemd services are correctly installed, that libexec scripts exist, or that polkit rules are in place. A broken COPY step could ship a non-functional image that passes the current verification.

**Implementation:**

**File:** `scripts/verify-image.sh`

```bash
# 4. Critical scripts and services
declare -a REQUIRED_SCRIPTS=(
    "/usr/libexec/hyprbazzite-ctl"
    "/usr/libexec/hyprbazzite-install-apps"
    "/usr/libexec/tblue-secureboot-firstboot"
    "/usr/libexec/tblue-hibernate-setup"
    "/usr/libexec/tblue-hhd-enable-user"
)
for script in "${REQUIRED_SCRIPTS[@]}"; do
    if [ ! -x "$script" ]; then
        echo "ERROR: Critical script '$script' is missing or not executable."
        exit 1
    fi
done
echo "All critical scripts are present and executable."

# 5. Systemd unit files
declare -a REQUIRED_UNITS=(
    "/usr/lib/systemd/system/tblue-secureboot-firstboot.service"
    "/usr/lib/systemd/system/tblue-hibernate-setup.service"
    "/usr/lib/systemd/system/tblue-hhd-enable-user.service"
)
for unit in "${REQUIRED_UNITS[@]}"; do
    if [ ! -f "$unit" ]; then
        echo "ERROR: Systemd unit '$unit' is missing."
        exit 1
    fi
done
echo "All systemd units are present."
```

---

### Add bootc lint as final verification step

**Priority:** P2 medium

**Rationale:** The Containerfile already runs `bootc container lint` at the end of the build. However, the `verify-image.sh` script could also run it to confirm the image is bootc-compliant when tested in CI.

**Implementation:** Already done in Containerfile Step 10. Verify it's not silently failing by checking the exit code is propagated.

---

## Tmpfiles.d Configuration

### R! directives destroy user customizations on every boot

**Priority:** P1 high

**Rationale:** The tmpfiles.d config uses `R!` (recursive remove) on `/etc/hypr`, `/etc/waybar`, `/etc/wofi`, `/etc/xdg`, and `/etc/swayidle` followed by `C+` (copy if different). This means any manual customization to these directories under `/etc` is **destroyed on every boot**. While bootc images are immutable, `/etc` is the mutable overlay -- users expect to be able to customize it.

**Implementation:** Replace `R!` + `C+` with `C` (copy only if absent) or use a versioned stamp file to only reset on image update:

```ini
# Only reset config on image version change, not every boot
# Alternative: use a version-stamped done file
C /etc/hypr - - - - /usr/lib/hyprbazzite/hypr
```

Or move to a user-facing `ujust hypr-reset` command (which already exists!) and remove the automatic purge entirely. Let the image ship defaults via `/etc/skel` and `/usr/share/hyprbazzite/config` (which is already set up in Step 7).

---

### keybind-profile has overly permissive mode 0666

**Priority:** P2 medium

**Rationale:** `C+ /etc/hypr/keybind-profile 0666 root root` creates a world-writable file. Any process or user can modify the keybind profile. This should be 0644 (root-writable, world-readable) since the `keybinds_switch` function in `hyprbazzite-ctl` already handles writing via the script.

**File:** `system_files/usr/lib/tmpfiles.d/hyprbazzite.conf`

```ini
C+ /etc/hypr/keybind-profile 0644 root root - /usr/lib/hyprbazzite/hypr/keybind-profile
```

---

## Disk Configuration

### disk.toml uses swap without hibernation offset

**Priority:** P3 nice-to-have

**Rationale:** `disk_config/disk.toml` defines an 8 GiB swap partition but the hibernate setup script expects a btrfs swapfile at `/var/swap/swapfile`. These are two different swap mechanisms. If the disk partition swap is used, the swapfile-based hibernate won't work. Clarify which swap mechanism is canonical.

**Implementation:** Document in SETUP.md whether the partition swap is for BIB VMs only and the swapfile is for bare-metal installs. Consider removing the swap partition from `disk.toml` if it's not needed for VMs.

---

### ISO kickstart references old image name

**Priority:** P1 high

**Rationale:** `disk_config/iso.toml` contains `bootc switch --mutate-in-place --transport registry ghcr.io/tristanbollard/tblue-bazzite:latest` but the MIGRATION.md indicates the image was renamed to `hyprbazzite` under `tvorfreude`. The kickstart still points to the old name/owner.

**File:** `disk_config/iso.toml`

```toml
bootc switch --mutate-in-place --transport registry ghcr.io/tvorfreude/hyprbazzite:latest
```

---

### ISO kickstart hardcodes MOK enrollment password

**Priority:** P2 medium

**Rationale:** `ENROLLMENT_PASSWORD="universalblue"` is hardcoded in the kickstart `%post` section. This is the standard Universal Blue MOK password and is publicly known. While this is common practice in the UBlue ecosystem (the password is only needed during the one-time MOK enrollment reboot), it should be documented that this is intentionally public and not a security credential.

**Implementation:** Add a comment in the kickstart and document in SETUP.md:

```bash
# This is a one-time enrollment password shown to the user at MOK enrollment.
# It is intentionally simple and publicly known (Universal Blue convention).
ENROLLMENT_PASSWORD="universalblue"
```

---

## Repository Hygiene

### Add CODEOWNERS file

**Priority:** P3 nice-to-have

**Rationale:** No `CODEOWNERS` file exists. For a personal project this is fine, but if collaborators are added, critical paths (Containerfile, workflows, secure-boot-keys/) should require owner review.

**Implementation:**

```
# .github/CODEOWNERS
* @tvorfreude
.github/workflows/ @tvorfreude
secure-boot-keys/ @tvorfreude
Containerfile @tvorfreude
```

---

### Add branch protection rules documentation

**Priority:** P3 nice-to-have

**Rationale:** The `build-iso.yml` workflow allows collaborators to trigger builds from PR branches. Document recommended branch protection settings (require PR review, require status checks, restrict force push) in a CONTRIBUTING.md.

---

### .gitignore should exclude BIB output and temp dirs

**Priority:** P3 nice-to-have

**Rationale:** The Justfile creates `_build-bib.*` temp directories and `output/` directory. The `.gitignore` covers `_build_*` and `output` but the pattern `_build-*/**` uses a glob that may not match the mktemp pattern `_build-bib.XXXXXXXXXX` (no wildcard after the dot for the directory itself).

**File:** `.gitignore`

```gitignore
_build*
output/
```

---

### Add security policy (SECURITY.md)

**Priority:** P2 medium

**Rationale:** No `SECURITY.md` exists. For a project that handles secure boot keys, builds signed OCI images, and ships system-level polkit rules, a security policy documenting how to report vulnerabilities and the key management process is important.

**Implementation:** Create `SECURITY.md` covering:
- How to report security issues (private disclosure)
- Secure boot key custody (where private key lives)
- Image signing verification instructions
- Scope of polkit/privilege escalation rules shipped

---

## bootc.toml Configuration

### bootc.toml is minimal but correct

**Priority:** N/A (audit: PASS)

**Rationale:** The file at `system_files/usr/lib/bootc/bootc.toml` defines filesystem layout for bootc. Confirmed it exists and is copied into the image. No issues found.

---

## Workflow Concurrency & Scheduling

### Scheduled builds should skip if no base image update AND no code change

**Priority:** P3 nice-to-have

**Rationale:** The `check_base_image` job correctly gates scheduled builds on base image updates. However, if the schedule fires and the base hasn't changed, no build runs -- which is correct. The current logic is sound. One enhancement: add a `workflow_dispatch` input to force a rebuild even when the base hasn't changed.

**Implementation:**

```yaml
on:
  workflow_dispatch:
    inputs:
      force_build:
        description: 'Force rebuild regardless of base image state'
        type: boolean
        default: false
```

Then in the `build_push` condition:

```yaml
    if: |
      always() &&
      (github.event_name == 'workflow_dispatch' ||
       (github.event_name == 'workflow_dispatch' && inputs.force_build) ||
       ...
```

---

### Add concurrency group to build-iso.yml

**Priority:** P2 medium

**Rationale:** `build-iso.yml` has no concurrency group. Multiple `/build-iso` comments on the same PR could trigger parallel ISO builds, consuming excessive resources.

**File:** `.github/workflows/build-iso.yml`

```yaml
concurrency:
  group: build-iso-${{ github.event.issue.number || github.run_id }}
  cancel-in-progress: true
```


---

# Part B -- Hyprland, Wayland & Helper Scripts

## Shell Script Robustness

### B-01: lidact.sh `command ls` Wayland socket discovery is fragile

**Priority:** P1  
**Rationale:** `command ls -1 "$XDG_RUNTIME_DIR" | grep -E '^wayland-[0-9]+$' | head -n 1` relies on filename-sorting order to find the active Wayland socket. If multiple compositors have run (e.g. a crashed session left `wayland-0` behind and the live one is `wayland-1`), this picks the wrong socket. Additionally, parsing `ls` output is a well-known anti-pattern (filenames with newlines, locale-dependent sorting). The same pattern is used to discover `HYPRLAND_INSTANCE_SIGNATURE` via `ls -1t "$HYPR_DIR"`.  
**Implementation:** Use the Hyprland-native `$HYPRLAND_INSTANCE_SIGNATURE` discovery or parse `/proc` for the compositor's socket. At minimum, prefer `find` or a glob:

```bash
# Preferred: use the compositor's own lock/pid file
if [ -z "$WAYLAND_DISPLAY" ]; then
    for sock in "$XDG_RUNTIME_DIR"/wayland-[0-9]*; do
        [ -S "$sock" ] && { export WAYLAND_DISPLAY="${sock##*/}"; break; }
    done
fi

# For Hyprland instance: use the most recent directory by checking running PIDs
if [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    for d in "$XDG_RUNTIME_DIR/hypr"/*/; do
        sig="${d%/}"; sig="${sig##*/}"
        if [ -S "$XDG_RUNTIME_DIR/hypr/$sig/.socket.sock" ]; then
            export HYPRLAND_INSTANCE_SIGNATURE="$sig"
            break
        fi
    done
fi
```

File: `system_files/usr/lib/hyprbazzite/hypr/scripts/lidact.sh`, lines 9-16.

---

### B-02: Duplicated env-detection boilerplate should be a shared sourced helper

**Priority:** P1  
**Rationale:** `lidact.sh` manually discovers `XDG_RUNTIME_DIR`, `WAYLAND_DISPLAY`, and `HYPRLAND_INSTANCE_SIGNATURE` (lines 3-16). `hyprbazzite-ctl` also checks `HYPRLAND_INSTANCE_SIGNATURE` (line 151) but differently (bails out with an error instead of discovering it). Any future script needing hyprctl access will duplicate this logic again. A single sourced helper guarantees consistency and makes fixes propagate.  
**Implementation:** Create `/usr/lib/hyprbazzite/hypr/scripts/_env.sh` (leading underscore signals it's not user-callable):

```bash
#!/usr/bin/env bash
# _env.sh -- shared Hyprland session environment resolver
# Source this at the top of any script needing hyprctl/wlr access.

: "${XDG_RUNTIME_DIR:="/run/user/$(id -u)"}"
export XDG_RUNTIME_DIR

if [ -z "${WAYLAND_DISPLAY:-}" ]; then
    for _sock in "$XDG_RUNTIME_DIR"/wayland-[0-9]*; do
        [ -S "$_sock" ] && { export WAYLAND_DISPLAY="${_sock##*/}"; break; }
    done
fi

if [ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    for _d in "$XDG_RUNTIME_DIR/hypr"/*/; do
        _sig="${_d%/}"; _sig="${_sig##*/}"
        [ -S "$XDG_RUNTIME_DIR/hypr/$_sig/.socket.sock" ] && {
            export HYPRLAND_INSTANCE_SIGNATURE="$_sig"; break
        }
    done
fi

if [ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    echo "[env] ERROR: No running Hyprland instance found." >&2
    exit 1
fi
```

Then in `lidact.sh`, `waybar-power-tdp-status.sh`, and any future script:

```bash
#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=/usr/lib/hyprbazzite/hypr/scripts/_env.sh
source /usr/lib/hyprbazzite/hypr/scripts/_env.sh
```

File: new file `system_files/usr/lib/hyprbazzite/hypr/scripts/_env.sh`; consumers: `lidact.sh`, `waybar-power-tdp-status.sh`, `hyprbazzite-ctl`.

---

### B-03: lidact.sh missing `set -euo pipefail`

**Priority:** P1  
**Rationale:** Every other script in the directory uses `set -euo pipefail`, but `lidact.sh` does not. A failing `hyprctl` or `jq` call will silently continue, potentially executing the wrong branch (e.g. disabling a monitor that's already off, or re-enabling one that shouldn't be).  
**Implementation:**

```bash
#!/usr/bin/env bash
set -euo pipefail
# ... rest of lidact.sh
```

File: `system_files/usr/lib/hyprbazzite/hypr/scripts/lidact.sh`, line 1.

---

### B-04: Missing scripts referenced at runtime — `toggle-osk.sh` and `tdp-control.sh`

**Priority:** P0  
**Rationale:** `swap-osk-half.sh` line 34 calls `/etc/hypr/scripts/toggle-osk.sh` and `waybar-power-tdp-status.sh` line 34 checks `-x /etc/hypr/scripts/tdp-control.sh`. `tdp-profile-selector.sh` line 7 also references `$SCRIPT_DIR/tdp-control.sh`. Neither file exists in the repo. The `|| true` guards prevent a crash but silently break functionality — the OSK won't restart after an anchor swap, and the TDP widget will never show wattage even on supported hardware.  
**Implementation:** Either:
1. Create the missing scripts, or
2. Replace the references with `hyprbazzite-ctl` subcommands (which already implement these functions):

```bash
# swap-osk-half.sh line 34 -- replace:
/etc/hypr/scripts/toggle-osk.sh >/dev/null 2>&1 || true
# with:
/usr/libexec/hyprbazzite-ctl osk toggle >/dev/null 2>&1 || true

# waybar-power-tdp-status.sh line 34 -- replace:
if [ -x /etc/hypr/scripts/tdp-control.sh ]; then
# with:
if command -v /usr/libexec/hyprbazzite-ctl >/dev/null 2>&1; then
```

Files: `system_files/usr/lib/hyprbazzite/hypr/scripts/swap-osk-half.sh`, `system_files/usr/lib/hyprbazzite/hypr/scripts/waybar-power-tdp-status.sh`, `system_files/usr/lib/hyprbazzite/hypr/scripts/tdp-profile-selector.sh`.

---

### B-05: Waybar config references non-existent `$HOME/.config/hypr/scripts/` scripts

**Priority:** P0  
**Rationale:** `config.jsonc` references `$HOME/.config/hypr/scripts/Wlogout.sh`, `$HOME/.config/hypr/scripts/WaybarScripts.sh`, and `$HOME/.config/hypr/scripts/Volume.sh` (lines 322, 346, 392-393, 504). None of these files exist in the repo. They appear to be cargo-culted from an upstream ML4W/JaKooLit dotfiles layout that was never ported. Right-clicking these waybar modules does nothing or throws a silent error.  
**Implementation:** Replace with working equivalents:

```jsonc
// Line 322 -- Wlogout.sh -> use hyprbazzite-ctl
"on-click-right": "/usr/libexec/hyprbazzite-ctl power menu"

// Line 346 -- WaybarScripts.sh --nmtui -> inline
"on-click-right": "kitty -e nmtui"

// Lines 392-393 -- Volume.sh -> use wpctl directly
"on-scroll-up":   "wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+",
"on-scroll-down": "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-",

// Line 504 -- WaybarScripts.sh --nvtop -> inline
"on-click-right": "kitty -e nvtop"
```

File: `system_files/usr/lib/hyprbazzite/waybar/config.jsonc`.

---

### B-06: TritonCtl.sh `ls | grep` pipeline fragile and exposes `executable_` prefixed filenames

**Priority:** P2  
**Rationale:** `TritonCtl.sh` line 30 does `ls "$SCRIPTS_DIR" | grep '\.sh$' | sed 's/\.sh//'` to build the menu. This exposes the `executable_install-cursor-clip` and `executable_update-theme` entries in the user-facing wofi menu — confusing and non-functional as menu items. It also breaks on filenames with spaces or special characters.  
**Implementation:** Use a glob + explicit exclusion of non-interactive scripts:

```bash
# Replace ls|grep pipeline with:
local options=""
for script in "$SCRIPTS_DIR"/*.sh; do
    [ -f "$script" ] || continue
    local name="${script##*/}"
    name="${name%.sh}"
    # Skip internal/non-interactive scripts
    [[ "$name" == _* ]] && continue
    [[ "$name" == executable_* ]] && continue
    [[ "$name" == "$gamemode_status" ]] || options+="$name\n"
done
options+="$gamemode_status"
```

File: `system_files/usr/lib/hyprbazzite/hypr/scripts/TritonCtl.sh`, lines 18, 30.

---

### B-07: `gamemode.sh` uses `swaybg` but autostart uses `swww-daemon`

**Priority:** P2  
**Rationale:** `autostart.lua` starts `swww-daemon` + `wallpaper-cycle` (lines 16-17). But `gamemode.sh` kills `swaybg` on enable (line 18) and spawns `swaybg` on disable (line 31). Since swww is the actual wallpaper backend, `pkill swaybg` is a no-op and the disable path spawns a competing wallpaper process that fights swww. Similarly, `refresh.sh` lists `swaybg` in its kill/restart array (line 5, 15) but never touches swww.  
**Implementation:** Unify on swww:

```bash
# gamemode.sh -- on enable:
swww clear 000000  # black background, no process to kill

# gamemode.sh -- on disable:
swww img "$HOME/.config/hypr/wallust/current_wallpaper.jpg" \
    --transition-type wipe --transition-duration 2

# refresh.sh -- replace swaybg references:
apps=(swww-daemon mako waybar fcitx5)
# ... after restarting:
swww-daemon &
sleep 0.3
wallpaper-cycle &
```

Files: `system_files/usr/lib/hyprbazzite/hypr/scripts/gamemode.sh`, `system_files/usr/lib/hyprbazzite/hypr/scripts/refresh.sh`.

---

### B-08: `refresh.sh` kills `hypridle` but autostart launches `swayidle`

**Priority:** P1  
**Rationale:** `autostart.lua` line 12 starts `swayidle -C /etc/swayidle/config -w`. But `refresh.sh` line 5 kills `hypridle` and line 11 restarts `hypridle`. These are different programs (swayidle vs hypridle). The refresh script will fail to kill the actual idle daemon and spawn a second (likely unconfigured) one. The Containerfile installs `swayidle` (line 73). Waybar CSS references `#custom-hypridle` (a status indicator), suggesting maybe both should be present, but the startup is inconsistent.  
**Implementation:** Decide on one idle daemon and make it consistent:

```bash
# If swayidle is the chosen daemon (matches autostart.lua + Containerfile):
# refresh.sh:
apps=(swayidle mako waybar fcitx5 swww-daemon)
# ...
swayidle -C /etc/swayidle/config -w &
```

Files: `system_files/usr/lib/hyprbazzite/hypr/scripts/refresh.sh`, `system_files/usr/lib/hyprbazzite/hypr/autostart.lua`.

---

### B-09: `wallpaper.sh` unconditionally requires `jq` and `bc` but never uses them

**Priority:** P3  
**Rationale:** Lines 5-8 check for `jq` and `bc` and exit 1 if missing, but neither is used anywhere in the script. This is likely leftover from a removed monitor-resolution-aware cropping feature. The false dependency blocks wallpaper changes on systems without `bc`.  
**Implementation:** Remove the dead check:

```diff
--- a/system_files/usr/lib/hyprbazzite/hypr/scripts/wallpaper.sh
+++ b/system_files/usr/lib/hyprbazzite/hypr/scripts/wallpaper.sh
@@ -5,11 +5,6 @@
-if ! command -v jq &>/dev/null || ! command -v bc &>/dev/null; then
-    notify-send "TritonCtl" "Missing dependency: jq or bc"
-    exit 1
-fi
```

File: `system_files/usr/lib/hyprbazzite/hypr/scripts/wallpaper.sh`, lines 5-8.

---

## Chezmoi & `executable_` Filename Prefix Issue

### B-10: `executable_` prefix is chezmoi source-state naming leaking into the shipped image

**Priority:** P0  
**Rationale:** Two scripts have the `executable_` prefix: `executable_install-cursor-clip.sh` and `executable_update-theme.sh`. In chezmoi's source-state convention, `executable_` is a metadata prefix that tells chezmoi to set +x on the target file, stripping the prefix. But this repo ships files directly via `COPY system_files/ /` in the Containerfile — chezmoi never processes them. The result: these scripts are installed to `/usr/lib/hyprbazzite/hypr/scripts/executable_install-cursor-clip.sh` literally, with that broken name. The Containerfile's `find ... -exec chmod +x` makes them executable regardless, making the prefix doubly pointless. Neither script is referenced anywhere else in the repo (grep confirms zero references to these filenames), meaning they're dead code AND wrongly named.  
**Implementation:**
1. Rename `executable_install-cursor-clip.sh` → `install-cursor-clip.sh`
2. Rename `executable_update-theme.sh` → `update-theme.sh`
3. Audit whether they should be in the image at all (`install-cursor-clip.sh` clones from GitHub and runs `cargo build` — inappropriate for an immutable image; it should be a build-time step in the Containerfile or removed entirely).

```bash
# In the repo:
mv system_files/usr/lib/hyprbazzite/hypr/scripts/executable_install-cursor-clip.sh \
   system_files/usr/lib/hyprbazzite/hypr/scripts/install-cursor-clip.sh
mv system_files/usr/lib/hyprbazzite/hypr/scripts/executable_update-theme.sh \
   system_files/usr/lib/hyprbazzite/hypr/scripts/update-theme.sh
```

Files: `system_files/usr/lib/hyprbazzite/hypr/scripts/executable_install-cursor-clip.sh`, `system_files/usr/lib/hyprbazzite/hypr/scripts/executable_update-theme.sh`.

---

### B-11: `executable_install-cursor-clip.sh` is a runtime installer — inappropriate for an immutable image

**Priority:** P1  
**Rationale:** This script clones a git repo, runs `cargo build --release`, and `sudo install`s the binary. On an immutable bootc/ostree image, `/usr/local/bin` is read-only at runtime. The script will always fail. `autostart.lua` already expects `cursor-clip --daemon` to be available (line 24), implying it should be baked into the image at build time.  
**Implementation:** Move the build into the Containerfile:

```dockerfile
# In Containerfile, add to build stage:
RUN git clone https://github.com/Sirulex/cursor-clip.git /tmp/cursor-clip && \
    cd /tmp/cursor-clip && \
    cargo build --release && \
    install -Dm755 target/release/cursor-clip /usr/bin/cursor-clip && \
    rm -rf /tmp/cursor-clip
```

Then delete the runtime installer script entirely.

File: `system_files/usr/lib/hyprbazzite/hypr/scripts/executable_install-cursor-clip.sh` (delete); `Containerfile` (add build step).

---

### B-12: Chezmoi in an immutable image — architectural friction

**Priority:** P2  
**Rationale:** The image ships chezmoi as a package (Containerfile line 77) and has a `chezmoi-provision` systemd user service for first-login dotfiles. The `chezmoi.sh` script provides push/pull hotkey actions. However, chezmoi's model (managing `~/.config` as a mutable target) conflicts with the system-level config in `/etc/hypr` (deployed via tmpfiles.d `C+` copy). A user who customises via chezmoi may have their `~/.config/hypr` changes ignored because Hyprland reads from `/etc/hypr` (the lua `require()` paths are relative to the config dir set at launch). The system works only if the user's chezmoi repo takes precedence AND Hyprland is pointed at `~/.config/hypr` instead of `/etc/hypr`.  
**Implementation:** Document the intended layering clearly. Either:
- Remove the `/etc/hypr` tmpfiles overlay and always use `~/.config/hypr` (chezmoi-managed), or
- Keep `/etc/hypr` as the system default but have chezmoi provision to `~/.config/hypr` and ensure `hyprland.desktop` passes `-c ~/.config/hypr/hyprland.lua` if that directory exists.

```ini
# Example: hyprland.desktop with user-config detection
[Desktop Entry]
Exec=sh -c 'if [ -f "$HOME/.config/hypr/hyprland.lua" ]; then exec Hyprland -c "$HOME/.config/hypr/hyprland.lua"; else exec Hyprland -c /etc/hypr/hyprland.lua; fi'
```

Files: `system_files/usr/lib/tmpfiles.d/hyprbazzite.conf`, `SETUP.md`, session desktop file.

---

## Lid Switch Handling

### B-13: Dual lid invocation — udev rule AND Hyprland binding (KNOWN BUG)

**Priority:** P0  
**Rationale:** The lid switch event triggers two independent handlers:
1. **udev rule** (`99-lid-action.rules`): `RUN+="/usr/lib/hyprbazzite/hypr/scripts/lidact.sh %s"` — runs as root, no session env (`$WAYLAND_DISPLAY`, `$HYPRLAND_INSTANCE_SIGNATURE` unset), no D-Bus. The script's env-discovery workaround (lines 4-16) is brittle (see B-01).
2. **Hyprland binding** (`bindings.lua` lines 347-348): `switch:on:Lid Switch` / `switch:off:Lid Switch` — runs in-session, full env, correct user.

Both call the same script with opposite semantics: udev passes `%s` (the kernel sysfs path, NOT "on"/"off"), while the binding passes literal "off"/"on". The udev call will hit the `else` branch and print "Usage:" to nowhere.

Additionally, `hyprbazzite-ctl lid {close|open}` (line 260+) implements SMARTER logic (hibernate if no external monitor, disable internal if external exists) — but nothing calls it.  
**Implementation:** Remove the udev rule entirely; Hyprland's native `switch:` binding is the correct mechanism. Update the binding to call `hyprbazzite-ctl lid` for the smarter logic:

```lua
-- bindings.lua -- replace:
hl.bind("switch:on:Lid Switch",  hl.dsp.exec_cmd("/usr/libexec/hyprbazzite-ctl lid close"), { locked = true })
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("/usr/libexec/hyprbazzite-ctl lid open"),  { locked = true })
```

Then delete or gate the udev rule (keep it only if a headless/no-compositor mode is needed):

```bash
# Delete:
rm system_files/usr/lib/hyprbazzite/udev/rules.d/99-lid-action.rules
```

Files: `system_files/usr/lib/hyprbazzite/udev/rules.d/99-lid-action.rules` (delete), `system_files/usr/lib/hyprbazzite/hypr/bindings.lua` lines 347-348.

---

### B-14: lidact.sh duplicates logic already in `hyprbazzite-ctl lid`

**Priority:** P2  
**Rationale:** After fixing B-13, `lidact.sh` becomes dead code — its logic (find monitor, enable/disable) is a subset of what `hyprbazzite-ctl lid_handle()` does (which also adds hibernate-if-no-external and reload-on-open). Maintaining two implementations creates drift.  
**Implementation:** Delete `lidact.sh`; all callers should use `hyprbazzite-ctl lid close|open`.

File: `system_files/usr/lib/hyprbazzite/hypr/scripts/lidact.sh` (delete after B-13).

---

## Swayidle / Hyprlock Coordination

### B-15: swayidle config doesn't inhibit lock if already locked

**Priority:** P2  
**Rationale:** The swayidle config fires `hyprlock` on both `timeout 300` and `before-sleep`. If the system suspends shortly after the 5-minute timeout, hyprlock is launched twice. Hyprlock may handle this gracefully (refusing a second instance), but it's still a race and unnecessary process spawn.  
**Implementation:** Use `pidof` or `pgrep` guard:

```
# /etc/swayidle/config
timeout 300 'pgrep -x hyprlock || hyprlock -c /etc/hypr/hyprlock.conf'
timeout 600 'hyprctl dispatch dpms off'
resume 'hyprctl dispatch dpms on'
before-sleep 'pgrep -x hyprlock || hyprlock -c /etc/hypr/hyprlock.conf'
```

File: `system_files/usr/lib/hyprbazzite/swayidle/config`.

---

### B-16: swayidle `resume` only restores DPMS but not after lock-triggered DPMS off

**Priority:** P3  
**Rationale:** The `resume` directive only fires after the `timeout 600` dpms-off event. If the user locks manually (Super+Alt+L or Ctrl+Q) and the screen turns off via DPMS during hyprlock, there's no `resume` to turn it back on when the user moves the mouse. Hyprlock's own input handling will wake the display, but this is worth noting as a potential confusion source for custom swayidle extensions.  
**Implementation:** Consider adding a lock/unlock hook:

```
lock 'hyprctl dispatch dpms off'
unlock 'hyprctl dispatch dpms on'
```

File: `system_files/usr/lib/hyprbazzite/swayidle/config`.

---

## Keybind Ergonomics & Conflicts

### B-17: macOS profile SUPER+S/Q conflict with standard app shortcuts

**Priority:** P2  
**Rationale:** In the macOS profile, `SUPER + S` toggles the special workspace and `SUPER + Q` toggles the scratchpad. On macOS, Cmd+S = Save and Cmd+Q = Quit. Since `m2` (ALT) is the WM modifier and SUPER is "free for app shortcuts", binding SUPER+S and SUPER+Q to WM actions steals the physical Cmd key from apps. This is inconsistent with the stated design ("Cmd = Super remains free for you to wire up separately").  
**Implementation:** Move special-workspace binds to the WM modifier (ALT/m2) or use a less-conflicting combo:

```lua
-- Option: use ALT (the WM mod) for scratchpads, consistent with design
hl.bind(m2 .. " + S", hl.dsp.workspace.toggle_special())
hl.bind(m2 .. " + SHIFT + S", ...)
hl.bind(m2 .. " + Q", hl.dsp.workspace.toggle_special("scratchpad"))
```

File: `system_files/usr/lib/hyprbazzite/hypr/bindings.lua`, lines 115-135.

---

### B-18: macOS profile Cmd+Shift+4 and Cmd+Shift+5 are identical

**Priority:** P3  
**Rationale:** Lines 155-157 bind `ALT + SHIFT + 3` (full), `ALT + SHIFT + 4` (area), and `ALT + SHIFT + 5` (area). On macOS, Cmd+Shift+5 opens the screenshot toolbar (which includes screen recording). Binding both 4 and 5 to the same `screenshot area` action wastes a keybind slot.  
**Implementation:** Differentiate Shift+5 — either bind to window-mode screenshot or a screen-recording tool:

```lua
hl.bind(m2 .. " + SHIFT + 5", hl.dsp.exec_cmd("/usr/libexec/hyprbazzite-ctl screenshot window"))
-- or for recording:
hl.bind(m2 .. " + SHIFT + 5", hl.dsp.exec_cmd("wf-recorder -g \"$(slurp)\""))
```

File: `system_files/usr/lib/hyprbazzite/hypr/bindings.lua`, line 157.

---

### B-19: Linux profile SUPER+K = OSK toggle conflicts with vim-style focus-up expectation

**Priority:** P3  
**Rationale:** In the linux profile, `SUPER+K` is bound to OSK toggle (line 321) while `SUPER+J` is window cycle-next (line 288). Users expecting vim-style navigation (H/J/K/L) will find K does something completely unrelated. The macOS profile correctly uses H/J/K/L for focus.  
**Implementation:** Consider moving OSK to a less-overloaded key:

```lua
-- Move OSK to a dedicated key that doesn't conflict with navigation:
hl.bind(m .. " + grave", hl.dsp.exec_cmd("/usr/libexec/hyprbazzite-ctl osk toggle"))
-- Or keep it but add proper vim focus to linux profile:
hl.bind(m .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(m .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(m .. " + L", hl.dsp.focus({ direction = "right" }))
```

File: `system_files/usr/lib/hyprbazzite/hypr/bindings.lua`, linux profile section.

---

### B-20: Linux profile missing vim-style focus movement entirely

**Priority:** P2  
**Rationale:** The macOS profile has full H/J/K/L focus + shift-move bindings. The linux profile only has arrow-key focus (lines 293-296) and uses J for cycle-next and K for OSK. Power users on the linux profile have no vim-style window navigation at all.  
**Implementation:** Add vim focus to linux profile, moving J-cycle and K-osk to other keys:

```lua
-- vim focus (matching macOS profile)
hl.bind(m .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(m .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(m .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(m .. " + L", hl.dsp.focus({ direction = "right" }))
-- Relocate cycle-next and OSK:
hl.bind(m .. " + Tab",   hl.dsp.window.cycle_next())
hl.bind(m .. " + grave", hl.dsp.exec_cmd("/usr/libexec/hyprbazzite-ctl osk toggle"))
```

File: `system_files/usr/lib/hyprbazzite/hypr/bindings.lua`, linux profile section.

---

## Monitor Configuration

### B-21: Hardcoded monitor descriptors make the config non-portable

**Priority:** P2  
**Rationale:** `monitors.lua` contains 6 monitor definitions with exact `desc:` strings including serial numbers (e.g. `"desc:GIGA-BYTE TECHNOLOGY CO. LTD. M27F A 23073B000294"`). This is a personal dotfile pattern, not suitable for a distributable image. Any user without these exact monitors gets only the fallback rule.  
**Implementation:** Either:
1. Move specific monitor configs to the chezmoi-managed user layer (`~/.config/hypr/monitors.lua`) and ship only the fallback in the system config, or
2. Add a comment/mechanism explaining this is expected to be overridden:

```lua
-- System default: all monitors auto-detected
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- User-specific monitor configs should go in ~/.config/hypr/monitors.lua
-- which chezmoi provisions per-device.
```

File: `system_files/usr/lib/hyprbazzite/hypr/monitors.lua`.

---

### B-22: HDR parameters in monitor config are non-standard Hyprland options

**Priority:** P3  
**Rationale:** The M27F and M27U entries include `cm`, `sdrbrightness`, `sdrsaturation`, `max_luminance`, `max_avg_luminance`, `sdr_max_luminance`. These are Hyprland 0.45+ color management parameters that require `render.cm_enabled = true` (set in hyprland.lua). If the user's Hyprland version doesn't support them, they'll be silently ignored or cause warnings. The config should document the minimum version requirement.  
**Implementation:** Add a version gate comment:

```lua
-- NOTE: cm/sdrbrightness/sdrsaturation/max_luminance require Hyprland ≥0.45
-- with render.cm_enabled = true (set in hyprland.lua)
```

File: `system_files/usr/lib/hyprbazzite/hypr/monitors.lua`.

---

## Portal Configuration

### B-23: Portal config missing FileChooser and Screenshot interface routing

**Priority:** P2  
**Rationale:** `hyprland-portals.conf` only specifies `default=hyprland;gtk` and `org.freedesktop.impl.portal.Settings=gtk`. It doesn't explicitly route `Screenshot`, `ScreenCast`, or `FileChooser` interfaces. While the default fallback handles this, explicit routing prevents surprising behavior when multiple portal backends are installed (e.g. if xdg-desktop-portal-kde gets pulled in as a dependency).  
**Implementation:**

```ini
[preferred]
default=hyprland;gtk
org.freedesktop.impl.portal.Settings=gtk
org.freedesktop.impl.portal.FileChooser=gtk
org.freedesktop.impl.portal.Screenshot=hyprland
org.freedesktop.impl.portal.ScreenCast=hyprland
org.freedesktop.impl.portal.GlobalShortcuts=hyprland
```

File: `system_files/usr/lib/hyprbazzite/xdg/xdg-desktop-portal/hyprland-portals.conf`.

---

## Keyd Configuration

### B-24: keyd `macos.conf` is shipped but keyd is "retired" — dead config creates confusion

**Priority:** P1  
**Rationale:** `hyprbazzite-ctl` explicitly states "keyd has been retired" (line 298) and the `_apply_keyd()` function only REMOVES leftover keyd configs. The bindings.lua comments confirm "NO keyd remapping is used." Yet the repo still ships `system_files/usr/lib/hyprbazzite/keyd/macos.conf` AND the Containerfile installs `keyd` (line 83). The shipped `macos.conf` remaps Meta→Alt, Alt→Ctrl which would FIGHT the bindings.lua macOS profile if accidentally installed to `/etc/keyd/default.conf`.  
**Implementation:**
1. Remove `macos.conf` from the repo (it's no longer used).
2. Consider removing `keyd` from the Containerfile package list (unless other use cases exist).
3. At minimum, add a `# DEPRECATED` header if keeping for migration:

```bash
# If keeping for migration reference only:
rm system_files/usr/lib/hyprbazzite/keyd/macos.conf
# In Containerfile, remove 'keyd' from package list if no other consumers
```

Files: `system_files/usr/lib/hyprbazzite/keyd/macos.conf` (delete), `Containerfile` line 83.

---

## Autostart & Session Management

### B-25: autostart.lua launches processes without duplicate-prevention

**Priority:** P2  
**Rationale:** `autostart.lua` uses `hl.exec_cmd()` for all processes. If Hyprland is reloaded (not restarted), `hyprland.start` fires again and launches duplicates of waybar, swaync, swayidle, blueman-applet, nm-applet, etc. Only `nm-applet` has a pgrep guard (line 25). The others will stack up.  
**Implementation:** Add pgrep guards or use Hyprland's `exec-once` equivalent:

```lua
-- Helper to avoid duplicate spawns on reload
local function exec_once(cmd, process_name)
    process_name = process_name or cmd:match("^(%S+)")
    hl.exec_cmd(string.format("pgrep -x %s >/dev/null || %s", process_name, cmd))
end

-- Usage:
exec_once("waybar --config /etc/waybar/config.jsonc --style /etc/waybar/style.css", "waybar")
exec_once("swaync -c /etc/swaync/config.json -s /etc/swaync/style.css", "swaync")
exec_once("swayidle -C /etc/swayidle/config -w", "swayidle")
```

File: `system_files/usr/lib/hyprbazzite/hypr/autostart.lua`.

---

### B-26: autostart.lua `cursor-clip --daemon` depends on a binary that may not be built into the image

**Priority:** P1  
**Rationale:** Line 24 starts `cursor-clip --daemon` unconditionally. The only installation mechanism is `executable_install-cursor-clip.sh` which is a runtime installer (see B-11) that won't work on an immutable image. If cursor-clip isn't baked into the Containerfile, this autostart line silently fails every boot.  
**Implementation:** Either add cursor-clip to the Containerfile build (see B-11) or guard the exec:

```lua
if os.execute("command -v cursor-clip >/dev/null 2>&1") == 0 then
    hl.exec_cmd("cursor-clip --daemon")
end
```

File: `system_files/usr/lib/hyprbazzite/hypr/autostart.lua`, line 24.

---

## Path Inconsistency

### B-27: Scripts use mixed path conventions — `/etc/hypr/scripts/` vs `/usr/lib/hyprbazzite/hypr/scripts/`

**Priority:** P1  
**Rationale:** The tmpfiles.d config copies `/usr/lib/hyprbazzite/hypr` → `/etc/hypr` at boot. Scripts reference BOTH paths inconsistently:
- `bindings.lua`: `/etc/hypr/scripts/` (correct at runtime)
- `TritonCtl.sh`: `/usr/lib/hyprbazzite/hypr/scripts` (correct at source-level but wrong if called from `/etc/hypr/scripts/TritonCtl.sh` since `$SCRIPTS_DIR` won't point to the copy)
- `waybar-power-tdp-status.sh`: `/etc/hypr/scripts/tdp-control.sh` (runtime path)
- `hyprlock.conf`: `$Scripts = /etc/hypr/scripts` (runtime path)
- waybar config.jsonc: `/etc/hypr/scripts/` (runtime path, line 509)
- waybar logibattery: `/usr/lib/hyprbazzite/hypr/scripts/logibattery.sh` (source path)

The `C+` copy means `/etc/hypr/scripts/TritonCtl.sh` exists at runtime, but its internal `SCRIPTS_DIR="/usr/lib/hyprbazzite/hypr/scripts"` points back to the source tree. This works because both exist, but it's confusing and fragile.  
**Implementation:** Standardise on `/etc/hypr/scripts/` for all runtime references since that's the tmpfiles-guaranteed path:

```bash
# TritonCtl.sh line 8 -- change:
SCRIPTS_DIR="/usr/lib/hyprbazzite/hypr/scripts"
# to:
SCRIPTS_DIR="/etc/hypr/scripts"
```

Files: `system_files/usr/lib/hyprbazzite/hypr/scripts/TritonCtl.sh`, `system_files/usr/lib/hyprbazzite/waybar/config.jsonc` (logibattery line).

---

## Wallust / Theming

### B-28: `wallust-hyprland.conf` only defines color variables but hyprlock.conf sources it with no validation

**Priority:** P3  
**Rationale:** `hyprlock.conf` line 1: `source = /etc/hypr/wallust/wallust-hyprland.conf`. This file defines Dracula color variables (`$orange`, `$purple`, etc.). If wallust hasn't generated this file yet (first boot, no wallpaper set), hyprlock will fail to resolve the variables and either crash or render with missing colors. The file in the repo is a static Dracula fallback, which is fine, but the `source` path assumes the tmpfiles copy happened.  
**Implementation:** This is acceptable as-is since tmpfiles.d `C+` copies it. But add a comment noting the dependency:

```
# NOTE: This file is sourced by hyprlock.conf. If wallust regenerates it
# (via wallpaper.sh), the new colors apply on next lock. The static version
# in the repo serves as the Dracula fallback.
```

File: `system_files/usr/lib/hyprbazzite/hypr/wallust/wallust-hyprland.conf`.

---

## Miscellaneous

### B-29: `powermenu.sh` uses `rofi` but the rest of the system uses `wofi`

**Priority:** P2  
**Rationale:** `powermenu.sh` calls `rofi -dmenu` with a rofi-specific theme file. Every other interactive script (`chezmoi.sh`, `quicksettings.sh`, `wallpaper.sh`, `tdp-profile-selector.sh`, `TritonCtl.sh`) uses `wofi`. The Containerfile installs `wofi` (line 75) but rofi is not listed. If rofi isn't installed, the power menu silently fails.  
**Implementation:** Port to wofi for consistency:

```bash
#!/bin/bash
set -euo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
WOFI_CONFIG="$CONFIG_DIR/wofi/config"
OPTIONS="⏻ Shutdown\n Reboot\n Suspend\n⏾ Hybrid Sleep\n Lock\n Logout"

choice=$(echo -e "$OPTIONS" | wofi -dmenu -p "Power Menu" -i -config "$WOFI_CONFIG")

case "$choice" in
    *Shutdown*) systemctl poweroff ;;
    *Reboot*) systemctl reboot ;;
    *Suspend*) systemctl suspend ;;
    *Hybrid*) systemctl suspend-then-hibernate ;;
    *Lock*) hyprlock ;;
    *Logout*) hyprctl dispatch exit ;;
esac
```

File: `system_files/usr/lib/hyprbazzite/hypr/scripts/powermenu.sh`.

---

### B-30: `screenshot.sh` uses unquoted `$EDITOR` variable that conflicts with the standard env var

**Priority:** P1  
**Rationale:** Line 15 defines `EDITOR="satty --filename - ..."`. This shadows the standard `$EDITOR` environment variable (typically `vim` or `nano`). If any child process or sourced file checks `$EDITOR`, it gets a satty command string. The variable is also used unquoted in pipe chains (line 28: `| $EDITOR`), which breaks if the path contains spaces.  
**Implementation:** Rename to `SCREENSHOT_EDITOR` and quote properly:

```bash
# Rename throughout:
SCREENSHOT_EDITOR="satty --filename - --output-filename $OUTPUT_DIR/$FILENAME ..."

# Use with eval for the pipe (since it contains flags):
eval "$SCREENSHOT_EDITOR"
# Or better, use a function:
run_editor() {
    if command -v satty &>/dev/null; then
        satty --filename - --output-filename "$OUTPUT_DIR/$FILENAME" \
            --early-exit --actions-on-enter save-to-clipboard \
            --save-after-copy --copy-command wl-copy
    elif command -v swappy &>/dev/null; then
        swappy -f - -o "$OUTPUT_DIR/$FILENAME"
    else
        cat > "$OUTPUT_DIR/$FILENAME"
    fi
}
```

File: `system_files/usr/lib/hyprbazzite/hypr/scripts/screenshot.sh`.

---

### B-31: `quicksettings.sh` and `chezmoi.sh` reference a rofi theme but use wofi

**Priority:** P3  
**Rationale:** Both scripts define `ROFI_THEME="$CONFIG_DIR/rofi/config-tritonctl.rasi"` but then call `wofi -dmenu`. In `chezmoi.sh` line 13, it actually passes `-config "$ROFI_THEME"` to wofi — wofi ignores unknown flags, so this is silently broken (the custom theme is never applied). `quicksettings.sh` does it correctly (uses `WOFI_CONFIG`).  
**Implementation:** Fix `chezmoi.sh` to use the wofi config:

```bash
# chezmoi.sh -- replace:
ROFI_THEME="$CONFIG_DIR/rofi/config-tritonctl.rasi"
# with:
WOFI_CONFIG="$CONFIG_DIR/wofi/config"

# And replace the wofi call:
choice=$(echo -e "Yes\nNo" | $RUNNER -dmenu -p "Pull and apply chezmoi changes?" -i -config "$WOFI_CONFIG")
```

File: `system_files/usr/lib/hyprbazzite/hypr/scripts/chezmoi.sh`.

---

### B-32: `logibattery.sh` exits silently on missing headsetcontrol — waybar module shows nothing

**Priority:** P3  
**Rationale:** The script exits with code 1 if `headsetcontrol` isn't installed (line 5) or if parsing fails (line 13, 18). When used as a waybar `exec` module, exit code 1 with no stdout means waybar shows an empty module. It should output valid JSON indicating unavailability so waybar can display a proper state.  
**Implementation:**

```bash
#!/bin/bash
set -euo pipefail

BIN="/usr/bin/headsetcontrol"
if ! command -v "$BIN" &>/dev/null; then
    echo '{"text":"","tooltip":"headsetcontrol not installed","class":"unavailable"}'
    exit 0
fi
```

File: `system_files/usr/lib/hyprbazzite/hypr/scripts/logibattery.sh`.

---

### B-33: `disable-nonpower-wakeup.sh` runs as root with no guard against non-ACPI systems

**Priority:** P3  
**Rationale:** The script reads `/proc/acpi/wakeup` unconditionally. On systems without ACPI (some ARM devices, VMs), this file may not exist and the script will error out. Since it runs via a systemd service at boot, a failure here could delay boot or spam the journal.  
**Implementation:**

```bash
#!/usr/bin/env bash
set -euo pipefail

if [ ! -f /proc/acpi/wakeup ]; then
    echo "[wakeup-filter] No ACPI wakeup file found, skipping." >&2
    exit 0
fi
```

File: `system_files/usr/lib/hyprbazzite/hypr/scripts/disable-nonpower-wakeup.sh`, add after line 4.

---

### B-34: hyprland.lua hardcodes Dracula theme colors instead of using wallust variables

**Priority:** P3  
**Rationale:** `hyprland.lua` lines 5-6 set `active_border = "rgba(bd93f9ee)"` and `inactive_border = "rgba(44475aaa)"` — hardcoded Dracula purple/grey. The wallust integration (wallust-hyprland.conf) generates dynamic colors from the wallpaper, but the main border colors don't reference them. After a wallpaper change, borders stay static Dracula while the lock screen and waybar adapt.  
**Implementation:** Source the wallust config for border colors. Since this is Lua (not Hyprland conf syntax), you'd need to read the generated colors file, or switch borders to use the Hyprland `source` mechanism in a separate `.conf` snippet that wallust regenerates.

File: `system_files/usr/lib/hyprbazzite/hypr/hyprland.lua`, lines 5-6.

---

### B-35: `keybind-profile` file has 0666 permissions via tmpfiles — world-writable system config

**Priority:** P1  
**Rationale:** `hyprbazzite.conf` line 20: `C+ /etc/hypr/keybind-profile 0666 root root`. This makes the keybind profile file world-writable. While this is intentional (any user can switch profiles via `hyprbazzite-ctl keybinds toggle`), it allows any process (including a compromised sandboxed app) to silently change the system's keybind profile. On a single-user system this is low-risk, but it's a bad practice that could surprise multi-user setups.  
**Implementation:** Use 0664 (group-writable, assuming a `hypr` group) or use polkit for the write:

```
C+ /etc/hypr/keybind-profile 0664 root users - /usr/lib/hyprbazzite/hypr/keybind-profile
```

File: `system_files/usr/lib/tmpfiles.d/hyprbazzite.conf`, line 20.


---

# Part C -- Theming, Login (SDDM), Bar, Launcher, Notifications, Terminal & Shell

## C1 -- Theme Consistency & Color Source-of-Truth

### C1.1 Dracula Static Palette vs wallust Dynamic Colors -- Architectural Conflict

**Priority:** P0  
**Rationale:** The image ships two conflicting theming strategies simultaneously. The entire UI stack (waybar `style.css`, wofi `colors.css`, swaync `style.css`, kitty `dracula.conf`, dconf `00-dracula-theme`, GTK settings) hardcodes Dracula hex values. Meanwhile, `system_files/usr/lib/hyprbazzite/hypr/scripts/wallpaper.sh` calls `wallust run` which regenerates color templates dynamically from the current wallpaper. If a user invokes `wallpaper.sh` (exposed via swaync's buttons-grid "wallpaper" button), wallust overwrites whatever templates it's configured for -- but the hardcoded Dracula colors in waybar/wofi/swaync/kitty remain unchanged, creating a visual split between wallust-managed and static-Dracula components.  
**Implementation:** Choose one strategy:

- **Option A (recommended for immutable image):** Remove `wallust run` from `wallpaper.sh` entirely; keep static Dracula everywhere. The GIF wallpaper cycler (`wallpaper-cycle`) already ignores wallust -- aligning on static Dracula means no color drift.
- **Option B:** Go full wallust -- convert all CSS/config to wallust templates (`{{color0}}` syntax), ship wallust template files, and trigger regeneration on wallpaper change. This is significantly more complex on a bootc image where `/usr` is read-only at runtime.

```bash
# wallpaper.sh line 49-50 -- currently calls wallust unconditionally:
wallust run "$WALLUST_CURRENT_WALL" -s
hyprctl reload

# Option A fix: remove these two lines entirely, or guard behind a user toggle:
if [[ "${WALLUST_ENABLED:-0}" == "1" ]]; then
    wallust run "$WALLUST_CURRENT_WALL" -s
    hyprctl reload
fi
```

File: `system_files/usr/lib/hyprbazzite/hypr/scripts/wallpaper.sh`

---

### C1.2 Dual Wallpaper Systems -- wallpaper-cycle vs wallpaper.sh

**Priority:** P1  
**Rationale:** Two independent wallpaper mechanisms exist: `system_files/usr/bin/wallpaper-cycle` (auto-cycling GIF wallpapers from `/usr/share/backgrounds/gif_wallpapers` every 15 min via swww) and `system_files/usr/lib/hyprbazzite/hypr/scripts/wallpaper.sh` (user-triggered picker from `~/Pictures/wallpapers` with wallust integration). They can fight over `swww img` state -- whichever runs last wins. Neither is aware of the other.  
**Implementation:** Add mutual awareness -- when `wallpaper.sh` sets a static wallpaper, write a flag file that `wallpaper-cycle` checks before overwriting. Or expose a single unified interface.

```bash
# In wallpaper-cycle, before cycle_now():
if [[ -f "${XDG_RUNTIME_DIR}/wallpaper-pinned" ]]; then
    return 0  # User pinned a wallpaper via picker, skip auto-cycle
fi

# In wallpaper.sh handle_selection(), after setting wallpaper:
touch "${XDG_RUNTIME_DIR}/wallpaper-pinned"
```

Files: `system_files/usr/bin/wallpaper-cycle`, `system_files/usr/lib/hyprbazzite/hypr/scripts/wallpaper.sh`

---

### C1.3 Hardcoded Colors Scattered Across 8+ Files

**Priority:** P1  
**Rationale:** The Dracula palette is manually duplicated in: waybar `style.css` (`@define-color` block), wofi `colors.css` (`@define-color` block), wofi `style.css` (inline hex), swaync `style.css` (inline hex + `@define-color`), kitty `dracula.conf`, SDDM `Main.qml` (Qt.rgba values), dconf `00-dracula-theme`, and GTK `settings.ini`. If the project ever changes accent color or ships a second theme, every file needs manual updates. This is error-prone.  
**Implementation:** Create a single canonical palette file and generate the per-tool configs at image build time (e.g., via a Containerfile `RUN` step or a pre-build script).

```bash
# system_files/usr/lib/hyprbazzite/theme/palette.env
DRACULA_BG="#282a36"
DRACULA_FG="#f8f8f2"
DRACULA_CURRENT="#44475a"
DRACULA_COMMENT="#6272a4"
DRACULA_CYAN="#8be9fd"
DRACULA_GREEN="#50fa7b"
DRACULA_ORANGE="#ffb86c"
DRACULA_PINK="#ff79c6"
DRACULA_PURPLE="#bd93f9"
DRACULA_RED="#ff5555"
DRACULA_YELLOW="#f1fa8c"

# Build-time script generates wofi/colors.css, waybar vars, etc. from this source
```

Files: all theme-bearing files listed above

---

### C1.4 Flatpak Dark Mode Env Conflicts with GTK Theme Name

**Priority:** P2  
**Rationale:** `skel/.config/environment.d/flatpak-dark-mode.conf` sets `GTK_THEME=Adwaita:dark` for Flatpaks. But `skel/.config/gtk-3.0/settings.ini` sets `gtk-theme-name=Dracula`. Native GTK apps see Dracula; Flatpak sandboxed apps see Adwaita:dark (a completely different visual). This is intentional (Flatpaks can't access host themes) but creates visible inconsistency if a user installs a GTK Flatpak app alongside native ones.  
**Implementation:** Document this as expected behaviour. Optionally ship `org.gtk.Gtk3theme.Dracula` Flatpak extension or add `--filesystem=~/.themes` override in Flatpak global overrides so Flatpaks can also use Dracula.

```ini
# /var/lib/flatpak/overrides/global (or skel equivalent)
[Context]
filesystems=~/.themes:ro;~/.icons:ro

[Environment]
GTK_THEME=Dracula
```

File: `system_files/usr/lib/hyprbazzite/skel/.config/environment.d/flatpak-dark-mode.conf`

---

### C1.5 Qt5ct Points to Non-Verified Color Scheme Path

**Priority:** P2  
**Rationale:** `skel/.config/qt5ct/qt5ct.conf` references `color_scheme_path=/usr/share/qt5ct/colors/Dracula.conf`. If this file doesn't ship in the image (not present in `system_files/`), Qt5 apps fall back to a default palette that won't match Dracula.  
**Implementation:** Verify `Dracula.conf` is installed by a dependency package (e.g., `dracula-qt5ct-colors`). If not, ship it in the image.

```ini
# Verify in Containerfile:
RUN test -f /usr/share/qt5ct/colors/Dracula.conf || \
    echo "ERROR: Dracula Qt5 color scheme missing" && exit 1
```

File: `system_files/usr/lib/hyprbazzite/skel/.config/qt5ct/qt5ct.conf`

---

### C1.6 Starship Prompt Uses Non-Dracula Palette

**Priority:** P2  
**Rationale:** `skel/.config/starship.toml` uses a blue/grey gradient palette (`#a3aed2`, `#769ff0`, `#394260`, `#212736`, `#1d2230`) that has zero overlap with the Dracula palette used everywhere else. The prompt visually clashes with the kitty terminal (Dracula background `#282a36`) and waybar.  
**Implementation:** Retheme starship to use Dracula colors for visual coherence.

```toml
# starship.toml -- Dracula-aligned palette
format = """
[░▒▓](#bd93f9)\
[  ](bg:#bd93f9 fg:#282a36)\
[](bg:#6272a4 fg:#bd93f9)\
$directory\
[](bg:#44475a fg:#6272a4)\
$git_branch\
$git_status\
[](bg:#282a36 fg:#44475a)\
$nodejs\
$rust\
$golang\
$php\
[](bg:#21222c fg:#282a36)\
$time\
[ ](fg:#21222c)\
\n$character"""

[directory]
style = "fg:#f8f8f2 bg:#6272a4"
format = "[ $path ]($style)"
truncation_length = 3
truncation_symbol = "…/"

[git_branch]
symbol = ""
style = "bg:#44475a"
format = "[[ $symbol $branch ](fg:#8be9fd bg:#44475a)]($style)"

[git_status]
style = "bg:#44475a"
format = "[[($all_status$ahead_behind )](fg:#50fa7b bg:#44475a)]($style)"

[time]
disabled = false
time_format = "%R"
style = "bg:#21222c"
format = "[[  $time ](fg:#f8f8f2 bg:#21222c)]($style)"
```

File: `system_files/usr/lib/hyprbazzite/skel/.config/starship.toml`

---

## C2 -- SDDM / Login Screen

### C2.1 SDDM QML Security -- No Embedded Shell/Exec (Confirmed Safe)

**Priority:** P3 (informational)  
**Rationale:** Reviewed `Main.qml` (580+ lines). It contains no `Qt.createQmlObject`, no `Process {}`, no `exec()`, no `Qt.openUrlExternally()`, no `Loader` with dynamic sources. All logic is pure QML declarative with standard SDDM API calls (`sddm.login()`). No security concerns.  
**Implementation:** No action needed. Consider adding a comment header noting the security audit date.

```qml
// Main.qml -- Security: Audited 2026-07-24, no shell exec, no dynamic loading
```

File: `system_files/usr/share/sddm/themes/hyprlockish/Main.qml`

---

### C2.2 SDDM Theme Colors Are Hardcoded Qt.rgba -- Not Derivable

**Priority:** P1  
**Rationale:** The SDDM theme uses Qt.rgba floating-point values (e.g., `Qt.rgba(0.741, 0.576, 0.976, 0.6)` for purple, `Qt.rgba(0.545, 0.914, 0.992, 0.62)` for cyan). These are Dracula purple (#bd93f9) and cyan (#8be9fd) converted to 0-1 range, plus background `#0f1119` and UI accent `#1a1b28`. These don't derive from any shared source. If the theme ever changes, this QML needs manual edits.  
**Implementation:** Extract colors to `theme.conf` properties and read them in QML via `config.color_bg` etc., or at minimum document the hex↔rgba mapping.

```ini
# theme.conf -- add color properties
[General]
Name=Hyprlockish
# ...existing...

[Colors]
background=#0f1119
gradient_top=#1a1d2e
purple=0.741,0.576,0.976
cyan=0.545,0.914,0.992
panel_bg=#1a1b28
border=#3d3f52
accent=#bd93f9
text=#f8f8f2
green=#50fa7b
comment=#6272a4
```

```qml
// In Main.qml, read from theme.conf:
property color accentColor: config.accent || "#bd93f9"
```

File: `system_files/usr/share/sddm/themes/hyprlockish/theme.conf`, `Main.qml`

---

### C2.3 Duplicate SDDM Config Files -- Three Locations

**Priority:** P1  
**Rationale:** Three SDDM config drop-ins exist:
1. `usr/lib/hyprbazzite/sddm.conf.d/10-theme.conf` -- sets Theme=hyprlockish + ThemeDir
2. `usr/lib/hyprbazzite/sddm.conf.d/kde_settings.conf` -- sets Session=hyprland + Theme=hyprlockish
3. `usr/lib/sddm/sddm.conf.d/10-theme.conf` -- sets Theme=hyprlockish + ThemeDir

Files 1 and 3 are nearly identical but in different directories (`/usr/lib/hyprbazzite/sddm.conf.d/` vs `/usr/lib/sddm/sddm.conf.d/`). Only one location is read by SDDM (`/usr/lib/sddm/sddm.conf.d/` is the upstream drop-in path). The `hyprbazzite/sddm.conf.d/` files likely need symlinking or copying into the correct location during image build.  
**Implementation:** Consolidate to a single file in `/usr/lib/sddm/sddm.conf.d/` with all settings. Remove duplicates or confirm the Containerfile copies them to the right place.

```ini
# Single file: /usr/lib/sddm/sddm.conf.d/10-hyprbazzite.conf
[General]
Session=hyprland
Theme=hyprlockish

[Theme]
Current=hyprlockish
ThemeDir=/usr/share/sddm/themes
```

Files: `system_files/usr/lib/hyprbazzite/sddm.conf.d/10-theme.conf`, `system_files/usr/lib/hyprbazzite/sddm.conf.d/kde_settings.conf`, `system_files/usr/lib/sddm/sddm.conf.d/10-theme.conf`

---

### C2.4 SDDM Clock Doesn't Update -- Empty Timer onTriggered

**Priority:** P0  
**Rationale:** The QML has a `Timer { interval: 1000; running: true; repeat: true; onTriggered: {} }` -- the handler is empty. The clock text binding `Qt.formatDateTime(new Date(), "HH:mm")` is a one-time evaluation in QML (property bindings on `new Date()` don't auto-refresh). The clock will show the time when the login screen loaded and never update. The date and greeting widget have the same issue.  
**Implementation:** Add a property that the timer updates, and bind text to it.

```qml
// Add near top of root Rectangle:
property int tick: 0

Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: root.tick++
}

// Then in clock Text:
Text {
    // Force re-evaluation every second by depending on tick
    text: { void(root.tick); return Qt.formatDateTime(new Date(), "HH:mm"); }
    // ...
}
```

File: `system_files/usr/share/sddm/themes/hyprlockish/Main.qml`

---

### C2.5 SDDM Theme -- Math.random() Positions Not Seeded per Load

**Priority:** P3  
**Rationale:** Blob positions use `Math.random()` for initial x/y and animation targets. These are evaluated once at Component.onCompleted and never change. The blobs animate between two fixed random targets forever. This means the visual pattern is identical for the entire session but varies between SDDM restarts. This is fine aesthetically but worth noting: if a user briefly sees the login screen, logs out, and sees it again, the pattern will be different (re-evaluation on component reload).  
**Implementation:** No action required unless deterministic positioning is desired.

---

### C2.6 SDDM Login Error Feedback Missing

**Priority:** P1  
**Rationale:** The QML calls `sddm.login()` on button click and Enter key but never connects to `sddm.loginFailed` signal. If the user enters a wrong password, there's no visual feedback -- no error message, no field shake, no color change.  
**Implementation:** Add a `Connections` block for the `sddm` object.

```qml
Connections {
    target: sddm
    function onLoginFailed() {
        passwordInput.text = ""
        passwordBox.border.color = "#ff5555"
        errorText.visible = true
        errorTimer.start()
    }
}

// Add error text below password field:
Text {
    id: errorText
    visible: false
    text: "Authentication failed"
    color: "#ff5555"
    font.family: "JetBrains Mono, Symbols Nerd Font"
    font.pixelSize: 11
    anchors.horizontalCenter: parent.horizontalCenter
}

Timer {
    id: errorTimer
    interval: 3000
    onTriggered: {
        errorText.visible = false
        passwordBox.border.color = "#2a2d3a"
    }
}
```

File: `system_files/usr/share/sddm/themes/hyprlockish/Main.qml`

---

## C3 -- Waybar (Status Bar)

### C3.1 custom/temperature and custom/power-profiles-daemon -- Low Intervals

**Priority:** P1  
**Rationale:** `custom/temperature` polls every 10 seconds (exec: `/usr/libexec/hyprbazzite-ctl automation temp`). `custom/power-profiles-daemon` polls every **2 seconds** (exec: `bash /etc/hypr/scripts/waybar-power-tdp-status.sh`). The power-profiles poll is aggressively frequent for data that changes rarely (only on user action). Each poll forks a bash process + reads sysfs.  
**Implementation:** Increase `custom/power-profiles-daemon` interval to 10-30 seconds. Power profile changes are user-initiated -- use signal-based refresh instead.

```jsonc
"custom/power-profiles-daemon": {
    "return-type": "json",
    "exec": "bash /etc/hypr/scripts/waybar-power-tdp-status.sh",
    "interval": 30,
    "signal": 8,  // Send `pkill -RTMIN+8 waybar` after profile change
    "on-click": "/usr/libexec/hyprbazzite-ctl power profile",
    "on-click-right": "/usr/libexec/hyprbazzite-ctl tdp profile"
}
```

File: `system_files/usr/lib/hyprbazzite/waybar/config.jsonc`

---

### C3.2 custom/headset-battery -- 5-Second Interval for Battery Level

**Priority:** P2  
**Rationale:** `custom/headset-battery` runs `logibattery.sh` every 5 seconds. Headset battery levels change over minutes/hours, not seconds. This is 720 unnecessary process forks per hour.  
**Implementation:** Increase to 60-120 seconds.

```jsonc
"custom/headset-battery": {
    "format": "󰠇 {}%",
    "exec": "/usr/lib/hyprbazzite/hypr/scripts/logibattery.sh",
    "interval": 60,
    "on-click": "solaar",
    "return-type": "integer"
}
```

File: `system_files/usr/lib/hyprbazzite/waybar/config.jsonc`

---

### C3.3 exclusive: false -- Bar Overlaps Fullscreen AND Normal Windows

**Priority:** P1  
**Rationale:** `"exclusive": false` means waybar doesn't reserve screen space. Combined with `"hide-on-focus": true` this creates a bar that overlaps windows and hides on focus. If `hide-on-focus` fails or is slow, windows render under the bar. Users may find top UI elements of apps clipped.  
**Implementation:** Consider `"exclusive": true` with `"hide-on-focus": true` for a bar that reserves space when visible but hides gracefully. Or document the intended UX explicitly.

```jsonc
// If the intent is auto-hide:
"exclusive": true,
"hide-on-focus": true,
// This reserves space when visible, releases when hidden
```

File: `system_files/usr/lib/hyprbazzite/waybar/config.jsonc`

---

### C3.4 Clock Calendar Tooltip Colors Are Not Dracula

**Priority:** P2  
**Rationale:** The clock's calendar tooltip uses custom span colors: `#ffead3`, `#ecc6d9`, `#99ffdd`, `#ffcc66`, `#ff6699`. None of these are Dracula palette colors. They're pastel variants that visually clash with the rest of the bar.  
**Implementation:** Replace with Dracula equivalents.

```jsonc
"calendar": {
    "format": {
        "months":   "<span color='#f8f8f2'><b>{}</b></span>",
        "days":     "<span color='#bd93f9'><b>{}</b></span>",
        "weeks":    "<span color='#50fa7b'><b>W{:%V}</b></span>",
        "weekdays": "<span color='#f1fa8c'><b>{}</b></span>",
        "today":    "<span color='#ff79c6'><b><u>{}</u></b></span>"
    }
}
```

File: `system_files/usr/lib/hyprbazzite/waybar/config.jsonc`

---

### C3.5 Waybar Font Declaration Mismatch

**Priority:** P2  
**Rationale:** `style.css` declares `font-family: "Liberation Mono", "JetBrainsMono Nerd Font", monospace;` -- Liberation Mono is the primary font, JetBrainsMono Nerd Font is fallback. But the fontconfig (`50-jetbrains-mono.conf`) sets JetBrains Mono as the system monospace default. The SDDM theme and kitty both use JetBrains Mono as primary. Waybar should too for consistency.  
**Implementation:** Swap font order.

```css
* {
  font-family: "JetBrainsMono Nerd Font", "Liberation Mono", monospace;
  /* ... */
}
```

File: `system_files/usr/lib/hyprbazzite/waybar/style.css`

---

### C3.6 Waybar Modules Reference $HOME Scripts -- Fragile on Multi-User

**Priority:** P2  
**Rationale:** Multiple modules reference `$HOME/.config/hypr/scripts/` (battery, network, mpris). On an immutable image with skel-based provisioning, these scripts must exist in the user's home. If they're not shipped in skel, the modules silently fail. Cross-reference with skel contents -- these scripts are NOT in the skel tree.  
**Implementation:** Either: (a) move referenced scripts to `/usr/lib/hyprbazzite/hypr/scripts/` and update waybar config to use absolute paths, or (b) add them to skel.

```jsonc
// Instead of:
"on-click-right": "$HOME/.config/hypr/scripts/Wlogout.sh"
// Use:
"on-click-right": "/usr/lib/hyprbazzite/hypr/scripts/Wlogout.sh"
```

File: `system_files/usr/lib/hyprbazzite/waybar/config.jsonc`

---

### C3.7 custom/light_dark and custom/settings Have No on-click Action

**Priority:** P2  
**Rationale:** `custom/light_dark` (toggle light/dark) and `custom/settings` (settings) define format and tooltip but no `on-click` handler. They're decorative buttons that do nothing when clicked.  
**Implementation:** Wire them to actual commands or remove from the drawer.

```jsonc
"custom/light_dark": {
    "format": "󰔎",
    "on-click": "/usr/libexec/hyprbazzite-ctl theme toggle",
    "tooltip": true,
    "tooltip-format": "Toggle Light / Dark"
},
"custom/settings": {
    "format": "󰒓",
    "on-click": "nwg-look",
    "tooltip": true,
    "tooltip-format": "Settings"
}
```

File: `system_files/usr/lib/hyprbazzite/waybar/config.jsonc`

---

## C4 -- Wofi (Application Launcher)

### C4.1 Wofi Config References /etc/wofi/ but Files Live Elsewhere

**Priority:** P1  
**Rationale:** The waybar `custom/menu` module calls `wofi --conf /etc/wofi/config --style /etc/wofi/style.css`. But the actual files are at `system_files/usr/lib/hyprbazzite/wofi/`. Unless the Containerfile creates symlinks from `/etc/wofi/` to these paths, wofi will fail to find its config and use built-in defaults (no styling).  
**Implementation:** Verify that `/etc/wofi/` symlinks or copies exist in the built image. If not, update the waybar invocation or add symlinks.

```bash
# In Containerfile:
RUN ln -sf /usr/lib/hyprbazzite/wofi /etc/wofi
```

File: `system_files/usr/lib/hyprbazzite/waybar/config.jsonc` (wofi invocation)

---

### C4.2 Wofi colors.css Is Defined but Never Imported

**Priority:** P1  
**Rationale:** `system_files/usr/lib/hyprbazzite/wofi/colors.css` defines `@define-color` variables (`bg`, `fg`, `accent`, etc.) but `style.css` uses raw hex values (`#282a36`, `#bd93f9`, etc.) without an `@import` of `colors.css`. The colors.css file is dead code.  
**Implementation:** Either import it in style.css and use the variables, or delete colors.css.

```css
/* Top of style.css -- add import */
@import url("colors.css");

/* Then replace hardcoded values: */
window {
  border: 2px solid @accent;
  background-color: @bg;
}

#input {
  color: @fg;
  background-color: @bg_alt;
}
```

File: `system_files/usr/lib/hyprbazzite/wofi/style.css`, `system_files/usr/lib/hyprbazzite/wofi/colors.css`

---

### C4.3 Wofi vs Rofi -- wallpaper.sh References Both

**Priority:** P2  
**Rationale:** `wallpaper.sh` has `RUNNER="wofi"` with a fallback to rofi (line: `else choice=$(generate_list | $RUNNER -dmenu ... -theme "$ROFI_THEME")`). The image ships wofi config but no rofi config. If anyone changes `RUNNER` to rofi, it'll fail. Additionally, wofi is increasingly unmaintained upstream.  
**Implementation:** Remove the dead rofi code path, or consider migrating to `fuzzel` (actively maintained, Wayland-native, similar UX) as a future improvement.

```bash
# wallpaper.sh -- remove dead rofi branch:
choice=$(generate_list | wofi -dmenu -p "🖼️ Wallpaper" -i)
```

File: `system_files/usr/lib/hyprbazzite/hypr/scripts/wallpaper.sh`

---

## C5 -- SwayNC (Notifications)

### C5.1 SwayNC Style Uses Mix of @define-color and Hardcoded Hex

**Priority:** P2  
**Rationale:** `swaync/style.css` defines `@define-color cc-bg`, `@define-color noti-border-color`, `@define-color noti-bg`, etc. at the top but then uses raw hex (`#bd93f9`, `#f8f8f2`, `#282a36`) throughout the rest of the file. The `@define-color` variables are only partially used.  
**Implementation:** Replace all inline hex references with the defined variables for maintainability.

```css
/* Replace scattered #bd93f9 with @noti-border-color or a new @accent var */
.close-button {
    color: @noti-border-color;  /* was: #bd93f9 */
    border: 1px solid @noti-border-color;
}

.widget-title {
    color: @noti-border-color;  /* was: #bd93f9 */
}
```

File: `system_files/usr/lib/hyprbazzite/xdg/swaync/style.css`

---

### C5.2 SwayNC Notification Sound -- canberra-gtk-play Dependency

**Priority:** P2  
**Rationale:** `config.json` scripts section runs `canberra-gtk-play -i message` on every notification receive. If `libcanberra-gtk3` isn't installed in the image, notifications silently fail the sound (or worse, `script-fail-notify: true` causes recursive notification loops on failure).  
**Implementation:** Guard the sound script or verify the package is in the image manifest.

```json
"scripts": {
    "sound": {
        "exec": "command -v canberra-gtk-play >/dev/null && canberra-gtk-play -i message || true",
        "run-on": "receive"
    }
}
```

File: `system_files/usr/lib/hyprbazzite/xdg/swaync/config.json`

---

### C5.3 SwayNC Buttons-Grid Calls wallpaper-cycle Directly

**Priority:** P3  
**Rationale:** The buttons-grid has `"command": "wallpaper-cycle"` which launches the long-running daemon process. This is likely meant to trigger a single cycle, not start the daemon. If the daemon is already running (started at login), this spawns a second instance competing for swww control.  
**Implementation:** Send USR1 to the existing process instead.

```json
{
    "label": "󰏘",
    "command": "pkill -USR1 wallpaper-cycle || wallpaper-cycle &"
}
```

File: `system_files/usr/lib/hyprbazzite/xdg/swaync/config.json`

---

## C6 -- Terminal & Shell (Zsh, Kitty, Starship)

### C6.1 Oh-My-Zsh Not Shipped -- .zshrc Sources Non-Existent File

**Priority:** P0  
**Rationale:** `.zshrc` does `export ZSH="$HOME/.oh-my-zsh"` then `source "$ZSH/oh-my-zsh.sh"`. On a fresh user created from skel, `~/.oh-my-zsh/` won't exist unless it's installed during first-login. The `if [ -r ... ]` guard prevents a hard error, but all plugins (git, dnf, z, fzf, sudo, colored-man-pages, command-not-found) silently won't load. The user gets a bare zsh with no completions, no `z` jump, no fzf integration.  
**Implementation:** Either:
- Ship oh-my-zsh in the image at `/usr/share/oh-my-zsh` and point `ZSH` there
- Add a first-login script that installs it
- Replace oh-my-zsh with lighter alternatives already in the image (e.g., zsh-autosuggestions + zsh-syntax-highlighting packages)

```bash
# Option A: point to system-installed oh-my-zsh
export ZSH="/usr/share/oh-my-zsh"

# Option B: auto-install on first login (add to .zshrc before source):
if [[ ! -d "$ZSH" ]]; then
    git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$ZSH" 2>/dev/null
fi
```

File: `system_files/usr/lib/hyprbazzite/skel/.zshrc`

---

### C6.2 .zshrc Aliases Assume lsd Is Installed

**Priority:** P1  
**Rationale:** `alias ls='lsd'` -- if `lsd` isn't packaged in the image, every `ls` command fails. Same for `kitten ssh` (requires kitty's kitten binary on PATH).  
**Implementation:** Guard aliases behind command existence checks.

```bash
# ===== ALIASES =====
if command -v lsd >/dev/null 2>&1; then
    alias ls='lsd'
    alias l='ls -l'
    alias la='ls -a'
    alias lla='ls -la'
    alias lt='ls --tree'
fi

if command -v kitten >/dev/null 2>&1; then
    alias s='kitten ssh'
fi
```

File: `system_files/usr/lib/hyprbazzite/skel/.zshrc`

---

### C6.3 Kitty disable_ligatures Always -- Defeats Nerd Font Purpose

**Priority:** P2  
**Rationale:** `kitty.conf` sets `disable_ligatures always`. JetBrainsMono Nerd Font includes programming ligatures (e.g., `!=` → `≠`, `=>` → `⇒`) which many developers expect. Disabling all ligatures also disables Nerd Font icon composition in some contexts.  
**Implementation:** Change to `disable_ligatures cursor` (disables only under cursor for editing clarity) or remove the line entirely.

```conf
# Disable ligatures only under the cursor for editing clarity
disable_ligatures cursor
```

File: `system_files/usr/lib/hyprbazzite/skel/.config/kitty/kitty.conf`

---

### C6.4 Kitty scrollback_lines 4000 -- Low for Power Users

**Priority:** P3  
**Rationale:** Default kitty scrollback is 2000; this sets 4000. For build logs, long command output, etc., this fills quickly. Kitty uses negligible memory for scrollback (uses pager for overflow).  
**Implementation:** Increase to 10000 or use `scrollback_pager_history_size` for overflow.

```conf
scrollback_lines 10000
```

File: `system_files/usr/lib/hyprbazzite/skel/.config/kitty/kitty.conf`

---

### C6.5 QT_QPA_PLATFORMTHEME=gtk3 -- Correct but Fragile

**Priority:** P3  
**Rationale:** `.zshrc` exports `QT_QPA_PLATFORMTHEME=gtk3` which makes Qt apps follow GTK theme. This is correct for Dracula coherence but should be set in `environment.d/` (session-wide) not in `.zshrc` (only shell sessions). Qt apps launched from wofi/waybar won't inherit this if not also set session-wide.  
**Implementation:** Move to environment.d alongside the flatpak dark mode vars.

```ini
# system_files/usr/lib/hyprbazzite/skel/.config/environment.d/qt-theme.conf
QT_QPA_PLATFORMTHEME=gtk3
```

Then remove the `export QT_QPA_PLATFORMTHEME=gtk3` line from `.zshrc`.

Files: `system_files/usr/lib/hyprbazzite/skel/.zshrc`, new `environment.d/qt-theme.conf`

---

## C7 -- Font Configuration

### C7.1 Font Config -- No Sans-Serif Default Set

**Priority:** P2  
**Rationale:** `50-jetbrains-mono.conf` sets JetBrains Mono as the monospace default with Symbols Nerd Font fallback. But no configuration sets a default sans-serif or serif font. GTK settings reference "JetBrainsMono Nerd Font 11" for `gtk-font-name` (a monospace font as UI font), which is unusual -- most desktops use a proportional font for UI.  
**Implementation:** Consider setting a proportional UI font (e.g., Inter, Cantarell, or Noto Sans) for GTK/Qt widget text, keeping JetBrainsMono for terminals only.

```ini
# gtk-3.0/settings.ini and gtk-4.0/settings.ini:
gtk-font-name=Cantarell 11
# (or whatever proportional font ships in the image)
```

File: `system_files/usr/lib/hyprbazzite/skel/.config/gtk-3.0/settings.ini`, `gtk-4.0/settings.ini`

---

### C7.2 GTK settings.ini Has Leading Tab in Font Name

**Priority:** P1  
**Rationale:** Both `gtk-3.0/settings.ini` and `gtk-4.0/settings.ini` have `gtk-font-name=\tJetBrainsMono Nerd Font 11` (literal tab character before the font name). GTK may fail to parse this or look for a font named `\tJetBrainsMono...`.  
**Implementation:** Remove the leading whitespace.

```ini
gtk-font-name=JetBrainsMono Nerd Font 11
```

Files: `system_files/usr/lib/hyprbazzite/skel/.config/gtk-3.0/settings.ini`, `system_files/usr/lib/hyprbazzite/skel/.config/gtk-4.0/settings.ini`

---

## C8 -- Skel vs Live Config Drift (Immutable Image Gotcha)

### C8.1 Skel Only Applies to NEW Users -- Existing Users Never Get Updates

**Priority:** P0  
**Rationale:** On a bootc/ostree immutable image, `/etc/skel` (or the equivalent `usr/lib/hyprbazzite/skel/`) is copied to `$HOME` only at user creation time. After that, the user's home directory diverges permanently. Image updates that change starship.toml, kitty.conf, .zshrc, GTK settings, etc. will NEVER reach existing users. This is a fundamental design constraint that should be documented and mitigated.  
**Implementation:** 

1. **Document it** -- add a README or wiki note explaining this
2. **Split "defaults" from "overrides"** -- move configs that should track the image into `/usr/lib/hyprbazzite/` (read via `include` or `XDG_CONFIG_DIRS`) rather than skel. Only put truly one-time personalization seeds in skel.
3. **For kitty:** already uses `include dracula.conf` -- if `dracula.conf` is also in skel, it drifts. Better: ship at `/usr/share/kitty-themes/dracula.conf` and include from there.
4. **For waybar/wofi/swaync:** These already live in `/usr/lib/hyprbazzite/` and are referenced by absolute path in hyprland config -- good, they track the image.
5. **For .zshrc/starship:** These are the biggest drift risk. Consider a `/etc/zshrc.d/` sourcing pattern.

```bash
# .zshrc -- source image-managed snippets that survive updates:
for f in /usr/lib/hyprbazzite/zsh.d/*.zsh(N); do
    source "$f"
done
```

Files: all skel files

---

### C8.2 Skel GTK Settings Duplicate Information from dconf

**Priority:** P2  
**Rationale:** The Dracula theme, icon theme, and cursor theme are set in BOTH `dconf/db/distro.d/00-dracula-theme` (system dconf database, applies to all users at login) AND `skel/.config/gtk-3.0/settings.ini` + `gtk-4.0/settings.ini`. The dconf approach is correct for immutable images (it's a system default that applies without copying to home). The skel ini files are redundant for GNOME/GTK apps that read dconf. They're only needed for non-dconf GTK apps (rare on Wayland).  
**Implementation:** Keep dconf as the authoritative source. The skel ini files can remain as a fallback for edge cases but document why both exist.

File: `system_files/usr/lib/hyprbazzite/dconf/db/distro.d/00-dracula-theme`

---

### C8.3 Dconf Sets icon-theme=breeze-dark but No Cursor Size

**Priority:** P3  
**Rationale:** `00-dracula-theme` sets `cursor-theme='breeze_cursors'` but no `cursor-size`. GTK defaults to 24px; some HiDPI users need 32 or 48. The skel `gtk-3.0/settings.ini` sets `gtk-cursor-theme-size=0` which means "use default" -- this is fine but inconsistent between the two config sources.  
**Implementation:** Add `cursor-size=24` to dconf for explicitness.

```ini
[org/gnome/desktop/interface]
cursor-size=24
```

File: `system_files/usr/lib/hyprbazzite/dconf/db/distro.d/00-dracula-theme`

---

## C9 -- Mimeapps & Default Applications

### C9.1 Mimeapps References Flatpak Desktop Files -- Assumes Flatpaks Installed

**Priority:** P1  
**Rationale:** `mimeapps.list` references `app.zen_browser.zen.desktop`, `com.discordapp.Discord.desktop`, `com.github.IsmaelMartinez.teams_for_linux.desktop`, etc. These are Flatpak app IDs. If these Flatpaks aren't pre-installed in the image, the MIME associations are broken (clicking a URL does nothing, or falls through to an undefined handler).  
**Implementation:** Either ensure all referenced Flatpaks are pre-installed in the image, or add a fallback chain.

```ini
# Multi-handler fallback (first installed wins):
x-scheme-handler/http=app.zen_browser.zen.desktop;firefox.desktop;org.mozilla.firefox.desktop
x-scheme-handler/https=app.zen_browser.zen.desktop;firefox.desktop;org.mozilla.firefox.desktop
```

File: `system_files/usr/lib/hyprbazzite/xdg/mimeapps.list`

---

### C9.2 text/plain Opens in kitty-open -- Surprising for Non-Terminal Users

**Priority:** P3  
**Rationale:** `text/plain=kitty-open.desktop` means double-clicking a .txt file opens it inside kitty terminal. For a desktop-oriented image, most users expect a GUI text editor (mousepad, gedit, kate). This is a power-user default that may confuse newcomers.  
**Implementation:** Consider `mousepad.desktop` or `org.gnome.TextEditor.desktop` as the text/plain handler, with kitty-open available as an option.

File: `system_files/usr/lib/hyprbazzite/xdg/mimeapps.list`

---

## C10 -- Wallpaper Theming Integration

### C10.1 wallpaper-cycle Uses --filter Nearest -- Pixelated on Non-Native Res

**Priority:** P2  
**Rationale:** `wallpaper-cycle` passes `--filter Nearest` to swww. Nearest-neighbor scaling is ideal for pixel art GIFs but produces pixelation artifacts on photographic or smooth-gradient wallpapers displayed on monitors where the GIF resolution doesn't match native resolution.  
**Implementation:** Use `--filter Lanczos3` for general use, or make it configurable.

```bash
# wallpaper-cycle -- make filter configurable:
readonly FILTER="${WALLPAPER_FILTER:-Lanczos3}"
# ...
swww img ... --filter "$FILTER" "$wallpaper"
```

File: `system_files/usr/bin/wallpaper-cycle`

---

### C10.2 wallpaper.sh Depends on imagemagick (magick convert) Without Check

**Priority:** P1  
**Rationale:** `wallpaper.sh` line: `magick convert "$wall_path" "$wallust_png"`. If ImageMagick isn't installed, this fails silently (or with an unhelpful error via notify-send). The script checks for `jq` and `bc` but not `magick`.  
**Implementation:** Add to the dependency check.

```bash
if ! command -v jq &>/dev/null || ! command -v bc &>/dev/null || ! command -v magick &>/dev/null; then
    notify-send "TritonCtl" "Missing dependency: jq, bc, or imagemagick"
    exit 1
fi
```

File: `system_files/usr/lib/hyprbazzite/hypr/scripts/wallpaper.sh`

---

### C10.3 wallpaper.sh Uses Deprecated `magick convert` Syntax

**Priority:** P3  
**Rationale:** ImageMagick 7+ deprecates `magick convert` in favor of just `magick`. The `convert` subcommand is a legacy compatibility shim that may be removed in future versions.  
**Implementation:** Use `magick` directly.

```bash
magick "$wall_path" "$wallust_png"
```

File: `system_files/usr/lib/hyprbazzite/hypr/scripts/wallpaper.sh`
