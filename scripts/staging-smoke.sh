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

echo "== reset viewer profile =="
curl -sf -X PATCH -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"is_premium":false}' \
  "$BASE_URL/v1/likes/viewer-profile" >/dev/null || true
sleep 1

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
INBOUND_BLUR_OK=0
for _ in 1 2 3 4 5; do
  if curl -sf -H "$AUTH" "$BASE_URL/v1/likes/inbound" \
    | python3 -c 'import sys,json; d=json.load(sys.stdin); items=d.get("items",[]); assert len(items)>0; assert items[0].get("is_visible") is False; print("is_visible=false ok")'; then
    INBOUND_BLUR_OK=1
    break
  fi
  sleep 1
done
[[ "$INBOUND_BLUR_OK" -eq 1 ]] && pass "inbound blur" || fail "inbound blur"

echo "== daily-stats =="
curl -sf -H "$AUTH" "$BASE_URL/v1/likes/daily-stats" \
  | python3 -c 'import sys,json; d=json.load(sys.stdin); assert d.get("daily_pool_size")==50; assert "spark_charges_remaining" in d; print("daily-stats ok")'
pass "daily-stats"

echo "== like body (spark + opener) =="
SPARKS_LEFT=$(curl -sf -H "$AUTH" "$BASE_URL/v1/likes/daily-stats" \
  | python3 -c 'import sys,json; print(json.load(sys.stdin).get("spark_charges_remaining",0))')
if [[ "$SPARKS_LEFT" -gt 0 ]]; then
  LIKE_INTENSITY="spark"
else
  LIKE_INTENSITY="like"
fi
LIKE_OK=0
for _ in 1 2 3 4 5; do
  if curl -sf -X POST -H "$AUTH" -H 'Content-Type: application/json' \
    -d "{\"intensity\":\"$LIKE_INTENSITY\",\"opener\":\"smoke test opener\",\"liked_question_id\":\"sq_1\"}" \
    "$BASE_URL/v1/likes/u_like_4/like" \
    | python3 -c 'import sys,json; d=json.load(sys.stdin); assert d.get("outcome") in ("pending","matched"); print("like body ok")'; then
    LIKE_OK=1
    break
  fi
  sleep 1
done
[[ "$LIKE_OK" -eq 1 ]] && pass "like body ($LIKE_INTENSITY)" || fail "like body"

echo "== premium sync + inbound unlock =="
curl -sf -X PATCH -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"is_premium":true}' \
  "$BASE_URL/v1/likes/viewer-profile" >/dev/null
PREMIUM_UNLOCK_OK=0
for _ in 1 2 3 4 5; do
  if curl -sf -H "$AUTH" "$BASE_URL/v1/likes/inbound" \
    | python3 -c 'import sys,json; d=json.load(sys.stdin); items=d.get("items",[]); assert len(items)>0; assert items[0].get("is_visible") is True; print("is_visible=true ok")'; then
    PREMIUM_UNLOCK_OK=1
    break
  fi
  sleep 1
done
[[ "$PREMIUM_UNLOCK_OK" -eq 1 ]] || fail "premium unlock"
curl -sf -X PATCH -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"is_premium":false}' \
  "$BASE_URL/v1/likes/viewer-profile" >/dev/null
REFUND_BLUR_OK=0
for _ in 1 2 3 4 5; do
  if curl -sf -H "$AUTH" "$BASE_URL/v1/likes/inbound" \
    | python3 -c 'import sys,json; d=json.load(sys.stdin); items=d.get("items",[]); assert len(items)>0; assert items[0].get("is_visible") is False; print("refund blur ok")'; then
    REFUND_BLUR_OK=1
    break
  fi
  sleep 1
done
[[ "$REFUND_BLUR_OK" -eq 1 ]] || fail "premium refund blur"
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
POST_ID=""
for _ in 1 2 3 4 5; do
  POST_ID=$(curl -s -X POST -H "$AUTH" -H 'Content-Type: application/json' \
    -d '{"title":"Smoke post","body":"Staging smoke body"}' \
    "$BASE_URL/v1/community/posts" \
    | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("post",{}).get("id",""))' \
    2>/dev/null || true)
  [[ -n "$POST_ID" ]] && break
  sleep 1
done
[[ -n "$POST_ID" ]] || fail "community post create"
REPLY_OK=0
REPLY_BODY=""
for _ in 1 2 3 4 5; do
  REPLY_BODY=$(curl -s -X POST -H "$AUTH" -H 'Content-Type: application/json' \
    -d '{"body":"Smoke reply"}' \
    "$BASE_URL/v1/community/posts/$POST_ID/replies" \
    | python3 -c 'import sys,json; d=json.load(sys.stdin); r=d.get("reply",{}); print(r.get("body","") if r.get("id") else "")' \
    2>/dev/null || true)
  if [[ "$REPLY_BODY" == "Smoke reply" ]]; then
    REPLY_OK=1
    break
  fi
  sleep 1
