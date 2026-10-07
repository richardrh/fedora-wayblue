# Fedora Sway Atomic developer workstation

[![bluebuild](https://github.com/richardrh/fedora-wayblue/actions/workflows/build.yml/badge.svg)](https://github.com/richardrh/fedora-wayblue/actions/workflows/build.yml)

A signed BlueBuild image based on Fedora 44 Sway Atomic. It retains Fedora's Sway, Waybar, Rofi, notification, and keybinding defaults while adding 2x output scaling, light Catppuccin Mocha styling, development toolchains, Podman/Kubernetes tooling, and workstation applications.

Published image:

```text
ghcr.io/richardrh/fedora-sway:latest
```

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
