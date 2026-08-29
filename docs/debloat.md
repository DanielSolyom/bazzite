# Debloat

What the image removes or disables at build time. Implemented in
`build_files/build.sh` §4–5.

## Packages removed (`dnf5 remove -y --no-autoremove`)

`--no-autoremove` keeps dnf from also yanking shared dependencies.

| Package | What it is |
|---|---|
| `open-vm-tools` (vmtoolsd, vgauthd) | VMware guest agent |
| `qemu-guest-agent` | QEMU guest agent |
| `intel-lpmd` | Intel low-power-mode daemon |
| `ModemManager` | WWAN modem manager |
| `mcelog` | machine-check logger (Intel-only; no AMD Zen support) |
| `containerd.io`, `docker-*` | Docker engine |
| `lutris` | game launcher |
| `libvirt-daemon-driver-libxl`, `-lxc`, `-vbox`, `-ch` | Xen / LXC / VirtualBox / cloud-hypervisor libvirt drivers |

## Services disabled (`systemctl disable`)

| Unit(s) | What it is |
|---|---|
| `vboxservice`, `vgauthd` | VirtualBox / VMware guest services |
| `iscsi-onboot`, `iscsi-starter` | iSCSI initiator startup |
| `lvm2-monitor` | LVM monitoring |
| `mdmonitor` | mdraid monitoring |
| `sssd` | enterprise auth daemon (service only; the package stays — PAM references pam_sss) |
| `NetworkManager-wait-online` | gates network-online.target, can hold boot up to 60 s (disabled, not masked) |
| `ds-inhibit` | DualSense-trackpad inhibitor |
| `bazzite-tdpfix` | handheld TDP fixup |
| `pipewire-workaround`, `wireplumber-workaround` | handheld audio DSP bind-mounts |
| `bazzite-iwd-migration` | one-time wifi backend migration |

Masked: `raid-check.timer` (mdraid scrub).

## Flatpaks

The image does not preinstall GNOME's starter-app set; the first-boot hook
installs exactly two apps — Brave and 1Password — and Firefox is deny-listed
([brave.md](brave.md)). Rebasing an existing machine onto this image changes
nothing: installed flatpaks are machine state in `/var/lib/flatpak`, which the
image never touches.
