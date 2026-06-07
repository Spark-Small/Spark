# Continuous Integration

**Canonical workflows:** [`.github/workflows/ios.yml`](../.github/workflows/ios.yml) · [`.github/workflows/deploy-spark-api.yml`](../.github/workflows/deploy-spark-api.yml)

| Job | What it runs |
|-----|----------------|
| `swiftlint` | `check-guardrails.sh` + `lint.sh` |
| `spm-tests` | `./scripts/test-packages.sh` (iOS Simulator) |
| `app-build-test` | `./scripts/build-app.sh` + `./scripts/test-app.sh` |
| **Deploy spark-api** (manual) | `./scripts/deploy-spark-api.sh` → CloudBase + smoke — needs `TCB_SECRET_ID` / `TCB_SECRET_KEY` ([STAGING.md](STAGING.md#github-actions-deploy)) |

## Local

```bash
make check          # secrets + UI bans + API contract (fails on missing paths)
make lint           # SwiftLint strict (brew install swiftlint)
make lint-hig        # HIG-focused rules (Dynamic Type, semantic colors)
make test-packages
make build && make test-app
make ci             # all of the above
```

**Simulator:** `iPhone 17` / OS `26.5` — override with `SPARK_DESTINATION=...`.

## Guardrail scripts

| Script | Purpose |
|--------|---------|
| `scripts/check-secrets.sh` | Block keys / secret paths in git |
| `scripts/check-ui.sh` | Ban fake glass, `print`, URLSession in Presentation |
| `scripts/check-api-contract.sh` | Fail if Live `/v1/` paths missing from `API_CONTRACT.md` |
| `scripts/lint-hig.sh` | HIG SwiftLint rules (`swiftlint_hig.yml`) — optional via `make lint-hig` |

The legacy `ci.yml` workflow was removed.
