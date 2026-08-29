# Brave Browser

Brave (Flatpak, `com.brave.Browser`) is the browser, installed system-wide by the
first-boot hook ([custom-image.md](custom-image.md)). Firefox is removed and
blocked.

## Components

| Piece | Path |
|---|---|
| Install | first-boot hook `30-flatpaks.sh` installs `com.brave.Browser` (system) |
| Firefox block | `deny org.mozilla.firefox/*` appended to `/usr/share/ublue-os/flatpak-blocklist` at build; `bazzite-flatpak-manager` applies the blocklist as a flathub remote filter (re-read on every flatpak operation), so Firefox is uninstallable, not merely absent |

The base image already ships a Brave-specific override
(`--system-talk-name=org.bluez`, for passkeys); nothing extra is baked.

The Brave extension cannot talk to the 1Password Flatpak — see
[onepassword.md](onepassword.md).

## Verification

```bash
flatpak list --app | grep -i brave
flatpak install flathub org.mozilla.firefox   # must be refused by the remote filter
```
