# ADR-0004: Premium inbound blur — inbox only, count visible

- **Date:** 2026-06-05
- **Status:** Proposed

## Context

MODULE-G needs a paywall strategy. Options: lock discover cards, lock inbound list, or hybrid. StoreKit paywall and `EntitlementManager` exist (Phase 3); inbound list ships in LIKES Phase 9.

## Decision (proposed)

1. **Scheme B — inbox only:** Discover feed stays fully visible; **inbound** cards blur avatar/name for non-subscribers.
2. **Free tier:** Toolbar badge shows real inbound **count**; list rows blurred with single CTA「开通 Spark+ 查看谁喜欢你」.
3. **API:** `GET /v1/likes/inbound` adds `is_visible: boolean` per item (`true` when entitled).
4. **Unlock:** Existing `PaywallView` sheet; on success refresh inbound without app restart.
5. **Feature flag:** `INFOPLIST_KEY_SPARKPremiumInboundBlurEnabled` default `NO` until MODULE-G Phase G.2.

## Consequences

- **Pros:** Clear upgrade moment; discover conversion not throttled; matches competitor norms.
- **Cons:** Requires MODULE-A for entitlement persistence; App Review scrutiny on digital unlock — must use StoreKit only.

## Alternatives considered

- **Lock discover card #2+:** Already used for Activity inbox; doubling sends mixed signals — rejected for inbound module.
- **Full blur + hide count:** Hurts engagement — rejected.
