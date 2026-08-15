# Go Module Migration

Status: phase 0 implementation on `phase0/go-module-migration`

## Dependency model

Before this migration, `opsnexus-agent` and `opsnexus-backend` required
`github.com/OpsNexusHQ/opsnexus-common v0.0.0` and committed a sibling
filesystem replacement:

```text
replace github.com/OpsNexusHQ/opsnexus-common => ../opsnexus-common
```

After this migration, both consumers require the released module
`github.com/OpsNexusHQ/opsnexus-common v0.5.0` and have no replacement. This
makes a clean, single-repository checkout resolve the same immutable module
version as CI and release builds. The multi-repository architecture is
unchanged.

The replacement was removed because it depends on a sibling checkout that is
not present in repository-local CI and cannot provide reproducible module
checksums or release provenance.

## Common toolchain and compatibility

`opsnexus-common/go.mod` remains:

```text
module github.com/OpsNexusHQ/opsnexus-common
go 1.22.2
```

The model source uses `time` and ordinary struct tags; it does not require Go
1.25 language or standard-library APIs. The README Go badge was corrected from
`1.25+` to `1.22+`. No model or API schema was redesigned.

Small deterministic tests were added for JSON serialization and tags on
`Agent`, `AgentRegistration`, and `AgentTelemetry`. No additional nested
telemetry model types exist in the current common package.

## Optional local workspace

Normal module mode remains the source of truth:

```bash
go mod download
go test ./...
go build ./...
```

For simultaneous local edits across sibling repositories, developers may use
an uncommitted workspace from the parent directory:

```bash
go work init ./opsnexus-common ./opsnexus-agent ./opsnexus-backend
go work use ./opsnexus-common ./opsnexus-agent ./opsnexus-backend
```

`go.work` and `go.work.sum` are optional, local-only files and must not be
committed. Repository-local CI does not use them. Exact root ignore entries
were added to the Go repositories to prevent accidental tracking without
ignoring unrelated files.

## CI strategy

Repository-local workflows check out only their own repository, install the Go
version declared by `go.mod`, and expose these check names:

- `ci/go-format`
- `ci/go-vet`
- `ci/unit-tests`
- `ci/build`

Agent and backend additionally expose `ci/race-tests`. No vulnerability or
security scanning was added. Agent and backend workflows have no dependency on
`../opsnexus-common`.

## Release ordering

1. Validate and merge `opsnexus-common`.
2. Create its reviewed semantic-version tag in a later release operation.
3. Confirm the tagged module is fetchable and usable by clean consumers.
4. Update agent and backend to the exact common version.
5. Validate and release consumers after their module files and sums are stable.

No tag, commit, push, or pull request is created by this migration.

## Compatibility implications and limitations

`v0.5.0` is selected because its tagged model source matches the current
common source consumed by agent and backend. The local repository contains the
tag and its module path is correct. Public proxy/GitHub fetch verification was
blocked in this environment by unavailable DNS/network access, and the local
Go tool is 1.22.2 while agent declares Go 1.24.0 and backend declares Go
1.25.0. Those requirements were not weakened.

The common module has no `go.sum` because it has no external dependencies.
Agent and backend retain their existing sums pending `go mod tidy` with the
repository-supported toolchains and successful access to the released module.

## Validation record

- Common `gofmt`, `go vet ./...`, `go test ./...`, and `go build ./...` passed
  using an isolated writable Go cache. The `v0.5.0` source was locally
  archived and tested successfully.
- Agent and backend formatting completed; tidy and downstream validation remain
  blocked by unavailable Go 1.24/1.25 toolchains and unavailable network/module
  proxy access. No agent/backend validation is claimed as passed.
- CLI formatting completed; its workflow was updated only for required job
  naming and remains independent of common.
