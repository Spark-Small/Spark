# UI review checklist

Aligned with [DESIGN_PHILOSOPHY.md](DESIGN_PHILOSOPHY.md).

## Every screen

- [ ] One clear primary task; no decorative controls (stub voice, fake chevrons without destination)
- [ ] Loading / empty / error with recovery (retry, dismiss, sign-in)
- [ ] Dynamic Type XL — layout does not clip
- [ ] Dark mode — semantic colors / materials only
- [ ] VoiceOver — labels on icon-only buttons

## Visual

- [ ] Materials or `@available(iOS 26, *)` `.glassEffect()` — no `Color.*.opacity` glass, `blur(radius:)`, decorative `shadow`
- [ ] No duplicate titles (nav title + huge headline saying the same thing)
- [ ] List rows: show chevron only when row navigates somewhere

## Previews

At least: default, `.preferredColorScheme(.dark)`, one failure or empty state for async screens.

## Automated

`make check-ui` enforces several bans in `*Presentation*` / `*View.swift`.
