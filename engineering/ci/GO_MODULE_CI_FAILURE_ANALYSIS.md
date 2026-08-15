# CI Failure Analysis

## Agent PR #2

- workflow: `Go CI` ([run](https://github.com/OpsNexusHQ/opsnexus-agent/actions/runs/31884072636))
- run ID: `31884072636`
- Go version: `go1.24.0 linux/amd64`, selected by `actions/setup-go@v5` from `go.mod` (`go-version-file: go.mod`). Runner image: Ubuntu 24.04.4, `ubuntu-24.04`.
- jobs: `ci/go-format` (passed), `ci/go-vet` (failed), `ci/race-tests` (failed), `ci/unit-tests` (failed), and `ci/build` (failed).
- first failing job: `ci/go-vet` ([job](https://github.com/OpsNexusHQ/opsnexus-agent/actions/runs/31884072636/job/95010661505)).
- failing step: `Run go vet ./...`.
- exact error: `cmd/agent/main.go:7:2: missing go.sum entry for module providing package github.com/OpsNexusHQ/opsnexus-common/models (imported by github.com/OpsNexusHQ/opsnexus-agent/cmd/agent); to add: go get github.com/OpsNexusHQ/opsnexus-agent/cmd/agent`.
- module commands and resolution evidence: the step ran `go vet ./...`; Go downloaded `github.com/shirou/gopsutil/v4 v4.26.7`, `golang.org/x/sys v0.41.0`, `github.com/tklauser/go-sysconf v0.3.16`, and `github.com/tklauser/numcpus v0.11.0`, then stopped on the missing `go.sum` entry. The checked-out PR `go.mod` requires `github.com/OpsNexusHQ/opsnexus-common v0.5.0`; its `go.sum` has no common-module entry.
- root cause assessment: confirmed CI failure is module checksum validation during package loading for `go vet`, before vet analysis. The same missing checksum prevents downstream compilation/test/race/build jobs. The log does not show a successful download of `opsnexus-common@v0.5.0`.

## Backend PR #2

- workflow: `Go CI` ([run](https://github.com/OpsNexusHQ/opsnexus-backend/actions/runs/31884077954))
- run ID: `31884077954`
- Go version: `go1.25.0 linux/amd64`, selected by `actions/setup-go@v5` from `go.mod` (`go-version-file: go.mod`). Runner image: Ubuntu 24.04.4, `ubuntu-24.04`.
- jobs: `ci/go-format` (passed), `ci/go-vet` (failed), `ci/race-tests` (failed), `ci/unit-tests` (failed), and `ci/build` (failed).
- first failing job: `ci/go-vet` ([job](https://github.com/OpsNexusHQ/opsnexus-backend/actions/runs/31884077954/job/95010675275)).
- failing step: `Run go vet ./...`.
- exact error: `internal/agent/handler.go:11:2: missing go.sum entry for module providing package github.com/OpsNexusHQ/opsnexus-common/models (imported by github.com/OpsNexusHQ/opsnexus-backend/internal/agent); to add: go get github.com/OpsNexusHQ/opsnexus-backend/internal/agent`.
- module commands and resolution evidence: the step ran `go vet ./...`; Go downloaded `github.com/jackc/pgx/v5 v5.10.0`, `github.com/jackc/pgpassfile v1.0.0`, `github.com/jackc/pgservicefile v0.0.0-20240606120523-5a60cdf6a761`, `golang.org/x/text v0.29.0`, `github.com/jackc/puddle/v2 v2.2.2`, and `golang.org/x/sync v0.17.0`, then stopped on the missing `go.sum` entry. The checked-out PR `go.mod` requires `github.com/OpsNexusHQ/opsnexus-common v0.5.0`; its `go.sum` has no common-module entry.
- root cause assessment: confirmed CI failure is module checksum validation during package loading for `go vet`, before vet analysis. Unit tests, race tests, and build also fail at package setup/compilation because the same common-module checksum is absent. The log does not show a successful download of `opsnexus-common@v0.5.0`.

## Common root cause

Both repositories declare the released dependency `github.com/OpsNexusHQ/opsnexus-common v0.5.0`, but neither PR contains the corresponding checksum data in `go.sum`. Their runners successfully install the declared Go versions and use the default `GOPROXY=https://proxy.golang.org,direct` and `GOSUMDB=sum.golang.org`. Both then fail while loading `github.com/OpsNexusHQ/opsnexus-common/models` with the same `missing go.sum entry` error.

This is a dependency-resolution/checksum failure, not a Go toolchain-selection failure, common-package API/compile failure, build-tag failure, generated-file failure, unit-test execution failure, or race-detector failure. The downstream test/race/build failures are consequences of package setup not completing.

## Confirmed facts

- Agent run `31884072636` used Go 1.24.0; backend run `31884077954` used Go 1.25.0.
- Both runs completed checkout and `actions/setup-go@v5` successfully.
- Both PR manifests require `github.com/OpsNexusHQ/opsnexus-common v0.5.0` and contain no corresponding `opsnexus-common` checksum entry in `go.sum`.
- Both first failing jobs are `ci/go-vet`, and both failing steps are `Run go vet ./...`.
- Both exact errors identify the missing `go.sum` entry for `github.com/OpsNexusHQ/opsnexus-common/models`.
- Agent jobs also failing: unit tests, race tests, and build. Backend jobs also failing: unit tests, race tests, and build. Format passed in both.
- The logs show other dependencies downloading, but do not show `opsnexus-common@v0.5.0` successfully downloading before the checksum error.
- `opsnexus-common` PR #2 run `31884065273` passed all four jobs: format, vet, unit tests, and build ([run](https://github.com/OpsNexusHQ/opsnexus-common/actions/runs/31884065273)). Its module is `github.com/OpsNexusHQ/opsnexus-common`, with `go 1.22.2`; this passing workflow does not demonstrate consumer checksum resolution.
- The agent PR changes the module declaration from local replacement usage to `require github.com/OpsNexusHQ/opsnexus-common v0.5.0` and the backend PR makes the equivalent released-module requirement. Imports use the `models` package; no `replace` directive is present in either migration branch.

## Hypotheses

- The likely missing change is generated module metadata for the released dependency, such as the `go.sum` lines produced by a successful `go mod tidy` or equivalent dependency-resolution command. This is an inference from the manifests and CI errors; it has not been applied or validated in this analysis.
- The absence of a download line for `opsnexus-common@v0.5.0` may reflect Go refusing to use the module until the checksum is recorded, rather than an unavailable tag or proxy outage. The logs alone do not establish why the checksum was omitted.
- There is no observed evidence that Go 1.24 versus Go 1.25, package contents, build tags, generated files, or an API mismatch caused the failure.

## Recommended fix

Update each consumer module's dependency metadata so the released `opsnexus-common v0.5.0` dependency is fully represented in `go.sum`, while preserving the remote module requirement and removing any local replacement. Validate locally with the declared Go version and network/module-proxy access, then run CI once the metadata change is reviewed. Do not use this analysis document as a substitute for that validation.

## OPS-5 impact

OPS-5 remains blocked. The common and CLI PRs pass, but agent and backend cannot validate against the remote `opsnexus-common v0.5.0` module until their dependency checksum metadata is corrected and the CI checks pass.
## Remote Diagnostic Resolution

The temporary diagnostic workflows ran on the same PR merge revisions as the normal Go CI:

- Agent diagnostic run [31891205133](https://github.com/OpsNexusHQ/opsnexus-agent/actions/runs/31891205133), job [95027628300](https://github.com/OpsNexusHQ/opsnexus-agent/actions/runs/31891205133/job/95027628300), used Go 1.24.0 linux/amd64.
- Backend diagnostic run [31891188797](https://github.com/OpsNexusHQ/opsnexus-backend/actions/runs/31891188797), job [95027588080](https://github.com/OpsNexusHQ/opsnexus-backend/actions/runs/31891188797/job/95027588080), used Go 1.25.0 linux/amd64.

Both diagnostics printed GOPROXY=https://proxy.golang.org,direct and GOSUMDB=sum.golang.org, then successfully ran:

    go mod download -json github.com/OpsNexusHQ/opsnexus-common@v0.5.0

The exact JSON returned in both runs was:

    {
      "Path": "github.com/OpsNexusHQ/opsnexus-common",
      "Version": "v0.5.0",
      "Info": "/home/runner/go/pkg/mod/cache/download/github.com/!ops!nexus!h!q/opsnexus-common/@v/v0.5.0.info",
      "GoMod": "/home/runner/go/pkg/mod/cache/download/github.com/!ops!nexus!h!q/opsnexus-common/@v/v0.5.0.mod",
      "Zip": "/home/runner/go/pkg/mod/cache/download/github.com/!ops!nexus!h!q/opsnexus-common/@v/v0.5.0.zip",
      "Dir": "/home/runner/go/pkg/mod/github.com/!ops!nexus!h!q/opsnexus-common@v0.5.0",
      "Sum": "h1:Yms+mM2MLozsC3caLDpxNW6AQbLcBgj5kEoLES37jm8=",
      "GoModSum": "h1:NBdLxpgZadhE5c2RAdQZprvq75KE+LcagoTZeEgcDoE=",
      "Origin": {
        "VCS": "git",
        "URL": "https://github.com/OpsNexusHQ/opsnexus-common",
        "Hash": "8e51918051b4ac57ac2b989c2f5b442d3665c46d",
        "Ref": "refs/tags/v0.5.0"
      }
    }

Thus, .mod, .zip, and .info metadata were downloaded and the extracted module cache directory was populated. The output contains Sum, GoModSum, Version, and Origin; it contains no Error field. The exact cache directory was /home/runner/go/pkg/mod/github.com/!ops!nexus!h!q/opsnexus-common@v0.5.0, with download artifacts under /home/runner/go/pkg/mod/cache/download/github.com/!ops!nexus!h!q/opsnexus-common/@v/.

The normal CI used the same declared Go versions and the same GOPROXY and GOSUMDB values. Its first failing step was go vet ./...: agent job [95027628212](https://github.com/OpsNexusHQ/opsnexus-agent/actions/runs/31891205101/job/95027628212) reported "cmd/agent/main.go:7:2: missing go.sum entry for module providing package github.com/OpsNexusHQ/opsnexus-common/models"; backend job [95027588754](https://github.com/OpsNexusHQ/opsnexus-backend/actions/runs/31891188907/job/95027588754) reported the corresponding "internal/agent/handler.go:11:2" error. The diagnostic directly downloads a requested module and returns its metadata; go vet ./... resolves imported packages as part of the consumer build and requires the consumer's checksum metadata. The diagnostic's successful cache download therefore does not add the missing lines to the committed consumer go.sum.

The current agent and backend go.sum files contain no opsnexus-common lines. The exact two lines expected by Go, using only the checksums emitted by the successful diagnostics, are:

    github.com/OpsNexusHQ/opsnexus-common v0.5.0 h1:Yms+mM2MLozsC3caLDpxNW6AQbLcBgj5kEoLES37jm8=
    github.com/OpsNexusHQ/opsnexus-common v0.5.0/go.mod h1:NBdLxpgZadhE5c2RAdQZprvq75KE+LcagoTZeEgcDoE=

Adding those generated checksum lines to each consumer go.sum, without changing the remote module requirement or CI workflow, is the exact remediation indicated by the evidence. It is deterministic for the tagged module because both Go 1.24.0 and Go 1.25.0 resolved the same path, version, tag, VCS hash, module sum, and go.mod sum. The resulting metadata should allow package loading for go vet, unit-test compilation/execution, race-test compilation/execution, and the build; those commands still require a subsequent CI run to confirm.

OPS-5 remains blocked until the checksum metadata is added, a new commit is pushed, and the updated agent/backend PR CI is green. This diagnostic did not modify either consumer's go.mod or go.sum; a new commit is required for the actual fix.

## Resolution

The successful remote diagnostics confirmed that github.com/OpsNexusHQ/opsnexus-common v0.5.0 is fetchable through the standard Go proxy/direct configuration. Both Go 1.24.0 and Go 1.25.0 resolved the tagged source at VCS SHA 8e51918051b4ac57ac2b989c2f5b442d3665c46d.

The exact checksums emitted by Go were:

    github.com/OpsNexusHQ/opsnexus-common v0.5.0 h1:Yms+mM2MLozsC3caLDpxNW6AQbLcBgj5kEoLES37jm8=
    github.com/OpsNexusHQ/opsnexus-common v0.5.0/go.mod h1:NBdLxpgZadhE5c2RAdQZprvq75KE+LcagoTZeEgcDoE=

The consumer modules declared the released dependency but their go.sum files lacked both checksum lines. The remediation is limited to adding these two generated entries to opsnexus-agent/go.sum and opsnexus-backend/go.sum; go.mod, workflows, source, and the module strategy remain unchanged.

Local validation passed with the declared Go versions and standard GOPROXY/GOSUMDB settings in both repositories: gofmt -l . produced no output, go vet ./..., go test ./..., go test -race ./..., and the respective builds passed. Remote CI must still be rerun automatically or manually after the fix commit is pushed to confirm the PR checks are green.

OPS-5 remains open until updated remote CI passes for both consumer PRs.
