---
name: spark-ui-spec
description: Generate and review Spark SwiftUI screens against TAB_SCREENS L3, TYPOGRAPHY, and SparkDesignSystem. Load references/login.md for LoginView.
---

# Spark UI spec

## When to use

- Implementing or reviewing SwiftUI in `**/Presentation/**` or `**/*View*.swift`
- Tab screens: read matching file under `references/`

## Checklist

1. [docs/TYPOGRAPHY.md](../../docs/TYPOGRAPHY.md) — semantic text styles only
2. [docs/TAB_SCREENS.md](../../docs/TAB_SCREENS.md) L3 — layout, spacing, section order
3. `.cursor/rules/ios-liquid-glass.mdc` — materials, no fake glass
4. `.cursor/rules/ios-swiftui-layout.mdc` — ViewModel boundary, `SparkLayoutMetrics`
5. `#Preview` — light, dark, accessibility XL where meaningful

## References

| Screen | File |
|--------|------|
| Login | [references/login.md](references/login.md) |

## Tokens

- Spacing / touch: `SparkLayoutMetrics`
- Readable width: `SparkAdaptiveLayout` / `sparkReadableWidth`
- Auth Form: `AuthFormChrome.swift` modifiers
