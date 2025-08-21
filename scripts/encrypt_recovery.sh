#!/usr/bin/env bash
set -euo pipefail
TAR=$(ls -1t recovery/recovery_*.tar | head -n1 || true)
[ -z "$TAR" ] && exit 0
[ -z "${ENC_AES_KEY:-}" ] || [ -z "${ENC_AES_IV:-}" ] && { echo "[enc] no key/iv; skipping"; exit 0; }
openssl enc -aes-256-cbc -K "$ENC_AES_KEY" -iv "$ENC_AES_IV" -pbkdf2 -in "$TAR" -out "${TAR}.enc"
sha256sum "${TAR}.enc" > "${TAR}.enc.sha256"
echo "[enc] wrote ${TAR}.enc"
