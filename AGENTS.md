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

## Agent skills

### Issue tracker

GitHub issues on **Spark-Small/Spark** (`gh` CLI). See [docs/agents/issue-tracker.md](docs/agents/issue-tracker.md).

### Triage labels

Five-role vocabulary for `/triage`. See [docs/agents/triage-labels.md](docs/agents/triage-labels.md).

### Domain docs

Single-context repo — use `docs/ARCHITECTURE.md`, `docs/DESIGN_PHILOSOPHY.md`, `docs/adr/`. See [docs/agents/domain.md](docs/agents/domain.md).

### [mattpocock/skills](https://github.com/mattpocock/skills) (skills.sh)

Canonical copy: [`skills/`](skills/) · Cursor: [`.cursor/skills/`](.cursor/skills/) (symlinks). Update: `npx skills@latest update -p`.

| Skill | Use when |
|-------|----------|
| `setup-matt-pocock-skills` | First-time or tracker/label/domain config change |
| `tdd` | Red-green-refactor feature or bugfix |
| `diagnose` | Hard bugs / performance regressions |
| `grill-with-docs` | Stress-test a plan against domain docs + ADRs |
| `grill-me` | Interview-style plan alignment (no doc writes) |
| `to-prd` / `to-issues` | Turn context into PRD or vertical-slice GitHub issues |
| `triage` | Issue intake and AFK-ready labeling |
| `improve-codebase-architecture` | Deepening / module boundary review |
| `zoom-out` | Unfamiliar code area — system context |
| `review` | Standards + spec review since a branch point |

**Spark UI skills** (project-specific, when present under `.cursor/skills/`):

- `spark-ui-spec` — SwiftUI 实现/审查 Tab 页面
- `ios-product-design` — PRD、UX 流、HIG 合规

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
