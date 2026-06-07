#!/usr/bin/env bash
# Spark — run Xcode app unit tests.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DESTINATION="$("$ROOT/scripts/resolve-spark-destination.sh")"
echo "==> Using destination: ${DESTINATION}"

xcodebuild test \
  -project Spark.xcodeproj \
  -scheme Spark \
  -destination "$DESTINATION" \
  -only-testing:SparkTests \
  CODE_SIGNING_ALLOWED=NO
