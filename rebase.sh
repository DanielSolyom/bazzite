#!/usr/bin/env bash
# Rebase a Bazzite/bootc machine to ghcr.io/danielsolyom/bazzite:stable with
# signature enforcement from the very first pull.
#
#   curl -fsSL https://raw.githubusercontent.com/DanielSolyom/bazzite/main/rebase.sh | sudo bash
#
# What it does: fetches the image's cosign public key (cosign.pub) from this
# repo, pins it into the container signature policy (the same trust the image
# itself bakes in — build_files/build.sh §3), then runs
# `bootc switch --enforce-container-sigpolicy`. Idempotent.
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/DanielSolyom/bazzite/main"
IMAGE="ghcr.io/danielsolyom/bazzite:stable"
KEY_PATH="/etc/pki/containers/danielsolyom.pub"

[ "$(id -u)" -eq 0 ] || { echo "error: must run as root (pipe into 'sudo bash')" >&2; exit 1; }
command -v bootc >/dev/null || { echo "error: bootc not found — this only works on a bootc host (Bazzite)" >&2; exit 1; }
command -v jq >/dev/null || { echo "error: jq not found" >&2; exit 1; }
command -v curl >/dev/null || { echo "error: curl not found" >&2; exit 1; }

### 1 · fetch and trust the signing key (cosign.pub in the repo)
tmpkey=$(mktemp)
trap 'rm -f "$tmpkey"' EXIT
curl -fsSL "$REPO_RAW/cosign.pub" -o "$tmpkey"
grep -q -- "-----BEGIN PUBLIC KEY-----" "$tmpkey" ||
	{ echo "error: downloaded cosign.pub is not a PEM public key" >&2; exit 1; }
install -D -m 0644 "$tmpkey" "$KEY_PATH"

### 2 · fetch signatures as sigstore attachments for the namespace
install -d -m 0755 /etc/containers/registries.d
cat >/etc/containers/registries.d/ghcr.io-danielsolyom.yaml <<'EOF'
docker:
  ghcr.io/danielsolyom:
    use-sigstore-attachments: true
EOF

### 3 · require that key for anything from ghcr.io/danielsolyom
tmp=$(mktemp)
jq --arg key "$KEY_PATH" '.transports.docker["ghcr.io/danielsolyom"] = [{
      "type": "sigstoreSigned",
      "keyPath": $key,
      "signedIdentity": {"type": "matchRepository"}
    }]' /etc/containers/policy.json >"$tmp"
mv "$tmp" /etc/containers/policy.json
chmod 0644 /etc/containers/policy.json

### 4 · switch, enforcing the policy from the first pull
bootc switch --enforce-container-sigpolicy "$IMAGE"

echo
echo "Staged: $IMAGE (signature-verified)."
echo "Reboot to finish: systemctl reboot"
