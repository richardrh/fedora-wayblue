#!/usr/bin/env bash
set -euo pipefail

export GOBIN=/usr/bin
export CARGO_HOME=/var/tmp/cargo-install

# Go CLIs unavailable as Fedora 44 RPMs.
go install github.com/yorukot/superfile@v1.6.0
go install github.com/josephburnett/jd/v2/jd@v2.3.0
go install github.com/jesseduffield/lazydocker@v0.25.2
go install github.com/getsops/sops/v3/cmd/sops@v3.11.0
go install github.com/kopia/kopia@v0.22.3

# Yazi is built from its pinned crates; spf is superfile's upstream command name.
cargo install --locked --root /usr --version 26.8.15 yazi-fm yazi-cli
ln -s /usr/bin/spf /usr/bin/superfile

arch=$(uname -m)
case "$arch" in
  x86_64) goarch=amd64; denoarch=x86_64; bunarch=x64; graalarch=x64 ;;
  aarch64) goarch=arm64; denoarch=aarch64; bunarch=aarch64; graalarch=aarch64 ;;
  *) echo "unsupported architecture: $arch" >&2; exit 1 ;;
esac

# Pinned Kubernetes clients. k3d uses Podman's Docker-compatible user socket.
curl -fsSL -o /usr/bin/kubectl "https://dl.k8s.io/release/v1.36.3/bin/linux/${goarch}/kubectl"
curl -fsSL -o /usr/libexec/k3d "https://github.com/k3d-io/k3d/releases/download/v5.8.3/k3d-linux-${goarch}"
curl -fsSL -o /usr/bin/herdr "https://github.com/herdrdev/herdr/releases/download/v0.7.5/herdr-linux-${arch}"
chmod 0755 /usr/bin/kubectl /usr/libexec/k3d /usr/bin/herdr

# Node 24 is Fedora-provided. Keep stable global baseline package versions pinned.
npm install --global pnpm@11.22.0 typescript@7.0.2

# Bun and Deno are installed from their signed-release project artifacts.
tmp=$(mktemp -d)
curl -fsSL "https://github.com/oven-sh/bun/releases/download/bun-v1.4.0/bun-linux-${bunarch}.zip" -o "$tmp/bun.zip"
unzip -q "$tmp/bun.zip" -d "$tmp/bun"
install -m 0755 "$tmp/bun/bun-linux-${bunarch}/bun" /usr/bin/bun
curl -fsSL "https://github.com/denoland/deno/releases/download/v2.9.5/deno-${denoarch}-unknown-linux-gnu.zip" -o "$tmp/deno.zip"
unzip -q "$tmp/deno.zip" -d "$tmp/deno"
install -m 0755 "$tmp/deno/deno" /usr/bin/deno

# GraalVM is alongside, not selected over, the Temurin system JDK.
graal_version=25.2.4
graal_jdk=25.0.4
curl -fsSL "https://github.com/graalvm/graalvm-ce-builds/releases/download/graal-${graal_version}/graalvm-community-jdk-25i2-${graal_jdk}_linux-${graalarch}_bin.tar.gz" -o "$tmp/graalvm.tar.gz"
mkdir -p /usr/lib/jvm/graalvm-25
ntar=$(tar -tzf "$tmp/graalvm.tar.gz" | sed -n '1s,/.*,,p')
tar -xzf "$tmp/graalvm.tar.gz" -C /usr/lib/jvm/graalvm-25 --strip-components=1
ln -s /usr/lib/jvm/graalvm-25/bin/native-image /usr/bin/native-image

rm -rf "$tmp" "$CARGO_HOME" /root/go /root/.cache/go-build
