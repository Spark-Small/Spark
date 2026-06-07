# Universal Links (Phase 17)

## iOS

**Personal Apple ID (free team):** cannot use Associated Domains or Push. Leave `CODE_SIGN_ENTITLEMENTS` unset in `Config/Spark.xcconfig` (default). Use `spark://activity/{id}` deep links; local activity reminders still work.

**Paid Apple Developer Program:**

1. In `Config/Secrets.xcconfig` (from example), uncomment:
   - `CODE_SIGN_ENTITLEMENTS = Config/Spark.entitlements`
   - `SWIFT_ACTIVE_COMPILATION_CONDITIONS = $(inherited) SPARK_ENABLE_PUSH`
2. `Config/Spark.entitlements` declares `applinks:spark.app` and `aps-environment` (not under `Spark/` — avoids Xcode auto-signing on personal teams).
3. Share/copy uses `https://spark.app/a/{activity_id}` (`ActivityInviteURL.shareLink`).
4. `DeepLinkParser` maps `/a/{id}`, `/activity/{id}`, `/activities/{id}` → `activityDetail`; `AppRouter` opens the **活动** tab and queues `pendingActivityID` (`ActivityRootView`).
5. Legacy likes URLs (`spark://likes`, `/tab/likes`, `/tab/likes/inbound`) redirect to **社区** tab (`SparkTab.community`).
6. Messages: `https://spark.app/matches/{thread_id}` or `https://spark.app/messages/thread/{thread_id}` → `conversation`.
7. Community post: `https://spark.app/community/posts/{post_id}` → `communityPost`.

## Web

Host `web/.well-known/apple-app-site-association` at:

- `https://spark.app/.well-known/apple-app-site-association`
- `https://www.spark.app/.well-known/apple-app-site-association`

Replace `TEAMID` in `appIDs` with your Apple Team ID + bundle id (see `Config/BundleID.xcconfig.example`).

Optional H5 preview at `/a/{id}` lives in `web/public/a/index.html` (static fallback + App Store link). Deploy with your web host alongside AASA.
