#!/usr/bin/bash
set -euo pipefail

minimum_kernel=7.1.13
fedora_release=$(rpm -E '%{fedora}')
kernel_version=$(rpm -q --qf '%{VERSION}\n' kernel-core | sort -V | tail -n 1)

if ((fedora_release < 44)); then
  printf 'Fedora %s is too old; Fedora 44 or newer is required for supported IPU7 camera drivers.\n' "$fedora_release" >&2
  exit 1
fi

mapfile -t ordered_versions < <(printf '%s\n' "$minimum_kernel" "$kernel_version" | sort -V)
if [[ ${ordered_versions[0]} != "$minimum_kernel" ]]; then
  printf 'Kernel %s is too old; %s or newer is required for the Fedora IPU7 camera fix.\n' \
    "$kernel_version" "$minimum_kernel" >&2
  exit 1
fi

shopt -s globstar nullglob
for module_pattern in intel_cvs.ko\* intel-ipu7.ko\* ov08x40.ko\*; do
  matches=(/usr/lib/modules/*/kernel/**/$module_pattern)
  if ((${#matches[@]} == 0)); then
    printf 'Required camera module is missing: %s\n' "$module_pattern" >&2
    exit 1
  fi
done

rpm -q kernel-core libcamera pipewire-plugin-libcamera
printf 'Verified Fedora %s, kernel %s, and the IPU7 camera module set.\n' \
  "$fedora_release" "$kernel_version"
