# WiFi Stability

Disables the rtw89 firmware low-power mode on the Realtek RTL8922AE (WiFi 7). The
firmware parks the radio between packets; the wake-up latency shows as periodic
multi-hundred-ms ping spikes. `iw`/NetworkManager power_save does **not** control
the firmware mode — only the module parameter does; both knobs are set.

## Components

| Piece | Path |
|---|---|
| Module param | `/usr/lib/modprobe.d/rtw89.conf` → `options rtw89_core disable_ps_mode=Y` — being in the image, it also lands in the prebuilt initramfs (/etc modprobe edits never reach the initramfs on ostree) |
| NM powersave | `/usr/lib/NetworkManager/conf.d/wifi-powersave-off.conf` → `[connection]` `wifi.powersave = 2` |

## Verification

```bash
cat /sys/module/rtw89_core/parameters/disable_ps_mode   # Y
ping -c 60 <gateway>                                    # no periodic multi-hundred-ms spikes
```
