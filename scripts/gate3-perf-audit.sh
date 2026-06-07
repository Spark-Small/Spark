#!/usr/bin/env bash
# Spark — Gate 3 performance risk static scan + checklist.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

FAIL=0
WARN=0

fail() {
  echo "FAIL: $1"
  FAIL=$((FAIL + 1))
}

warn() {
  echo "WARN: $1"
  WARN=$((WARN + 1))
}

pass() {
  echo "OK: $1"
}

echo "==> P0: cold launch — no sync bootstrap in SparkApp.init"
if rg -n 'CompositionRoot\.bootstrap\(\)' Spark/SparkApp.swift 2>/dev/null | rg -q 'init|State\(initialValue'; then
  fail "SparkApp.init still synchronously bootstraps dependencies"
else
  pass "SparkApp uses async bootstrap path"
fi

if rg -n 'bootstrapAsync' Spark/SparkApp.swift Spark/App/CompositionRoot.swift >/dev/null 2>&1; then
  pass "bootstrapAsync() present"
else
  fail "bootstrapAsync() missing"
fi

echo "==> P1: APIClient JSON decode off caller executor"
if rg -n 'Task\.detached\(priority: \.utility\)' Packages/SparkNetworking/Sources/SparkNetworking/APIClient.swift >/dev/null 2>&1; then
  pass "APIClient decode uses Task.detached"
else
  fail "APIClient decode not offloaded to background"
fi

echo "==> P1: bounded discover image cache"
if rg -n 'private var storage: \[URL: UIImage\]|UIImage\(data: data\)' \
  Packages/SparkLikes/Sources/SparkLikes/Data/DiscoverMediaImageCache.swift >/dev/null 2>&1; then
  fail "DiscoverMediaImageCache still uses unbounded dict or full-res decode"
else
  pass "DiscoverMediaImageCache delegates to bounded RemoteImageCache"
fi

if rg -n 'NSCache|RemoteImageCache' Packages/SparkNetworking/Sources/SparkNetworking/RemoteImageCache.swift >/dev/null 2>&1; then
  pass "RemoteImageCache uses NSCache"
else
  fail "RemoteImageCache missing"
fi

echo "==> P1: inbound sort cached (not computed in body)"
if rg -n 'var sortedInboundItems: \[InboundLikeItem\] \{' \
  Packages/SparkLikes/Sources/SparkLikes/Presentation/LikesFeedViewModel.swift >/dev/null 2>&1; then
  fail "sortedInboundItems is still a computed property"
else
  pass "sortedInboundItems is stored state"
fi

echo "==> P1: Presentation uses cached remote images (no AsyncImage)"
if rg -q 'AsyncImage\(' Packages --glob '**/Presentation/**/*.swift' 2>/dev/null; then
  fail "Presentation still uses uncached AsyncImage:"
  rg -n 'AsyncImage\(' Packages --glob '**/Presentation/**/*.swift' 2>/dev/null || true
else
  pass "no uncached AsyncImage in Presentation"
fi

echo "==> P1: Community remote images use SparkCachedRemoteImage"
COMMUNITY_ASYNC=$(rg -l 'AsyncImage\(' Packages/SparkCommunity/Sources/SparkCommunity/Presentation 2>/dev/null || true)
if [[ -n "$COMMUNITY_ASYNC" ]]; then
  fail "Community Presentation still uses AsyncImage:"
  echo "$COMMUNITY_ASYNC"
else
  pass "Community Presentation uses cached remote images"
fi

echo "==> P2: ForEach stable identity (no id: \\.self)"
FOREACH_SELF=$(rg -n 'ForEach\([^)]*id: \\.self' Packages --glob '**/Presentation/**/*.swift' 2>/dev/null || true)
if [[ -n "$FOREACH_SELF" ]]; then
  fail "ForEach(..., id: \\.self) still present:"
  echo "$FOREACH_SELF"
else
  pass "no ForEach(..., id: \\.self) in Presentation"
fi

echo "==> CRITICAL: main-thread sync IO patterns"
SYNC_IO=$(rg -n 'FileManager\.default|contentsOfDirectory|Data\(contentsOf:|String\(contentsOf:' \
  Packages Spark --glob '**/*.swift' 2>/dev/null || true)
if [[ -n "$SYNC_IO" ]]; then
  warn "Sync file IO references found (verify not on main thread at runtime):"
  echo "$SYNC_IO"
else
  pass "no obvious sync file IO APIs"
fi

echo "==> CRITICAL: DispatchQueue.main.sync"
if rg -n 'DispatchQueue\.main\.sync' Packages Spark --glob '**/*.swift' >/dev/null 2>&1; then
  fail "DispatchQueue.main.sync found"
else
  pass "no DispatchQueue.main.sync"
fi

echo "==> INFO: Presentation layer counts $(rg -l 'LazyVStack|LazyHStack|LazyVGrid' Packages --glob '**/Presentation/**/*.swift' 2>/dev/null | wc -l | tr -d ' ')"
echo "Plain VStack+ForEach: $(rg -l 'VStack' Packages --glob '**/Presentation/**/*.swift' 2>/dev/null | wc -l | tr -d ' ') files with VStack (manual review for long lists)"

echo
echo "Gate 3 static scan complete."
echo "Failures: $FAIL | Warnings: $WARN"
echo
echo "Instruments checklist (manual, required before release):"
echo "  - App Launch: cold start + time to first interactive"
echo "  - SwiftUI + Animation Hitches: Likes feed + Community feed scroll"
echo "  - Allocations: 5 min feed scroll, memory plateau < 150MB"
echo "  - Leaks: 10 min mixed navigation"

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
