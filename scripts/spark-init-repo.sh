#!/usr/bin/env bash
# Spark one-time repository bootstrap (run from repo root).
# Usage: ./scripts/spark-init-repo.sh
# Aligns with docs/PACKAGES.md — does not create legacy Spark/Features layout.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

log() { printf '==> %s\n' "$*"; }

ensure_dir() {
  mkdir -p "$@"
}

if [[ -f Packages/SparkCore/Package.swift ]]; then
  log "Spark SPM layout already present — skipping package scaffold."
else
  log "Creating Packages/SparkCore scaffold (clone docs/PACKAGES.md for full set)…"
  ensure_dir Packages/SparkCore/Sources/SparkCore Packages/SparkCore/Tests/SparkCoreTests
  touch Packages/SparkCore/Sources/SparkCore/.gitkeep Packages/SparkCore/Tests/SparkCoreTests/.gitkeep
fi

log "Ensuring app & tooling directories…"
ensure_dir \
  Spark/App \
  Config \
  docs \
  scripts \
  .github/workflows \
  .github/ISSUE_TEMPLATE

touch Config/.gitkeep 2>/dev/null || true

log "Initializing Git (if needed)…"
if [[ ! -d .git ]]; then
  git init -b main
fi

if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
  git add -A
  git commit -m "$(cat <<'EOF'
chore: bootstrap Spark repository layout

EOF
)"
fi

if ! git show-ref --verify --quiet refs/heads/develop 2>/dev/null; then
  git branch develop
  log "Created branch: develop"
fi

if [[ -n "${GITHUB_REMOTE_URL:-}" ]]; then
  if git remote get-url origin >/dev/null 2>&1; then
    log "Remote origin already set: $(git remote get-url origin)"
  else
    git remote add origin "$GITHUB_REMOTE_URL"
    log "Added remote: $GITHUB_REMOTE_URL"
  fi
  git push -u origin main
  git push -u origin develop
else
  log "Skip push (set GITHUB_REMOTE_URL to push)."
fi

log "Done. See docs/INIT.md and docs/GITHUB_BRANCH_PROTECTION.md"
