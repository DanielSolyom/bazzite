#!/usr/bin/env bash

source /usr/lib/ublue/setup-services/libsetup.sh

version-script custom-flatpaks privileged 1 || exit 0

# Preinstalled apps for this machine: browser + password manager.
# Idempotent — flatpak install is a no-op for apps already present.
flatpak install --system --noninteractive flathub \
	com.brave.Browser com.onepassword.OnePassword
