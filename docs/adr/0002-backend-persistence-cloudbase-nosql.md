# ADR-0002: Staging backend persistence — CloudBase NoSQL

- **Date:** 2026-06-05
- **Status:** Accepted

## Context

`spark-api` Staging MVP runs as a CloudBase HTTP 云函数 with in-memory Maps. Cold starts wipe user-created activities, RSVPs, and messages. MODULE-B (APNs), MODULE-F (avatar), and MODULE-G (premium state) all require durable user records.

Candidates: CloudBase NoSQL (CN, zero-ops), PostgreSQL on CloudRun (not enabled on trial env), PlanetScale/Supabase (cross-border PIPL risk).

## Decision

1. **Primary store:** CloudBase **document database** (`@cloudbase/node-sdk`) in the same env `ais-d1gab0emob99361a0`.
2. **Collections:** `spark_users`, `spark_activities`, `spark_threads`, `spark_community_posts`, `spark_inbox_state` (mutual matches + inbox action items; legacy `spark_likes_state` migrated on hydrate), `spark_meta` (counters).
3. **Runtime pattern:** Load collections into Maps on cold start; **write-through** on response `finish` for dirty entity IDs (keeps route handlers unchanged).
4. **Fallback:** `SPARK_PERSISTENCE=memory` for local dev without CloudBase credentials.
5. **Seed:** If `spark_activities` is empty after load, run `lib/seed-data.js` and persist seed set once.

## Consequences

- **Pros:** Same env/billing; PIPL-friendly; unlocks APNs token storage and profile URLs; reversible via env flag.
- **Cons:** Document DB not ideal for complex relational queries; no transactions across collections in v1; staging passwords remain plaintext (MVP only).

## Alternatives considered

- **PostgreSQL on CloudRun:** Rejected until 云托管 is enabled on the trial env.
- **PlanetScale / Supabase:** Rejected for CN Staging default (data residency).
- **Keep memory + warn users:** Rejected — blocks Staging smoke sign-off for Phase 15.
