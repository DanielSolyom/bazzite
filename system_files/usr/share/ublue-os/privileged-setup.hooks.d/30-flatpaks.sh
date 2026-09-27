#!/usr/bin/env bash

source /usr/lib/ublue/setup-services/libsetup.sh

version-script custom-flatpaks privileged 3 || exit 0

# The Bazzite ISO installs Firefox into /var/lib/flatpak; the image cannot,
# because flatpaks are not part of it. Remove it here instead.
flatpak uninstall --system --noninteractive --delete-data org.mozilla.firefox || :

# Preinstalled apps for this machine: browser + password manager.
# Idempotent — flatpak install is a no-op for apps already present.
flatpak install --system --noninteractive flathub \
	com.brave.Browser com.onepassword.OnePassword

# Keep X11 available alongside Wayland for 1Password's clipboard access.
flatpak override --system --nosocket=fallback-x11 com.onepassword.OnePassword
