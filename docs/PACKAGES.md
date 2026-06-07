# Spark SPM packages

Minimum platform: **iOS 17**. Swift **6** with strict concurrency.

See also: [API_CONTRACT.md](API_CONTRACT.md), [DEVELOPMENT.md](DEVELOPMENT.md), [CI.md](CI.md).

## Dependency graph

```
Spark (App) — CompositionRoot, environments
 ├── SparkAppShell → SparkAuth, SparkCommunity, SparkMessages,
 │                   SparkActivity, SparkSearch, SparkPersistence, SparkPayments
 ├── SparkAuth → SparkCore, SparkNetworking, SparkPersistence, SparkDesignSystem
 ├── SparkPayments → SparkCore
 └── SparkNetworking, SparkMessages, SparkPersistence, SparkDesignSystem

SparkCore (no deps)
SparkNetworking → SparkCore
SparkPersistence → SparkCore
SparkDesignSystem → SwiftUI primitives
SparkActivity → SparkCore, SparkNetworking, SparkDesignSystem
SparkCommunity / SparkSearch → SparkCore, SparkNetworking, SparkDesignSystem
SparkMessages → SparkCore, SparkNetworking, SparkDesignSystem
```

App target links: **SparkAppShell**, **SparkAuth**, **SparkPayments**, **SparkDesignSystem**, **SparkNetworking**, **SparkMessages**, **SparkPersistence**, **SparkActivity**, **SparkSearch**, **SparkCommunity**, **SparkProfile**, **SparkTrust**.

## Module responsibilities

| Package | Responsibility |
|---------|----------------|
| SparkCore | `AppError`, `UserID`, `RetryPolicy`, `SparkLog`, `AccessTokenProviding` |
| SparkNetworking | `HTTPClient`, `APIClient`, interceptors, `APIConfiguration` |
| SparkPersistence | Keychain (`KeychainManager`, `KeychainAccessTokenProvider`, `InMemoryKeychainManager` for tests) |
| SparkDesignSystem | `SparkScreenContainer`, `SparkPlaceholderCard`, list styling |
| SparkAuth | Auth state machine, `Live`/`Mock` auth, Sign in with Apple, `LoginView` |
| SparkMessages | Inbox + conversation (Mock/Live), unread count |
| SparkPayments | StoreKit 2, entitlements, `PaywallView`, `SparkFeatureFlags` premium gating |
| SparkAppShell | `SparkRootView`, tabs, deep links, global presentation |
| SparkActivity | Activity tab inbox + detail；`GET /v1/activities/feed` + CRUD/RSVP |
| SparkSearch | Search Mock/Live, suggestions + results list |
| SparkCommunity | Community posts Mock/Live, feed list + post detail, media stage |
| SparkLikes | **Archived** — not in App; see [adr/0004-sparklikes-archived.md](adr/0004-sparklikes-archived.md) |

## App integration

- **DI:** `Spark/App/CompositionRoot.swift` — `usesMockBackend` when host is `mock.spark.local`
- **URL scheme:** `Config/SparkURLScheme.plist` (merged via Xcode `INFOPLIST_FILE`, not under `Spark/` sync root)
- **API base URL:** `Config/Spark.xcconfig` → `INFOPLIST_KEY_SPARKAPIBaseURL`
- **Localization:** `Spark/Localizable.xcstrings` (en + zh-Hans); feature strings also use `String(localized:defaultValue:comment:)`

## Tests

```bash
./scripts/test-packages.sh   # all Packages/Spark* on iOS Simulator
make test-app                # Spark.xcodeproj unit tests
make ci                      # lint + packages + app (see CI.md)
```
