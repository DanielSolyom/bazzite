# No Swap

Swap (Bazzite's default zram) is permanently off on this machine.

## Mechanism

Kernel arg **`systemd.zram=0`** in `/usr/lib/bootc/kargs.d/10-no-swap.toml` —
zram-generator's documented off-switch. Declarative, reinstall-proof, no /etc
files.

## Effects

- `systemd-oomd` logs `No swap; memory pressure usage will be degraded` at boot;
  the plain kernel OOM killer handles runaway processes.
- Hibernation is unavailable (it needs disk swap ≥ RAM). Suspend-to-RAM works.

## Verification

```bash
swapon --show      # empty
zramctl            # empty
cat /proc/cmdline | tr ' ' '\n' | grep systemd.zram
```
