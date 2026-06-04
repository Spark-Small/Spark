#!/usr/bin/env bash
# Spark — guardrails for SwiftUI presentation code (no fake glass / decoration patterns).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail=0

swift_files() {
  find Packages Spark -name '*.swift' \
    ! -path '*/Tests/*' \
    ! -path '*/.build/*' \
    -print
}

presentation_files() {
  swift_files | while read -r f; do
    case "$f" in
      *Presentation*|*View.swift) echo "$f" ;;
    esac
  done
}

if_presentation_matches() {
  local pattern="$1"
  local message="$2"
  local hits
  hits="$(presentation_files | xargs grep -En "$pattern" 2>/dev/null || true)"
  if [[ -n "$hits" ]]; then
    echo "error: $message"
    echo "$hits"
    fail=1
  fi
}

if_presentation_matches 'Color\.white\.opacity|Color\.black\.opacity' \
  'Do not use opacity fills for glass (use Material or glassEffect)'

if_presentation_matches 'blur\(radius:' \
  'Do not use manual blur — use system materials'

if_presentation_matches 'shadow\(color:' \
  'Do not use shadow for depth — use materials / hierarchy'

hits="$(swift_files | xargs grep -En 'print\(' 2>/dev/null || true)"
if [[ -n "$hits" ]]; then
  echo "error: Do not use print() — use Logger (os)"
  echo "$hits"
  fail=1
fi

hits="$(swift_files | xargs grep -En 'DispatchQueue\.main\.async' 2>/dev/null || true)"
if [[ -n "$hits" ]]; then
  echo "error: Use @MainActor / async-await instead of DispatchQueue.main.async"
  echo "$hits"
  fail=1
fi

hits="$(presentation_files | xargs grep -En 'URLSession|URLRequest' 2>/dev/null || true)"
if [[ -n "$hits" ]]; then
  echo "error: URLSession must not appear in Presentation views"
  echo "$hits"
  fail=1
fi

if [[ "$fail" -ne 0 ]]; then
  echo "check-ui failed — see docs/DESIGN_PHILOSOPHY.md and docs/UI_REVIEW.md"
  exit 1
fi

echo "check-ui passed"
