# SparkLikes (archived)

**Status:** Archived 2026-06-08 — not linked from the App target or `SparkAppShell`.

Social discovery and matching now ship through:

- **SparkCommunity** — feed, people discovery, UGC posts
- **SparkMessages** — `unmessaged_matches`, DM threads, peer profile → propose meetup

See [docs/adr/0004-sparklikes-archived.md](../../docs/adr/0004-sparklikes-archived.md).

This package is retained for reference (swipe UX, inbound likes, avatar upload UseCases). Do not add new product dependencies here without an ADR.

```bash
# CI skips this package; local only:
cd Packages/SparkLikes && swift test
```
