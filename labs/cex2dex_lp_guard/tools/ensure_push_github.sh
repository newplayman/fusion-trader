#!/usr/bin/env bash
set -euo pipefail

# Ensures origin is set and pushes main + phase3 branch to GitHub via SSH.
# If the GitHub repo does not exist yet, prints the exact URL to create.

FUSION_DIR="${FUSION_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || true)}"
if [ -z "$FUSION_DIR" ]; then
  echo "ERROR: run inside a git repo or set FUSION_DIR" >&2
  exit 2
fi

cd "$FUSION_DIR"

OWNER="${GITHUB_OWNER:-newplayman}"
REPO="${GITHUB_REPO:-fusion-trader}"
SSH_URL="git@github.com:${OWNER}/${REPO}.git"

if git remote get-url origin >/dev/null 2>&1; then
  echo "origin=$(git remote get-url origin)"
else
  git remote add origin "$SSH_URL"
  echo "origin_added=$SSH_URL"
fi

# GitHub's SSH intentionally exits 1 even on success; detect by message.
ssh_out="$(ssh -o BatchMode=yes -T git@github.com 2>&1 || true)"
if ! echo "$ssh_out" | rg -q "successfully authenticated"; then
  echo "ERROR: GitHub SSH auth not ready. Output:" >&2
  echo "$ssh_out" | sed -n '1,20p' >&2
  exit 3
fi

git remote set-url origin "$SSH_URL"

set +e
ls_remote_out="$(git ls-remote --heads origin 2>&1)"
ls_remote_ec=$?
set -e

if [ $ls_remote_ec -ne 0 ] && echo "$ls_remote_out" | rg -q "Repository not found"; then
  echo "ERROR: GitHub repo does not exist yet: $OWNER/$REPO" >&2
  echo "Create it (empty is fine): https://github.com/new" >&2
  echo "Then rerun: bash labs/cex2dex_lp_guard/tools/ensure_push_github.sh" >&2
  exit 4
fi

git push -u origin main
git push -u origin phase3_cex2dex_lp_guard
echo "push_ok=1"

