# Universal Links (Phase 17)

## iOS

**Personal Apple ID (free team):** cannot use Associated Domains or Push. Leave `CODE_SIGN_ENTITLEMENTS` unset in `Config/Spark.xcconfig` (default). Use `spark://activity/{id}` deep links; local activity reminders still work.

**Paid Apple Developer Program:**

1. In `Config/Secrets.xcconfig` (from example), uncomment:
   - `CODE_SIGN_ENTITLEMENTS = Config/Spark.entitlements`
   - `SWIFT_ACTIVE_COMPILATION_CONDITIONS = $(inherited) SPARK_ENABLE_PUSH`
2. `Config/Spark.entitlements` declares `applinks:spark.app` and `aps-environment` (not under `Spark/` — avoids Xcode auto-signing on personal teams).
3. Share/copy uses `https://spark.app/a/{activity_id}` (`ActivityInviteURL.shareLink`).
4. `DeepLinkParser` maps `/a/{id}` → `activityDetail`; `AppRouter` opens the **活动** tab and queues `pendingActivityID` (`ActivityRootView`).

## Web

Host `web/.well-known/apple-app-site-association` at:

- `https://spark.app/.well-known/apple-app-site-association`
- `https://www.spark.app/.well-known/apple-app-site-association`

Replace `TEAMID` in `appIDs` with your Apple Team ID + bundle id (see `Config/BundleID.xcconfig.example`).

Optional H5 preview at `/a/{id}` is out of scope for the iOS repo; App Store / TestFlight handles install.
