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

## Update an existing workstation

Changes in this repository do not reach Fedora until they are committed and
pushed to `main` and the [image build](https://github.com/richardrh/fedora-wayblue/actions/workflows/build.yml)
has successfully published `ghcr.io/richardrh/fedora-sway:latest`.
On the Fedora machine, check the current deployment with `rpm-ostree status`.
If it already tracks the signed image above, update and boot the new deployment:

```bash
sudo rpm-ostree upgrade
sudo systemctl reboot
```

If it still tracks the stock Fedora image, follow **Install or rebase** above
instead. Changes in `~/dev/dotfiles` have a separate update path: push that
repository, then on Fedora fetch without applying, review, and apply:

```bash
chezmoi update --apply=false
chezmoi diff
chezmoi apply
```

`chezmoi apply` alone uses the locally cached source and does not fetch new
commits.

## User state and dotfiles

Personal configuration and version-sensitive language runtimes are intentionally not baked into the image. The BlueBuild chezmoi module installs chezmoi and enables its initialization and update services globally for all users.

On first login, the initialization service applies `https://github.com/richardrh/dotfiles` with the equivalent of `chezmoi init --apply`. Existing conflicting files are preserved. The repository must be publicly accessible for unattended initialization.

The dotfiles repository uses chezmoi source names such as `dot_bashrc`, `dot_gitconfig`, `dot_config/doom/`, `dot_config/ghostty/`, `dot_config/helix/`, and `dot_config/mise/`. `run_onchange_after_10-install-mise-tools.sh.tmpl` installs mise tools, and `run_onchange_after_20-install-doom.sh.tmpl` initializes Doom after files are applied.

Native PGTK Emacs is included. `bootstrap-doom-emacs` clones Doom into `~/.config/emacs` without touching the chezmoi-managed `~/.config/doom`.

Use `mise` from the dotfiles repository for Go, Rust, Python, Node, Java, and other version-sensitive developer tools.

## Launcher and Advantage2 keyboard

Fedora's Sway config sets `$mod` to `Mod4` (Super/Windows) and binds `$mod+d`
to Rofi's combined application/command launcher. Press **Super+D**, type an
application name, and press Enter. **Super+Return** opens a terminal;
**Super+Shift+C** reloads Sway's config. This image uses `rofi-wayland`, not
Wofi, and retains those Fedora bindings; `files/system/etc/rofi.rasi` styles
Rofi and enables application icons.

On an unmodified Kinesis Advantage2 in **Windows mode**, press the Windows
thumb key (the third of the four top thumb keys, left to right) with **D**.
To select Windows mode, hold **Program** and tap **F7** (`win`). In **PC mode**
(Program+F6), those thumb keys are Ctrl/Alt/Alt/Ctrl: there is no Windows key
there. If your keyboard is remapped, type **Program+Esc** in a text editor to
print its active layout and thumb-key mode before changing any Sway bindings.

Fedora's launcher definition and bindings are in `/etc/sway/config` on the
running machine. `swaymsg -t get_bindings` lists the active bindings if a
shortcut behaves differently.

If the shortcut fails, `rofi -show drun` opens the application launcher from
a terminal in the Sway session. See the [Fedora Sway default config](https://gitlab.com/fedora/sigs/sway/sway-config-fedora/-/raw/0.4.3/sway/config.in)
and [Kinesis Advantage2 support](https://kinesis-ergo.com/support/advantage2/)
for the upstream bindings and thumb-key modes.

## Runtime notes

- `k3s` is pinned, runs as a native system service with its own containerd, and uses Rancher's SELinux policy package.
- Podman remains independent. Its user socket is enabled; the `k3d` wrapper points Docker-API calls at that socket and never falls back to Docker Engine.
- Steel Helix is built from the pinned `steel-event-system` commit compatible with Steel 0.8.2. Checksum-pinned Steel, Forge, and language-server release binaries avoid rebuilding those tools; only `hx` is compiled in the isolated BlueBuild stage.
- Chezmoi initializes and updates each user's dotfiles through systemd user units; no separate image bootstrap script is used.
- Tailscale is enabled but unconfigured. Each machine must run `sudo tailscale up` itself.
- Builds run on every push to `main`, on manual dispatch, and daily. The signing module remains last and uses the existing `SIGNING_SECRET`; no private key is stored here.
