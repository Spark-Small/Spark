# Spark — Development (Mock & Staging)

Doc index: [README.md](README.md) · Rule map: [RULES.md](RULES.md)

## Default: Mock API

`Config/Spark.xcconfig` sets `SPARK_API_BASE_URL = https://mock.spark.local`.  
`APIConfiguration.usesMockBackend` is `true` for that host → `CompositionRoot` wires **Mock** repositories and auth.

You can develop UI and ViewModels without a running server.

## Signing (personal Apple ID vs paid team)

**Personal / free team (e.g. “Yu Shao”):** Apple does not provision **Push Notifications** or **Associated Domains**. The app must **not** link `Config/Spark.entitlements` (keep `CODE_SIGN_ENTITLEMENTS` unset in `Config/Spark.xcconfig`). Do not add those capabilities in Xcode → Signing & Capabilities.

- Deep links: `spark://activity/{id}` (`Config/SparkURLScheme.plist`)
- Local activity reminders: on-device (`ActivityLocalReminderScheduler`); no `aps-environment`
- Remote APNs + `https://spark.app/a/{id}` Universal Links: paid program only — see `Config/Secrets.xcconfig.example`

If Xcode still reports missing `aps-environment` / `associated-domains`: Product → Clean Build Folder; confirm **Code Sign Entitlements** is empty and `Spark/Spark.entitlements` is gone (entitlements live under `Config/` for optional paid-team use).

## Mock-first development

1. Implement new features against **Mock** types (`MockMessagesRepository`, `MockAuthService`) until Live paths exist.
2. Align new endpoints with [`API_CONTRACT.md`](API_CONTRACT.md) before implementing `Live*`.
3. Run CI locally: `make test-packages && make build && make test-app` (see [`CI.md`](CI.md)).

## When Staging is available

1. Create `Config/Secrets.xcconfig` from `Config/Secrets.xcconfig.example`.
2. Set `SPARK_API_BASE_URL` to the Staging host (not `mock.spark.local`).
3. Follow [`STAGING.md`](STAGING.md) — verify auth, messages, activities, search, and community against [`API_CONTRACT.md`](API_CONTRACT.md).
4. Keep Mock for SwiftUI previews and unit tests.

### Activity Staging smoke (Phase 15 — client ready)

With a Staging token, confirm end-to-end:

| Step | Action | Pass |
|------|--------|------|
| 1 | 活动 Tab loads `GET /v1/activities/feed` | List renders |
| 2 | Open detail, RSVP `going` | `POST .../rsvp` + `thread_id` |
| 3 | Open activity group chat | `POST /v1/messages/activity-threads` or existing thread |
| 4 | Share uses `https://spark.app/a/{id}` when opened on device | Universal link resolves |
| 5 | Host: edit time → group system message (Mock: local message) | Reschedule copy in thread |
| 6 | Full activity `act_2`: join waitlist | `POST .../waitlist` |
| 7 | Report returns `report_id` | `POST .../report` body |

Push (`activity.*` payload → detail) requires a **paid** Apple Developer team + `SPARK_ENABLE_PUSH` in `Secrets.xcconfig`. Local scheduled reminders work on personal teams when **活动提醒** is on (Activity tab → ⋯ → 活动提醒).

## Localization

User-visible copy uses `String(localized:defaultValue:comment:)`.  
Shared strings live in `Spark/Localizable.xcstrings` (en + zh-Hans). Add keys there when stabilizing copy.
