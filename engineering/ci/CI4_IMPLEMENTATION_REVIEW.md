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
