# Contributing to Spark

Read first: [DESIGN_PHILOSOPHY.md](DESIGN_PHILOSOPHY.md), [ARCHITECTURE.md](ARCHITECTURE.md), [API_CONTRACT.md](API_CONTRACT.md).

## Before you code

1. **Issue / scope** — one user journey or one module per PR (≤ ~400 lines diff).
2. **Contract** — new/changed HTTP APIs → update `API_CONTRACT.md` **before** `Live*` implementations.
3. **Mock first** — UI and ViewModels against `Mock*` until Staging exists ([DEVELOPMENT.md](DEVELOPMENT.md)).

## Feature checklist

- [ ] `Packages/Spark{Feature}/` — Domain → Data (Mock + Live) → Presentation
- [ ] `@MainActor` `@Observable` ViewModel; UseCases only (no `URLSession` in VM/View)
- [ ] Repository protocol + `Mock` + `Live` where network applies
- [ ] `#Preview`: loading, loaded, empty, error (UI PRs)
- [ ] `String(localized:defaultValue:comment:)`; stable copy → `Spark/Localizable.xcstrings`
- [ ] Materials / `glassEffect` only — see [UI_REVIEW.md](UI_REVIEW.md)
- [ ] Unit tests for ViewModel / UseCase / Mock repository

## Before opening a PR

```bash
make check          # secrets + UI + API contract warnings (no ripgrep required)
make lint           # SwiftLint strict (brew install swiftlint)
make test-packages
make build && make test-app
```

## PR title

Conventional Commits: `feat(activity): add mock activity feed loader`

## Review

Reviewers use [UI_REVIEW.md](UI_REVIEW.md) and the PR template **Spark guardrails** section.
