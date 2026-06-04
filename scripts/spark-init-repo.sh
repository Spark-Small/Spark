#!/usr/bin/env bash
# Spark one-time repository bootstrap (run from repo root).
# Usage: ./scripts/spark-init-repo.sh
# Optional: GITHUB_REMOTE_URL=https://github.com/ORG/Spark.git ./scripts/spark-init-repo.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

log() { printf '==> %s\n' "$*"; }

ensure_dir() {
  mkdir -p "$@"
}

log "Creating directory scaffold…"

# SPM feature / infrastructure packages (Clean Architecture layout per module)
MODULES=(Auth Feed Profile Notifications Onboarding)
INFRA=(Core Network Persistence UI DesignSystem)

for mod in "${MODULES[@]}"; do
  base="Packages/${mod}"
  ensure_dir \
    "${base}/Sources/${mod}/Domain/Models" \
    "${base}/Sources/${mod}/Domain/UseCases" \
    "${base}/Sources/${mod}/Data/DTOs" \
    "${base}/Sources/${mod}/Presentation" \
    "${base}/Tests/${mod}Tests/Mocks"
  touch "${base}/Sources/${mod}/Domain/.gitkeep" \
        "${base}/Sources/${mod}/Data/.gitkeep" \
        "${base}/Tests/${mod}Tests/.gitkeep"
done

for mod in "${INFRA[@]}"; do
  base="Packages/${mod}"
  ensure_dir "${base}/Sources/${mod}" "${base}/Tests/${mod}Tests"
  touch "${base}/Sources/${mod}/.gitkeep" "${base}/Tests/${mod}Tests/.gitkeep"
done

# App target folders (Xcode FS-synced Spark/ app stays at Spark/)
ensure_dir \
  Spark/App \
  Spark/Features \
  Spark/Core \
  Spark/DesignSystem \
  Spark/Resources/Localization/en.lproj \
  Spark/Resources/Localization/zh-Hans.lproj

touch Spark/Features/.gitkeep Spark/Core/.gitkeep Spark/DesignSystem/.gitkeep

# Config, tooling, docs
ensure_dir \
  Config \
  Secrets \
  Scripts \
  fastlane \
  docs/adr \
  Tests/SparkUITests \
  .github/workflows \
  .github/ISSUE_TEMPLATE

touch Config/.gitkeep Secrets/.gitkeep fastlane/.gitkeep Tests/SparkUITests/.gitkeep

log "Initializing Git (if needed)…"
if [[ ! -d .git ]]; then
  git init -b main
fi

if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
  git add -A
  git commit -m "$(cat <<'EOF'
chore(release): bootstrap Spark monorepo layout and Git workflow docs

Add Packages scaffold, GitHub templates, CI stub, and contributor docs.
EOF
)"
fi

if ! git show-ref --verify --quiet refs/heads/develop; then
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
  log "Pushing main and develop…"
  git push -u origin main
  git push -u origin develop
else
  log "Skip push (set GITHUB_REMOTE_URL to push), e.g.:"
  log "  GITHUB_REMOTE_URL=https://github.com/YOUR_ORG/Spark.git ./scripts/spark-init-repo.sh"
fi

log "Done. Next: configure branch protection — see docs/GITHUB_BRANCH_PROTECTION.md"
