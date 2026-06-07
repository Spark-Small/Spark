#!/usr/bin/env bash
# Spark — build iOS app for simulator.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DESTINATION="$("$ROOT/scripts/resolve-spark-destination.sh")"
echo "==> Using destination: ${DESTINATION}"

xcodebuild \
  -project Spark.xcodeproj \
  -scheme Spark \
  -destination "$DESTINATION" \
  -configuration Debug \
  build \
  CODE_SIGNING_ALLOWED=NO
