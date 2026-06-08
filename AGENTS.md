# Spark — agent instructions

## Read first (in order)

1. [docs/DESIGN_PHILOSOPHY.md](docs/DESIGN_PHILOSOPHY.md) — form serves function
2. [docs/DEVELOPMENT_PLAN.md](docs/DEVELOPMENT_PLAN.md) — phased roadmap (Phase 0–14 shipped; Phase 25+ partial)
3. [docs/MISSING_MODULES_PLAN.md](docs/MISSING_MODULES_PLAN.md) — Phase 25+ 缺失模块立项（MODULE A–H）
4. [docs/ACTIVITY_UPGRADE_PLAN.md](docs/ACTIVITY_UPGRADE_PLAN.md) — activity full vision (Phase 15+)
5. [docs/UNIVERSAL_LINKS.md](docs/UNIVERSAL_LINKS.md) — Associated Domains setup (Phase 17)
6. [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — layers, navigation, DI
7. [docs/API_CONTRACT.md](docs/API_CONTRACT.md) — HTTP contract (update before Live APIs)
8. [docs/STAGING.md](docs/STAGING.md) · [cloudfunctions/spark-api/README.md](cloudfunctions/spark-api/README.md) — CloudBase Staging MVP
9. [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) — PR checklist
10. [docs/HIG_COMPLIANCE.md](docs/HIG_COMPLIANCE.md) — HIG compliance memo

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
make lint-hig       # optional HIG-focused SwiftLint rules
make test-packages
```

## New feature module

Follow `.cursor/rules/ios-module-scaffold.mdc` under `Packages/Spark{Feature}/`.
