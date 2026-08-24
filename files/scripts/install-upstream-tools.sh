#!/usr/bin/env bash
set -euo pipefail

arch=$(uname -m)
case "$arch" in
  x86_64)
    goarch=amd64
    yaziarch=x86_64
    yazisha=cc67eb7991550c2f9407cda52d3f5af0937627aa6884e7de99a04fcf059807e0
    ;;
  aarch64)
    goarch=arm64
    yaziarch=aarch64
    yazisha=f5a85771f06bb0e8c488136ae0aedaec8d341a7cee995549df391d7d852fe8d1
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
curl -fsSL -o /usr/bin/kubectl "https://dl.k8s.io/release/v1.36.3/bin/linux/${goarch}/kubectl"
curl -fsSL -o /usr/libexec/k3d "https://github.com/k3d-io/k3d/releases/download/v5.8.3/k3d-linux-${goarch}"
chmod 0755 /usr/bin/kubectl /usr/libexec/k3d
