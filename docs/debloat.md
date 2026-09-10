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
| `displaylink`, `libevdi`, `kmod-evdi` | DisplayLink USB display daemon, library, and kernel module |
| `inputplumber`, `input-remapper` | InputPlumber controller handling and Input Remapper |
| `hipcc`, `rocm-hip`, `rocm-device-libs` | Native HIP compiler, HIP runtime, and device libraries |
| `rocm-llvm-static`, `rocm-llvm-devel`, `rocm-llvm`, `rocm-lld` | ROCm LLVM static libraries, development files, tools, and linker |
| `rocm-clang-devel`, `rocm-clang`, `rocm-clang-runtime-devel`, `rocm-libc++-devel` | ROCm Clang and C++ development files |

Smart-card packages stay installed; their daemon and activation socket are
masked. The ROCm OpenCL runtime and its shared libraries stay installed.

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
| `bazzite-iwd-migration` | one-time wifi backend migration |

## Services masked (`systemctl mask`)

Enabled services and activation sockets are disabled before masking. Masks
prevent dependency, D-Bus, or socket activation from starting these units again.

| Unit(s) | What it is |
|---|---|
| `raid-check.timer` | mdraid scrub timer |
| `pipewire-sysconf.service`, `wireplumber-sysconf.service` | handheld audio hardware-profile setup |
| `pipewire-workaround.service`, `wireplumber-workaround.service` | writable bind-mounts over `/usr/share/pipewire` and `/usr/share/wireplumber` |
| `displaylink.service` | DisplayLink USB display daemon |
| `inputplumber.service`, `input-remapper.service` | controller handling and input remapping daemons |
| `pcscd.service`, `pcscd.socket` | smart-card daemon and activation socket |

Both `*-sysconf` units require their corresponding `*-workaround` unit. All four
are masked together. The desktop's `pipewire`, `pipewire-pulse`, and
`wireplumber` user services provide normal audio.

## Flatpaks

Flatpaks are machine state in `/var/lib/flatpak`, not image content, so nothing
about them can be changed at build time. The first-boot hook
`30-flatpaks.sh` does the work on the machine: it uninstalls
`org.mozilla.firefox` (which the Bazzite ISO installs) and installs Brave and
1Password. Firefox is additionally deny-listed so the store cannot bring it
back ([brave.md](brave.md)). GNOME's starter-app set, also placed by the ISO,
is left alone.

## Verification

```bash
systemctl is-enabled \
  pipewire-sysconf.service wireplumber-sysconf.service \
  pipewire-workaround.service wireplumber-workaround.service \
  displaylink.service inputplumber.service input-remapper.service \
  pcscd.service pcscd.socket                            # masked
systemctl --user is-active pipewire pipewire-pulse wireplumber  # active
findmnt --mountpoint /usr/share/pipewire               # no bind mount
findmnt --mountpoint /usr/share/wireplumber            # no bind mount
rpm -q displaylink inputplumber input-remapper hipcc rocm-hip rocm-llvm-static
                                                      # not installed
rpm -q pcsc-lite rocm-opencl                          # installed
```
