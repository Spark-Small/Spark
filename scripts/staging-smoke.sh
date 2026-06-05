#!/usr/bin/env bash
# Staging HTTP smoke for spark-api (docs/STAGING.md).
set -euo pipefail

BASE_URL="${SPARK_API_BASE_URL:-https://ais-d1gab0emob99361a0.service.tcloudbase.com}"
EMAIL="${SPARK_STAGING_EMAIL:-staging@test.com}"
PASSWORD="${SPARK_STAGING_PASSWORD:-staging123}"

echo "== health =="
curl -sf "$BASE_URL/health" | tee /tmp/spark-health.json
echo

TOKEN=$(curl -sf -X POST "$BASE_URL/v1/auth/email" \
  -H 'Content-Type: application/json' \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}" \
  | python3 -c 'import sys,json; print(json.load(sys.stdin)["access_token"])')

AUTH="Authorization: Bearer $TOKEN"
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; exit 1; }

echo "== browse =="
BROWSE_COUNT=$(curl -sf -H "$AUTH" "$BASE_URL/v1/activities/browse" \
  | python3 -c 'import sys,json; print(len(json.load(sys.stdin).get("items",[])))')
[[ "$BROWSE_COUNT" -ge 2 ]] && pass "browse count=$BROWSE_COUNT" || fail "browse count=$BROWSE_COUNT"

echo "== browse time filter =="
read -r WEEK_START WEEK_END < <(python3 -c 'from datetime import datetime, timezone, timedelta
now = datetime.now(timezone.utc)
start = (now - timedelta(days=now.weekday())).replace(hour=0, minute=0, second=0, microsecond=0)
end = start + timedelta(days=7)
print(start.strftime("%Y-%m-%dT%H:%M:%SZ"), end.strftime("%Y-%m-%dT%H:%M:%SZ"))')
FILTERED_COUNT=$(curl -sf -H "$AUTH" \
  "$BASE_URL/v1/activities/browse?starts_after=$WEEK_START&starts_before=$WEEK_END" \
  | python3 -c 'import sys,json; print(len(json.load(sys.stdin).get("items",[])))')
[[ "$FILTERED_COUNT" -ge 1 && "$FILTERED_COUNT" -le "$BROWSE_COUNT" ]] \
  && pass "browse week filter count=$FILTERED_COUNT (total=$BROWSE_COUNT)" \
  || fail "browse week filter count=$FILTERED_COUNT (total=$BROWSE_COUNT)"

echo "== inbound is_visible =="
curl -sf -H "$AUTH" "$BASE_URL/v1/likes/inbound" \
  | python3 -c 'import sys,json; d=json.load(sys.stdin); items=d.get("items",[]); assert len(items)>0; assert items[0].get("is_visible") is False; print("is_visible=false ok")'
pass "inbound blur"

echo "== daily-stats =="
curl -sf -H "$AUTH" "$BASE_URL/v1/likes/daily-stats" \
  | python3 -c 'import sys,json; d=json.load(sys.stdin); assert d.get("daily_pool_size")==50; assert "spark_charges_remaining" in d; print("daily-stats ok")'
pass "daily-stats"

echo "== like body (spark + opener) =="
curl -sf -X POST -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"intensity":"spark","opener":"smoke test opener","liked_question_id":"sq_1"}' \
  "$BASE_URL/v1/likes/u_like_3/like" \
  | python3 -c 'import sys,json; d=json.load(sys.stdin); assert d.get("outcome") in ("pending","matched"); print("like body ok")'
pass "like body"

echo "== premium sync + inbound unlock =="
curl -sf -X PATCH -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"is_premium":true}' \
  "$BASE_URL/v1/likes/viewer-profile" >/dev/null
curl -sf -H "$AUTH" "$BASE_URL/v1/likes/inbound" \
  | python3 -c 'import sys,json; d=json.load(sys.stdin); items=d.get("items",[]); assert len(items)>0; assert items[0].get("is_visible") is True; print("is_visible=true ok")'
curl -sf -X PATCH -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"is_premium":false}' \
  "$BASE_URL/v1/likes/viewer-profile" >/dev/null
