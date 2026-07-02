# ADR-0003: Activities browse — Activity Tab discover (not new Tab)

- **Date:** 2026-06-05
- **Status:** Accepted (amended 2026-06-19)

## Context

`GET /v1/activities/browse` is planned for Phase 19 (public activity discovery). The former 喜欢 Tab and `SparkLikes` module were removed (2026-06-08). Reviving browse as its own Tab would make five tabs and confuse「人 vs 局」.

## Decision

1. **Do not** add a sixth Tab or resurrect `ActivityBrowseRootView`.
2. **Browse 逛局** lives on the **活动 Tab · 发现** segment as inline content (`ActivityBrowseContent` + `ActivityBrowseFilterBar`), not as a separate Sheet (`ActivityBrowseListView` removed 2026-06-19).
3. **API:** `GET /v1/activities/browse` with `category`, `starts_after`, `starts_before`, `cursor`.
4. **Reuse** `ActivityItem` / `ActivityDTOMapper` from feed; separate `ActivityBrowseRepository` protocol for clarity.
5. **Premium:** Browse list **not** paywall-gated at 0→1 (per ACTIVITY_UPGRADE_PLAN Wave 3 note); inbox feed gating unchanged.
6. **Tab CTA:** Discover create + detail RSVP use `ActivityTabBottomAccessory` on iOS 26.1+; pre-26.1 uses `safeAreaInset` fallbacks.

## Consequences

- **Pros:** Aligns with ADR-0001; one mental model — Activity Tab = 发现逛局 + 地图 + 我的活动.
- **Cons:** Lower discoverability than dedicated Tab; marketing must explain entry.

## Alternatives considered

- **Likes sub-segment (人 | 局):** N/A — Likes module removed.
- **Independent Discover Tab:** Rejected for 0→1 scope and tab-bar cost.
- **Browse as Sheet (`ActivityBrowseListView`):** Superseded 2026-06-19 — discover is now the default home segment.

## Amendment log

| Date | Change |
|------|--------|
| 2026-06-19 | Inline discover replaces toolbar Sheet browse; filter model → `ActivityBrowseFilter` |
