# Spark

iOS 17+ social app (Swift 6, SwiftUI, SPM, Clean Architecture).

## Requirements

- Xcode 16+
- iOS 17.0+ deployment target
- Simulator: `iPhone 17` (see `Makefile` / `docs/CI.md` for `SPARK_DESTINATION`)

## Repository layout

```
Spark/                 # App target
Packages/              # SPM feature & infra modules
Config/                # xcconfig, URL scheme plist
docs/                  # Architecture, API contract, workflow — start at docs/README.md
.github/workflows/     # ios.yml (canonical CI)
scripts/               # build, test, lint
```

## Quick start

```bash
open Spark.xcodeproj
# Default API: https://mock.spark.local (Mock auth/messages/payments)
make test-packages
make build
```

See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) for Staging URL and secrets.

## Documentation

| Doc | Content |
|-----|---------|
| [docs/README.md](docs/README.md) | Index |
| [docs/PACKAGES.md](docs/PACKAGES.md) | Modules |
| [docs/API_CONTRACT.md](docs/API_CONTRACT.md) | Backend contract |
| [docs/CI.md](docs/CI.md) | CI & `make` targets |
| [AGENTS.md](AGENTS.md) | Cursor / agent onboarding |
| [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) | PR checklist |
| [docs/DESIGN_PHILOSOPHY.md](docs/DESIGN_PHILOSOPHY.md) | Form serves function |
| [docs/RULES.md](docs/RULES.md) | Canonical docs map |

## Git workflow

[docs/GIT_WORKFLOW.md](docs/GIT_WORKFLOW.md) · [docs/GITHUB_BRANCH_PROTECTION.md](docs/GITHUB_BRANCH_PROTECTION.md)

```bash
git checkout develop && git pull
git checkout -b feature/42-my-feature
# PR → squash merge to develop
```

One-time bootstrap: [docs/INIT.md](docs/INIT.md).

## Secrets

Do **not** commit:

- `Config/Secrets.xcconfig` (copy from `Config/Secrets.xcconfig.example`)
- `GoogleService-Info.plist`, `Secrets/`, `*.mobileprovision`, `AuthKey_*.p8`

API URL is injected via xcconfig → Info.plist (`SPARKAPIBaseURL`), not Swift source.
