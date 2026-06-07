#!/usr/bin/env bash
# Deploy cloudfunctions/spark-api to CloudBase Staging (docs/DEVELOPMENT.md).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/cloudfunctions/spark-api"

ENV_ID="${TCB_ENV_ID:-ais-d1gab0emob99361a0}"
FN_NAME="${TCB_FUNCTION_NAME:-spark-api}"
BASE_URL="${SPARK_API_BASE_URL:-https://${ENV_ID}.service.tcloudbase.com}"

echo "==> Installing spark-api dependencies"
npm install --omit=dev

deploy_with_tcb() {
  local tcb_cmd="$1"
  printf '\n' | "$tcb_cmd" fn code update "$FN_NAME" \
    -e "$ENV_ID" \
    --dir . \
    --deployMode zip \
    --yes
}

echo "==> Updating CloudBase function: ${FN_NAME} (env ${ENV_ID})"
if command -v tcb >/dev/null 2>&1; then
  deploy_with_tcb tcb
elif command -v cloudbase >/dev/null 2>&1; then
  deploy_with_tcb cloudbase
else
  printf '\n' | npx --yes @cloudbase/cli@latest tcb fn code update "$FN_NAME" \
    -e "$ENV_ID" \
    --dir . \
    --deployMode zip \
    --yes
fi

echo "==> Waiting ~30s for gateway propagation"
sleep 30

echo "==> Health check: ${BASE_URL}/health"
curl -sf "${BASE_URL}/health" | tee /tmp/spark-health.json
echo

if [[ "${SKIP_SMOKE:-}" == "1" ]]; then
  echo "==> Skipping staging smoke (SKIP_SMOKE=1)"
else
  echo "==> Staging smoke (trust + recap)"
  cd "$ROOT"
  SPARK_API_BASE_URL="$BASE_URL" ./scripts/staging-smoke.sh
fi

echo "Deploy checks passed."
