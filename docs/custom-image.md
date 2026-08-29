# Custom Image

The delivery vehicle for every feature in this repo: a bootc image
`FROM ghcr.io/ublue-os/bazzite-dx-gnome:stable`, built daily by GitHub Actions on
top of upstream, cosign-signed, pushed to `ghcr.io/danielsolyom/bazzite:stable`.
The machine tracks it via one `bootc switch`; a reinstall is
stock ISO → switch → restore /home. The image does not rebrand — os-release stays
stock Bazzite.

Created from [ublue-os/image-template](https://github.com/ublue-os/image-template) —
the same pattern Bazzite-DX itself uses on Bazzite. Note: bazzite-dx-gnome is built
FROM bazzite-**deck**-gnome, which explains the deck-heritage services and the
"deck" IMAGE_ID.

## Repo anatomy

Template files (Containerfile, Justfile, workflow) are used verbatim; all of the
opinion lives in `build.sh` and `system_files/`.

```
rebase.sh                      # curl | sudo bash bootstrap: pins the cosign key into the
                               #   signature policy + bootc switch (see "Deploying")
Containerfile                  # template's; FROM bazzite-dx-gnome:stable (unpinned —
                               #   the daily cron rebuild tracks upstream) + cosign.pub in ctx
Justfile                       # template's build logic: just build / ostree-rechunk / tags
image-template.env             # image identity: name, GitHub owner, default tag
cosign.pub                     # ECDSA P-256; private key exists only as the
                               #   Actions secret SIGNING_SECRET
.github/workflows/build.yml    # template's verbatim: PR/push/daily-cron/manual;
                               #   build → rpm-ostree rechunk → push → cosign sign digest
build_files/build.sh           # six numbered sections (see below)
disk_config/disk.toml          # ONLY for optional local VM/ISO test builds (see below)
system_files/                  # copied verbatim onto /
├─ usr/lib/systemd/system/gpu-undervolt.service   (self-contained; no helper script)
├─ usr/lib/bootc/kargs.d/10-gpu-undervolt.toml    (amdgpu.ppfeaturemask=0xffffffff)
├─ usr/lib/bootc/kargs.d/10-no-swap.toml          (systemd.zram=0)
├─ usr/lib/bootc/kargs.d/10-split-lock-off.toml   (split_lock_detect=off)
├─ usr/lib/modprobe.d/rtw89.conf
├─ usr/lib/NetworkManager/conf.d/wifi-powersave-off.conf
├─ usr/lib/modules-load.d/nct6775.conf
└─ usr/share/ublue-os/privileged-setup.hooks.d/30-flatpaks.sh
```

### Kernel args

One `kargs.d` file per feature; bootc merges all of them and applies them at
install and on every switch/upgrade. `bluetooth.disable_ertm=1` is **not** baked:
`bazzite-hardware-setup` re-adds it on every machine by itself.

### disk_config/disk.toml

Consumed **only** by bootc-image-builder when running the optional local recipes
(`just build-qcow2` / `build-raw` / `run-vm-*`) to size the root filesystem of a
generated test disk image. It has zero effect on the published container image and
zero effect on the real machine's partitions — bootc never repartitions an
installed system.

## build.sh

Six numbered sections:

1. **system files** — `cp -avf /ctx/system_files/. /`
2. **identity plumbing** (not branding) — image-info.json rewritten to
   `ostree-image-signed:docker://ghcr.io/danielsolyom/bazzite` so
   rollback/rebase tooling tracks our ref.
3. **signature trust for our own ref** — cosign.pub → `/etc/pki/containers/danielsolyom.pub`,
   a registries.d sigstore-attachments entry, and a `sigstoreSigned` scope for
   `ghcr.io/danielsolyom` jq-patched into `/etc/containers/policy.json` (the same
   shape Bazzite uses for `ghcr.io/ublue-os`). Upgrades verify automatically after
   the switch.
4. **debloat** per [debloat.md](debloat.md) — `systemctl disable` runs BEFORE
   `dnf5 remove` (vgauthd's unit vanishes with open-vm-tools), then removes the
   package list and masks `raid-check.timer`.
5. **flatpak policy** — `deny org.mozilla.firefox/*` appended to
   `/usr/share/ublue-os/flatpak-blocklist` ([brave.md](brave.md)).
6. **our services** — `systemctl enable gpu-undervolt.service`

`30-flatpaks.sh` (first-boot hook in `privileged-setup.hooks.d`, the directory
Bazzite executes): sources `libsetup.sh`, guards with
`version-script custom-flatpaks privileged 1` so it runs once, then installs
`com.brave.Browser` + `com.onepassword.OnePassword` system-wide. Idempotent —
if both are already installed it is a no-op.

## Signing

- `cosign.pub` is committed; the private key is never committed and lives in
  the repo's `SIGNING_SECRET` Actions secret.
- The workflow signs the pushed digest; anyone can check with
  `cosign verify --key cosign.pub ghcr.io/danielsolyom/bazzite:stable`.
- The image bakes the public key and policy (build.sh §3), so a machine running
  this image verifies every subsequent update automatically.

## Deploying to the machine

```bash
curl -fsSL https://raw.githubusercontent.com/DanielSolyom/bazzite/main/rebase.sh | sudo bash
systemctl reboot
```

`rebase.sh` (repo root) does four things:

1. fetches `cosign.pub` from this repo and installs it as
   `/etc/pki/containers/danielsolyom.pub`
2. writes a registries.d entry so signatures are fetched as sigstore attachments
3. jq-patches a `sigstoreSigned` scope for `ghcr.io/danielsolyom` into
   `/etc/containers/policy.json`
4. `bootc switch --enforce-container-sigpolicy ghcr.io/danielsolyom/bazzite:stable`

Because the key is trusted before the switch, even the first pull is
signature-enforced (steps 1–3 mirror what build.sh §3 bakes into the image
itself, which maintains the trust from then on). The script is idempotent.
Rollback safety: the previous deployment stays bootable (`rpm-ostree rollback`),
and greenboot auto-rolls-back on boot failure.

### Verify after boot

```bash
bootc status | head -5
cat /proc/cmdline | tr ' ' '\n' | grep -E 'ppfeaturemask|split_lock|systemd.zram'
swapon --show                                          # empty — by design
systemctl status gpu-undervolt --no-pager | tail -3
grep VDDGFX /sys/bus/pci/devices/0000:03:00.0/pp_od_clk_voltage
cat /sys/module/rtw89_core/parameters/disable_ps_mode  # Y
sensors | grep -i nct
flatpak list --app | grep -iE 'brave|onepassword'
```

## Reinstall flow

Stock Bazzite ISO → the same `rebase.sh` one-liner → reboot → restore /home.
The script gives a fresh machine the key before switching, so the reinstall is
signature-enforced end to end; the image bakes in the same trust for every
update afterwards.

Machine-local state to redo after a reinstall: wifi reconnect, /home restore.

## Local build fallback (no registry involved)

The repo alone is enough to reproduce the OS, with the desktop as the build server:

```bash
podman build -t localhost/bazzite:stable .
sudo bootc switch --transport containers-storage localhost/bazzite:stable
```

Atomicity/rollback/kargs all still work; freshness and reinstalls are manual.

## Life afterwards

- **Updates:** zero config — uupd runs `bootc upgrade` daily against whatever ref
  the machine tracks; flatpaks update too. The image itself rebuilds daily on top
  of upstream via the workflow cron.
- **Iterating:** edit → push → Actions (~15–25 min) → `sudo bootc upgrade` → reboot.