curl -sf -H "$AUTH" "$BASE_URL/v1/likes/inbound" \
  | python3 -c 'import sys,json; d=json.load(sys.stdin); items=d.get("items",[]); assert len(items)>0; assert items[0].get("is_visible") is False; print("refund blur ok")'
pass "premium sync refund blur"

echo "== community feed =="
FEED_ITEMS=$(curl -sf -H "$AUTH" "$BASE_URL/v1/community/feed" \
  | python3 -c 'import sys,json; print(len(json.load(sys.stdin).get("items",[])))')
[[ "$FEED_ITEMS" -ge 1 ]] && pass "feed items=$FEED_ITEMS" || fail "feed items=$FEED_ITEMS"

echo "== community detail =="
curl -sf -H "$AUTH" "$BASE_URL/v1/community/communities/cm_hike" \
  | python3 -c 'import sys,json; c=json.load(sys.stdin)["community"]; assert c["id"]=="cm_hike"; print("community ok")'
pass "community detail cm_hike"

echo "== community post + reply =="
POST_ID=$(curl -sf -X POST -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"title":"Smoke post","body":"Staging smoke body"}' \
  "$BASE_URL/v1/community/posts" \
  | python3 -c 'import sys,json; print(json.load(sys.stdin)["post"]["id"])')
curl -sf -X POST -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"body":"Smoke reply"}' \
  "$BASE_URL/v1/community/posts/$POST_ID/replies" >/dev/null
REPLIES=$(curl -sf -H "$AUTH" "$BASE_URL/v1/community/posts/$POST_ID" \
  | python3 -c 'import sys,json; print(len(json.load(sys.stdin)["post"].get("replies",[])))')
[[ "$REPLIES" -ge 1 ]] && pass "replies=$REPLIES on $POST_ID" || fail "replies missing"

echo "== devices 204 =="
curl -sf -o /dev/null -w "%{http_code}" -X POST -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"token":"abc123smoke","platform":"ios"}' \
  "$BASE_URL/v1/devices" | grep -q 204 && pass "devices" || fail "devices"

echo "== avatar upload-url =="
curl -sf -X POST -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"content_type":"image/jpeg"}' \
  "$BASE_URL/v1/users/avatar/upload-url" \
  | python3 -c 'import sys,json; assert "upload_url" in json.load(sys.stdin); print("upload_url ok")'
pass "avatar upload-url"

echo "== community report =="
REPORT_ID=$(curl -sf -X POST -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"reason":"smoke_test"}' \
  "$BASE_URL/v1/community/posts/cp_001/report" \
  | python3 -c 'import sys,json; print(json.load(sys.stdin)["report_id"])')
[[ -n "$REPORT_ID" ]] && pass "report $REPORT_ID" || fail "community report"

echo "== messages inbox =="
curl -sf -H "$AUTH" "$BASE_URL/v1/messages/inbox" \
  | python3 -c 'import sys,json; d=json.load(sys.stdin); assert len(d.get("action_items",[]))>=1; assert len(d.get("unmessaged_matches",[]))>=1; assert len(d.get("dm_conversations",[]))>=1; assert len(d.get("group_conversations",[]))>=1; print("inbox ok")'
pass "messages inbox"

echo "== inbox action dismiss =="
curl -sf -X POST -H "$AUTH" "$BASE_URL/v1/messages/inbox/action-items/action_change_1/dismiss" -o /dev/null
curl -sf -H "$AUTH" "$BASE_URL/v1/messages/inbox" \
  | python3 -c 'import sys,json; d=json.load(sys.stdin); ids=[i["id"] for i in d.get("action_items",[])]; assert "action_change_1" not in ids; print("dismiss ok")'
pass "inbox action dismiss"

echo "== notifications stub =="
curl -sf -X POST -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"user_id":"u_staging_1","type":"likes.inbound","payload":{}}' \
  "$BASE_URL/v1/notifications/send" \
  | python3 -c 'import sys,json; d=json.load(sys.stdin); assert d.get("queued") is True; print("queued ok")'
pass "notifications"

echo "All staging smoke checks passed."
