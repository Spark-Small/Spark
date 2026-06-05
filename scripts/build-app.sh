#!/usr/bin/env bash
# Spark — build iOS app for simulator.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DESTINATION="${SPARK_DESTINATION:-platform=iOS Simulator,name=iPhone 17,OS=26.5}"

xcodebuild \
  -project Spark.xcodeproj \
  -scheme Spark \
  -destination "$DESTINATION" \
  -configuration Debug \
  build \
  CODE_SIGNING_ALLOWED=NO
