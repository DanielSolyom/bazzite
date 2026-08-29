# Board Sensors

Loads the **nct6775** kernel module so the ASUS X870 board's Nuvoton Super-I/O chip
exposes fan speeds, voltages, and temperatures to `lm_sensors`/GNOME monitors.
The module is not autoloaded by default — it has to be asked for.

## Components

| Piece | Path |
|---|---|
| Module load | `/usr/lib/modules-load.d/nct6775.conf` → `nct6775` |

## Verification

```bash
sensors | grep -iA4 nct
```
