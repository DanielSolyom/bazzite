# 1Password

1Password runs as the Flathub Flatpak (`com.onepassword.OnePassword`), system
install, put on the machine by the first-boot hook
([custom-image.md](custom-image.md)). The hook also applies a system-wide
clipboard override for GNOME's Wayland session.

## Clipboard access

`system_files/usr/share/ublue-os/privileged-setup.hooks.d/30-flatpaks.sh` runs:

```bash
flatpak override --system --nosocket=fallback-x11 com.onepassword.OnePassword
```

The Flatpak's `fallback-x11` permission hides X11 when Wayland is available.
Disabling it leaves the app's existing `x11` and `wayland` permissions active,
so 1Password can open the clipboard connection on GNOME.

The override is written to
`/var/lib/flatpak/overrides/com.onepassword.OnePassword` by the setup hook on the
machine. Hook version 3 applies it on fresh installs and when an existing
installation next runs setup after updating the image.

## Properties of the Flatpak build

- No 1Password SSH agent (unsupported in Flatpak) — GNOME keyring is the SSH agent.
- No browser-extension ↔ app link (a sandboxed app can't do native messaging).
- No `op` CLI; available separately via `brew install --cask ublue-os/tap/1password-cli-linux`.

## Verification

```bash
flatpak list --app | grep -i onepassword
flatpak override --system --show com.onepassword.OnePassword
```

The override output includes `sockets=!fallback-x11;`. After setup, fully quit
and reopen 1Password if it was already running, then copy a non-sensitive field
(such as a website address) and paste it into another app.
