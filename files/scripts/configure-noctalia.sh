#!/usr/bin/env bash
set -euo pipefail

# Noctalia is started by the Sway config and owns org.freedesktop.Notifications.
# Remove packaged D-Bus activation for competing notification daemons.
for service in \
    /usr/share/dbus-1/services/org.knopwob.dunst.service \
    /usr/share/dbus-1/services/fr.emersion.mako.service; do
    rm -f "$service"
done

# Mask their user units only when a package actually supplied one.
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

# The greeter wrapper must exist where greetd's config expects it.
test -x /usr/bin/noctalia-greeter-session
