#!/usr/bin/env bash
set -euo pipefail
TAR=$(ls -1t recovery/recovery_*.tar | head -n1 || true)
[ -z "$TAR" ] && { echo "no recovery tar found"; exit 0; }
[ -z "${ENC_AES_KEY:-}" ] || [ -z "${ENC_AES_IV:-}" ] && { echo "[enc] no key/iv; skipping"; exit 0; }
OUT="${TAR}.enc"
openssl enc -aes-256-cbc -K "$ENC_AES_KEY" -iv "$ENC_AES_IV" -pbkdf2 -in "$TAR" -out "$OUT"
sha256sum "$OUT" > "${OUT}.sha256"
echo "[enc] wrote $OUT"
