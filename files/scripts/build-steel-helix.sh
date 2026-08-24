#!/usr/bin/env bash
set -euo pipefail

HELIX_COMMIT=77978be9dd87402dbb3a9dc59fe29124d9baefdc
STEEL_VERSION=0.8.2

apt-get update
apt-get install -y --no-install-recommends git ca-certificates curl xz-utils pkg-config libssl-dev clang cmake
rm -rf /var/lib/apt/lists/*

case "$(uname -m)" in
  x86_64)
    target=x86_64-unknown-linux-gnu
    steel_sha256=d0334d14168df4b88bb16bd4dbdfe03ab4bac147122f1be0c2ec5f083bf726fe
    forge_sha256=11bafc23cf8a93655fbfc9a06d7cf0015173ad8b40abd999b26d496e27cadd70
    lsp_sha256=d6cbc621cb76d132f91236acbba41868a0d84e95aaa412c0bd07e7ca0460810a
    ;;
  aarch64)
    target=aarch64-unknown-linux-gnu
    steel_sha256=151f9380b0bcdee0314dc884a8fa461da099785d201b503c2657a42c44d22ac8
    forge_sha256=21f6c903b5325e9953af9e5c05c5bfe4152ccc10b28bcc2c8c726c1fd0bb9654
    lsp_sha256=a09f8ce8fad3e9552d0c461c23307652681e6e7776f40c40a42a999191c68e8a
    ;;
  *)
    echo "Unsupported architecture: $(uname -m)" >&2
    exit 1
    ;;
esac

install_release() {
  local package=$1 binary=$2 checksum=$3 archive="/tmp/${package}.tar.xz"
  local url="https://github.com/mattwparas/steel/releases/download/v${STEEL_VERSION}/${package}-${target}.tar.xz"

  curl --fail --location --retry 3 --output "$archive" "$url"
  printf '%s  %s\n' "$checksum" "$archive" | sha256sum --check --strict
  tar -xJf "$archive" --strip-components=1 -C /usr/local/cargo/bin "${package}-${target}/${binary}"
  rm -f "$archive"
}

install_release steel-interpreter steel "$steel_sha256"
install_release steel-forge forge "$forge_sha256"
install_release steel-language-server steel-language-server "$lsp_sha256"

git clone --filter=blob:none https://github.com/mattwparas/helix.git /src/helix
git -C /src/helix checkout "$HELIX_COMMIT"
cd /src/helix
export CARGO_BUILD_JOBS="$(nproc)"
export CARGO_PROFILE_RELEASE_LTO=off
export CARGO_PROFILE_RELEASE_CODEGEN_UNITS=16
export CARGO_INCREMENTAL=0
cargo run --release --package xtask -- codegen
cargo build --release --package helix-term --features steel,git --locked

install -d /out/bin /out/lib64/helix
install -m 0755 target/release/hx /out/bin/hx
for binary in steel forge steel-language-server; do
  install -m 0755 "/usr/local/cargo/bin/$binary" "/out/bin/$binary"
done
cp -a runtime/. /out/lib64/helix/runtime/
