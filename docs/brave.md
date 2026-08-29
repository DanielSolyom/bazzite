# Brave Browser

Brave (Flatpak, `com.brave.Browser`) is the browser, installed system-wide by the
first-boot hook ([custom-image.md](custom-image.md)). Firefox is uninstalled and
blocked.

## Components

| Piece | Path |
|---|---|
| Install | first-boot hook `30-flatpaks.sh` installs `com.brave.Browser` (system) |
| Firefox uninstall | the same hook runs `flatpak uninstall --system --delete-data org.mozilla.firefox`; the Bazzite ISO installs Firefox into `/var/lib/flatpak`, which is machine state the image cannot touch at build time |
| Firefox block | `deny org.mozilla.firefox/*` appended to `/usr/share/ublue-os/flatpak-blocklist` at build; `bazzite-flatpak-manager` applies the blocklist as a flathub remote filter (re-read on every flatpak operation), so Firefox cannot come back from the store |

The base image already ships a Brave-specific override
(`--system-talk-name=org.bluez`, for passkeys); nothing extra is baked.

The Brave extension cannot talk to the 1Password Flatpak — see
[onepassword.md](onepassword.md).

## Verification

```bash
flatpak list --app | grep -i brave
flatpak list --app | grep -i firefox        # no output
flatpak install flathub org.mozilla.firefox # must be refused by the remote filter
```
