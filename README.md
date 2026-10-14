# Wayblue Sway developer workstation

[![bluebuild](https://github.com/richardrh/fedora-wayblue/actions/workflows/build.yml/badge.svg)](https://github.com/richardrh/fedora-wayblue/actions/workflows/build.yml)

A signed BlueBuild image based on [Wayblue Sway](https://github.com/wayblueorg/wayblue). The desktop inherits Wayblue's defaults as a whole, with only 2x output scaling added locally. Development toolchains, Podman/Kubernetes tooling, workstation applications, and dotfiles setup remain layered on top.

Published image:

```text
ghcr.io/richardrh/fedora-sway:latest
```

## Desktop defaults

- Base: `ghcr.io/wayblueorg/sway:latest`, using Wayblue's recommended SDDM variant.
- Wayblue owns the Sway session, Waybar, Rofi, notifications, screen lock, and login-screen defaults. This repository does not overlay a separate desktop theme.
- Application defaults come from Wayblue: Adwaita-dark, a dark color-scheme preference, and Papirus icons. Applications with their own themes, including personal editor and terminal configs, can differ.
- The file manager and archive tools also come from Wayblue.
- `files/system/etc/sway/config.d/99-display.conf` retains `output * scale 2` for the workstation's 4K display. This scales every Sway output; it does not configure the SDDM greeter.
- Wayblue supports only `latest`, so the Fedora release follows upstream rather than staying pinned to Fedora 44. The published workstation image remains `ghcr.io/richardrh/fedora-sway:latest`.

### Existing installations

Once the new image is published, installations already tracking
`ghcr.io/richardrh/fedora-sway:latest` need only `sudo rpm-ostree upgrade` and a
reboot, not a different image URL.

Rebasing or upgrading does not reset your home directory. Existing
`~/.config/sway`, `~/.config/waybar`, `~/.config/rofi`, notification/lock configs,
or saved application appearance preferences can override the new defaults.
Back up and move aside any desktop overrides you no longer want before logging
in again. The public dotfiles repository currently leaves these desktop configs
to the image.

OSTree also preserves locally modified `/etc` files. If old styling remains,
compare `/etc/rofi.rasi`, `/etc/xdg/waybar`, and `/etc/sway/config.d` with the new
deployment's `/usr/etc` defaults. The old `90-theme.conf` is no longer supplied;
retain `99-display.conf` if you still want 2x scaling. Do not copy the old
Catppuccin overrides back over Wayblue's defaults.

## Fresh install from USB

This repository publishes a signed OCI/ostree image to GHCR; it does not
currently publish its own installable ISO or USB image. Start with the official
[Fedora Sway Atomic download](https://fedoraproject.org/atomic-desktops/sway/download).
Write the downloaded ISO to a USB drive with
[Fedora Media Writer](https://fedoramagazine.org/how-to-use-fedora-media-writer/)
or an equivalent image-writing tool, boot it in UEFI mode, and install Fedora
Sway Atomic normally.

After the first boot:

1. Connect to the network and update the base deployment:

   ```bash
   sudo rpm-ostree upgrade
   sudo systemctl reboot
   ```

2. Rebase to the unsigned transport once. This deploys the custom image's
   signing policy and public key:

   ```bash
   sudo rpm-ostree rebase \
     ostree-unverified-registry:ghcr.io/richardrh/fedora-sway:latest
   sudo systemctl reboot
   ```

3. After reboot, switch to the signature-enforced transport:

   ```bash
   sudo rpm-ostree rebase \
     ostree-image-signed:docker://ghcr.io/richardrh/fedora-sway:latest
   sudo systemctl reboot
   ```

   Keep both reboots: Wayblue provisions the SDDM user during the initial boot.

4. Confirm the active deployment:

   ```bash
   rpm-ostree status
   ```

On the first graphical login, the image initializes the public
[dotfiles repository](https://github.com/richardrh/dotfiles), installs the
configuration and tools, then opens the interactive `workstation-setup`
terminal for SSH keys, GitHub/GitLab CLI authentication, and Tailscale
enrollment.

If the custom image is unavailable or a rebase fails, return to the previous
deployment with:

```bash
sudo rpm-ostree rollback
sudo systemctl reboot
```

## Install or rebase

Rebase once to the unsigned transport so the image's signing policy and public key are deployed:

```bash
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/richardrh/fedora-sway:latest
sudo systemctl reboot
```

After reboot, move to the signature-enforced image and reboot again:

```bash
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/richardrh/fedora-sway:latest
sudo systemctl reboot
```

Verify a published image independently with the repository public key:

```bash
cosign verify --key cosign.pub ghcr.io/richardrh/fedora-sway
```

## User state and dotfiles

Personal configuration and version-sensitive language runtimes are intentionally not baked into the image. The BlueBuild chezmoi module installs chezmoi and enables its initialization and update services globally for all users.

On first login, the initialization service applies `https://github.com/richardrh/dotfiles` with the equivalent of `chezmoi init --apply`. Existing conflicting files are preserved. The repository must be publicly accessible for unattended initialization.

The dotfiles repository uses chezmoi source names such as `dot_bashrc`, `dot_gitconfig`, `dot_config/doom/`, `dot_config/ghostty/`, `dot_config/helix/`, and `dot_config/mise/`. `run_onchange_after_05-install-doom.sh.tmpl` initializes Doom, `run_once_after_03-install-nerd-font.sh.tmpl` ensures JetBrainsMono Nerd Font is installed, and `run_onchange_after_10-install-mise-tools.sh.tmpl` installs all mise-managed tools, including Oh My Pi and Herdr.

Native PGTK Emacs is included. `bootstrap-doom-emacs` clones Doom into `~/.config/emacs` without touching the chezmoi-managed `~/.config/doom`.

Use `mise` from the dotfiles repository for Go, Rust, Python, Node, Java, and other version-sensitive developer tools.

## Runtime notes

- `k3s` is pinned, runs as a native system service with its own containerd, and uses Rancher's SELinux policy package.
- Podman remains independent. Its user socket is enabled; the `k3d` wrapper points Docker-API calls at that socket and never falls back to Docker Engine.
- Steel Helix is built from the pinned `steel-event-system` commit compatible with Steel 0.8.2. Checksum-pinned Steel, Forge, and language-server release binaries avoid rebuilding those tools; only `hx` is compiled in the isolated BlueBuild stage.
- Chezmoi initializes and updates each user's dotfiles through systemd user units; the first graphical login opens `workstation-setup` for interactive SSH, GitHub/GitLab, and Tailscale setup.
- Tailscale starts automatically; `workstation-setup` runs `sudo tailscale up` interactively because tailnet enrollment requires user authentication.
- Builds run on every push to `main`, on manual dispatch, and daily. The signing module remains last and uses the existing `SIGNING_SECRET`; no private key is stored here.
