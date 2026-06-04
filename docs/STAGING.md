# Spark — Staging cutover

**Related:** [DEVELOPMENT.md](DEVELOPMENT.md) · [API_CONTRACT.md](API_CONTRACT.md) · [DEVELOPMENT_PLAN.md](DEVELOPMENT_PLAN.md) Phase 5

## When to use Staging

Use Staging when the backend team has deployed endpoints in [API_CONTRACT.md](API_CONTRACT.md) and you need to validate **Live*** repositories on a real host (not `mock.spark.local`).

## Setup (one time)

1. Copy the example secrets file:
   ```bash
   cp Config/Secrets.xcconfig.example Config/Secrets.xcconfig
   ```
2. Edit `Config/Secrets.xcconfig` and set your team URL:
   ```
   SPARK_API_BASE_URL = https://api.staging.spark.app
   ```
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

Record failures with HTTP status + `error.code` from the contract error body.

## Rollback

Remove or comment out `SPARK_API_BASE_URL` in `Secrets.xcconfig`, or set it back to `https://mock.spark.local`, then rebuild.

## Production

Same mechanism: set `SPARK_API_BASE_URL = https://api.spark.app` in a Release-specific secrets file or CI-injected xcconfig. Never commit real secrets to git.
