#!/usr/bin/env bash
# Spark — aggregate local guardrail scripts (UI, secrets, API contract).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

./scripts/check-secrets.sh
./scripts/check-ui.sh
./scripts/check-api-contract.sh

echo "All guardrail checks finished"
