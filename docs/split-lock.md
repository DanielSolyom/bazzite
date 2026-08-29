# Split-Lock Detection Off

Kernel arg **`split_lock_detect=off`** in
`/usr/lib/bootc/kargs.d/10-split-lock-off.toml`.

Stops the kernel from detecting split locks (atomic instructions whose operand
crosses a cache-line boundary) and deliberately slowing the offending process.
Games — especially Windows titles under Proton — are the main real-world source
of split locks, and the penalty can tank their performance.

## Verification

```bash
cat /proc/cmdline | tr ' ' '\n' | grep split_lock   # split_lock_detect=off
```
