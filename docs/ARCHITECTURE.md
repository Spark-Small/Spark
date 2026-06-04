# Spark architecture conventions

## Layers (per feature package)

```
Presentation  →  View, ViewModel (@MainActor @Observable)
Domain        →  Models, UseCases, Repository protocols
Data          →  DTOs, Live*, Mock*, mappers
```

- **Views** are stateless functions of ViewModel; no networking.
- **ViewModels** call UseCases only.
- **Repositories** are the only network/cache boundary.

## App composition

- `Spark/App/CompositionRoot.swift` — wires `Live*` vs `Mock*` from `APIConfiguration.usesMockBackend`.
- `Spark/ContentView.swift` — builds `SparkRootView` with constructor-injected repositories and routers (`AppRouter`, `PaywallRouter`).

## Navigation

| Pattern | Use |
|---------|-----|
| Tab root | `SparkScreenContainer(navigationTitle:)` — embeds one `NavigationStack` |
| Tab with push | Outer `NavigationStack` + `SparkScreenContainer(..., embedding: .none)` + `.navigationDestination` |
| Modal / paywall | Own `NavigationStack` in sheet/fullScreenCover |

**Do not** nest two `NavigationStack`s without `embedding: .none`.

## Errors

See [ERRORS.md](ERRORS.md). Map transport failures to `AppError`; feature errors wrap `AppError` or stand alone as `LocalizedError`.

## UI

See [DESIGN_PHILOSOPHY.md](DESIGN_PHILOSOPHY.md) and [UI_REVIEW.md](UI_REVIEW.md).
