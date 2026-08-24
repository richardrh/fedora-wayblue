# Fedora Sway Atomic developer workstation

[![bluebuild](https://github.com/richardrh/fedora-wayblue/actions/workflows/build.yml/badge.svg)](https://github.com/richardrh/fedora-wayblue/actions/workflows/build.yml)

A signed BlueBuild image based on Fedora 44 Sway Atomic. It retains Fedora's Sway, Waybar, Rofi, notification, and keybinding defaults while adding 2x output scaling, light Catppuccin Mocha styling, development toolchains, Podman/Kubernetes tooling, and workstation applications.

Published image:

```text
ghcr.io/richardrh/fedora-sway:latest
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

The dotfiles repository uses chezmoi source names such as `dot_bashrc`, `dot_gitconfig`, `dot_config/doom/`, `dot_config/ghostty/`, `dot_config/helix/`, and `dot_config/mise/`. `run_once_after_10-mise-install.sh` and `run_once_after_20-doom-install.sh` install mise tools and initialize Doom after files are applied.

Native PGTK Emacs is included. `bootstrap-doom-emacs` clones Doom into `~/.config/emacs` without touching the chezmoi-managed `~/.config/doom`.

Use `mise` from the dotfiles repository for Go, Rust, Python, Node, Java, and other version-sensitive developer tools.

## Runtime notes

- `k3s` is pinned, runs as a native system service with its own containerd, and uses Rancher's SELinux policy package.
- Podman remains independent. Its user socket is enabled; the `k3d` wrapper points Docker-API calls at that socket and never falls back to Docker Engine.
- Steel Helix is built from the pinned `steel-event-system` commit compatible with Steel 0.8.2. Checksum-pinned Steel, Forge, and language-server release binaries avoid rebuilding those tools; only `hx` is compiled in the isolated BlueBuild stage.
- Chezmoi initializes and updates each user's dotfiles through systemd user units; no separate image bootstrap script is used.
- Tailscale is enabled but unconfigured. Each machine must run `sudo tailscale up` itself.
- Builds run on every push to `main`, on manual dispatch, and daily. The signing module remains last and uses the existing `SIGNING_SECRET`; no private key is stored here.
