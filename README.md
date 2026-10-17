# Noctalia Sway developer workstation

[![bluebuild](https://github.com/richardrh/fedora-wayblue/actions/workflows/build.yml/badge.svg)](https://github.com/richardrh/fedora-wayblue/actions/workflows/build.yml)

A signed BlueBuild image combining [Wayblue Sway](https://github.com/wayblueorg/wayblue) with [Noctalia](https://noctalia.dev/). Noctalia provides the coordinated desktop shell; Sway retains its normal tiling workflow. Development toolchains, Podman/Kubernetes tooling, workstation applications, dotfiles setup, and 2x output scaling remain included.

Published image:

```text
ghcr.io/richardrh/fedora-sway:latest
```

Manual builds from branches other than `main` publish a signed **`:noctalia` preview**,
without replacing `:latest`. After a successful preview build, an installation
already using this repository's signing policy can try it with:

```bash
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/richardrh/fedora-sway:noctalia
sudo systemctl reboot
```

For a fresh Fedora installation, use `:noctalia` instead of `:latest` in both rebase
steps below. To return to the previous deployment, use `sudo rpm-ostree rollback`
and reboot.

## Desktop defaults

- Base: `ghcr.io/wayblueorg/sway:latest`.
- Noctalia owns the bar, launcher, settings panels, notifications, media/brightness OSDs, idle handling, lock screen and wallpaper. The `noctalia` RPM comes from Fedora.
- Sway starts `noctalia` once from `95-noctalia.conf`. Fedora's competing bar, media-key, and swayidle snippets are shadowed using its supported same-name config layering. Dunst/Mako D-Bus activation is removed and their packaged user services are masked.
- Application defaults come from Wayblue: Adwaita-dark, a dark color-scheme preference, and Papirus icons. Applications with their own themes, including personal editor and terminal configs, can differ.
- The file manager and archive tools also come from Wayblue.
- Login uses greetd with [Noctalia Greeter](https://github.com/noctalia-dev/noctalia-greeter) (from the Terra repo, restricted to that one package); SDDM is disabled. After first login, run **Settings → Security → Noctalia Greeter → Sync Now** in Noctalia to copy wallpaper, palette and monitor layout to the login screen. Boot-testing the greeter on real hardware is not covered by CI.
- `files/system/etc/sway/config.d/99-display.conf` retains `output * scale 2` for the workstation's 4K display. This scales every Sway output; it does not configure the login greeter (use Sync Now).
- Wayblue supports only `latest`. Its current image is built from Fedora Sway Atomic 44, so this image is already on Fedora 44. Keep Wayblue as the base rather than duplicating its Sway/SDDM integration directly on Fedora; `latest` will move to Fedora 45 only after Wayblue does.

### Desktop shortcuts

`Mod` is the Sway modifier (normally the Super/Windows key).

| Shortcut | Action |
| --- | --- |
| `Mod+d` | Noctalia application launcher |
| `Mod+comma` | Noctalia settings |
| `Mod+Alt+l` | Lock screen |
| Audio, microphone, media, brightness keys | Noctalia controls and OSDs |

Sway's normal tiling bindings, including `Mod+space` and `Mod+v`, stay unchanged.

### Existing installations

The preview requires the explicit `:noctalia` rebase above. Once these changes are
merged and successfully published from `main`, installations tracking
`ghcr.io/richardrh/fedora-sway:latest` need only `sudo rpm-ostree upgrade` and a
reboot.

Rebasing or upgrading does not reset your home directory. Existing
`~/.config/sway`, `~/.config/waybar`, `~/.config/rofi`, notification/lock configs,
or saved application appearance preferences can override the new defaults.
Back up and move aside any desktop overrides you no longer want before logging
in again. The public dotfiles repository currently leaves these desktop configs
to the image.

Remove personal autostarts for Waybar, Dunst/Mako, or swayidle/swaylock if you
want Noctalia to be their sole replacement. If you layered `noctalia` with
`rpm-ostree install`, run `rpm-ostree uninstall noctalia` after upgrading.

OSTree also preserves locally modified `/etc` files. If old components remain,
compare `/etc/sway/config.d` with the deployment's `/usr/etc/sway/config.d`.
In particular, the `90-bar.conf`, `90-swayidle.conf`, and media-key snippets
must use this image's replacements. The old `90-theme.conf` is no longer
supplied; retain `99-display.conf` if you still want 2x scaling.

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

   On an XPS with an Intel IPU7 camera, also verify that the active deployment
   contains Fedora's camera fix:

   ```bash
   rpm -q kernel-core
   modinfo intel_cvs
   ```

   The kernel must be 7.1.13 or newer and `intel_cvs` must resolve.

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
- Steel Helix is built from the pinned `steel-event-system` commit compatible with Steel 0.8.2, using its `code-gen` task. Checksum-pinned Steel, Forge, and language-server release binaries avoid rebuilding those tools; `hx` and its generation task are compiled in the isolated BlueBuild stage.
- Chezmoi initializes and updates each user's dotfiles through systemd user units; the first graphical login opens `workstation-setup` for interactive SSH, GitHub/GitLab, and Tailscale setup.
- Tailscale starts automatically; `workstation-setup` runs `sudo tailscale up` interactively because tailnet enrollment requires user authentication.
- Builds run on every push to `main`, on manual dispatch, and daily. The signing module remains last and uses the existing `SIGNING_SECRET`; no private key is stored here.
- The build fails before signing if the base is older than Fedora 44, the kernel is older than 7.1.13, or the `intel_cvs`, `intel_ipu7`, or `ov08x40` modules are absent. Chunked, squashed OCI output keeps the inherited Wayblue layer count below Docker's layer-depth limit; CI retries registry pushes and verifies installed packages.
- CI verifies the published image signature, starts its actual Sway configuration headlessly, exercises Noctalia launcher/settings/notification/lock interfaces, checks for competing shell processes, and uploads screenshots/logs as `noctalia-desktop-smoke`. This does not replace a boot test for greetd, hardware, or suspend/resume.
