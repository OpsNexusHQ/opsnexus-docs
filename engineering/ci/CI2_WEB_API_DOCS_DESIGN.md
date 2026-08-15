# Phase 0E CI-2: Dashboard + API + Documentation Design

Status: implemented design baseline
Branch: phase0/ci-docs
Scope: opsnexus-dashboard, opsnexus-api, and opsnexus-docs

## Current inventory

The three repositories were inspected from current main:

| Repository | Current main | Relevant state |
|---|---|---|
| opsnexus-dashboard | 95874f2 | React 19, TypeScript, Vite, ESLint, npm lockfile; no test runner or browser-test dependency |
| opsnexus-api | 8cdbd4a | OpenAPI 3.1 contract at api/openapi.yaml with 16 external schema files and 27 references |
| opsnexus-docs | ceaf85a | Markdown documentation and existing Go-module CI records; no documentation-site generator or docs workflow |

The requested approved reference file, engineering/ci/CI_ARCHITECTURE.md, is not present on current docs main. The available engineering/ci records establish repository-local CI, stable check names, least-privilege permissions, pinned/reproducible tooling, and no unrelated-project workflow copying. This document records the CI-2 design pending reconciliation with the missing reference.

### Dashboard baseline

package.json defines:

- npm ci as the reproducible install operation implied by package-lock.json lockfileVersion 3.
- npm run lint as eslint .
- npm run build as tsc -b && vite build.

The package has no engines, .nvmrc, or .node-version declaration. The resolved lockfile versions include Vite 8.2.1, TypeScript 6.0.3, ESLint 10.8.1, and @vitejs/plugin-react 6.0.5. Vite and the React Vite plugin require Node ^20.19.0 or >=22.12.0; ESLint requires Node ^20.19.0, ^22.13.0, or >=24. The proposed pinned baseline is Node 22.23.2 with npm 10.9.8, both observed locally and compatible with every current package engine requirement. CI should use setup-node with the exact Node version, npm caching keyed by package-lock.json, and npm ci.

TypeScript is checked by the existing build command through tsc -b. No separate typecheck script is required for CI-2. No test framework, test script, Vitest/Jest dependency, Playwright dependency, or Cypress dependency is present. Browser testing is therefore absent and must not be implied by the initial CI.

Stable dashboard jobs:

- ci/npm-install — npm ci
- ci/web-lint — npm run lint
- ci/web-build — npm run build
- future ci/web-tests — reserved for a later test framework

## Selected tools and versions

Versions below are design pins. Implementation must use exact versions, preferably through immutable action/container digests or a checked-in tool manifest where the chosen distribution supports it.

### Dashboard

- Node.js 22.23.2
- npm 10.9.8, bundled with the selected Node distribution
- Repository dependencies remain controlled exclusively by package-lock.json and npm ci
- No new test dependency in CI-2

Commands:

    npm ci
    npm run lint
    npm run build

### API contract

Use one small, explicit toolchain:

- Redocly CLI 2.46.1 for OpenAPI 3.1 parsing, reference resolution, linting, and deterministic bundling.
- oasdiff 1.26.1 for future baseline-versus-revision breaking-change detection.

The API workflow should use a pinned Node runtime for Redocly and a pinned oasdiff binary/container release. Redocly is selected because one tool covers validation, external-reference resolution, and bundle generation; oasdiff is selected because it is purpose-built for OpenAPI compatibility and breaking checks. No schema or openapi.yaml change is part of CI-2 design.

Proposed commands:

    npx --yes @redocly/cli@2.46.1 lint api/openapi.yaml --config redocly.yaml
    npx --yes @redocly/cli@2.46.1 bundle api/openapi.yaml --output /tmp/opsnexus-openapi.bundle.yaml --ext yaml
    oasdiff breaking --base /tmp/opsnexus-openapi-main.yaml --revision /tmp/opsnexus-openapi.bundle.yaml

The implementation must decide whether the Redocly configuration is supplied inline or as a committed config file; if a config file is needed, that is an explicit follow-up repository change and not part of this design-only branch. The bundle is a temporary CI artifact or workspace file, never a committed generated schema. Breaking detection is future work until a trusted main baseline is checked out or downloaded and the repository establishes its compatibility policy.

Stable API jobs:

- ci/api-contract — OpenAPI 3.1 lint, parse, reference resolution, and schema validation
- ci/api-bundle — deterministic bundle generation and bundle sanity check
- future ci/api-breaking-change — oasdiff against an explicitly selected main/release baseline

### Documentation

Use the smallest split toolchain:

- markdownlint-cli2 0.23.2 for Markdown/CommonMark style and structural validation.
- lychee 0.20.1 for relative and external link checking, configured to avoid treating temporary/cache paths as repository links.
- POSIX shell plus the runner's standard Python installation for a small repository/reference consistency check; no site generator and no third-party documentation framework.

