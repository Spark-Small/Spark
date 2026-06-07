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
   Test account: `staging@test.com` / `staging123`. Backend uses CloudBase NoSQL write-through ([ADR-0002](adr/0002-backend-persistence-cloudbase-nosql.md)).
3. `Config/Spark.xcconfig` already `#include`s `Secrets.xcconfig` when present (gitignored).
4. Clean build in Xcode (or `make build`) so `APIConfiguration.loadFromBundle()` picks up the new host.

## How iOS chooses Mock vs Live

`APIConfiguration.usesMockBackend` is `true` when the base URL host contains `mock.spark.local`. Any other host (Staging, Production) wires **Live*** types in `Spark/App/CompositionRoot.swift`.

| Repository | Mock | Live |
|------------|------|------|
| Auth | `MockAuthService` | `LiveAuthService` |
| Messages | `MockMessagesRepository` | `LiveMessagesRepository` |
| Activity feed | `MockActivityFeedRepository` | `LiveActivityFeedRepository` |
| Search | `MockSearchRepository` | `LiveSearchRepository` |
| Community | `MockCommunityPostsRepository` | `LiveCommunityPostsRepository` |
| StoreKit | `MockStoreKitService` | `LiveStoreKitService` |

SwiftUI previews and `make test-packages` always use Mock types in tests — do not point unit tests at Staging.

## Staging smoke checklist

After login on a Staging build:

| # | Flow | Endpoint |
|---|------|----------|
| 1 | Session restore / email sign-in | `GET /v1/auth/session`, `POST /v1/auth/email` |
| 2 | Messages inbox + open thread | `GET /v1/messages/threads`, thread messages |
| 3 | Activity tab list | `GET /v1/activities/feed` |
| 4 | Search tab (type query, submit) | `GET /v1/search?q=...` |
| 5 | Community tab list | `GET /v1/community/posts` |
| 6 | Community post detail (tap row) | `GET /v1/community/posts/{post_id}` |
| 7 | User profile patch | `PATCH /v1/users/profile` |
| 8 | Host: create activity | `POST /v1/activities` |
| 9 | Host: edit / cancel | `PATCH /v1/activities/{id}` · `POST .../cancel` |
| 10 | Waitlist (use `act_002`, at capacity) | `POST .../waitlist` · host `.../waitlist/{id}/promote` |
| 11 | Host announce + feedback | `POST .../announce` · `POST .../feedback` |
| 12 | Report activity | `POST .../report` → `report_id` |
| 13 | Browse public activities (Activity Tab → 逛局) | `GET /v1/activities/browse` |
| 14 | Persistence: create activity → wait ~1 min (cold start) → feed still lists it | `POST /v1/activities` then `GET /v1/activities/feed` |
| 15 | Community reply thread | `POST /v1/community/posts/{id}/replies` then `GET .../{id}` includes `replies` |
| 16 | Device token + push stub | `POST /v1/devices` · `POST /v1/notifications/send` (`202` without `APNS_*`) |
| 17 | Community post report | `POST /v1/community/posts/{id}/report` → `report_id` |
| 18 | Trust profile (我的 Tab) | `GET /v1/trust/profile` |
| 19 | Activity recap post | `POST /v1/community/posts` with `kind: activity_recap`, `activity_id` |

APNs 真机：云函数配置 `APNS_*` 后消息/活动/回复会自动触发 Push（MODULE-B.4）。见 [ADR-0005](adr/0005-apns-http2-delivery.md)。

```bash
# Deploy latest spark-api, then full HTTP smoke (auth + browse + trust + recap + …)
./scripts/deploy-spark-api.sh

# Smoke only (already deployed)
./scripts/staging-smoke.sh

# Local API + smoke (no CloudBase credentials)
cd cloudfunctions/spark-api && SPARK_PERSISTENCE=memory PORT=3000 node index.js
# other terminal:
SPARK_API_BASE_URL=http://127.0.0.1:3000 ./scripts/staging-smoke.sh
```

Record failures with HTTP status + `error.code` from the contract error body.

### Inbox persistence migration

Pre-inbox staging DBs may still have legacy thread `th_001` or missing `inbox_action_items`. On cold start, `spark-api` runs `lib/migrate-inbox-state.js` after hydrate: removes legacy threads, merges seed DM/group threads and `mutual_matches`, backfills default action items. Redeploy `cloudfunctions/spark-api` after changing migration logic.

## Rollback

Remove or comment out `SPARK_API_BASE_URL` in `Secrets.xcconfig`, or set it back to `https://mock.spark.local`, then rebuild.

## CloudBase deployment

**Canonical source:** `cloudfunctions/spark-api/` (HTTP 云函数). **Optional Docker mirror:** `cloudrun/spark-api/` (in-memory only; keep trust/recap routes in sync manually).

| Item | Value |
|------|--------|
| Env ID | `ais-d1gab0emob99361a0` |
| Public URL | `https://ais-d1gab0emob99361a0.service.tcloudbase.com` |
| Function | `spark-api` (Node 18, handler `index.main`) |
| Persistence | CloudBase NoSQL write-through (`persistence: cloudbase` in `/health`) |
| Config | [`cloudbaserc.json`](../cloudbaserc.json) |

**Last verified (2026-06-07):** `/health` returns `ok`; `./scripts/staging-smoke.sh` passes incl. `GET /v1/trust/profile` and `POST /v1/community/posts` with `kind: activity_recap`.

### Local redeploy

```bash
# Device login (first time): tcb login
./scripts/deploy-spark-api.sh
```

Uses `tcb fn code update` (or `cloudbase` / `npx @cloudbase/cli`). Waits ~30s, hits `/health`, then runs full smoke unless `SKIP_SMOKE=1`.

### GitHub Actions deploy

Workflow: [`.github/workflows/deploy-spark-api.yml`](../.github/workflows/deploy-spark-api.yml) — **manual** (`workflow_dispatch`).

**One-time repo secrets** (Settings → Secrets and variables → Actions):

| Secret | Source |
|--------|--------|
| `TCB_SECRET_ID` | [腾讯云 CAM](https://console.cloud.tencent.com/cam/capi) → 新建密钥 → SecretId |
| `TCB_SECRET_KEY` | Same key pair → SecretKey |

Grant the sub-account **CloudBase 云开发** permissions on env `ais-d1gab0emob99361a0` (云函数更新 + HTTP 访问).

```bash
# After secrets are set (requires gh CLI + repo admin)
gh secret set TCB_SECRET_ID --body "<SecretId>"
gh secret set TCB_SECRET_KEY --body "<SecretKey>"
```

Run: GitHub → Actions → **Deploy spark-api** → Run workflow. Optional: check **Skip staging-smoke** for code-only pushes.

If secrets are missing, the workflow fails at **Require CloudBase API keys** with a link to this section.

## Production

Same mechanism: set `SPARK_API_BASE_URL = https://api.spark.app` in a Release-specific secrets file or CI-injected xcconfig. Never commit real secrets to git.
