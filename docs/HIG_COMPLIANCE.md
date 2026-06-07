## Spark — HIG Compliance Memo (Apple-only)

Decision sources (the only allowed sources):

- Apple Human Interface Guidelines (HIG): `https://developer.apple.com/design/human-interface-guidelines`
- Apple SDK documentation (SwiftUI / UIKit / Foundation / Accessibility)

This memo exists to make UI/interaction changes reviewable and repeatable.

### Core principles (HIG-aligned)

- **Prefer system components** over custom UI (Buttons, Lists, Forms, Search, Empty states).
- **Respect user settings**: Dynamic Type, Reduce Motion, Increase Contrast.
- **Use semantic system colors** and adaptive materials; avoid hard-coded palettes for meaning.
- **Touch targets**: interactive controls must be at least **44×44pt**.
- **Accessibility is not optional**: labels, hints, values, focus behavior.
- **Ask permission only when needed** (in-context, user-initiated).

---

## What Spark is already aligned with

- **Tab Bar** uses 5 top-level destinations (HIG tab bar guidance: 3–5).
- **NavigationStack + typed navigationDestination** is used for stacks.
- **ContentUnavailableView** is used for several empty states.
- **ShareLink / DatePicker / PhotosPicker** are used instead of custom equivalents.
- **Destructive actions** use `Button(role: .destructive)` and confirmations use `confirmationDialog` in places.

---

## Forbidden patterns (and required replacements)

### 1) Permission prompts at launch

- **Forbidden**: requesting notifications (or other permissions) during app launch without a user action.
- **Use instead**:
  - Gate the request behind an explicit user toggle/action.
  - Show the system permission prompt at the moment the feature is enabled.

### 2) Hard-coded fonts that break Dynamic Type

Spark typography canonical spec: **[TYPOGRAPHY.md](TYPOGRAPHY.md)** (system semantic text styles only).

- **Forbidden**: `Font.system(size:)` without `relativeTo:` for user-visible body text
- **Forbidden**: custom font families; hex grays for text hierarchy
- **Use instead**:
  - Semantic text styles: `.font(.body)`, `.font(.subheadline.weight(.semibold))`, `.font(.caption)`, etc.
  - Foreground: `.primary`, `.secondary`, `Color.accentColor`
  - If a specific size is needed (decorative symbols only): `.font(.system(size: X, relativeTo: .body))` with `// REASONING:`

### 3) Tap gestures used as buttons

- **Forbidden**: `.onTapGesture { ... }` for primary actions.
- **Use instead**:
  - `Button { ... } label: { ... }` with `.buttonStyle(.plain)` when needed.
- **Allowed exceptions** (document with `// REASONING:` in code):
  - **Double-tap to zoom** on discover photos (`onTapGesture(count: 2)`) — Photos-style media gesture; pair with `accessibilityHint` for zoom.
  - **Tap to play/pause** on inline video surfaces — system player pattern; use `accessibilityHint` + `.startsMediaSession`.

### 4) Touch targets below 44×44pt

- **Forbidden**: icon-only buttons without a minimum hit area.
- **Use instead**:
  - `.frame(minWidth: 44, minHeight: 44)` on tappable content.
  - Prefer system button styles where possible.

### 5) Animations that ignore Reduce Motion

- **Forbidden**: unconditional `withAnimation {}` and `.animation(...)` for non-essential motion.
- **Use instead**:
  - Read `@Environment(\.accessibilityReduceMotion)` and disable or reduce animations.

### 6) Unlabeled combined rows

- **Forbidden**: `.accessibilityElement(children: .combine)` without a coherent `accessibilityLabel`.
- **Use instead**:
  - Provide a single localized label (and hint/value if needed).

---

## Error handling (`try?`)

Use `try?` only when failure is **expected or non-actionable** for the current UX path. Every site must have a `// REASONING:` comment (see `ios-foundation.mdc`).

| Pattern | Example | Why ignore is OK |
|---------|---------|------------------|
| Missing Keychain session | `AuthSessionStore.load` | Signed-out is normal, not an error banner |
| Background sync | premium entitlement sync | Local StoreKit state is already authoritative |
| Best-effort side effects | group chat announce, opener message | Primary navigation must not block |
| Picker / transfer cancel | avatar `loadTransferable` | User dismissed; no alert |
| Notification schedule duplicate | `UNUserNotificationCenter.add` | RSVP must not fail on reminder collision |
| StoreKit unverified entitlement | `Transaction` enumeration | Skip bad payloads; keep verified set |

Prefer `do/catch` with typed errors when the user needs recovery UI.

---

## Pre-merge checklist (HIG/SDK)

- [ ] Permissions are requested **in context**, not at launch.
- [ ] New text uses **Dynamic Type** (semantic styles or `relativeTo:`).
- [ ] Interactive elements meet **44×44pt** minimum touch target.
- [ ] Animations respect **Reduce Motion**.
- [ ] Icons/images have appropriate accessibility labeling (or are hidden if decorative).
- [ ] Tested in Dark Mode and with a large Dynamic Type size.