Proposed commands:

    markdownlint-cli2@0.23.2 "**/*.md" "#node_modules"
    lychee --config .lychee.toml --no-progress "**/*.md"

The consistency check should verify only facts with local sources: documented repository names resolve to the expected OpsNexusHQ repositories, referenced paths exist when they are repository-relative, and practical version references agree with the controlled compatibility document. It must report ambiguous prose for review rather than rewrite documentation. External-link checks should be allowed to distinguish a broken URL from a transient remote failure.

Stable documentation jobs:

- ci/docs-validate — Markdown lint plus repository/reference/version consistency
- ci/link-check — relative-link and external-link checks

## Workflow design

All eventual PR workflows should trigger on pull requests targeting main and use workflow_dispatch where manual diagnostics are useful. Each workflow should set permissions to contents: read and avoid write tokens, package publishing, deployments, or secrets. Jobs should use stable names exactly as listed above. The implementation must not alter the existing Go workflows or copy workflows from another project.

A dashboard workflow should check out one repository, install the exact Node version, run npm ci, and expose the three dashboard jobs. An API workflow should check out one repository, install the pinned contract tools, lint the source contract, create a temporary bundle, and run only deterministic checks. A docs workflow should check out one repository and run Markdown/reference/link checks without building a full documentation site.

## Implementation order

1. Restore or explicitly supersede the missing CI_ARCHITECTURE.md reference.
2. Confirm Node 22.23.2/npm 10.9.8 against the dashboard lockfile and runner image.
3. Add the dashboard PR workflow with install, lint, and build jobs.
4. Add the API tool acquisition and contract lint/bundle workflow without changing schemas.
5. Establish the main/release baseline policy before enabling oasdiff breaking detection.
6. Add Markdown/reference validation and link checking for docs.
7. Review job names, permissions, fork behavior, logs, and temporary artifact handling.
8. Observe green runs on each repository's PR branch before making checks required.
9. Add browser tests and API breaking-change enforcement only in their separately reviewed follow-up phases.

## Known limitations

- The dashboard has no test framework or browser automation today; lint and build do not prove runtime behavior, accessibility, responsive behavior, or authenticated flows.
- The API contract currently uses relative YAML references. Bundle and lint must run from the repository root with the source path unchanged.
- Breaking detection requires a trusted baseline. Comparing every PR to an arbitrary current main checkout can create race conditions; a pinned release/merge-base policy is required.
- External-link checks are network-dependent and can be flaky. They should report failures clearly and use bounded retries/timeouts, without silently converting errors to success.
- Version consistency is partly prose-based today. The consistency check must not invent a platform version or rewrite existing docs.
- Redocly and oasdiff output formats and defaults can change across releases, so versions and configuration must remain pinned.
- CI-2 does not add generated API clients, browser tests, a docs site, deployment checks, or security scanning.

## Future test and browser strategy

First add a dashboard unit/component test framework only when there is behavior worth testing and an agreed runner/browser model. Vitest is a likely candidate for component-level tests, but it is intentionally not selected or installed in CI-2. Add future ci/web-tests only after committing its lockfile changes and defining deterministic DOM, accessibility, and API-mocking boundaries.

Browser smoke tests should be a later job using a pinned Playwright release and browser binaries, with no production secrets. They should cover the operator entry path, loading/error/empty states, routing, accessibility smoke checks, and a safe mocked or disposable API boundary. They must not expose Vite environment values or authenticate against production.

## Security considerations

- Use permissions: contents: read at workflow scope.
- Do not require repository secrets for normal PR checks.
- Do not run shell-evaluated PR content, download and execute unpinned scripts, or use untrusted fork-controlled action references.
- Pin third-party actions and tool distributions to reviewed immutable refs/digests where possible.
- Use npm ci, not npm install, and retain package-lock.json as the dependency source of truth.
- Do not expose Vite environment variables, API tokens, browser storage, or deployment credentials in logs or artifacts.
- Keep API bundles and diagnostics in temporary workspace paths unless a reviewed, non-secret artifact is necessary; do not commit generated bundles.
- Fork PRs must remain read-only and must be safe when secrets are unavailable.
- Do not upload dependency caches or logs containing environment variables, tokens, or user data.
- Do not create global installations on developer or runner machines.

## Exact repository changes expected

This design branch creates only this document in opsnexus-docs. No workflow files are created in CI-2 design.

The later implementation PRs are expected to contain only:

- opsnexus-dashboard: one new repository-local CI workflow, with no source, package manifest, lockfile, Vite configuration, or environment changes unless separately approved.
- opsnexus-api: one new repository-local contract workflow and, only if required by the selected tool invocation, one reviewed pinned-tool configuration file; no openapi.yaml or schema changes.
- opsnexus-docs: one new repository-local docs workflow and any explicitly reviewed lint/link configuration; no documentation content changes required by CI-2.
- No changes to main, runtime code, API schemas, Docker files, secrets, generated artifacts, or unrelated workflows.

