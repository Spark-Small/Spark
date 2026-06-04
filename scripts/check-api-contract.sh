#!/usr/bin/env bash
# Spark — warn when Live API paths are missing from docs/API_CONTRACT.md.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

CONTRACT="$ROOT/docs/API_CONTRACT.md"
if [[ ! -f "$CONTRACT" ]]; then
  echo "error: missing $CONTRACT"
  exit 1
fi

LIVE_PATHS="$(grep -rhoE '"/v1/[^"]+"' Packages Spark/App --include='*.swift' 2>/dev/null \
  | tr -d '"' \
  | sed 's/{[^}]*}//g' \
  | sort -u || true)"

missing=0
while IFS= read -r path; do
  [[ -z "$path" ]] && continue
  if ! grep -qF "$path" "$CONTRACT"; then
    echo "warning: Live path not documented in API_CONTRACT.md: $path"
    missing=1
  fi
done <<< "$LIVE_PATHS"

if [[ "$missing" -ne 0 ]]; then
  echo "check-api-contract: update docs/API_CONTRACT.md (warnings only)"
  exit 0
fi

echo "check-api-contract passed"
