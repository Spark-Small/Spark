# Spark Likes — Upgrade plan (Phase 8–12)

**Status:** Shipped (2026-06-05)  
**Prior phases:** [LIKES_DEVELOPMENT_PLAN.md](LIKES_DEVELOPMENT_PLAN.md) Phase 0–7

## Phase 8 — Decision quality

| # | Deliverable | Status |
|---|-------------|--------|
| 8.1 | Multi-photo horizontal gallery + page indicator | ☑ |
| 8.2 | `DiscoverProfileSheet` (bio, tags, location, activity, report) | ☑ |
| 8.3 | `LikesViewerProfileGateSheet` — gate like/pass until profile complete | ☑ |
| 8.4 | `DiscoverCard` extensions + API contract | ☑ |

## Phase 9 — Inbound signals

| # | Deliverable | Status |
|---|-------------|--------|
| 9.1 | `GET /v1/likes/inbound` + `LikesInboundListView` | ☑ |
| 9.2 | Toolbar inbound entry + unread badge | ☑ |
| 9.3 | Deep links `spark://likes/inbound` · `/tab/likes/inbound` | ☑ |
| 9.4 | Like-back from inbound → match flow | ☑ |

## Phase 10 — Match conversion

| # | Deliverable | Status |
|---|-------------|--------|
| 10.1 | `MatchSheetView` icebreaker picker | ☑ |
| 10.2 | First message via `LikesOpenConversationHandler` + `sendMessage` | ☑ |
| 10.3 | Match does not advance card until dismiss/send | ☑ |
| 10.4 | `LikesTelemetry` signposts | ☑ |

## Phase 11 — Rewind & safety

| # | Deliverable | Status |
|---|-------------|--------|
| 11.1 | `POST /v1/likes/rewind` + daily Mock limit | ☑ |
| 11.2 | Report in profile sheet + merged toolbar menu | ☑ |
| 11.3 | Preferences hint after 5 browsed cards | ☑ |

## Phase 12 — Spark differentiation

| # | Deliverable | Status |
|---|-------------|--------|
| 12.1 | Shared activity line on card + match hint | ☑ |
| 12.2 | Intent=friends → bottom friend CTA + toolbar friend action | ☑ |

## Phase 13 — Completion (2026-06-05)

| # | Deliverable | Status |
|---|-------------|--------|
| 13.1 | `LikesPushPayload` + AppDelegate routing | ☑ |
| 13.2 | `PATCH /v1/likes/viewer-profile` + async save | ☑ |
| 13.3 | First-visit `LikesOnboardingSheet` | ☑ |
| 13.4 | Empty state CTAs + inbound refresh on appear | ☑ |
| 13.5 | Shared activity → Activity tab (`onOpenSharedActivity`) | ☑ |
| 13.6 | Staging smoke + API push docs | ☑ |

## Out of scope (future)

- APNs push payloads for inbound/match (deep links ready)
- Paid «likes you» blur / premium rewind
- Real profile photo upload (toggle mock only)

## Verification

```bash
make check && make test-packages && make build
```

Manual: inbound badge → 小晨 → like back; 阿乐 multi-photo swipe; match 小雨 → pick icebreaker → Messages has first line; Menu → rewind; profile gate if toggle photo off.
