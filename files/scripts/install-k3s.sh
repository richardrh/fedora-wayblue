#!/usr/bin/env bash
set -euo pipefail

K3S_VERSION=v1.36.3+k3s1
SELINUX_RPM=https://rpm.rancher.io/k3s/latest/common/centos/9/noarch/k3s-selinux-1.6-1.el9.noarch.rpm

# Install Rancher's actual policy package; do not suppress SELinux failures.
dnf5 install -y "$SELINUX_RPM"

curl -sfL https://get.k3s.io | \
  INSTALL_K3S_VERSION="$K3S_VERSION" \
  INSTALL_K3S_SKIP_START=true \
  INSTALL_K3S_SKIP_ENABLE=true \
  INSTALL_K3S_SKIP_SELINUX_RPM=true \
  INSTALL_K3S_BIN_DIR=/usr/bin \
  INSTALL_K3S_SYSTEMD_DIR=/usr/lib/systemd/system \
  INSTALL_K3S_EXEC="server --selinux" \
  sh -

rpm -q k3s-selinux >/dev/null
