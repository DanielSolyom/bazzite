# 🎮 bazzite

**The personal operating system of exactly one machine** — a custom
[Bazzite](https://bazzite.gg) image for a Ryzen 7 9800X3D / RX 9070 XT
desktop. Everything this machine needs is baked in, everything it will never
use is taken out.

Built from `ghcr.io/ublue-os/bazzite-dx-gnome:stable` with the
[ublue-os/image-template](https://github.com/ublue-os/image-template) pattern,
rebuilt daily on top of upstream by GitHub Actions, cosign-signed, and
published to `ghcr.io/danielsolyom/bazzite:stable`.

Every feature below — added or removed — has a full write-up in
[`docs/`](docs/). How the image is built, deployed, updated, and reinstalled
is covered in [docs/custom-image.md](docs/custom-image.md).

## 🚀 Install

```bash
curl -fsSL https://raw.githubusercontent.com/DanielSolyom/bazzite/main/rebase.sh | sudo bash
systemctl reboot
```

One command on any Bazzite/bootc install: [`rebase.sh`](rebase.sh) pins the
image's cosign public key into the container signature policy and runs
`bootc switch --enforce-container-sigpolicy ghcr.io/danielsolyom/bazzite:stable`,
so even the first pull is signature-verified. A reinstall is the stock Bazzite
ISO → the same command → restore `/home`.

## 🖥️ Hardware

```
CPU        AMD Ryzen 7 9800X3D (8C/16T)
Board      ASUS X870 MAX GAMING WIFI7 · BIOS 1682 (2026-06-22)
RAM        64 GB DDR5 — 2× 32 GiB Kingston Fury KF564C32-32 (6400 CL32 @ 6000 MT/s)
dGPU       AMD Radeon RX 9070 XT (Navi 48) · PCI 0000:03:00.0
iGPU       AMD Radeon (Granite Ridge) — exposes a decoy overdrive node; never address GPUs by card index
SSD        Samsung 9100 Pro 1 TB (PCIe 5.0) · M.2_1 (CPU) · OS drive
WiFi       Realtek RTL8922AE (WiFi 7 / 802.11be)
Ethernet   Realtek RTL8125 2.5GbE
USB4       ASMedia ASM4242 · 2× 40 Gbps
Audio      AMD Ryzen HD Audio + GPU HDMI/DP audio
OS         Bazzite-DX GNOME (bazzite-dx-gnome:stable, Fedora 44, bootc/ostree)
```

## ✨ Added

Everything in this table is baked into the image.

| Feature | What it does | Doc |
|---|---|---|
| ⚡ GPU undervolt | RX 9070 XT: −80 mV V/F offset + 265 W cap at boot and after suspend; stock clocks at −55 W | [gpu-undervolt.md](docs/gpu-undervolt.md) |
| 📶 WiFi stability | rtw89 firmware power-save off (kills periodic latency spikes) + NetworkManager powersave off | [wifi-stability.md](docs/wifi-stability.md) |
| 🌡️ Board sensors | nct6775 module load for fan/temp/voltage readout | [sensors.md](docs/sensors.md) |
| 🚫 No swap | Swap permanently off via the `systemd.zram=0` kernel arg | [no-swap.md](docs/no-swap.md) |
| 🔓 Split-lock off | `split_lock_detect=off` so games that trigger split locks aren't throttled | [split-lock.md](docs/split-lock.md) |
| 🔑 1Password | Flatpak, system install, shipped via first-boot hook | [onepassword.md](docs/onepassword.md) |
| 🦁 Brave browser | Flatpak browser, shipped via first-boot hook; Firefox blocklisted | [brave.md](docs/brave.md) |

## 🧹 Removed

Full table with what each item is: [debloat.md](docs/debloat.md).

| Removal | How |
|---|---|
| `open-vm-tools`, `qemu-guest-agent` | package |
| `intel-lpmd` | package |
| `ModemManager` | package |
| `mcelog` | package |
| `docker-*`, `containerd.io` | package |
| `lutris` | package |
| libvirt xen/lxc/vbox/ch drivers | package |
| `vboxservice`, `vgauthd` | service disable |
| iSCSI units | service disable |
| `lvm2-monitor` | service disable |
| `mdmonitor` + `raid-check.timer` | disable + mask |
| `sssd` (service only) | service disable |
| `NetworkManager-wait-online` | service disable |
| `ds-inhibit` | service disable |
| handheld leftovers (`bazzite-tdpfix`, PipeWire workarounds, iwd migration) | service disable |
| Firefox | flatpak blocklist |

## 🗂️ Repo layout

```
rebase.sh                   curl | sudo bash — trust the key + bootc switch (see top)
Containerfile               base image + one RUN of build.sh + bootc lint
build_files/build.sh        all the opinion: system files, identity, signing trust, debloat
system_files/               copied verbatim onto / (units, kargs, modprobe, hooks)
disk_config/                bootc-image-builder config for optional local VM/ISO test builds
docs/                       one write-up per feature — the source of truth
Justfile, image-template.env, .github/workflows/build.yml   ublue image-template build machinery
cosign.pub                  public signing key (private key lives only in Actions secrets)
```
