# GPU Undervolt

RX 9070 XT: **−80 mV voltage/frequency offset + 265 W power cap**, applied by a
oneshot service at boot and re-applied after suspend. Under load this holds stock
clocks at roughly −55 W package power.

## Components

| Piece | Path |
|---|---|
| Service | `/usr/lib/systemd/system/gpu-undervolt.service` — self-contained, no helper script; enabled at build for `multi-user.target` + `suspend.target` |
| Kernel arg | `amdgpu.ppfeaturemask=0xffffffff` in `/usr/lib/bootc/kargs.d/10-gpu-undervolt.toml` — unlocks the overdrive sysfs interface; Bazzite auto-adds it only on Valve/handheld hardware, so the image carries it |

## How the unit works

- Addresses the GPU **by PCI path** (`/sys/bus/pci/devices/0000:03:00.0`) — never by
  card index, because the iGPU exposes a decoy overdrive node.
- Waits up to 60 s for the OD node (amdgpu can be slow after resume), then writes the
  RDNA4 sequence: `vo -80` → `c` (commit) into `pp_od_clk_voltage`, and the cap in µW
  into every `hwmon/*/power1_cap`.
- `WantedBy=suspend.target` + `After=suspend.target` starts the unit when the target
  completes, i.e. on resume.
- Offset range on this card: `-200mv..0mv`.

## Verification

```bash
systemctl status gpu-undervolt --no-pager | tail -3
grep VDDGFX /sys/bus/pci/devices/0000:03:00.0/pp_od_clk_voltage   # OD_VDDGFX_OFFSET: -80mV
cat /sys/bus/pci/devices/0000:03:00.0/hwmon/hwmon*/power1_cap      # 265000000
```
