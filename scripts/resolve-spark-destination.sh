#!/usr/bin/env bash
# Resolves xcodebuild -destination for Spark scripts.
# Honors SPARK_DESTINATION when set; otherwise picks the newest available iPhone simulator.
set -euo pipefail

if [[ -n "${SPARK_DESTINATION:-}" ]]; then
  printf '%s' "$SPARK_DESTINATION"
  exit 0
fi

PREFERRED_DEVICE="${SPARK_SIMULATOR_DEVICE:-iPhone 17}"

runtime_line="$(xcrun simctl list runtimes available 2>/dev/null | grep -E 'iOS [0-9]' | tail -1 || true)"
if [[ -z "$runtime_line" ]]; then
  printf 'generic/platform=iOS Simulator'
  exit 0
fi

# Prefer the build number inside parentheses, e.g. "iOS 26.4 (26.4.1 - …)" → 26.4.1
if [[ "$runtime_line" =~ \(([0-9]+\.[0-9]+\.[0-9]+) ]]; then
  os_version="${BASH_REMATCH[1]}"
else
  os_version="$(echo "$runtime_line" | sed -E 's/.*iOS ([0-9.]+).*/\1/')"
fi

if xcrun simctl list devices available 2>/dev/null | grep -q "${PREFERRED_DEVICE} ("; then
  printf 'platform=iOS Simulator,name=%s,OS=%s' "$PREFERRED_DEVICE" "$os_version"
else
  device_name="$(xcrun simctl list devices available 2>/dev/null | grep -E 'iPhone' | head -1 | sed -E 's/^[[:space:]]+([^()]+).*/\1/' | sed 's/[[:space:]]*$//')"
  if [[ -n "$device_name" ]]; then
    printf 'platform=iOS Simulator,name=%s,OS=%s' "$device_name" "$os_version"
  else
    printf 'generic/platform=iOS Simulator'
  fi
fi
