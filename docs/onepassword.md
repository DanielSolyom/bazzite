# 1Password

1Password runs as the Flathub Flatpak (`com.onepassword.OnePassword`), system
install, put on the machine by the first-boot hook
([custom-image.md](custom-image.md)). No flatpak overrides are baked — clipboard
works stock (the Flathub build ships `sockets=wayland;x11`).

## Properties of the Flatpak build

- No 1Password SSH agent (unsupported in Flatpak) — GNOME keyring is the SSH agent.
- No browser-extension ↔ app link (a sandboxed app can't do native messaging).
- No `op` CLI; available separately via `brew install --cask ublue-os/tap/1password-cli-linux`.

## Verification

```bash
flatpak list --app | grep -i onepassword
```
