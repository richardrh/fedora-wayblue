#!/usr/bin/env bash
set -euo pipefail

HELIX_COMMIT=111fed238821163ac571f52b360fa5029c78448c

apt-get update
apt-get install -y --no-install-recommends git ca-certificates pkg-config libssl-dev clang cmake
rm -rf /var/lib/apt/lists/*

git clone --filter=blob:none https://github.com/mattwparas/helix.git /src/helix
git -C /src/helix checkout "$HELIX_COMMIT"
cd /src/helix
export CARGO_BUILD_JOBS="$(nproc)"
export CARGO_PROFILE_RELEASE_LTO=off
export CARGO_PROFILE_RELEASE_CODEGEN_UNITS=16
export CARGO_INCREMENTAL=0
cargo xtask steel

install -d /out/bin /out/lib64/helix
for binary in hx steel forge steel-language-server; do
  install -m 0755 "/usr/local/cargo/bin/$binary" "/out/bin/$binary"
done
cp -a runtime/. /out/lib64/helix/runtime/
