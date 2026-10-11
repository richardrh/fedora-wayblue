#!/usr/bin/env bash
set -euo pipefail

arch=$(uname -m)
case "$arch" in
  x86_64)
    goarch=amd64
    yaziarch=x86_64
    yazisha=cc67eb7991550c2f9407cda52d3f5af0937627aa6884e7de99a04fcf059807e0
    kubectlsha=ebbd080e7c2e275093b55915722043257eb24004363e20acb3c4d71919f88336
    k3dsha=dbaa79a76ace7f4ca230a1ff41dc7d8a5036a8ad0309e9c54f9bf3836dbe853e
    ;;
  aarch64)
    goarch=arm64
    yaziarch=aarch64
    yazisha=f5a85771f06bb0e8c488136ae0aedaec8d341a7cee995549df391d7d852fe8d1
    kubectlsha=3d86f24401c41ae5a46ac50eef8865fe891d3647d324a0836f6c63757a126e62
    k3dsha=0b8110f2229631af7402fb828259330985918b08fefd38b7f1b788a1c8687216
    ;;
  *) echo "unsupported architecture: $arch" >&2; exit 1 ;;
esac

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# This Yazi release is distributed as binaries but is not published to crates.io.
yazi_version=26.8.15
curl -fsSL \
  "https://github.com/sxyazi/yazi/releases/download/v${yazi_version}/yazi-${yaziarch}-unknown-linux-gnu.zip" \
  -o "$tmp/yazi.zip"
printf '%s  %s\n' "$yazisha" "$tmp/yazi.zip" | sha256sum --check --status
unzip -q "$tmp/yazi.zip" -d "$tmp/yazi"
install -m 0755 "$tmp/yazi/yazi-${yaziarch}-unknown-linux-gnu/yazi" /usr/bin/yazi
install -m 0755 "$tmp/yazi/yazi-${yaziarch}-unknown-linux-gnu/ya" /usr/bin/ya

# Pinned Kubernetes clients. k3d uses Podman's Docker-compatible user socket.
curl -fsSL -o "$tmp/kubectl" "https://dl.k8s.io/release/v1.36.3/bin/linux/${goarch}/kubectl"
printf '%s  %s\n' "$kubectlsha" "$tmp/kubectl" | sha256sum --check --status
install -m 0755 "$tmp/kubectl" /usr/bin/kubectl
curl -fsSL -o "$tmp/k3d" "https://github.com/k3d-io/k3d/releases/download/v5.8.3/k3d-linux-${goarch}"
printf '%s  %s\n' "$k3dsha" "$tmp/k3d" | sha256sum --check --status
install -m 0755 "$tmp/k3d" /usr/libexec/k3d
