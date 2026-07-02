# ADR-0007: Community UGC moderation (Staging MVP)

- Date: 2026-07-02
- Status: Accepted
- Context: MODULE-E P4 requires UGC compliance before CN distribution. Legal sign-off and third-party classifiers are external; engineering must enforce a minimal write-time guard and report queue.
- Decision:
  1. **Policy:** Staging uses **post-publish + report queue** (see [COMMUNITY_UGC_COMPLIANCE.md](../COMMUNITY_UGC_COMPLIANCE.md)).
  2. **Write-time guard:** `lib/content-moderation.js` scans post/reply text; reject with `422 content_rejected`.
  3. **Client pre-check:** `SparkCore.UGCModeration` mirrors blocklist for fast UX; server remains authoritative.
  4. **Reports:** `POST /v1/community/posts/{id}/report` → `spark_community_reports` (`status: pending`).
  5. **ICP:** `SPARK_ICP_RECORD_NUMBER` build setting → About screen via `SparkLegalLinks`.
- Consequences:
  - **Pros:** Low cost, testable in smoke, App Store Guideline 1.2 report path exists
  - **Cons:** Blocklist is not ML; false negatives possible until E.3 vendor API
- Alternatives: Pre-moderation queue for all posts (rejected: blocks Staging velocity); vendor API only (rejected: external dependency)

## Kill switches

| Flag | Effect |
|------|--------|
| `MODERATION_DISABLED=true` | Server skips text scan (local dev only) |
| `MODERATION_BLOCKED_TOKENS` | Comma-separated override list |

## Production follow-up

- Wire 易盾/天御 for images (MODULE-E.3 / F.4)
- Legal: privacy policy UGC section + ICP filing number
