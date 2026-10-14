#!/usr/bin/env bash
set -euo pipefail

# DMS is started by the Sway config.  Remove packaged autostart paths that
# could claim org.freedesktop.Notifications before DMS gets to the session bus.
for service in \
    /usr/share/dbus-1/services/org.knopwob.dunst.service \
    /usr/share/dbus-1/services/fr.emersion.mako.service; do
    rm -f "$service"
done

# D-Bus service files can request systemd user activation.  Mask those units
# only when a package supplied one; do not create unrelated masks on images
# that do not contain the corresponding daemon.
for unit in dunst.service mako.service; do
    found=0
    for unit_dir in /usr/lib/systemd/user /usr/share/systemd/user /etc/systemd/user; do
        if [[ -e "$unit_dir/$unit" ]]; then
            found=1
            break
        fi
    done
    if (( found )); then
        mkdir -p /etc/systemd/user
        ln -sfn /dev/null "/etc/systemd/user/$unit"
    fi
done

# Do not leave a package preset/global enable for DMS: 95-dms.conf owns startup
# in Sway so another graphical session cannot start a second shell instance.
rm -f \
    /etc/systemd/user/graphical-session.target.wants/dms.service \
    /etc/systemd/user/default.target.wants/dms.service
