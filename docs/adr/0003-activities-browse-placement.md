# ADR-0003: Activities browse — Likes Tab sub-entry (not new Tab)

- **Date:** 2026-06-05
- **Status:** Accepted

## Context

`GET /v1/activities/browse` is planned for Phase 19 (public activity discovery). ADR-0001 removed `ActivityBrowse*` from the 喜欢 Tab and assigned **人发现** to `SparkLikes`. Reviving browse as its own Tab would make six tabs and confuse「人 vs 局」.

## Decision

1. **Do not** add a sixth Tab or resurrect `ActivityBrowseRootView`.
2. **Browse 逛局** enters from **活动 Tab** toolbar as a secondary destination (`ActivityBrowseEntry` → push `ActivityBrowseListView`), not from Likes.
3. **API:** `GET /v1/activities/browse` with `category`, `starts_after`, `starts_before`, `cursor` (backend ships in MODULE-A follow-up).
4. **Reuse** `ActivityItem` / `ActivityDTOMapper` from feed; separate `ActivityBrowseRepository` protocol for clarity.
5. **Premium:** Browse list **not** paywall-gated at 0→1 (per ACTIVITY_UPGRADE_PLAN Wave 3 note); inbox feed gating unchanged.

## Consequences

- **Pros:** Aligns with ADR-0001; one mental model — Activity Tab = 我的局 + 逛局入口.
- **Cons:** Lower discoverability than dedicated Tab; marketing must explain entry.

## Alternatives considered

- **Likes sub-segment (人 | 局):** Rejected — re-blends two discovery modes ADR-0001 separated.
- **Independent Discover Tab:** Rejected for 0→1 scope and tab-bar cost.
