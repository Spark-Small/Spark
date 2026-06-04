#!/usr/bin/env bash
# Spark — block accidental commit of secrets and production keys.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail=0

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  TRACKED=()
  while IFS= read -r line; do TRACKED+=("$line"); done < <(git ls-files)
else
  TRACKED=()
  while IFS= read -r line; do TRACKED+=("$line"); done < <(find Packages Spark Config -type f 2>/dev/null)
fi

for path in "${TRACKED[@]}"; do
  case "$path" in
    *Secrets.xcconfig|*GoogleService-Info.plist|*.p8|*.mobileprovision)
      echo "error: secret or signing file must not be tracked: $path"
      fail=1
      ;;
  esac
done

scan_content() {
  local pattern="$1"
  local label="$2"
  for path in "${TRACKED[@]}"; do
    case "$path" in
      *.example|scripts/check-secrets.sh) continue ;;
    esac
    if grep -qE "$pattern" "$path" 2>/dev/null; then
      echo "error: possible $label in $path"
      fail=1
    fi
  done
}

scan_content 'BEGIN (RSA |OPENSSH |EC) PRIVATE KEY' 'private key'
scan_content 'sk_live_|sk_test_' 'payment secret key'

if [[ "$fail" -ne 0 ]]; then
  exit 1
fi

echo "check-secrets passed"