done
[[ "$REPLY_OK" -eq 1 ]] || fail "community reply create"
pass "replies=1 on $POST_ID"

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
INBOX_OK=0
for _ in 1 2 3 4 5 6 7 8 9 10; do
  if curl -sf -H "$AUTH" "$BASE_URL/v1/messages/inbox" \
    | python3 -c 'import sys,json; d=json.load(sys.stdin); assert len(d.get("unmessaged_matches",[]))>=1; assert len(d.get("group_conversations",[]))>=1; assert (len(d.get("dm_conversations",[]))+len(d.get("group_conversations",[])))>=1; print("inbox ok")' \
    2>/dev/null; then
    INBOX_OK=1
    break
  fi
  sleep 2
done
[[ "$INBOX_OK" -eq 1 ]] && pass "messages inbox" || fail "messages inbox"

echo "== inbox action dismiss =="
ACTION_ID=$(curl -sf -H "$AUTH" "$BASE_URL/v1/messages/inbox" \
  | python3 -c 'import sys,json; items=json.load(sys.stdin).get("action_items",[]); preferred=next((i["id"] for i in items if i.get("type")!="activity_invite"), None); print(preferred or (items[0]["id"] if items else ""))')
if [[ -n "$ACTION_ID" ]]; then
  curl -sf -X POST -H "$AUTH" "$BASE_URL/v1/messages/inbox/action-items/$ACTION_ID/dismiss" -o /dev/null || true
  export ACTION_ID
  DISMISS_OK=0
  for _ in 1 2 3 4 5; do
    if curl -sf -H "$AUTH" "$BASE_URL/v1/messages/inbox" \
      | python3 -c 'import sys,json,os; d=json.load(sys.stdin); ids=[i["id"] for i in d.get("action_items",[])]; assert os.environ["ACTION_ID"] not in ids; print("dismiss ok")' \
      2>/dev/null; then
      DISMISS_OK=1
      break
    fi
    sleep 1
  done
  [[ "$DISMISS_OK" -eq 1 ]] && pass "inbox action dismiss $ACTION_ID" || fail "inbox action dismiss $ACTION_ID"
else
  pass "inbox action dismiss skipped (empty)"
fi

echo "== thread hide =="
# REASONING: Hide a group thread so repeated smokes do not drain the only DM inbox row.
THREAD_ID="th_activity_act_002"
HIDE_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "$AUTH" \
  "$BASE_URL/v1/messages/threads/$THREAD_ID/hide")
if [[ "$HIDE_CODE" == "204" ]]; then
  pass "thread hide $THREAD_ID"
elif [[ "$HIDE_CODE" == "404" ]]; then
  pass "thread hide skipped (already hidden)"
else
  fail "thread hide HTTP $HIDE_CODE"
fi

echo "== community join =="
curl -sf -X POST -H "$AUTH" "$BASE_URL/v1/community/communities/cm_run/join" \
  | python3 -c 'import sys,json; c=json.load(sys.stdin)["community"]; assert c["id"]=="cm_run"; assert c["is_joined"] is True; print("join ok")'
pass "community join cm_run"

echo "== attendee review + cohost =="
curl -sf -X POST -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"decision":"approve"}' \
  "$BASE_URL/v1/activities/act_smoke_host/attendees/u_like_3/review" >/dev/null \
  || true
REVIEW_OK=0
for _ in 1 2 3 4 5; do
  if curl -sf -H "$AUTH" "$BASE_URL/v1/activities/act_smoke_host" \
    | python3 -c 'import sys,json; a=json.load(sys.stdin)["activity"]; att=next(x for x in a.get("attendees",[]) if x["id"]=="u_like_3"); assert att["rsvp_status"] in ("going","host"); print("review ok")'; then
    REVIEW_OK=1
    break
  fi
  sleep 1
done
[[ "$REVIEW_OK" -eq 1 ]] && pass "attendee review approve" || fail "attendee review approve"
curl -sf -X POST -H "$AUTH" \
  "$BASE_URL/v1/activities/act_smoke_host/attendees/u_like_3/cohost" >/dev/null \
  || true
COHOST_OK=0
for _ in 1 2 3 4 5; do
  if curl -sf -H "$AUTH" "$BASE_URL/v1/activities/act_smoke_host" \
    | python3 -c 'import sys,json; a=json.load(sys.stdin)["activity"]; att=next(x for x in a.get("attendees",[]) if x["id"]=="u_like_3"); assert att.get("is_cohost") is True; print("cohost ok")'; then
    COHOST_OK=1
    break
  fi
  sleep 1
done
[[ "$COHOST_OK" -eq 1 ]] && pass "attendee cohost" || fail "attendee cohost"

echo "== notifications stub =="
curl -sf -X POST -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"user_id":"u_staging_1","type":"likes.inbound","payload":{}}' \
  "$BASE_URL/v1/notifications/send" \
  | python3 -c 'import sys,json; d=json.load(sys.stdin); assert d.get("queued") is True; print("queued ok")'
pass "notifications"

echo "All staging smoke checks passed."
