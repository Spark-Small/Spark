#!/usr/bin/env bash
# Spark — CI entry point (lint + SPM tests + app build/test).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

export SPARK_DESTINATION="${SPARK_DESTINATION:-platform=iOS Simulator,name=iPhone 17,OS=26.4.1}"

./scripts/check-guardrails.sh

if command -v swiftlint >/dev/null 2>&1; then
  ./scripts/lint.sh
else
  echo "warning: swiftlint not installed; skipping lint"
fi

./scripts/test-packages.sh
./scripts/build-app.sh
./scripts/test-app.sh
