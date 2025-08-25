#!/usr/bin/env bash
set -euo pipefail
status="${1:?}"; stage="${2:?}"; endpoint="${3:?}"; url="${4:-}"; reason="${5:-}"; http="${6:-}"; meta="${7:-{}}"
metrics="{}"
bin_dir="$(cd "$(dirname "$0")" && pwd)"
"$bin_dir/codex_log.sh" --cat distribution --stage "$stage" --status "$status" \
  --endpoint "$endpoint" --feed_url "$url" --reason "$reason" --http "$http" --meta "$meta"
