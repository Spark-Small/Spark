# spark-api (CloudBase HTTP 云函数)

Staging REST MVP aligned with [docs/API_CONTRACT.md](../../docs/API_CONTRACT.md). **CloudBase NoSQL write-through** ([ADR-0002](../../docs/adr/0002-backend-persistence-cloudbase-nosql.md)); local fallback `SPARK_PERSISTENCE=memory`.

## Deployed (env `ais-d1gab0emob99361a0`)

| Item | Value |
|------|--------|
| Public base URL | `https://ais-d1gab0emob99361a0.service.tcloudbase.com` |
| Gateway path | `/` |
| Test login | `staging@test.com` / `staging123` |

## iOS Live endpoints (all implemented)

- **Auth:** session, email, apple, sign-out
- **Messages:** unread-count, threads, messages, read, hide, delete, inbox, activity-threads, direct-threads
- **Activities:** feed (`host_id`), **browse** (`category`, `starts_after`, `starts_before`, `cursor`), create, detail, patch, rsvp, waitlist, promote, **attendees/review**, **attendees/cohost**, cancel, report, announce, feedback
- **Search, Community** (feed, join, posts + replies), **Likes** (full path table in API contract), **devices**, **notifications/send** (APNs when `APNS_*` env set)

**iOS wired:** Activity browse ([ADR-0003](../../docs/adr/0003-activities-browse-placement.md)), Community compose + reply thread, inbound blur, avatar upload-url.

### APNs env (MODULE-B.3)

| Variable | Description |
|----------|-------------|
| `APNS_KEY_ID` | Apple Push Key id |
| `APNS_TEAM_ID` | Team id |
| `APNS_PRIVATE_KEY` | `.p8` PEM (use `\n` for newlines in env) |
| `APNS_BUNDLE_ID` | App bundle id |
| `APNS_USE_SANDBOX` | `false` for production (default sandbox) |

### Persistence collections

`spark_users` · `spark_activities` · `spark_threads` · `spark_community_posts` · `spark_community_reports` · `spark_likes_state` · `spark_devices` · `spark_meta`

**MODULE-B.4:** Business events auto-call APNs (`likes.*`, `messages.new`, `activity.*`, `community.reply`) via `lib/push-triggers.js`.

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

```bash
npm install --omit=dev
npx mcporter call cloudbase.manageFunctions \
  action=updateFunctionCode \
  functionName=spark-api \
  functionRootPath="$(cd .. && pwd)"
```

MCP may require code under `.cursor/projects/.../cloudfunctions` — copy this folder there if deploy fails on path.

## Cloud Run (optional)

`cloudrun/spark-api/` — Docker image for 云托管 when the env has CloudRun enabled.
