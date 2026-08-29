# Passwordless sudo

Members of the `wheel` group run `sudo` without being asked for a password.

## Mechanism

`/etc/sudoers.d/10-wheel-nopasswd`, shipped in the image:

```
%wheel ALL=(ALL) NOPASSWD: ALL
```

`/etc/sudoers` ends with `#includedir /etc/sudoers.d`, and sudo applies the
last matching rule, so this drop-in overrides the stock `%wheel ALL=(ALL) ALL`
above it. `build.sh` sets the file to mode `0440` and validates it with
`visudo -cf` at build time.

The scope is `sudo` only. GUI privilege prompts go through polkit, which is
untouched and still asks for a password.

## Verification

```bash
sudo -k && sudo -n true && echo "no password needed"
sudo -l | grep NOPASSWD
id -nG | tr ' ' '\n' | grep wheel
```
