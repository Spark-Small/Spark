# Domain Docs

How engineering skills should consume Spark's domain documentation when exploring the codebase.

## Before exploring, read these

Spark does not use a root `CONTEXT.md` yet — that is intentional. `/grill-with-docs` may create or extend it when domain terms crystallise. Until then, use these canonical sources:

| Topic | File |
|-------|------|
| Product philosophy | [docs/DESIGN_PHILOSOPHY.md](../DESIGN_PHILOSOPHY.md) |
| Architecture & layers | [docs/ARCHITECTURE.md](../ARCHITECTURE.md) |
| HTTP contract | [docs/API_CONTRACT.md](../API_CONTRACT.md) |
| Tab / screen layout | [docs/TAB_SCREENS.md](../TAB_SCREENS.md) |
| Typography | [docs/TYPOGRAPHY.md](../TYPOGRAPHY.md) |
| Decisions (ADRs) | [docs/adr/](../adr/) |

Read ADRs that touch the area you are about to work in (e.g. activity browse → [ADR-0003](../adr/0003-activities-browse-placement.md), people discovery → [ADR-0007](../adr/0007-activity-driven-people-discovery.md)).

Agent onboarding order is defined in [AGENTS.md](../../AGENTS.md).

## File structure

Single-context repo:

```
/
├── AGENTS.md
├── docs/
│   ├── DESIGN_PHILOSOPHY.md
│   ├── ARCHITECTURE.md
│   ├── adr/
│   └── agents/          ← issue tracker + triage + this file
└── Packages/Spark*/
```

## Use consistent vocabulary

When naming domain concepts (issues, refactors, tests), prefer terms from `DESIGN_PHILOSOPHY.md`, `ARCHITECTURE.md`, and existing ADRs. Examples: **Activity Tab**, **browse**, **UserContextSheet**, **Liquid Glass** (materials for hierarchy, not ornament).

## Flag ADR conflicts

If a proposal contradicts an existing ADR, surface it explicitly:

> _Contradicts ADR-0007 (activity-driven people discovery) — but worth reopening because…_
