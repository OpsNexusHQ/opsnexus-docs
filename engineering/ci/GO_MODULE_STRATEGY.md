# Go Module Dependency Strategy

Status: analysis only
Scope: `opsnexus-common`, `opsnexus-agent`, and `opsnexus-backend`

Implementation follow-up: the approved Option C design is implemented and
recorded in [`GO_MODULE_MIGRATION.md`](GO_MODULE_MIGRATION.md); remote agent
and backend validation remains pending.

## 1. Current state

OpsNexus is organized as multiple repositories, but agent and backend currently consume common through:

```text
replace github.com/OpsNexusHQ/opsnexus-common => ../opsnexus-common
```

This works in the local sibling checkout but is not reproducible in a normal single-repository GitHub Actions checkout. The current workflows use one checkout, so they must not depend on files outside their repository.

## 2. Evidence from common

`opsnexus-common/go.mod` declares module path `github.com/OpsNexusHQ/opsnexus-common` and Go `1.22.2`. The repository has one tag, `v0.5.0`, at `8e51918`. Current main before the CI branch is `e1f5d69), so the tag does not point to current main.

Commits after `v0.5.0` change documentation and governance files only. There is no source diff under `models/`; the tagged model source is compatible with the current agent/backend imports. The module has a valid public GitHub path and is suitable for normal Go module consumption. It has no `go.sum` because it has no external dependencies.

The common README advertises Go `1.25+`, while `go.mod` declares `1.22.2`. This documentation discrepancy must be corrected separately; `go.mod` is the build requirement until then.

## 3. Evidence from agent

Agent declares Go `1.24.0`, requires common as `v0.0.0`, and replaces it with `../opsnexus-common`. It imports `github.com/OpsNexusHQ/opsnexus-common/models` from:

- `internal/agent/agent.go`
- `internal/agent/agent_test.go`
- `internal/transport/registration.go`
- `cmd/agent/main.go`

Current use is limited to the shared `models` package. Because that source is unchanged from `v0.5.0` through current main, `v0.5.0` is the minimum viable remote version, pending full agent test/build validation. `v0.0.0` plus a local replacement is not a reproducible released dependency declaration.

## 4. Evidence from backend

Backend declares Go `1.25.0`, requires common as `v0.0.0`, and uses the same sibling replacement. It imports the common `models` package in agent, telemetry, observability, alerting, repository, handler, and test code.

The minimum viable remote dependency is also `v0.5.0`, because common model source is unchanged from that tag through current main. Full backend tests and build must be rerun after migration.

## 5. Options A/B/C

### Option A — versioned remote module

Remove permanent sibling replacements and consume a released common version.

Advantages: reproducible single-repository checkouts, immutable module checksums, explicit contract versions, independent releases, and clear platform manifests.

Costs: common must be released before consumers adopt changes, coordinated changes need release ordering, and local simultaneous development needs a separate mechanism.

### Option B — full workspace checkout in CI

Keep replacements and check out common at a compatible ref into the expected sibling path.

This supports unreleased development, but makes repository-local CI cross-repository, complicates forks and access, risks ref mismatches, and preserves a release/tooling liability. It belongs only in a separately named compatibility workflow, not normal repository-local CI.

### Option C — released module plus optional `go.work`

Use the released remote module in committed `go.mod` files, while developers create an uncommitted local `go.work` for simultaneous sibling development. A workspace must not be required by CI or reintroduce a committed filesystem replacement.

## 6. Recommended option

Adopt Option C:

1. Make the released remote module the only committed dependency declaration.
2. Use `v0.5.0` as the first viable common dependency for current agent/backend source.
3. Use optional ignored `go.work` for coordinated local edits.
4. Build separate explicit-ref compatibility CI for unreleased combinations.

This preserves the multi-repository architecture while making normal repository-local CI reproducible.

## 7. Required repository changes

Future implementation should:

- replace agent/backend `v0.0.0` requirements with an explicit released version;
- remove committed `replace ../opsnexus-common` directives;
- run `go mod tidy` using the supported Go versions and review `go.sum`;
- document optional local `go.work` without committing a machine-specific file;
- correct common README’s Go version claim;
- add serialization and compatibility tests before common contract changes are released.

No module files or workflows are changed by this analysis.

## 8. Local development workflow

Default local mode uses the released module:

```text
go mod download
go test ./...
go build ./...
```

For simultaneous development, a developer may create a local workspace in the parent directory:

```text
go work init ./opsnexus-common ./opsnexus-agent ./opsnexus-backend
go work use ./opsnexus-common ./opsnexus-agent ./opsnexus-backend
```

The workspace must be ignored and must not be required by repository CI. Developers should run normal module-mode checks before submitting changes.

## 9. CI workflow

Repository-local CI should check out only its repository, install the Go version in its `go.mod`, resolve common normally, and run formatting, vet, tests, race tests where required, and the supported build.

Cross-repository compatibility CI should be separate. It must accept explicit common and consumer refs, use a controlled workspace or module proxy, run compatibility fixtures, never float silently on main, and report the exact ref matrix.

## 10. Release workflow

1. Merge and validate common on main.
2. Create a reviewed semantic version tag.
3. Verify the module is fetchable by its GitHub path.
4. Update consumers to the new common version.
5. Run repository-local and explicit-ref compatibility CI.
6. Release consumers only after exact dependency versions are recorded.

Release workflows are not part of this baseline.

## 11. Versioning implications

Common is a public contract module and should use semantic versioning. Breaking changes require a major-version strategy; compatible additions generally use minor releases; fixes use patch releases.

Agent and backend should record the exact common version in `go.mod`. Platform releases should publish a compatibility manifest containing exact component commits or tags, including common.

`v0.5.0` is a historical release point, not current main. Governance-only commits after it do not require a new module release; the next consumer-visible source or contract change does.

## 12. Migration plan

1. Resolve the common Go-version documentation discrepancy.
2. Add or verify common model serialization and compatibility tests.
3. Validate `v0.5.0` against clean agent/backend module-mode builds.
4. Migrate agent/backend to remote `v0.5.0`.
5. Remove sibling replacements and refresh sums.
6. Run repository-local CI from isolated checkouts.
7. Document and test optional local `go.work`.
8. Add explicit-ref compatibility CI.
9. Define the compatibility manifest and release order.
10. Establish required checks only after passing runs are observed on main.

## 13. Risks

- Retained replacements cause clean agent/backend CI failures or unsafe checkout workarounds.
- Common releases without consumer tests can cause silent model drift.
- Floating common refs remove reproducibility.
- Committed `go.work` can make builds depend on local filesystem layout.
- Incorrect release order can leave consumers between incompatible contracts.
- The common README’s incorrect Go version can cause unintended toolchain selection.

## 14. Exact implementation order

1. Resolve and document the common Go-version discrepancy.
2. Add common compatibility tests.
3. Validate `v0.5.0` in clean agent/backend module mode.
4. Update consumer requirements and remove replacements.
5. Refresh module sums and fix repository-local CI.
6. Document optional `go.work`.
7. Implement explicit-ref cross-repository compatibility CI.
8. Define the compatibility manifest and release order.
9. Establish stable required checks after passing runs on main.

## 15. Stable CI check-name strategy

Current workflows expose one job named `Go baseline`, which does not match the approved stable check convention. Future workflows should expose these exact job names:

| Purpose | Stable job/check name |
|---|---|
| Formatting | `ci/go-format` |
| Static analysis | `ci/go-vet` |
| Unit tests | `ci/unit-tests` |
| Build | `ci/build` |

Agent and backend should additionally expose `ci/race-tests`. Common and CLI do not need race checks in this baseline. Cross-repository compatibility should use a separate `ci/compatibility` check. Names should be observed on main before being made required branch-protection checks.
