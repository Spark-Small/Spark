# ADR-0007: Activity-driven light people discovery (W7–W10)

- Date: 2026-06-08
- Status: Accepted
- Supersedes: [ADR-0003](0003-activities-browse-placement.md) (browse placement only)

## Context

Spark positions as **「用真实线下局，认识可信的人」**. `SparkLikes` and a fifth Tab remain archived ([ADR-0004](0004-sparklikes-archived.md)). Premium must not gate core browse/feed rows; value belongs in **host tools**.

## Decision

1. **Activity Tab** uses dual-axis **发现 | 我的**. Public browse is inline on **发现** (not a secondary sheet). Map lives under **我的** toolbar menu.
2. **People discovery** is contextual: activity attendee roster, community **识人** segment (`people_discovery` feed items), messages match **推荐一局** CTA — not swipe/match Tab revival.
3. **Unified identity** via `UserContextSheet` + `GET /v1/users/{id}/context` from any tab (`SparkMainTabView` presents sheet).
4. **Premium** gates `PremiumFeature.hostTools` (approval, announce); feed browse rows are never locked.
5. **Post-event** primary CTA: share recap to community (`integration_activity_end_to_recap` telemetry).

## Consequences

- **Pros:** Single spine (discover → RSVP → group → offline → recap); trust signals on browse cards; measurable integration funnel.
- **Cons:** No high-volume cold-start discovery; community home feed still filters `people_discovery` (dedicated segment only).
- **Follow-up:** Optional `NewMatchesCarousel` if messages inbox density needs it.
