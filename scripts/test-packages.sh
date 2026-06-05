#!/usr/bin/env bash
# Spark — run Swift Testing for all local iOS SPM packages (simulator).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DESTINATION="${SPARK_DESTINATION:-platform=iOS Simulator,name=iPhone 17,OS=26.5}"

for package_dir in Packages/Spark*/; do
  [[ -f "${package_dir}Package.swift" ]] || continue
  name="$(basename "$package_dir")"
  echo "==> xcodebuild test: ${name}"
  (
    cd "$package_dir"
    xcodebuild test \
      -scheme "$name" \
      -destination "$DESTINATION" \
      CODE_SIGNING_ALLOWED=NO \
      -quiet
  )
done
