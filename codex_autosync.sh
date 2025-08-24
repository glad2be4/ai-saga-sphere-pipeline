#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

# --- Safety snapshot of whatever you have right now
ts="$(date +%Y%m%d_%H%M%S)"
cur_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)"
git status --porcelain >/dev/null 2>&1 || { echo "Not a git repo"; exit 1; }

# If a rebase or merge is in progress, back out cleanly
if [ -d .git/rebase-apply ] || [ -d .git/rebase-merge ]; then
  git rebase --abort || true
fi
if [ -f .git/MERGE_HEAD ]; then
  git merge --abort || true
fi

# Create a local snapshot branch with your uncommitted work (if any)
if ! git diff --quiet || ! git diff --cached --quiet; then
  snap="local-snapshot-$ts"
  git checkout -B "$snap"
  git add -A
  git commit -m "snapshot: local work $ts"
  git checkout "$cur_branch"
fi

# Ensure we’re on main (or the current tracked branch)
git checkout "$cur_branch" >/dev/null 2>&1 || git checkout -B "$cur_branch"

# Make sure we’re tracking origin/main
git fetch origin main
git branch --set-upstream-to=origin/main "$cur_branch" >/dev/null 2>&1 || true

# Merge origin/main into local (merge > rebase for binaries)
git merge --no-edit origin/main || true

# If conflicts remain, auto-resolve by type/pattern
if [ -n "$(git diff --name-only --diff-filter=U)" ]; then
  echo "== Auto-resolving conflicts by policy =="

  # 1) Prefer REMOTE for audio & big binaries already published
  for f in $(git diff --name-only --diff-filter=U | grep -Ei '\.(wav|mp3|flac|ogg|m4a|zip|tar|7z|bin)$' || true); do
    echo "  -> theirs (remote) $f"
    git checkout --theirs -- "$f" || true
    git add "$f" || true
  done

  # 2) Prefer LOCAL for pipeline code, workflows, scripts
  for f in $(git diff --name-only --diff-filter=U | grep -E '^(\.github/workflows/|scripts/|work/|source/|public/.*\.(json|xml|yml|yaml|sh|py))' || true); do
    echo "  -> ours (local)   $f"
    git checkout --ours -- "$f" || true
    git add "$f" || true
  done

  # 3) Anything still conflicted → keep ours by default (safer for your pipeline)
  if [ -n "$(git diff --name-only --diff-filter=U)" ]; then
    for f in $(git diff --name-only --diff-filter=U); do
      echo "  -> default ours   $f"
      git checkout --ours -- "$f" || true
      git add "$f" || true
    done
  fi
fi

# If there are staged changes from the conflict resolution, finish the merge
if ! git diff --cached --quiet; then
  git commit -m "merge: sync with origin/main (audio=theirs, pipeline=ours) $ts"
fi

# Push the synchronized main
git push origin "$cur_branch"
echo "== AutoSync complete =="
