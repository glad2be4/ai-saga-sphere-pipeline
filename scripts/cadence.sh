#!/usr/bin/env bash
set -euo pipefail
REPO_SLUG="${REPO_SLUG:-${GITHUB_REPOSITORY:-}}"; [ -z "$REPO_SLUG" ] && REPO_SLUG="$(gh api user -q .login)/$(basename "$(git rev-parse --show-toplevel)")"
FEED_URL="${FEED_URL:-}"
YEAR=$(date -u +%Y); WEEK=$(date -u +%V); MONTH=$(date -u +%m)
Q=$(( (10#$MONTH + 2)/3 )); QEND=$(date -u -d "$(printf '%04d-%02d-01' "$YEAR" $(( (Q-1)*3 + 1 ))) +2 months +1 month -1 day" +%Y-%m-%d)
label(){ gh label list -R "$REPO_SLUG" | grep -q "^$1\b" || gh label create "$1" --color "$2" --description "$3" -R "$REPO_SLUG"; }
label excerpt 1f8838 "Weekly excerpt"; label arc 0e8a16 "Quarterly arc"; label anniversary 5319e7 "Anniversary echo"
weekly(){ T="Weekly Excerpt ${YEAR}-W${WEEK}"; gh issue list -R "$REPO_SLUG" --state all --label excerpt --search "in:title $T" -L 1 | grep -q "$T" || gh issue create -R "$REPO_SLUG" -t "$T" -b "Feed: ${FEED_URL}" -l excerpt; }
quarterly(){ T="Q${Q} ${YEAR} — Arc Milestone"; gh api "repos/$REPO_SLUG/milestones?state=all" | jq -e --arg t "$T" '.[]|select(.title==$t)' >/dev/null || gh api -X POST "repos/$REPO_SLUG/milestones" -f title="$T" -f state=open -f due_on="${QEND}T23:59:59Z"; }
anniv(){ TAG="anniv-${YEAR}"; gh release view "$TAG" -R "$REPO_SLUG" >/dev/null 2>&1 || gh release create "$TAG" -t "Anniversary ${YEAR}" -n "Feed: ${FEED_URL}" -R "$REPO_SLUG"; }
case "${CADENCE_MODE:-all}" in weekly) weekly;; quarterly) quarterly;; anniversary) anniv;; *) weekly; quarterly; anniv;; esac
