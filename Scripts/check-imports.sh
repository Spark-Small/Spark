#!/usr/bin/env bash
# 模块边界静态检查：Design 不依赖领域模型；CoordinateModels 不依赖 UI 框架。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FAILED=0

DESIGN_ALLOWLIST=(
  "ActivityZoomNavigation.swift"
  "WalletPassFace.swift"
  "WalletPassStripViews.swift"
  "WalletPassFaceFactory.swift"
  "WalletPassRecordFace.swift"
  "PlatformCatalogCards.swift"
  "PlatformMessagesChromeMetrics.swift"
  "PlatformChatThreadChrome.swift"
  "PlatformChatBubble.swift"
  "PlatformMessageComposerBar.swift"
  "CredentialArtTheme.swift"
)

is_allowlisted() {
  local file="$1"
  local base
  base="$(basename "$file")"
  for allowed in "${DESIGN_ALLOWLIST[@]}"; do
    if [[ "$base" == "$allowed" ]]; then
      return 0
    fi
  done
  return 1
}

echo "→ Features/ 不应 import AppComposition（走 AppDependencies / @Environment）"
while IFS= read -r file; do
  if grep -q '^import.*AppComposition' "$file" || grep -q 'AppComposition\.' "$file"; then
    echo "  ✗ $file"
    FAILED=1
  fi
done < <(find "$ROOT/坐标系/Features" -name '*.swift' 2>/dev/null | sort)

echo "→ Features/ 不应 import CoordinateData（走 CoordinateDomain 协议）"
while IFS= read -r file; do
  if grep -q '^import CoordinateData' "$file"; then
    echo "  ✗ $file"
    FAILED=1
  fi
done < <(find "$ROOT/坐标系/Features" -name '*.swift' 2>/dev/null | sort)

echo "→ Design/ 不应 import CoordinateModels（白名单除外）"
while IFS= read -r file; do
  if is_allowlisted "$file"; then
    continue
  fi
  if grep -q '^import CoordinateModels' "$file"; then
    echo "  ✗ $file"
    FAILED=1
  fi
done < <(find "$ROOT/坐标系/Design" -name '*.swift' 2>/dev/null | sort)

echo "→ CoordinateModels/ 不应 import SwiftUI / UIKit"
while IFS= read -r file; do
  if grep -Eq '^import (SwiftUI|UIKit)' "$file"; then
    echo "  ✗ $file"
    FAILED=1
  fi
done < <(find "$ROOT/Packages/CoordinateKit/Sources/CoordinateModels" -name '*.swift' 2>/dev/null | sort)

if [[ "$FAILED" -ne 0 ]]; then
  echo ""
  echo "Import boundary check failed."
  exit 1
fi

echo "Import boundaries OK."
