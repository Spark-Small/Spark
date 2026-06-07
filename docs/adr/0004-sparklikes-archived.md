# ADR-0004: SparkLikes archived — social discovery via Community + Messages

- Date: 2026-06-08
- Status: Accepted
- Supersedes: informal「喜欢 Tab」placement (never shipped as primary Tab on main)

## Context

`Packages/SparkLikes` implemented swipe-card discovery, inbound likes, and match sheets with `/v1/likes/*` APIs. Product converged on a **four-tab** shell (社区 / 消息 / 活动 / 我的). Matching and DM now live in **SparkMessages** inbox (`unmessaged_matches`, `EnsureDirectMessageThreadUseCase`). Public discovery moved to **SparkCommunity** feed and people surfaces.

Keeping `SparkLikes` in CI and deep links created confusion: engineers assumed the Tab was live; guardrails referenced dead API paths.

## Decision

1. **Do not** link `SparkLikes` from `SparkAppShell` or the App target.
2. **Redirect** legacy deep links (`spark://likes`, `/tab/likes`) to **Community** (`SparkTab.swift`, `DeepLinkParser`).
3. **Archive** the package in-repo for reference; skip it in `make test-packages`.
4. **Cancel** MODULE B (`MISSING_MODULES_PLAN.md`) and `/v1/likes/*` Staging routes — no new Live work on likes APIs until product re-opens discovery scope.

## Consequences

- **Pros:** Single discovery story; smaller App binary; CI faster; no duplicate match UX.
- **Cons:** Swipe-card UX and avatar upload helpers remain only in archived code; revival requires ADR update + API contract restore.
- **Migration:** Users with old `likes` links land on Community; matches use Messages inbox.

## Alternatives considered

| Option | Why rejected |
|--------|----------------|
| Re-enable Likes Tab | Five tabs; overlaps Community + Messages |
| Delete package immediately | Loses reference impl for inbound/match flows |
| Hide behind feature flag | Still ships binary + maintenance cost |
