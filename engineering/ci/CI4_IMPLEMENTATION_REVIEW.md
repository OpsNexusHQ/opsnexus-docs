# CI-4 Implementation Review

## Status

NOT READY FOR CI-4 IMPLEMENTATION REVIEW

This is a local implementation pre-review. No remote CI, push, PR, or merge
has occurred.

## Implemented files

`opsnexus-docs`:

- `engineering/releases/platform-compatibility.yaml`
- `scripts/validate-platform-compatibility.rb`
- `.github/workflows/ci-compatibility-manifest.yml`

`opsnexus-deployment`:

- `.github/workflows/ci-deployment-validation.yml`

The deployment workflow now exposes a `workflow_call` interface with injectable
deployment, common, backend, and dashboard commit SHAs. Existing pull-request
and manual triggers remain, and the existing deployment jobs remain the source
of truth for Compose validation, builds, readiness, migrations, smoke checks,
diagnostics, and cleanup.

## Manifest

The manifest contains all eight component entries, current reviewed component
versions/tags/SHAs, API contract version `1.0.0`, backend migration evidence,
controlled compatibility values, and an explicit `null` image field where image
digest data is not yet available.

The validator checks YAML structure, component coverage, SHA format, remote
commit/tag identity, compatibility enums, API contract format, migration shape,
and image syntax. It uses read-only Git metadata and emits no secrets.

## Stable checks

Implemented:

- `ci/compatibility-manifest`

Not yet implemented:

- `ci/compatibility-modules`
- `ci/compatibility-contract`
- `ci/compatibility-deployment`

## Blocker discovered during implementation

The approved design requires contract HTTP assertions to run against the same
selected live deployment set used by CI-3, without duplicating deployment
logic. GitHub Actions jobs do not share a live Docker Compose service across
jobs. A separate contract job would therefore either duplicate the CI-3 stack
or require an assertion mode inside the reusable CI-3 workflow.

The current implementation has only added the reusable workflow inputs; it has
not added that assertion mode or created a divergent second deployment stack.
The remaining implementation decision is to extend the reusable CI-3 workflow
with an explicit contract-assertion input/step and define how its result maps
to `ci/compatibility-contract`, while retaining one deployment source of truth.

## Validation

- Platform manifest parsed successfully with local PyYAML.
- CI-4 manifest workflow YAML parsed successfully.
- CI-3 workflow YAML parsed successfully after adding `workflow_call` inputs.
- `git diff --check` passed for docs and deployment.
- Ruby is not installed locally, so the Ruby manifest validator could not be
  executed locally; GitHub-hosted runner execution remains required.
- Docker daemon availability and live compatibility execution were not tested.

## Scope review

No application source, OpenAPI, migration, Dockerfile, Compose topology,
dependency, or runtime files were changed. No manifest was created outside the
approved docs location. No credentials or secrets were added.

The implementation is intentionally stopped before adding incomplete module,
contract, and deployment callers.

## Blocker resolution attempt

The deployment workflow now accepts:

- `run_contract_assertions: boolean`, default `false`;
- `contract_profile: contract-basic`, a fixed non-shell-injection profile.

The `contract-basic` profile is implemented as
`opsnexus-deployment/.github/scripts/ci-contract-basic.sh` and covers only
OpenAPI-present routes: registration, agent telemetry, agent health, metrics,
overview, alerts, and bounded SSE connection validation. It uses test-only
data, bounded curl requests, explicit JSON assertions, and fails on any
assertion error.

The reusable workflow executes the profile after backend restart readiness and
before its existing diagnostics/cleanup steps. This proves the lifecycle
injection point without duplicating Compose startup or cleanup.

The remaining issue is GitHub check identity: exposing both independent stable
checks `ci/compatibility-contract` and `ci/compatibility-deployment` while
running one reusable workflow requires either two workflow invocations (which
creates two Compose lifecycles) or a single job with one check name. GitHub
Actions jobs cannot publish two independent required check names from one job
without an additional status-publishing mechanism, which would require write
permissions and is outside the approved security model. The implementation is
therefore still stopped rather than duplicating deployment or inventing a
privileged status bridge.

## Revised check semantics implementation

The static/live split is now represented by:

- `.github/compatibility/contract-basic.json`: one fixed assertion definition;
- `ci/compatibility-contract`: static OpenAPI operation/media-type validation;
- `ci/compatibility-deployment`: the sole live caller of reusable CI-3 with
  `run_contract_assertions: true`;
- `ci/compatibility-modules`: relationship checks in agent and backend.

The live assertion script remains the only runtime HTTP implementation and is
invoked inside CI-3 before its existing cleanup. No second Compose lifecycle or
status-writing permission was introduced.

## Remaining implementation limitations

The module and deployment callers currently use the approved baseline refs;
the complete PR-head substitution and base-manifest resolution still need to
be wired through caller inputs for every repository before remote validation.
The local Docker daemon is unavailable, so live assertions remain unexecuted
locally. Ruby is unavailable, so the Ruby manifest validator remains unexecuted
locally; YAML, shell, and static contract validation passed.
