# ADR-0002: Activity browse UI on Activity tab (Nexus W1)

- **Date:** 2026-06-05
- **Status:** Accepted

## Context

Nexus MVP requires public activity discovery (`GET /v1/activities/browse`) on the **活动** tab. ADR-0001 removed browse UI from the **喜欢** tab; inbox-only Activity tab left the 0→1 「逛局」 path broken.

## Decision

1. **Activity tab dual axis:** segmented `我的` (inbox) + `发现` (browse).
2. Browse calls `ActivityFeedRepository.fetchBrowsableActivities(filter:cursor:)`.
3. Browse detail uses `ActivityDetailContext.discover` (public signup, not invite inbox).
4. Live path: `ActivityAPIPath.browse` → `GET /v1/activities/browse`.

## Consequences

- **Pros:** Restores supply/demand loop; aligns with Nexus PRD without violating ADR-0001.
- **Cons:** Activity tab complexity; repository protocol grows.

## Alternatives considered

- **Browse on Likes tab:** Rejected — ADR-0001.
- **Browse-only tab:** Rejected — five-tab limit; form serves function.