## Local tooling availability

Observed locally:

- Node.js 22.23.2
- npm 10.9.8
- npx 10.9.8

Not installed locally:

- actionlint
- markdownlint / markdownlint-cli2
- lychee
- Redocly CLI
- oasdiff
- browser test framework or browser binaries

No dependency was installed globally. Registry version queries were read-only; no package installation or workflow execution was performed.

## Design conclusion

CI-2 should add narrow, pinned, repository-local checks with stable names and least privilege. The first implementation increment is dashboard install/lint/build plus API contract lint/bundle and docs Markdown/link checks. Browser tests and breaking-change enforcement remain explicit follow-ups with their own baseline and dependency decisions.
## Implementation

Implementation branches:

- opsnexus-dashboard: phase0/ci-dashboard
- opsnexus-api: phase0/ci-api
- opsnexus-docs: phase0/ci-docs

The implementation adds:

- opsnexus-dashboard/.github/workflows/ci-web.yml
- opsnexus-api/.github/workflows/ci-api-contract.yml
- opsnexus-docs/.github/workflows/ci-docs.yml
- opsnexus-docs/.markdownlint.json

All workflows use permissions: contents: read. They target pull requests to main and workflow_dispatch. No secrets are required by the dashboard or API workflows. The docs link action uses the automatic read-only GitHub token only for normal link-check operation.

Exact tool versions and stable jobs:

| Repository | Tool/version | Stable jobs |
|---|---|---|
| dashboard | Node 22.23.2, npm 10.9.8, package-lock.json via npm ci | ci/npm-install, ci/web-lint, ci/web-build |
| API | Redocly CLI 2.46.1, oasdiff 1.26.1, Node 22.23.2 | ci/api-contract, ci/api-bundle, ci/api-breaking-change |
| docs | markdownlint-cli2 0.23.2, lychee v0.20.1 | ci/docs-validate, ci/link-check |

Dashboard commands:

    npm ci
    npm run lint
    npm run build

The workflow does not load .env.local, pass Vite secrets, add a test job, or commit dist/node_modules.

API commands:

    npx --yes @redocly/cli@2.46.1 lint --extends=minimal api/openapi.yaml
    npx --yes @redocly/cli@2.46.1 bundle api/openapi.yaml --output "$RUNNER_TEMP/opsnexus-openapi.bundle.yaml" --ext yaml
    curl .../oasdiff_1.26.1_linux_amd64.tar.gz
    sha256sum --check
    oasdiff breaking --base "$RUNNER_TEMP/baseline.yaml" --revision "$RUNNER_TEMP/revision.yaml"

The oasdiff archive is downloaded into RUNNER_TEMP and verified against the release SHA256 before execution; it is not installed globally. The breaking-change job verifies that the explicit API repository tag v0.5.0 resolves to commit c52c716c9d456f6314f06b1f11f71f7bc9caa654, then archives that verified commit and never compares against a floating main. Redocly lint passes the existing contract in minimal mode with 11 pre-existing warnings; no OpenAPI or schema files were changed. The bundle is written only to RUNNER_TEMP and is not committed or uploaded.

Docs commands:

    npx --yes markdownlint-cli2@0.23.2 "**/*.md" "#node_modules" "#dist" "#vendor"
    lycheeverse/lychee-action@v2 with lycheeVersion: v0.20.1

The committed .markdownlint.json disables only eight pre-existing baseline rules that produced 813 issues across the existing documentation; the exact content was not rewritten. With those narrow baseline exclusions, markdownlint-cli2 reports 0 issues. Lychee could not be run locally because the pinned Docker image tag tested was unavailable; the workflow uses the lychee action's explicit v0.20.1 download input and bounded retries.

Local validation:

- dashboard: npm ci, npm run lint, and npm run build passed.
- API: Redocly minimal lint passed with 11 existing warnings; current and v0.5.0 bundles were generated successfully.
- API oasdiff: blocked locally because the v1.26.1 Go module requires Go 1.26 and the local environment could not resolve GitHub to download that toolchain. The workflow uses the pinned release binary instead.
- docs: markdownlint-cli2 0.23.2 passed with the baseline configuration. Lychee was not locally available; the attempted pinned container tag was not found.
- CI_ARCHITECTURE.md is absent from current docs main and was not recreated.

GitHub Actions are pinned to immutable reviewed commits: checkout v4.2.2, setup-node v4.4.0, and lychee-action v2.0.0.

Known limitations and deferred scope:

- API breaking-change validation is implemented against the explicit v0.5.0 baseline, but the baseline policy is only suitable while v0.5.0 remains the approved previous release. A future release policy must update this explicit reference.
- Browser tests, dependency/security scanning, SBOMs, release workflows, a docs-site generator, and runtime/API schema changes remain out of scope.
- The docs baseline exclusions should be reduced through separate documentation cleanup rather than silently expanding them in CI.
