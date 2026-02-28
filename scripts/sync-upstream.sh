#!/usr/bin/env bash

set -euo pipefail

RUN_DEPLOY=0
TARGET_BRANCH="main"
SKIP_STASH=0
STASH_CREATED=0
STASH_MESSAGE=""

usage() {
  cat <<'USAGE'
Usage:
  scripts/sync-upstream.sh [options]

Options:
  --deploy           Deploy to Vercel with `npx vercel --prod` after syncing.
  --branch <name>    Upstream branch to sync from. Default: main.
  --skip-stash       Refuse to run if there are local changes (no automatic stash).
  --help             Show this help text.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --deploy)
      RUN_DEPLOY=1
      shift
      ;;
    --branch)
      if [[ $# -lt 2 ]]; then
        echo "Missing branch name for --branch"
        usage
        exit 1
      fi
      TARGET_BRANCH="$2"
      shift 2
      ;;
    --skip-stash)
      SKIP_STASH=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Not in a git repository."
  exit 1
fi

if ! git remote get-url origin >/dev/null 2>&1; then
  echo "Missing remote 'origin'. Add origin first: git remote add origin <url>"
  exit 1
fi

CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$CURRENT_BRANCH" == "HEAD" ]]; then
  echo "Cannot run on detached HEAD. Checkout a branch first."
  exit 1
fi

echo "==> Syncing from origin/${TARGET_BRANCH} into ${CURRENT_BRANCH}"

git fetch --prune origin "${TARGET_BRANCH}"

has_local_changes=false
if [[ -n "$(git status --porcelain)" ]]; then
  has_local_changes=true
fi

if [[ "$has_local_changes" == true ]]; then
  if [[ "$SKIP_STASH" == 1 ]]; then
    echo "Local changes detected. Commit, stash, or rerun without --skip-stash."
    git status --short
    exit 1
  fi

  STASH_MESSAGE="codex-sync-upstream-$(date +%Y%m%dT%H%M%S)"
  STASH_MESSAGE="codex-sync-upstream-$(date +%Y%m%dT%H%M%S)"
  echo "==> Stashing local changes (${STASH_MESSAGE})"
  git stash push -u -m "$STASH_MESSAGE" >/dev/null
  STASH_CREATED=1
fi

echo "==> Rebasing ${CURRENT_BRANCH} onto origin/${TARGET_BRANCH}"
if ! git rebase "origin/${TARGET_BRANCH}"; then
  echo "Rebase failed. Resolve conflicts, then run:"
  echo "  git rebase --continue"
  echo "or restore with:"
  echo "  git rebase --abort"
  echo "Then rerun this script."
  exit 1
fi

if [[ "$STASH_CREATED" == 1 ]]; then
  echo "==> Restoring local changes"
  if ! git stash pop >/dev/null; then
    echo "Stash restore hit conflicts."
    echo "Resolve conflicts, stage files, then run:"
    echo "  git add -u && git stash pop"
    echo "or keep stash and run:"
    echo "  git stash show -p"
    exit 1
  fi
fi

echo "==> Sync complete"
if [[ "$RUN_DEPLOY" == 1 ]]; then
  echo "==> Deploying with Vercel"
  npx --yes vercel --prod --yes
fi
