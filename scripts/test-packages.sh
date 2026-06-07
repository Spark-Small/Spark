#!/usr/bin/env bash
# Spark — run Swift Testing for all local iOS SPM packages (simulator).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DESTINATION="$("$ROOT/scripts/resolve-spark-destination.sh")"
echo "==> Using destination: ${DESTINATION}"

for package_dir in Packages/Spark*/; do
  [[ -f "${package_dir}Package.swift" ]] || continue
  name="$(basename "$package_dir")"
  if [[ "$name" == "SparkLikes" ]]; then
    echo "==> skip archived package: ${name} (see docs/adr/0004-sparklikes-archived.md)"
    continue
  fi
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
