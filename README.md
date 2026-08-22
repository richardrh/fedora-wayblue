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

Personal configuration is intentionally not baked into the image. GNU Stow is installed for a separate dotfiles repository:

```bash
git clone git@github.com:richardrh/dotfiles.git ~/dotfiles
cd ~/dotfiles
stow bash nvim doom ghostty helix git
```

Native PGTK Emacs is included. `bootstrap-doom-emacs` clones Doom into `~/.config/emacs` without touching `~/.config/doom`; run Doom's installer after stowing the user's Doom configuration.

`mise` is installed only for repository-local version overrides. Baseline languages and commands are available without `mise install`.

## Runtime notes

- `k3s` is pinned, runs as a native system service with its own containerd, and uses Rancher's SELinux policy package.
- Podman remains independent. Its user socket is enabled; the `k3d` wrapper points Docker-API calls at that socket and never falls back to Docker Engine.
- Steel Helix is built from Matthew Paras's pinned `steel-event-system` commit in an isolated BlueBuild stage. Only `hx`, `steel`, `forge`, `steel-language-server`, and the Helix runtime are copied into the final image.
- Tailscale is enabled but unconfigured. Each machine must run `sudo tailscale up` itself.
- Builds run on every push to `main`, on manual dispatch, and daily. The signing module remains last and uses the existing `SIGNING_SECRET`; no private key is stored here.
