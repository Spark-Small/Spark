# spark-api (Cloud Run Docker mirror)

In-memory REST stub aligned with [docs/API_CONTRACT.md](../../docs/API_CONTRACT.md). **Not used for Staging** — production Staging traffic goes to `cloudfunctions/spark-api` on CloudBase.

Use for local Docker smoke or future 云托管 when the env enables CloudRun.

```bash
docker build -t spark-api .
docker run --rm -p 3000:3000 spark-api
SPARK_API_BASE_URL=http://127.0.0.1:3000 ./scripts/staging-smoke.sh
```

## Sync policy

`cloudfunctions/spark-api/` is the source of truth (persistence, inbox migration, APNs, full community API). This folder is a **subset**. When shipping new Live routes, port handlers here or delete this tree if CloudRun is never adopted.

**Synced (2026-06-07):** `GET/POST /v1/trust/*`, `POST /v1/community/posts` (`activity_recap`), post replies.
