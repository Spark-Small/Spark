# spark-api (CloudBase HTTP 云函数)

Staging REST MVP aligned with [docs/API_CONTRACT.md](../../docs/API_CONTRACT.md). **CloudBase NoSQL write-through** ([ADR-0002](../../docs/adr/0002-backend-persistence-cloudbase-nosql.md)); local fallback `SPARK_PERSISTENCE=memory`.

## Deployed (env `ais-d1gab0emob99361a0`)

| Item | Value |
|------|--------|
| Public base URL | `https://ais-d1gab0emob99361a0.service.tcloudbase.com` |
| Gateway path | `/` |
| Test login | `staging@test.com` / `staging123` |
| Persistence | CloudBase NoSQL (`/health` → `"persistence":"cloudbase"`) |
| Last smoke | 2026-06-08 — likes API removed; inbox state in `spark_inbox_state` |

## iOS Live endpoints (all implemented)

- **Auth:** session, email, register, password-reset, apple, sign-out, account/delete
- **Community:** feed, posts, **media/stage**, replies, report
- **Messages:** inbox, unread-count, threads, messages, read, activity-threads, direct-threads
- **Activities:** feed, **browse**, create, detail, patch, rsvp, waitlist, promote, cancel, report, announce, feedback
- **Buddy:** `GET /v1/buddies`, detail, `POST /v1/buddy-orders`, provider status/application/earnings/orders
- **Search, Community** (posts + replies + `activity_recap`), **Users** (avatar upload-url, profile), **Trust** (`/v1/trust/*`), **devices**, **notifications/send**

**iOS wired:** Activity browse ([ADR-0003](../../docs/adr/0003-activities-browse-placement.md)), Community compose + reply thread, avatar upload-url.

### APNs env (MODULE-B.3)

| Variable | Description |
|----------|-------------|
| `APNS_KEY_ID` | Apple Push Key id |
| `APNS_TEAM_ID` | Team id |
| `APNS_PRIVATE_KEY` | `.p8` PEM (use `\n` for newlines in env) |
| `APNS_BUNDLE_ID` | App bundle id |
| `APNS_USE_SANDBOX` | `false` for production (default sandbox) |

### Persistence collections

`spark_users` · `spark_activities` · `spark_threads` · `spark_community_posts` · `spark_community_reports` · `spark_inbox_state` · `spark_devices` · `spark_meta`

Legacy `spark_likes_state` is read once on hydrate for migration, then superseded by `spark_inbox_state`.

**MODULE-B.4:** Business events auto-call APNs (`messages.new`, `activity.*`, `community.reply`) via `lib/push-triggers.js`.

## Seed highlights

| Id | Notes |
|----|--------|
| `act_001` | RSVP + activity thread |
| `act_002` | At capacity (`capacity: 2`) — waitlist smoke |

## Local run

```bash
npm install
PORT=3000 node index.js
curl http://127.0.0.1:3000/health
```

HTTP 云函数 listens on **9000** by default (`scf_bootstrap`).

## Redeploy

From repo root:

```bash
./scripts/deploy-spark-api.sh
```

CI: GitHub Actions → **Deploy spark-api** (secrets `TCB_SECRET_ID`, `TCB_SECRET_KEY` — [docs/STAGING.md](../../docs/STAGING.md#github-actions-deploy)).

## Cloud Run (optional)

`cloudrun/spark-api/` — Docker in-memory mirror for local/云托管 experiments. **Staging uses this HTTP 云函数 only.** When adding routes (e.g. trust, recap), update both `index.js` files or prefer extending `cloudfunctions/spark-api` first.
