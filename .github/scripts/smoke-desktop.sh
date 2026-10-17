#!/usr/bin/env bash
set -euo pipefail

# Run as an unprivileged user in the built image, with /artifacts writable.
export HOME=/tmp/noctalia-smoke
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_RUNTIME_DIR="$HOME/runtime"
export WLR_BACKENDS=headless WLR_HEADLESS_OUTPUTS=1 WLR_RENDERER=pixman
export QT_QUICK_BACKEND=software QT_QPA_PLATFORM=wayland
export XDG_CURRENT_DESKTOP=sway XDG_SESSION_TYPE=wayland
mkdir -p "$XDG_CONFIG_HOME" "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

if [[ ${1:-} != session ]]; then
  exec dbus-run-session -- bash "$0" session
fi

cleanup() {
  local status=$?
  trap - EXIT
  if [[ -n ${SWAYSOCK:-} ]]; then swaymsg exit || true; fi
  if [[ -n ${sway_pid:-} ]]; then kill "$sway_pid" 2>/dev/null || true; fi
  exit "$status"
}
trap cleanup EXIT

sway --validate --config /etc/sway/config
sway --config /etc/sway/config --debug > /artifacts/sway.log 2>&1 &
sway_pid=$!
for ((attempt=0; attempt<60; attempt++)); do
  sockets=("$XDG_RUNTIME_DIR"/sway-ipc.*.sock)
  if [[ -S ${sockets[0]} ]]; then export SWAYSOCK=${sockets[0]}; break; fi
  kill -0 "$sway_pid"
  sleep 1
done
: "${SWAYSOCK:?Sway did not expose an IPC socket}"
export WAYLAND_DISPLAY=wayland-1
for socket in "$XDG_RUNTIME_DIR"/wayland-*; do
  if [[ -S $socket ]]; then export WAYLAND_DISPLAY=${socket##*/}; break; fi
done
swaymsg 'output HEADLESS-1 mode 3840x2160'
swaymsg -t get_outputs | tee /artifacts/outputs.json | jq -e 'any(.[]; .active and .scale == 2)'

ready=false
for ((attempt=0; attempt<90; attempt++)); do
  if noctalia msg panel-toggle launcher > /artifacts/ipc.log 2>&1; then ready=true; break; fi
  kill -0 "$sway_pid"
  sleep 1
done
[[ $ready == true ]]
sleep 3
grim /artifacts/launcher.png
noctalia msg panel-close
sleep 2
grim /artifacts/desktop.png
gdbus call --session --dest org.freedesktop.Notifications \
  --object-path /org/freedesktop/Notifications \
  --method org.freedesktop.Notifications.GetServerInformation \
  | tee /artifacts/notification-server.txt
gdbus call --session --dest org.freedesktop.Notifications \
  --object-path /org/freedesktop/Notifications \
  --method org.freedesktop.Notifications.Notify \
  workstation-smoke 0 "" "Noctalia desktop ready" \
  "Notifications are served by the desktop shell." '[]' '{}' 10000
sleep 2
grim /artifacts/notification.png
noctalia msg settings-open
sleep 2
grim /artifacts/settings.png

if pgrep -x 'waybar|swaybar|dunst|mako|swayidle'; then
  echo 'A competing desktop component is running' >&2
  exit 1
fi

noctalia msg session lock
sleep 3
pgrep -x noctalia
printf 'Sway output scaling, Noctalia launcher/settings/lock IPC, and shell exclusivity passed.\n'
