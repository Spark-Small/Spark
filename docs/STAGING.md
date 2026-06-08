# Spark — Staging cutover

**Related:** [DEVELOPMENT.md](DEVELOPMENT.md) · [API_CONTRACT.md](API_CONTRACT.md) · [DEVELOPMENT_PLAN.md](DEVELOPMENT_PLAN.md) Phase 5

## When to use Staging

Use Staging when the backend team has deployed endpoints in [API_CONTRACT.md](API_CONTRACT.md) and you need to validate **Live*** repositories on a real host (not `mock.spark.local`).

## Setup (one time)

1. Copy the example secrets file:
   ```bash
   cp Config/Secrets.xcconfig.example Config/Secrets.xcconfig
   ```
2. Edit `Config/Secrets.xcconfig` and set your team URL (no trailing slash):
   ```
   // CloudBase 体验环境（HTTP 云函数 spark-api）
   SPARK_API_BASE_URL = https://ais-d1gab0emob99361a0.service.tcloudbase.com
   ```
   Test account (CI/smoke only): `staging@test.com` / `staging123` via `POST /v1/auth/email` — **not shown in the iOS login UI**.

   **CN login on Staging (no vendor SDK):** set `SPARK_CN_AUTH_STAGING_BRIDGE = 1` in `Secrets.xcconfig` (default in `Spark.xcconfig`). The app uses magic tokens accepted by Staging:

   | Provider | Magic value |
   |----------|-------------|
   | WeChat | OAuth code `staging-wechat-code` |
   | Aliyun phone | token `staging-aliyun-token` |
   | Tencent phone | token `staging-tencent-token` |
   | Alipay | auth code `staging-alipay-code` |

   See [CN_AUTH_SDK_SETUP.md](CN_AUTH_SDK_SETUP.md) for production SDK wiring.

   **CN payments on Staging:** set `INFOPLIST_KEY_SPARKCNPaymentsEnabled = YES` in `Secrets.xcconfig`. Paywall shows WeChat Pay / Alipay when logged in. Magic receipts:

   | Provider | Magic receipt |
   |----------|---------------|
   | WeChat Pay | `staging-wechat-pay-receipt` |
   | Alipay Pay | `staging-alipay-pay-receipt` |
3. `Config/Spark.xcconfig` already `#include`s `Secrets.xcconfig` when present (gitignored).
4. Clean build in Xcode (or `make build`) so `APIConfiguration.loadFromBundle()` picks up the new host.

## How iOS chooses Mock vs Live

`APIConfiguration.usesMockBackend` is `true` when the base URL host contains `mock.spark.local`. Any other host (Staging, Production) wires **Live*** types in `Spark/App/CompositionRoot.swift`.

| Repository | Mock | Live |
|------------|------|------|
| Auth | `MockAuthService` | `LiveAuthService` |
| Messages | `MockMessagesRepository` | `LiveMessagesRepository` |
| Activity feed | `MockActivityFeedRepository` | `LiveActivityFeedRepository` |
| Likes discover | `MockLikesFeedRepository` | `LiveLikesFeedRepository` |
| Search | `MockSearchRepository` | `LiveSearchRepository` |
| Community | `MockCommunityPostsRepository` | `LiveCommunityPostsRepository` |
| StoreKit | `MockStoreKitService` | `LiveStoreKitService` |

SwiftUI previews and `make test-packages` always use Mock types in tests — do not point unit tests at Staging.

## Staging smoke checklist

After login on a Staging build:

| # | Flow | Endpoint |
|---|------|----------|
| 1 | Session restore / CN or email sign-in | `GET /v1/auth/session`, `POST /v1/auth/wechat` · `phone-one-tap` · `alipay` (UI) or `POST /v1/auth/email` (smoke) |
| 2 | Messages inbox + open thread | `GET /v1/messages/threads`, thread messages |
| 3 | Activity tab list | `GET /v1/activities/feed` |
| 4 | Search tab (type query, submit) | `GET /v1/search?q=...` |
| 5 | Community tab list | `GET /v1/community/posts` |
| 6 | Community post detail (tap row) | `GET /v1/community/posts/{post_id}` |
| 7 | Likes tab vertical feed | `GET /v1/likes/feed` |
| 8 | Like user → match → DM | `POST /v1/likes/{user_id}/like`, `POST /v1/messages/direct-threads` |
| 9 | Inbound likes list | `GET /v1/likes/inbound` |
| 10 | Rewind pass | `POST /v1/likes/rewind` |
| 11 | Viewer profile gate | `GET` / `PATCH /v1/likes/viewer-profile` |
| 12 | Host: create activity | `POST /v1/activities` |
| 13 | Host: edit / cancel | `PATCH /v1/activities/{id}` · `POST .../cancel` |
| 14 | Waitlist (use `act_002`, at capacity) | `POST .../waitlist` · host `.../waitlist/{id}/promote` |
| 15 | Host announce + feedback | `POST .../announce` · `POST .../feedback` |
| 16 | Report activity | `POST .../report` → `report_id` |
| 17 | Browse public activities (Activity Tab → 逛局) | `GET /v1/activities/browse` |
| 18 | Persistence: create activity → wait ~1 min (cold start) → feed still lists it | `POST /v1/activities` then `GET /v1/activities/feed` |
| 19 | Community reply thread | `POST /v1/community/posts/{id}/replies` then `GET .../{id}` includes `replies` |
| 20 | Inbound blur (`is_visible: false` for non-premium) | `GET /v1/likes/inbound` |
| 21 | Device token + push stub | `POST /v1/devices` · `POST /v1/notifications/send` (`202` without `APNS_*`) |
| 22 | Community post report | `POST /v1/community/posts/{id}/report` → `report_id` |

APNs 真机：云函数配置 `APNS_*` 后 like/match/消息/活动/回复会自动触发 Push（MODULE-B.4）。见 [ADR-0005](adr/0005-apns-http2-delivery.md)。

```bash
# Full HTTP smoke (auth + browse + inbound + community + devices)
./scripts/staging-smoke.sh

# Quick browse smoke (after login token)
curl -s -H "Authorization: Bearer $TOKEN" \
  "$SPARK_API_BASE_URL/v1/activities/browse"
```

Record failures with HTTP status + `error.code` from the contract error body.

### Inbox persistence migration

Pre-inbox staging DBs may still have legacy thread `th_001` or missing `inbox_action_items`. On cold start, `spark-api` runs `lib/migrate-inbox-state.js` after hydrate: removes legacy threads, merges seed DM/group threads and `mutual_matches`, backfills default action items. Redeploy `cloudfunctions/spark-api` after changing migration logic.

## Rollback

Remove or comment out `SPARK_API_BASE_URL` in `Secrets.xcconfig`, or set it back to `https://mock.spark.local`, then rebuild.

## Production

Same mechanism: set `SPARK_API_BASE_URL = https://api.spark.app` in a Release-specific secrets file or CI-injected xcconfig. Never commit real secrets to git.
