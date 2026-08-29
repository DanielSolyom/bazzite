# CLAUDE.md

Custom Bazzite image source for exactly **one machine**: a Ryzen 7 9800X3D /
RX 9070 XT desktop. Base image `ghcr.io/ublue-os/bazzite-dx-gnome:stable`,
ublue image-template pattern. Docs-first: `docs/` is the source of truth; the
image files grow around it.

## Privacy — this repo is PUBLIC

Everything committed here is published. Never commit:

- Real names, e-mail addresses, or any other personal identifying info. The
  GitHub username appears **only** where technically required (image refs,
  registry scopes, signing paths, image-template.env) — nowhere else.
- The local Unix username — use `$USER` in documented commands.
- Network names/SSIDs, wifi profiles/PSKs, SSH keys, tokens, private keys.
- References to any files, notes, plans, or tooling that live outside this
  repo — the repo must read as fully self-contained.

Name shipped files and units **by function**, never by person
(`gpu-undervolt.service`, `10-no-swap.toml`): a stranger reading the filename
should learn what it does, not who owns the machine.

Hardware specs are fine — the hardware inventory in README.md is intentional.

## Invariants

- Scope is this one machine — never add content for other hardware.
- Only what ships, exactly as shipped: README and docs describe each feature,
  its mechanism/paths, and verification commands. Nothing else — no decision
  records, rationale, alternatives considered, history, measurements journals,
  TODO lists, status, or open questions, in docs **or** in code comments.
- Features not yet live stay out of the repo entirely until they ship.
- Every feature, added **or** removed, has a row in `README.md`'s tables AND a
  full write-up in `docs/`. New feature = new `docs/` file + README row;
  removals go in `docs/debloat.md`.
- The hardware inventory lives in `README.md` only.

## Verify before claiming

Docs must match the running system; check when possible:

- `rpm-ostree status` / `bootc status`
- `sudo ostree admin config-diff`
- `systemctl list-units --type=service --state=running` (also `--user`)
- `flatpak list --app`

## Map

- `README.md` — rebase one-liner + hardware inventory + Added/Removed tables
- `docs/custom-image.md` — how the image is built, signed, deployed, reinstalled
- `docs/debloat.md` — every removal/disable
- `build_files/build.sh` — the only place with build logic; template files
  (Containerfile, Justfile, workflow) are verbatim
