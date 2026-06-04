# GitHub branch protection (第二步)

Configure in **Repository → Settings → Branches → Branch protection rules**.

Create **two rules** (one per branch).

---

## `main`

| Setting | Value |
|---------|--------|
| Branch name pattern | `main` |
| Require a pull request before merging | ✅ |
| Required approvals | 1 (adjust for team size) |
| Dismiss stale pull request approvals when new commits are pushed | ✅ |
| Require review from Code Owners | ✅ (if `CODEOWNERS` is used) |
| Require status checks to pass before merging | ✅ (after CI workflow exists) |
| Require branches to be up to date before merging | ✅ |
| Require conversation resolution before merging | ✅ |
| Require signed commits | Optional |
| Require linear history | ❌ (release → main uses merge commit) |
| Include administrators | ✅ |
| Restrict who can push | Release managers / admins only |
| Allow force pushes | ❌ |
| Allow deletions | ❌ |

**Merge settings (repo Settings → General):**

- Allow **merge commits** (for `release/*` → `main`)
- Allow **squash merging** (optional for hotfix PRs if policy allows)
- Default: merge commit for release PRs only (document in PR template)

After each merge to `main`, create an annotated tag: `v{MAJOR}.{MINOR}.{PATCH}`.

---

## `develop`

| Setting | Value |
|---------|--------|
| Branch name pattern | `develop` |
| Require a pull request before merging | ✅ |
| Required approvals | 1 |
| Require status checks to pass before merging | ✅ |
| Require branches to be up to date before merging | ✅ |
| Require linear history | ✅ (optional; pairs with squash merge) |
| Allow force pushes | ❌ |
| Allow deletions | ❌ |

**Merge settings:**

- Default merge method: **Squash merge** only for feature/fix PRs into `develop`

---

## Status checks (when CI is enabled)

Add required checks from `.github/workflows/ci.yml`, for example:

- `build-and-test` (or your workflow job name)

---

## Quick checklist

- [ ] Rule for `main` created
- [ ] Rule for `develop` created
- [ ] Force push disabled on both
- [ ] Squash merge enabled for feature PRs → `develop`
- [ ] Merge commit allowed for `release/*` → `main`
- [ ] Default branch set to `develop` for day-to-day work (optional) or keep `main` as default display only
