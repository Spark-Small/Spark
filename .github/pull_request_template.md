## What

<!-- What changed? -->

## Why

<!-- Why is this change needed? Link issue: closes # -->

## How

<!-- Implementation notes, feature flags, migrations -->

## Screenshots / recordings

<!-- Required for UI changes. N/A for non-UI: write "N/A" -->

## Test plan

- [ ] `make check` (secrets + UI guardrails)
- [ ] `make lint` and `make test-packages` (see [docs/CI.md](../docs/CI.md))
- [ ] `make build && make test-app` (app changes)
- [ ] Manual QA (devices / OS versions)
- [ ] Accessibility (VoiceOver, Dynamic Type XL)
- [ ] Dark mode (UI)

## HIG compliance (Apple-only)

- [ ] New controls prefer Apple native components (Button, List, Form, Search, ContentUnavailableView)
- [ ] New colors use semantic system colors (supports Dark Mode)
- [ ] New tappable elements meet 44×44pt minimum touch target
- [ ] New animations respect Reduce Motion (`accessibilityReduceMotion`)
- [ ] New icons/images have `accessibilityLabel` (or are hidden if decorative)
- [ ] Verified on iPhone SE (smallest) layout

## Spark guardrails

- [ ] [DESIGN_PHILOSOPHY.md](../docs/DESIGN_PHILOSOPHY.md) — no decorative / stub UI
- [ ] API changes reflected in [API_CONTRACT.md](../docs/API_CONTRACT.md)
- [ ] New stable copy in `Spark/Localizable.xcstrings` (or justified `defaultValue` only)
- [ ] Materials / `glassEffect` only — no opacity glass, blur, shadow hacks
- [ ] ViewModel/View: no `URLSession`; logic in Repository / UseCase
- [ ] Navigation matches [ARCHITECTURE.md](../docs/ARCHITECTURE.md) (no nested stacks)

## Checklist

- [ ] PR title follows Conventional Commits (`type(scope): subject`)
- [ ] Diff ≤ ~400 lines (or split planned)
- [ ] No secrets / API keys / `.env`
- [ ] `closes #N` in description
