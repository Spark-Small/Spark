#!/usr/bin/env bash
# Spark — Domain + Data line coverage gate (Gate 1 ≥ 80%).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

MIN_COVERAGE="${SPARK_MIN_DOMAIN_DATA_COVERAGE:-80}"
DESTINATION="${SPARK_DESTINATION:-platform=iOS Simulator,name=iPhone 17}"

total_executable=0
total_covered=0

should_skip_file() {
  local name="$1"
  case "$name" in
    Live*|Preview*) return 0 ;;
    *+Live.swift) return 0 ;;
    AppleSignInCoordinator.swift) return 0 ;;
    ActivityLocalReminderScheduler.swift) return 0 ;;
    ActivityCalendarExportService.swift) return 0 ;;
    *APIPath.swift) return 0 ;;
  esac
  return 1
}

for package_dir in Packages/Spark*/; do
  [[ -f "${package_dir}Package.swift" ]] || continue
  name="$(basename "$package_dir")"
  result="/tmp/spark-coverage-${name}.xcresult"
  rm -rf "$result"

  echo "==> Coverage: ${name}"
  (
    cd "$package_dir"
    xcodebuild test \
      -scheme "$name" \
      -destination "$DESTINATION" \
      -enableCodeCoverage YES \
      -resultBundlePath "$result" \
      CODE_SIGNING_ALLOWED=NO \
      -quiet
  )

  while IFS=$'\t' read -r executable covered; do
    [[ -z "$executable" ]] && continue
    total_executable=$((total_executable + executable))
    total_covered=$((total_covered + covered))
  done < <(
    xcrun xccov view --report --json "$result" 2>/dev/null | python3 -c '
import json, sys

SKIP_NAMES = {
    "AppleSignInCoordinator.swift",
    "ActivityLocalReminderScheduler.swift",
    "ActivityCalendarExportService.swift",
}

def should_skip(name: str) -> bool:
    if name in SKIP_NAMES:
        return True
    if name.startswith("Live") or name.startswith("Preview"):
        return True
    if name.endswith("+Live.swift"):
        return True
    if name.endswith("APIPath.swift"):
        return True
    return False

data = json.load(sys.stdin)
by_path: dict[str, tuple[int, int]] = {}
for target in data.get("targets", []):
    for file in target.get("files", []):
        path = file.get("path", "")
        name = path.split("/")[-1]
        if "/Domain/" not in path and "/Data/" not in path:
            continue
        if should_skip(name):
            continue
        lines = int(file.get("executableLines", 0))
        if lines == 0:
            continue
        line_cov = file.get("lineCoverage")
        cov = int(round(float(line_cov) * lines)) if line_cov is not None else 0
        prev = by_path.get(path)
        if prev is None or lines > prev[0]:
            by_path[path] = (lines, cov)

executable = sum(v[0] for v in by_path.values())
covered = sum(v[1] for v in by_path.values())
print(f"{executable}\t{covered}")
'
  )
done

if [[ "$total_executable" -eq 0 ]]; then
  echo "error: no Domain/Data executable lines collected"
  exit 1
fi

pct=$((total_covered * 100 / total_executable))
echo "Domain+Data coverage: ${pct}% (${total_covered}/${total_executable} lines, min ${MIN_COVERAGE}%)"

if [[ "$pct" -lt "$MIN_COVERAGE" ]]; then
  exit 1
fi
