# Spark — agent instructions

## Read first (in order)

1. [docs/DESIGN_PHILOSOPHY.md](docs/DESIGN_PHILOSOPHY.md) — form serves function
2. [docs/DEVELOPMENT_PLAN.md](docs/DEVELOPMENT_PLAN.md) — phased roadmap (Phase 0–14 shipped)
3. [docs/SPRINT_PROGRESS_PLAN.md](docs/SPRINT_PROGRESS_PLAN.md) — 当前 Sprint 执行计划（P0–P4 PR 拆分与验收）
4. [docs/MISSING_MODULES_PLAN.md](docs/MISSING_MODULES_PLAN.md) — Phase 25+ 缺失模块立项（MODULE A–H）
5. [docs/ACTIVITY_UPGRADE_PLAN.md](docs/ACTIVITY_UPGRADE_PLAN.md) — activity full vision (Phase 15+)
6. [docs/PRODUCT_INTEGRATION_PLAN.md](docs/PRODUCT_INTEGRATION_PLAN.md) — Nexus integration roadmap (W0–W6)
7. [docs/UNIVERSAL_LINKS.md](docs/UNIVERSAL_LINKS.md) — Associated Domains setup (Phase 17)
8. [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — layers, navigation, DI
9. [docs/API_CONTRACT.md](docs/API_CONTRACT.md) — HTTP contract (update before Live APIs)
10. [docs/STAGING.md](docs/STAGING.md) · [cloudfunctions/spark-api/README.md](cloudfunctions/spark-api/README.md) — CloudBase Staging MVP
11. [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) — PR checklist
12. [docs/HIG_COMPLIANCE.md](docs/HIG_COMPLIANCE.md) · [docs/HIG_AUDIT_AND_PLAN.md](docs/HIG_AUDIT_AND_PLAN.md) — HIG audit & compliance
13. [docs/TYPOGRAPHY.md](docs/TYPOGRAPHY.md) — system semantic text styles (canonical font spec)
14. [docs/TAB_SCREENS.md](docs/TAB_SCREENS.md) — Tab L3 layout + per-component typography

Cursor rules: `.cursor/rules/ios-product-philosophy.mdc` (always), `ios-liquid-glass.mdc`, `ios-foundation.mdc`.

**UI 实现 Skill：** `.cursor/skills/spark-ui-spec/SKILL.md` — 生成/审查 Spark SwiftUI 页面时优先加载，并按 `references/` 下对应 Tab 规范输出。

**产品设计 Skill：** `.cursor/skills/ios-product-design/SKILL.md` — 设计/规格/PRD/HIG 合规/功能规划时加载；产出 PRD、UX 流、组件清单与 Cursor 实现 Prompt。

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
