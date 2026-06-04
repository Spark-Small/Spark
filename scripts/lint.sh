#!/usr/bin/env bash
# Spark — run SwiftLint (install: brew install swiftlint)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! command -v swiftlint >/dev/null 2>&1; then
  echo "error: swiftlint not found. Install with: brew install swiftlint" >&2
  exit 1
fi

swiftlint lint --config .swiftlint.yml --strict
