# Continuous Integration

**Canonical workflow:** [`.github/workflows/ios.yml`](../.github/workflows/ios.yml)

| Job | What it runs |
|-----|----------------|
| `swiftlint` | `check-guardrails.sh` + `lint.sh` |
| `spm-tests` | `./scripts/test-packages.sh` (iOS Simulator) |
| `app-build-test` | `./scripts/build-app.sh` + `./scripts/test-app.sh` |

## Local

```bash
make check          # secrets + UI bans + API contract warnings
make lint           # SwiftLint strict (brew install swiftlint)
make test-packages
make build && make test-app
make ci             # all of the above
```

**Simulator:** `iPhone 17` / OS `26.4.1` — override with `SPARK_DESTINATION=...`.

## Guardrail scripts

| Script | Purpose |
|--------|---------|
| `scripts/check-secrets.sh` | Block keys / secret paths in git |
| `scripts/check-ui.sh` | Ban fake glass, `print`, URLSession in Presentation |
| `scripts/check-api-contract.sh` | Warn if Live `/v1/` paths missing from `API_CONTRACT.md` |

The legacy `ci.yml` workflow was removed.
