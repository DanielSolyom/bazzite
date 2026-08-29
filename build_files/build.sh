#!/bin/bash

set -ouex pipefail

### 1 · system files (undervolt unit, kargs, modprobe, NM conf, first-boot hook)
cp -avf /ctx/system_files/. /

### 2 · identity plumbing (NOT branding) — rollback/rebase tooling tracks our ref
IMAGE_NAME="bazzite"
IMAGE_REF="ostree-image-signed:docker://ghcr.io/danielsolyom/bazzite"
jq --arg ref "$IMAGE_REF" --arg name "$IMAGE_NAME" \
	'.["image-name"]=$name | .["image-ref"]=$ref' \
	/usr/share/ublue-os/image-info.json >/tmp/image-info.json
mv /tmp/image-info.json /usr/share/ublue-os/image-info.json

### 3 · trust our own signature — upgrades verify against this key after the switch
install -D -m 0644 /ctx/cosign.pub /etc/pki/containers/danielsolyom.pub
install -d /etc/containers/registries.d
cat >/etc/containers/registries.d/ghcr.io-danielsolyom.yaml <<'EOF'
docker:
  ghcr.io/danielsolyom:
    use-sigstore-attachments: true
EOF
jq '.transports.docker["ghcr.io/danielsolyom"] = [{
      "type": "sigstoreSigned",
      "keyPath": "/etc/pki/containers/danielsolyom.pub",
      "signedIdentity": {"type": "matchRepository"}
    }]' /etc/containers/policy.json >/tmp/policy.json
mv /tmp/policy.json /etc/containers/policy.json

### 4 · debloat — see docs/debloat.md
# disables first: vgauthd's unit is gone once open-vm-tools is removed
systemctl disable vboxservice vgauthd sssd mdmonitor lvm2-monitor \
	iscsi-onboot iscsi-starter ds-inhibit bazzite-tdpfix \
	pipewire-workaround wireplumber-workaround bazzite-iwd-migration \
	NetworkManager-wait-online
systemctl mask raid-check.timer
dnf5 remove -y --no-autoremove \
	open-vm-tools qemu-guest-agent intel-lpmd ModemManager mcelog \
	containerd.io 'docker-*' lutris \
	libvirt-daemon-driver-libxl libvirt-daemon-driver-lxc \
	libvirt-daemon-driver-vbox libvirt-daemon-driver-ch

### 5 · flatpak policy — Brave is the browser; Firefox is blocked at the remote
echo 'deny org.mozilla.firefox/*' >>/usr/share/ublue-os/flatpak-blocklist

### 6 · our services
systemctl enable gpu-undervolt.service
