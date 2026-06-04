# Spark

iOS 17+ social app (Swift 6, SwiftUI, Clean Architecture).

## Requirements

- Xcode 16+
- iOS 17.0+ deployment target

## Repository layout

```
Spark/                 # App target (Xcode)
Packages/              # SPM feature & infra modules
docs/                  # Workflow & ADRs
.github/               # PR/Issue templates, CI
scripts/               # Tooling (incl. repo bootstrap)
```

## Git workflow

See [docs/GIT_WORKFLOW.md](docs/GIT_WORKFLOW.md) and [docs/GITHUB_BRANCH_PROTECTION.md](docs/GITHUB_BRANCH_PROTECTION.md).

### Bootstrap (one-time)

```bash
chmod +x scripts/spark-init-repo.sh
./scripts/spark-init-repo.sh
```

Push to GitHub (create an empty repo first):

```bash
GITHUB_REMOTE_URL=https://github.com/YOUR_ORG/Spark.git ./scripts/spark-init-repo.sh
```

### Feature development

```bash
git checkout develop && git pull
git checkout -b feature/42-my-feature
# … implement …
# Open PR → Squash merge to develop
```

## Secrets

Never commit `Config/Secrets.swift`, `GoogleService-Info.plist`, or files under `Secrets/`. Use local xcconfig (gitignored) for environment values.
