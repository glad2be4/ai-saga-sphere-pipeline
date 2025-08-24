#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

branch="${1:-main}"

# If any dirty state, stash (keeps index + working tree clean)
if ! git diff --quiet || ! git diff --cached --quiet; then
  git stash push -u -m "codex_autostash_$(date -u +%Y%m%d_%H%M%S)" || true
fi

# Ensure branch exists and is checked out
git fetch origin "$branch" || true
if ! git rev-parse --verify "$branch" >/dev/null 2>&1; then
  git checkout -b "$branch" || git checkout "$branch"
else
  git checkout "$branch"
fi

# Make sure tracking is set
git branch --set-upstream-to="origin/$branch" "$branch" 2>/dev/null || true

# Rebase onto remote (preferred) or soft-merge fallback
if ! git rebase "origin/$branch"; then
  echo "[codex_git_sync] rebase had conflicts, falling back to merge..."
  git rebase --abort || true
  git merge --no-edit "origin/$branch" || true
fi

# Restore any stashed work (if we stashed)
if git stash list | grep -q codex_autostash_; then
  git stash pop || true
fi

# If there are new commits locally, push; otherwise no-op
if [ -n "$(git log --oneline origin/$branch..$branch)" ]; then
  git push origin "$branch"
else
  echo "[codex_git_sync] nothing to push (up to date)."
fi
