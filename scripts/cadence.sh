#!/usr/bin/env bash
set -euo pipefail

REPO_SLUG="${REPO_SLUG:-$(gh api user -q .login)/${REPO:-$(basename "$(git rev-parse --show-toplevel)")}}"
FEED_URL="${FEED_URL:-$(gh variable get FEED_URL -R "$REPO_SLUG" 2>/dev/null || true)}"
FEED_URL="${FEED_URL:-}"
TODAY_UTC="$(date -u +%Y-%m-%d)"
YEAR="$(date -u +%Y)"
WEEK="$(date -u +%V)"         # ISO week (01-53)
DOW="$(date -u +%u)"          # 1=Mon..7=Sun
MONTH="$(date -u +%m)"
# quarter calc: 1–3 -> Q1, 4–6 -> Q2, 7–9 -> Q3, 10–12 -> Q4
case "$MONTH" in
  01|02|03) Q=1; QEND="${YEAR}-03-31" ;;
  04|05|06) Q=2; QEND="${YEAR}-06-30" ;;
  07|08|09) Q=3; QEND="${YEAR}-09-30" ;;
  10|11|12) Q=4; QEND="${YEAR}-12-31" ;;
esac

# ensure labels
ensure_label () {
  local name=$1 color=$2 desc=$3
  if ! gh label list -R "$REPO_SLUG" --limit 200 | grep -q "^$name\b"; then
    gh label create "$name" --color "$color" --description "$desc" -R "$REPO_SLUG" >/dev/null
  fi
}
ensure_label "excerpt"    "1f8838" "Weekly excerpt drop"
ensure_label "arc"        "0e8a16" "Quarterly arc milestone"
ensure_label "anniversary" "5319e7" "Anniversary echo release"

weekly_excerpt () {
  local title="Weekly Excerpt ${YEAR}-W${WEEK}"
  # idempotent: skip if exists
  if gh issue list -R "$REPO_SLUG" --state all --label excerpt --search "in:title $title" -L 1 | grep -q "$title"; then
    echo "[weekly] exists: $title"; return 0
  fi
  local frag1="public/fragments/fragment1.txt"
  local frag2="public/fragments/fragment2.txt"
  local body="Autonomic weekly excerpt.
- Feed: ${FEED_URL:-<set FEED_URL repo variable>}
- Artifact: see latest Actions artifacts
- Fragments:
$( [ -f "$frag1" ] && echo '```txt'; [ -f "$frag1" ] && sed -n '1,12p' "$frag1"; [ -f "$frag1" ] && echo '```' )
$( [ -f "$frag2" ] && echo '```txt'; [ -f "$frag2" ] && sed -n '1,12p' "$frag2"; [ -f "$frag2" ] && echo '```' )
"
  gh issue create -R "$REPO_SLUG" -t "$title" -b "$body" -l excerpt >/dev/null
  echo "[weekly] created: $title"
}

quarterly_arc () {
  local title="Q${Q} ${YEAR} — Arc Milestone"
  # idempotent: skip if exists
  if gh api "repos/$REPO_SLUG/milestones?state=all" | jq -e --arg t "$title" '.[]|select(.title==$t)' >/dev/null; then
    echo "[quarterly] milestone exists: $title"; return 0
  fi
  gh api -X POST "repos/$REPO_SLUG/milestones" \
    -f title="$title" -f state="open" -f due_on="${QEND}T23:59:59Z" >/dev/null
  echo "[quarterly] milestone created: $title (due ${QEND})"
}

anniversary_release () {
  local tag="anniv-${YEAR}"
  if gh release view "$tag" -R "$REPO_SLUG" >/dev/null 2>&1; then
    echo "[anniv] release exists: $tag"; return 0
  fi
  local notes="Anniversary Echo — ${YEAR}
- Codex integrity: OK
- Feed: ${FEED_URL:-<set FEED_URL repo variable>}
- Mirrors: OneDrive / Storacha (if enabled)
"
  gh release create "$tag" -t "Anniversary ${YEAR}" -n "$notes" -R "$REPO_SLUG" >/dev/null
  echo "[anniv] release created: $tag"
}

case "${CADENCE_MODE:-all}" in
  weekly)      weekly_excerpt ;;
  quarterly)   quarterly_arc  ;;
  anniversary) anniversary_release ;;
  all)         weekly_excerpt; quarterly_arc; anniversary_release ;;
esac
