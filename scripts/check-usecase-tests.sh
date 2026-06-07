#!/usr/bin/env bash
# Spark — ensure every Domain UseCase has at least one test reference (Gate 1).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

missing=0

while IFS= read -r usecase_file; do
  usecase_name="$(basename "$usecase_file" .swift)"
  package_dir="$(dirname "$(dirname "$(dirname "$(dirname "$(dirname "$usecase_file")")")")")"
  tests_dir="${package_dir}/Tests"
  if [[ ! -d "$tests_dir" ]]; then
    echo "error: no Tests/ for ${usecase_name} in ${package_dir}"
    missing=$((missing + 1))
    continue
  fi
  if ! rg -q "${usecase_name}" "$tests_dir" 2>/dev/null; then
    rel_path="${usecase_file#${ROOT}/}"
    echo "error: missing test reference for ${usecase_name} (${rel_path})"
    missing=$((missing + 1))
  fi
done < <(find Packages/Spark*/Sources -path '*/Domain/UseCases/*.swift' -type f ! -name '*Protocols.swift' | sort)

if [[ "$missing" -gt 0 ]]; then
  echo "UseCase test gate failed: ${missing} untested use case(s)."
  exit 1
fi

echo "UseCase test gate passed."
