## HIG Audit Summary & Development Plan (Apple-only)

Decision sources (the only allowed sources):

- Apple Human Interface Guidelines (HIG): `https://developer.apple.com/design/human-interface-guidelines`
- Apple SDK documentation (SwiftUI / UIKit / Foundation / Accessibility)

This document turns the audit into an execution plan.

---

## Audit summary (high-signal)

### ✅ Already aligned

- 5-tab top-level navigation (HIG tab bar guidance: 3–5)
- Use of `NavigationStack` + typed `navigationDestination`
- Use of `ContentUnavailableView` in multiple empty states
- Use of system components: `Form`, `Picker`, `Toggle`, `DatePicker`, `ShareLink`, `PhotosPicker`
- Destructive actions use `Button(role: .destructive)` in multiple places

### P0 — MUST FIX (completed)

- [x] **Permissions on launch**: notification permission requested only when user enables reminders
- [x] **Dynamic Type violations**: removed fixed `Font.system(size:)` without `relativeTo:`
- [x] **Touch targets**: icon-only tappables use `minWidth/minHeight: 44` where needed
- [x] **Tap gestures as buttons**: primary actions use `Button` (double-tap zoom gestures retained)
- [x] **Accessibility**: combined rows have coherent `accessibilityLabel` in key surfaces
- [x] **Reduce Motion**: non-essential animations gated by `accessibilityReduceMotion`

### P1 — SHOULD FIX (completed)

- [x] `.refreshable` on Messages, Community, Activity, Likes, and Search lists/feeds
- [x] `.swipeActions` on inbox conversation rows (mark read; syncs via per-thread read API)
- [x] Tab bar icon variants (selected filled vs unselected outline)
- [x] `scrollDismissesKeyboard(.interactively)` on Search and conversation composer

### P2 — CONSIDER (superseded)

- ~~`NavigationSplitView` on iPad regular width~~ — **removed (2026-07)**; iPhone-first `NavigationStack` on all tabs
- ~~iPad split for Community / Messages~~ — same policy

---

## iPhone-first layout policy (2026-07)

- All tabs use **`NavigationStack`** push / Sheet; no `horizontalSizeClass` layout branching
- Removed `SparkAdaptiveLayout`, `sparkReadableWidth`, and `SparkPreviewSupport.iPadRegular`
- PR checklist: verify iPhone SE (smallest) only

---

## Execution record (what shipped)

### P0 — MUST FIX

1) **On-demand permission requests**
   - Removed launch-time `ActivityNotificationRegistrar.registerIfNeeded()` from `Spark/SparkApp.swift`
   - `ActivityNotificationPreferences.remindersEnabled` defaults to `false`
   - Request runs only from `ActivityNotificationSettingsSection` when user toggles reminders on

2) **Dynamic Type compliance**
   - Replaced fixed sizes with semantic styles (`.title`, `.largeTitle`, etc.) in Likes/Messages surfaces

3) **44×44pt touch targets**
   - Send button (`ConversationDetailView`), like button (`PeopleDiscoveryCard`)

4) **Replace gesture-as-button**
   - `InboundLikeCell`, `CommunityPostCard` media, `DiscoverCardView` profile overlay → `Button`

5) **Accessibility completion**
   - `CommunityRowCell`, `InboundLikeCell`, `ConversationRow`, `CommunityMembersSheet` member rows

6) **Reduce Motion**
   - `DiscoverPhotoZoomState`, `DiscoverCardStackView`, `CommunityPostCard`, `ConversationDetailView`, `CommunityRootView`

### P1 — SHOULD FIX

- Pull-to-refresh on all primary feeds
- Swipe “标为已读” on DM/group inbox rows
- Opening a thread marks it read (detail `.task` — compact + split)
- Keyboard dismiss on scroll for Search + composer

### P2 — CONSIDER (historical)

- ~~Messages / Community split inbox~~ — removed; see iPhone-first policy above
- Inbox list extracted to `MessagesRootView+InboxList.swift` for maintainability

---

## Shipped follow-ups (2026-06-05)

| Item | Notes |
|------|--------|
| Per-thread read API | `POST /v1/messages/threads/{thread_id}/read` + optimistic `markConversationRead` with rollback |
| Double-tap zoom gestures | Documented in `docs/HIG_COMPLIANCE.md`; a11y hints on mock + remote photo layers |

## Phase 3 — Five-tab layout completion (2026-06-05)

| Tab | Shipped |
|-----|---------|
| 喜欢 | Inbound `.refreshable`; iPad discover card `maxWidth` 480pt; pass/friend glass controls (`sparkGlassControl`) |
| 社区 | Toolbar search 44×44pt |
| 消息 | Composer `.sensoryFeedback(.success)` on send |
| 活动 | 发现 `ActivityBrowseContent` `.refreshable` + `ActivityBrowseFilterBar` (verified 2026-06-19) |
| 搜索 | suggestion rows 44pt; result `accessibilityHint` |
| 共用 | `SparkGlassSurface` in SparkDesignSystem |

## Phase 4 — P2 polish (2026-06-05)

| Tab | Shipped |
|-----|---------|
| 社区 | `CommunityPostCard` avatar `sparkGlassControl` |
| 喜欢 | `MatchSheetView` glass + no decorative gradient; `friendRequestSuccessToken` + `.sensoryFeedback(.success)` |
| 消息 | Composer `sparkGlassSurface`; `ArchivedChatsDisclosure` a11y |
| 共用 | `SparkPreviewSupport` (dark / XL); root Preview matrix on Community / Search / Messages / Activity |

---

## Verification

```bash
make check
make lint
make test-packages
```

Manual: Dynamic Type XL, Reduce Motion, VoiceOver on inbox/community rows; swipe mark read; pull-to-refresh on Search.
