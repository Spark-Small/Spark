# Spark — agent instructions

## Read first (in order)

1. [docs/DESIGN_PHILOSOPHY.md](docs/DESIGN_PHILOSOPHY.md) — form serves function
2. [docs/DEVELOPMENT_PLAN.md](docs/DEVELOPMENT_PLAN.md) — phased roadmap (Phase 0–14 shipped)
3. [docs/ACTIVITY_UPGRADE_PLAN.md](docs/ACTIVITY_UPGRADE_PLAN.md) — activity full vision (Phase 15+)
4. [docs/UNIVERSAL_LINKS.md](docs/UNIVERSAL_LINKS.md) — Associated Domains setup (Phase 17)
4. [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — layers, navigation, DI
5. [docs/API_CONTRACT.md](docs/API_CONTRACT.md) — HTTP contract (update before Live APIs)
6. [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) — PR checklist

Cursor rules: `.cursor/rules/ios-product-philosophy.mdc` (always), `ios-liquid-glass.mdc`, `ios-foundation.mdc`.

## Do not

- Add decorative UI, stub toolbars, or fake navigation affordances
- Use `Color.white.opacity`, manual `blur`, or `shadow` for glass in Views
- Put `URLSession` in ViewModels or Views
- Create `Spark/Features/` — use `Packages/Spark*`
- Duplicate full Liquid Glass essay in new docs — link existing files

## Before finishing

```bash
make check
make lint
make test-packages
```

## New feature module

Follow `.cursor/rules/ios-module-scaffold.mdc` under `Packages/Spark{Feature}/`.
