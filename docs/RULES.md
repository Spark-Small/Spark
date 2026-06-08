# Rules and documentation map

Avoid maintaining the same guidance in multiple places. When something changes, update **one canonical file** below.

## Cursor AI rules

| Canonical | Do not duplicate in |
|-----------|---------------------|
| `.cursor/rules/ios-product-philosophy.mdc` | Long prose in PRs / README |
| `.cursor/rules/ios-liquid-glass.mdc` | `.cursorrules`, README |
| `.cursor/rules/ios-foundation.mdc` | `.cursorrules`, PACKAGES.md (stack only) |
| `.cursor/rules/ios-swiftui.mdc` | — |
| `.cursor/rules/ios-design-system.mdc` | — |
| `.cursor/rules/ios-module-scaffold.mdc` | — |
| `.cursor/rules/ios-performance.mdc` | — |
| `.cursorrules` | **Index only** |
| `AGENTS.md` | Duplicate of CONTRIBUTING — link, don’t copy |

**Product role & philosophy:** `ios-product-philosophy.mdc` (always on). UI scope: **product philosophy wins**.

## Engineering docs

| Topic | Canonical |
|-------|-----------|
| **Design philosophy** | `docs/DESIGN_PHILOSOPHY.md` |
| **Contributing / PR flow** | `docs/CONTRIBUTING.md` |
| **Architecture & navigation** | `docs/ARCHITECTURE.md` |
| **UI review** | `docs/UI_REVIEW.md` |
| **Errors** | `docs/ERRORS.md` |
| **Naming** | `docs/NAMING.md` |
| **Package graph** | `docs/PACKAGES.md` |
| **HTTP contract** | `docs/API_CONTRACT.md` |
| **Roadmap** | `docs/DEVELOPMENT_PLAN.md` · `docs/MISSING_MODULES_PLAN.md` |
| **HIG compliance** | `docs/HIG_COMPLIANCE.md` |
| **CI & guardrails** | `docs/CI.md`, `scripts/check-*.sh` |
| **ADRs** | `docs/adr/0000-template.md` |
| **Doc index** | `docs/README.md` |

## Automated guardrails

| Script | Enforced in CI |
|--------|----------------|
| `check-secrets.sh` | yes |
| `check-ui.sh` | yes |
| `check-api-contract.sh` | warnings only |
| `lint.sh` | yes (SwiftLint) |

Run locally: `make check` then `make ci`.

## Known past conflicts (resolved)

- ~~`ci.yml` vs `ios.yml`~~ → only `ios.yml`
- ~~`Spark/App/Info.plist` for URL scheme~~ → `Config/SparkURLScheme.plist`
- ~~`.cursorrules` duplicated Liquid Glass~~ → index only
- ~~`README` `Secrets.swift`~~ → `Config/Secrets.xcconfig`
- ~~`Spark/Features/` scaffold~~ → `Packages/Spark*` only
