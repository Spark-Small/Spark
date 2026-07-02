#!/usr/bin/env bash
# Upload APNs env vars to CloudBase spark-api (MODULE-B.3 / P3).
# See docs/adr/0005-apns-http2-delivery.md and docs/STAGING.md
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_ID="${TCB_ENV_ID:-ais-d1gab0emob99361a0}"
FN_NAME="${TCB_FN_NAME:-spark-api}"
KEY_PATH="${APNS_KEY_PATH:-}"
KEY_ID="${APNS_KEY_ID:-}"
TEAM_ID="${APNS_TEAM_ID:-}"
BUNDLE_ID="${APNS_BUNDLE_ID:-com.spark.app}"
USE_SANDBOX="${APNS_USE_SANDBOX:-true}"

if [[ -z "$KEY_PATH" || -z "$KEY_ID" || -z "$TEAM_ID" ]]; then
  echo "Usage: APNS_KEY_PATH=~/AuthKey_XXX.p8 APNS_KEY_ID=XXX APNS_TEAM_ID=YYY \\" >&2
  echo "       APNS_BUNDLE_ID=com.spark.app APNS_USE_SANDBOX=true \\" >&2
  echo "       ./scripts/configure-apns-env.sh" >&2
  exit 1
fi

if [[ ! -f "$KEY_PATH" ]]; then
  echo "error: APNS_KEY_PATH not found: $KEY_PATH" >&2
  exit 1
fi

PRIVATE_KEY="$(python3 - "$KEY_PATH" <<'PY'
import pathlib, sys
print(pathlib.Path(sys.argv[1]).read_text())
PY
)"
export PRIVATE_KEY
ENV_JSON="$(python3 - "$KEY_ID" "$TEAM_ID" "$BUNDLE_ID" "$USE_SANDBOX" <<'PY'
import json, os, sys
key_id, team_id, bundle_id, sandbox = sys.argv[1:5]
pem = os.environ["PRIVATE_KEY"]
print(json.dumps({
  "APNS_KEY_ID": key_id,
  "APNS_TEAM_ID": team_id,
  "APNS_PRIVATE_KEY": pem,
  "APNS_BUNDLE_ID": bundle_id,
  "APNS_USE_SANDBOX": sandbox,
}))
PY
)"

cd "$ROOT"
if command -v tcb >/dev/null 2>&1; then
  TCB=tcb
elif command -v cloudbase >/dev/null 2>&1; then
  TCB=cloudbase
else
  TCB="npx --yes -p @cloudbase/cli@latest tcb"
fi

echo "==> Updating $FN_NAME env on $ENV_ID (APNS_KEY_ID=$KEY_ID, sandbox=$USE_SANDBOX)"
# shellcheck disable=SC2086
$TCB fn config update "$FN_NAME" -e "$ENV_ID" --envVariables "$ENV_JSON"

echo "==> Health check (apns_configured should be true after cold start)"
BASE_URL="${SPARK_API_BASE_URL:-https://${ENV_ID}.service.tcloudbase.com}"
sleep 5
curl -sf "$BASE_URL/health" | python3 -c 'import sys,json; h=json.load(sys.stdin); print(h); assert "apns_configured" in h'
echo
echo "Done. Register a device token on a physical device, then trigger:"
echo "  POST $BASE_URL/v1/notifications/send"
