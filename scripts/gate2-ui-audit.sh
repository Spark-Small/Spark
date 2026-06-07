#!/usr/bin/env bash
# Spark — Gate 2 UI compliance scan (liquid glass + HIG + a11y smoke).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> CRITICAL pattern scan (must be 0)"
CRITICAL=$(rg -n \
  'Color\.(white|gray)\.opacity|Color\(white:|\.blur\(radius:|\.cornerRadius\(|\.shadow\(radius:\s*(9|[1-9][0-9])' \
  Packages --glob '**/Presentation/**/*.swift' 2>/dev/null || true)
if [[ -n "$CRITICAL" ]]; then
  echo "$CRITICAL"
  echo "FAIL: CRITICAL violations found"
  exit 1
fi
echo "OK: no CRITICAL violations"

echo "==> P1: cornerRadius < 16 on cards"
rg -n 'cornerRadius:\s*(8|9|10|11|12|13|14|15)' \
  Packages --glob '**/Presentation/**/*.swift' 2>/dev/null || true

echo "==> P1: easeIn/easeOut on interactions"
rg -n '\.animation\(\.(easeIn|easeOut|easeInOut|linear)' \
  Packages --glob '**/Presentation/**/*.swift' 2>/dev/null || true

echo "==> P1: direct Material (should use sparkGlassSurface/Control)"
rg -n '\.background\(\.(ultraThin|thin|regular|thick)Material' \
  Packages --glob '**/Presentation/**/*.swift' 2>/dev/null || true

echo "==> P1: hardcoded Color.green/red/blue"
rg -n 'Color\.(green|red|blue|orange|pink)\b' \
  Packages --glob '**/Presentation/**/*.swift' 2>/dev/null || true

echo "==> A11y coverage"
A11Y_PATTERN='accessibilityLabel|accessibilityHidden|accessibilityElement|accessibilityHint|accessibilityValue|accessibilityAddTraits'
VIEW_FILES=$(rg -l 'struct \w+: View' Packages --glob '**/Presentation/**/*.swift' 2>/dev/null | sort)
VIEW_COUNT=$(echo "$VIEW_FILES" | sed '/^$/d' | wc -l | tr -d ' ')
MISSING=$(comm -23 \
  <(echo "$VIEW_FILES") \
  <(rg -l "$A11Y_PATTERN" Packages --glob '**/Presentation/**/*.swift' 2>/dev/null | sort))
MISSING_COUNT=$(echo "$MISSING" | sed '/^$/d' | wc -l | tr -d ' ')
COVERED=$((VIEW_COUNT - MISSING_COUNT))
echo "Presentation views with a11y: $COVERED / $VIEW_COUNT"
if [[ -n "$MISSING" ]]; then
  echo "Missing a11y in:"
  echo "$MISSING"
  echo "FAIL: a11y coverage must be 100% ($COVERED / $VIEW_COUNT)"
  exit 1
fi

echo "Gate 2 UI audit scan complete."
