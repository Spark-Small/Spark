# Spark Git Workflow (GitFlow + Trunk-Based hybrid)

## Branches

| Branch | Purpose |
|--------|---------|
| `main` | Production; merge only from `release/*`; tag on every merge |
| `develop` | Integration; all features land here |
| `feature/{issue-id}-{kebab-name}` | Short-lived feature work |
| `fix/{issue-id}-{kebab-name}` | Bug fixes |
| `release/{version}` | Release candidates (e.g. `release/1.2.0`) |
| `hotfix/{issue-id}-{kebab-name}` | Production hotfixes |

## Conventional Commits

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:** `feat` | `fix` | `perf` | `refactor` | `style` | `test` | `docs` | `chore` | `revert`

**Scopes:** `auth` | `feed` | `profile` | `notifications` | `onboarding` | `core` | `network` | `persistence` | `ui` | `design-system` | `ci` | `release` | `deps`

## Rules

- No `git push --force` to `main` / `develop` (use `--force-with-lease` on your own branches only)
- Rebase feature branches; avoid merge commits on feature branches
- Prefer ≤ 3 files of logical change per commit
- Never commit secrets, `.env`, Derived Data, `.DS_Store`
- Avoid vague messages: "fix bug", "update", "change"

## Pull requests

- Title: Conventional Commits format
- Body: **What**, **Why**, **How**, **Screenshots** (required for UI)
- Max ~400 lines diff; split if larger
- Footer: `closes #N`
- Merge: **Squash** into `develop`
- `release/*` → `main`: **Merge commit** + annotated tag `vMAJOR.MINOR.PATCH`

## Versioning

- SemVer: `MAJOR.MINOR.PATCH` or `MAJOR.MINOR.PATCH-beta.N`
- Tags: `git tag -a v1.2.0 -m "Release 1.2.0: …"`

## Day-to-day

1. Pick up Issue
2. `git checkout develop && git pull`
3. `git checkout -b feature/{id}-{name}`
4. Implement (use Cursor module scaffold for new features)
5. Open PR → Squash merge to `develop`
