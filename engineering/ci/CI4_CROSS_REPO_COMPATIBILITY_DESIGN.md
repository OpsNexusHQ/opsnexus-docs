# CI-4 Cross-Repository Compatibility Design

## 1. Executive Summary

OpsNexus remains a multi-repository system with independently versioned
components. CI-4 should validate one explicitly selected, reviewable platform
set rather than attempt every historical version combination. The selected set
will be represented by a canonical platform compatibility manifest owned by
`opsnexus-docs`, while each component keeps its own `go.mod`, package metadata,
release tags, and lifecycle.

The manifest schema/ownership and route classifications are approved. CI-4
uses a deterministic manifest-derived compatibility set, replaces changed
component refs with the immutable PR head SHA, and delegates deployment
validation to the existing CI-3 mechanism. Complete public API compatibility
remains explicitly deferred until the classified A routes are represented in
OpenAPI; the initial contract gate covers only the exact contract-covered
assertions defined below.

## 2. Current Repository Dependency Graph

```text
opsnexus-common ───────► opsnexus-agent
        │
        └───────────────► opsnexus-backend ─────► PostgreSQL
                                  │
opsnexus-api ─────────────────────┼────► opsnexus-dashboard
                                  │
                                  └────► deployment

opsnexus-api ─────► opsnexus-cli (planned; current CLI is a placeholder)
opsnexus-docs ────► compatibility/release governance for all components
awesome-opsnexus ─► no runtime/build dependency observed
```

The graph is derived from Go imports and module files, backend route
registration, dashboard API clients, OpenAPI ownership, and Compose build
contexts. It is not a proposal to merge repositories.

## 3. Compatibility Relationships

CI-4 treats these as distinct contracts:

1. Go module contract: agent and backend consume released common APIs.
2. HTTP/API contract: backend routes and response shapes must match the
   authoritative API contract for the selected platform set.
3. Dashboard runtime contract: dashboard base URL, REST paths, JSON fields,
   and SSE event assumptions must be supported by backend/API.
4. Deployment contract: exact deployment/common/backend/dashboard revisions
   form a known-good Compose set.
5. Release-documentation contract: the platform manifest and compatibility
   records name exact component refs, contract version, migration state, and
   image references.

## 4. Go Module Compatibility

The supported current consumer relation is:

```text
opsnexus-agent  ─► github.com/OpsNexusHQ/opsnexus-common v0.5.0
opsnexus-backend ─► github.com/OpsNexusHQ/opsnexus-common v0.5.0
```

CI-4 should run repository-local module checks using declared toolchains and
the public released module: `go list -m`, `go mod verify`, compilation, and
tests for agent/backend. It should fail if a sibling `replace` appears. It
should not create a `go.work`, rewrite module files, or test arbitrary common
versions. A future compatibility upgrade is a deliberate matrix entry, not an
implicit consequence of a branch build.

## 5. API Contract Compatibility

`opsnexus-api/api/openapi.yaml` is the authoritative OpenAPI 3.1 source. CI-2
already validates references, bundles the contract, and checks an explicit
baseline for API breaking changes. CI-4 should add only the consumer assurance
that the selected backend/dashboard set matches the selected contract.

The audit observed backend/dashboard paths for notifications, API tokens, and
alert comments that are not all present in the OpenAPI file. These are
classified A in the audit. CI-4 must not paper over this by generating clients
or treating source-call discovery as the contract. Until those A routes are
represented in OpenAPI, the complete public API consumer gate is deferred;
existing API CI remains active.

## 6. Dashboard/Backend Compatibility

The dashboard builds with a compiled `VITE_API_BASE_URL`, defaults to
`http://localhost:8080`, calls `/health`, REST resources under `/api/v1`, and
the `/api/v1/events` SSE stream. Nginx serves static files and does not proxy
API requests.

The deterministic CI-4 check uses the manifest-derived exact set and the
selected backend/API/dashboard revisions. It prepares one disposable agent
fixture through the contract-covered registration and telemetry routes, then
asserts the following contract-covered responses: agent health, latest metrics,
overview, alerts, and the SSE content type. Static dashboard reachability
remains CI-3's responsibility. Browser automation is not required.

## 7. CLI/API Compatibility

The CLI currently has no API or common-module dependency and its executable
prints a placeholder message. CI-4 should validate that it builds and should
report its preview status in the manifest, but should not make it a blocking
API-consumer gate. When real API commands are introduced, their endpoint,
authentication, and output contracts must be added explicitly.

## 8. Deployment Compatibility

CI-4 should reuse the known-good CI-3 component set without replacing its exact
refs:

| Component | CI-3 validated commit |
|---|---|
| deployment | `262c78fa28d6a1ebc63363012802b348375712f4` |
| common | `b571c0a7ae028906d08cf108e357350dda9384d7` |
| backend | `8b1e3340fee81f52a88bde293dd0a05fbc132668` |
| dashboard | `fe5f4d309b09ed39fceac73ccdfbddfb1c562d97` |

Deployment compatibility should be validated by exact workspace assembly and
the existing Compose validation/startup/migration/smoke path. The manifest
must make changes to these refs deliberate and reviewable. It must not turn
deployment into a monorepo or make runtime repositories share a release
version.

## 9. Version Drift Findings

Independent tags (`v0.5.0` for most components and `v0.6.0` for deployment) are
not errors. The manifest must distinguish component version/tag, commit SHA,
API contract version, migration state, and image references. Dashboard npm
metadata (`0.0.0`) must not be used as a substitute for component release
metadata. The OpenAPI `info.version` (`1.0.0`) must be recorded separately from
the API repository release tag.

The missing API paths identified in the audit are actual compatibility debt and
must be resolved or explicitly classified before a full consumer gate is
claimed. Floating Docker image tags remain a reproducibility limitation and are
not silently converted into digest pinning by CI-4.

## 10. Canonical Compatibility/Release Manifest Strategy

The approved owner is `opsnexus-docs`, and the approved location is
`engineering/releases/platform-compatibility.yaml`. The manifest is a reviewed
governance/release record, not a dependency override or monorepo mechanism. It
should contain, per component:

```yaml
platform:
  version: baseline-2026-08
  compatibility: supported
  migration_requirements: []
  release_notes: RELEASE_PRESENTATION_KIT.md

components:
  opsnexus-backend:
    version: v0.5.0
    commit: 8b1e3340fee81f52a88bde293dd0a05fbc132668
    tag: v0.5.0
    compatibility: supported
    contract_version: 1.0.0
    migration:
      state: 004_phase5
      required: true
    image: null
```

The initial schema uses only scalar fields and a component map. It does not add
JSON Schema, generated schemas, release automation, or dependency-graph syntax.
The full selected values are recorded in the audit's resolved manifest table;
the machine-readable file is intentionally deferred to implementation.

The component owner proposes updates when a supported ref, tag, contract,
migration, or image changes. Affected component owners review; the
`opsnexus-docs` release/compatibility owner verifies that every commit exists
and that `tag` resolves to `commit` whenever both are present. A manifest change
is a CI-4 compatibility trigger. Normal PR review preserves immutable history.

## 11. Proposed CI-4 Validation Layers

The proposed implementation layers are:

1. **Module compatibility** — verify released common resolution, sums, build,
   tests, and no sibling replacements for agent/backend.
2. **Contract compatibility** — validate/bundle the selected OpenAPI contract,
   compare it with the approved baseline, and run the exact contract-covered
   fixture/assertion sequence in Section 19. The gate does not claim complete
   public consumer compatibility while A-class route debt remains.
3. **Deployment-set compatibility** — validate the manifest's exact refs and
   run the existing CI-3 deployment smoke path against that set.
4. **Release metadata consistency** — verify component refs exist, tags and
   SHAs agree where both are supplied, migration state is explicit, and image
   fields are present or explicitly marked deferred.

Do not create an all-by-all historical version matrix. The manifest is the
selection mechanism.

## 12. Repository Trigger/Impact Matrix

| Changed repository | Required CI-4 impact |
|---|---|
| common | Agent/backend module compatibility against the changed released/selected common ref; deployment set only when its manifest ref changes |
| agent | Agent module/build/test validation and selected backend contract checks; no forced backend source change |
| backend | Backend module/build/test, OpenAPI consumer checks, and deployment smoke against the selected set |
| api | OpenAPI lint/bundle/breaking checks plus selected consumer checks after contract classification |
| dashboard | Dashboard lint/build plus selected backend/API response contract checks; no browser gate by default |
| cli | Build and informational compatibility status while placeholder; blocking API checks only after a real client exists |
| deployment | Manifest/ref validation and full CI-3 deployment validation |
| docs | Manifest/schema/reference validation; docs-only changes do not force runtime matrices unless release metadata changes |

The workflow uses path-aware triggers, but a compatibility check is required
whenever a listed relationship is affected. A check may be omitted only when
the relationship is not applicable and repository branch-protection policy
permits path-aware omission. Applicable checks never silently succeed without
running.

## 13. Blocking vs Non-Blocking Rules

Blocking:

- a selected component SHA or tag does not exist or does not match;
- agent/backend cannot resolve or compile against the selected released common;
- a sibling filesystem replacement is required;
- an approved API breaking change lacks coordinated consumer/migration evidence;
- selected deployment revisions fail the CI-3 configuration, startup, migration,
  health, or smoke validation;
- a manifest omits a required component, contract version, migration state, or
  exact ref.

Non-blocking or informational:

- CLI placeholder status before it becomes a real client;
- intentional independent component versions;
- documented image-tag reproducibility debt;
- documentation lag that does not alter the selected manifest or supported
  contract, provided it is tracked for follow-up.

The resolved route decision is: `/health` is B (operational and outside the
versioned public contract); every observed missing `/api/v1/*` route is A
(supported public API) and must be added to OpenAPI before the complete
consumer gate is enabled. There are no C or D routes. Until those A routes are
represented and reviewed, CI-4 may run module, manifest, deployment, and
contract-covered consumer checks, but must report full API consumer
compatibility as deferred rather than claiming it.

## 14. Security/Supply-Chain Considerations

Compatibility workflows must use immutable repository SHAs for cross-repo
inputs and immutable SHAs for all third-party GitHub Actions, with
`contents: read`. Temporary workspaces must not receive credentials or
developer `.env` files. No secrets are needed for normal PR validation.

Module and package downloads should use declared lock/checksum metadata and
standard public registries. Generated bundles and reports belong in temporary
locations or controlled artifacts; they must not silently modify source or
release manifests. No generated client overhaul, broad scanning, or privileged
deployment credentials are part of CI-4.

## 15. Stable CI Check Names

Proposed stable checks, subject to the design-review gate, are:

- `ci/compatibility-modules`
- `ci/compatibility-contract`
- `ci/compatibility-deployment`
- `ci/compatibility-manifest`

The checks are layer-oriented and do not imply that every repository runs every
layer. Path-aware workflow logic may skip irrelevant layers, but a required
layer must not be silently treated as successful when its selected input
changed.

## 16. CI-4 Definition of Done

CI-4 is complete only when:

- the manifest schema and owner are approved;
- exact selected component refs are represented and verified;
- common module compatibility is validated without sibling replacement;
- the authoritative API contract and consumer scope are resolved, with all
  A-class public routes represented or an explicitly approved staged scope;
- selected dashboard/backend assumptions have deterministic checks;
- the CLI is accurately represented as informational or supported;
- deployment validation consumes exact manifest refs and retains CI-3 checks;
- blocking/non-blocking rules and path impact are documented;
- immutable actions, least privilege, secret hygiene, and temporary-workspace
  rules are implemented;
- remote GitHub Actions results are green;
- PR review is complete and the implementation is merged.

## 17. Explicit Non-Goals

CI-4 does not introduce Kubernetes, cloud deployment, automation redesign,
OpenTelemetry, AI/Intelligent Operations, broad security scanning, package
management redesign, monorepo conversion, generated-client overhaul,
application refactoring, feature development, image digest pinning, or release
automation.

## 18. Implementation Plan

1. Add the approved manifest at
   `engineering/releases/platform-compatibility.yaml` with the selected
   current component refs and review it through the normal docs PR process.
2. Add a focused manifest validation tool/check using immutable refs and no
   runtime changes.
3. Add module compatibility checks for agent/backend against selected common.
4. Add contract-covered consumer assertions and dashboard/backend checks; keep
   the complete consumer claim deferred until A routes are represented.
5. Connect deployment validation to manifest-selected exact revisions without
   weakening CI-3.
6. Validate path-aware triggers, fork safety, diagnostics, and failure rules.
7. Review, commit, push, create PRs, inspect remote CI, and merge only after
   all blocking checks are green.

The manifest and route-governance prerequisites are resolved. Workflow
implementation may begin with the staged scope above. A complete API consumer
compatibility claim remains blocked until the A-class routes are added to the
authoritative OpenAPI contract and reviewed.

## 19. Resolved implementation decisions

### Compatibility-set selection

The base set is the current reviewed `platform-compatibility.yaml` on the PR's
base branch. For a component PR, CI checks out the PR head SHA for the changed
component and the manifest SHA for every unchanged component. A multi-component
compatibility PR uses PR head SHAs for exactly the changed components and the
manifest SHAs for the rest. A manifest PR validates every manifest ref and uses
the manifest's complete selected set. No floating branch, latest tag, or
historical matrix is allowed.

The selected set is printed at the start of every applicable check as
`repository`, `version`, `tag`, and `commit`; the same set is passed to all
downstream checks. A missing PR SHA, manifest entry, or ref resolution is a
failure, not a fallback.

### Applicability, inputs, and skip semantics

| Check | Applicable changes | Required inputs | Exact validation and success condition |
|---|---|---|---|
| `ci/compatibility-modules` | common, agent, backend, or manifest changes affecting them | selected common SHA/version; selected agent/backend SHAs; declared Go toolchains | Assert no sibling `replace`; resolve selected common; run `go list -m all` and `go mod verify` in agent/backend; compile/test only the affected consumer relationship. Success requires selected module identity and relationship checks; CI-1 owns repository-local quality jobs. |
| `ci/compatibility-contract` | api, backend, dashboard, or manifest changes involving them | selected API/backend/dashboard SHAs; selected OpenAPI file; exact test fixture | Run CI-2 contract validation, then start the selected backend/database fixture and run the Section 19 HTTP/SSE assertions. Success requires all status/content/field assertions. |
| `ci/compatibility-deployment` | deployment, backend, dashboard, common, or manifest changes affecting the runtime set | selected deployment/common/backend/dashboard SHAs and controlled test env | Call the reusable CI-3 workflow with those exact four inputs. Success is the existing CI-3 config/build/startup/smoke result; CI-4 owns selection, CI-3 owns deployment behavior and cleanup. |
| `ci/compatibility-manifest` | manifest or docs/release metadata changes; also required as a dependency for any check consuming the manifest | manifest path and selected refs | Parse YAML; validate required fields, enum values, SHA format/existence, tag/SHA agreement, API contract format, migration shape, and image field rules. Success requires every referenced repository/ref to resolve. |

“Not applicable” means no affected relationship exists and the workflow may
omit the check through path-aware logic where branch protection supports that
behavior. “Applicable and passing” means the check ran and all assertions
passed. “Applicable and failing” is blocking. “Cannot determine applicability”
is itself a blocking failure and never becomes a successful skipped check.

### CI-3 reuse boundary

The single reuse mechanism is a reusable workflow interface. The smallest CI-3
change is to add `workflow_call` inputs with defaults equal to its current
validated SHAs:

```text
deployment_sha  (required string, default current CI-3 deployment SHA)
common_sha      (required string, default current CI-3 common SHA)
backend_sha     (required string, default current CI-3 backend SHA)
dashboard_sha   (required string, default current CI-3 dashboard SHA)
```

CI-3 replaces its hardcoded checkout refs with these inputs while retaining its
existing pull-request and manual triggers. CI-4's deployment check calls this
workflow and passes the selected set. API is validated by the contract check
and is not a Docker build-context input in the current Compose topology.

The called workflow remains the sole owner of Compose config, builds,
PostgreSQL readiness, migrations, backend health/restart, dashboard reachability,
diagnostics, and cleanup. Inputs are read-only strings; permissions remain
`contents: read`; failures propagate from the called workflow; cleanup remains
owned by CI-3 with `always()` semantics.

### Contract-covered consumer assertions

The contract check uses auth-disabled CI test configuration, a disposable
database, and a unique fixture ID such as `ci-compatibility-agent`. Requests
have a 10-second per-request timeout and the test has a bounded 120-second
backend readiness deadline.

1. `POST /api/v1/agents/register` with the exact required fields from
   `AgentRegistrationRequest.yaml`: `id`, `name`, `hostname`, `os`, `arch`, and
   `version`. Expect HTTP `201`, JSON content type, and the returned `id`.
2. `POST /api/v1/agents/ci-compatibility-agent/telemetry` with the required
   `agent_id`, RFC3339 `timestamp`, and `metrics.system` object from
   `MetricPayload.yaml`. Expect HTTP `201` and JSON `status: accepted`.
3. `GET /api/v1/agents/ci-compatibility-agent/health`. Expect HTTP `200`, JSON
   content type, and required `agent_id` and `status` fields.
4. `GET /api/v1/agents/ci-compatibility-agent/metrics`. Expect HTTP `200`,
   JSON content type, and required `agent_id`, `timestamp`, and `metrics`.
5. `GET /api/v1/overview`. Expect HTTP `200`, JSON content type, and required
   `total`, `healthy`, `stale`, and `offline` fields.
6. `GET /api/v1/alerts`. Expect HTTP `200`, JSON content type, and an `alerts`
   array.
7. `GET /api/v1/events`. Expect HTTP `200` and `Content-Type` beginning with
   `text/event-stream`; the assertion reads the initial `: connected` event
   and closes the bounded request without treating normal stream lifetime as a
   failure.

All seven paths are present in the current authoritative OpenAPI file. No
dashboard source is used as an alternate contract. The A-class notification,
token, comment, and extra telemetry routes remain tracked debt and are outside
this initial gate.

### Manifest release semantics

The initial manifest uses these exact semantics:

- `platform.version`: required coordinated platform identifier; use SemVer
  only for a real platform release, and use an explicit baseline identifier
  such as `baseline-2026-08` before one exists. It is not copied from a
  component version.
- `components.<name>.version`: required component release version or explicit
  `preview` value for an unreleased component.
- `commit`: required lower-case 40-hex immutable SHA.
- `tag`: optional string or YAML `null`; if present it must exist and resolve
  exactly to `commit`; null is valid for an unreleased/preview component.
- `compatibility`: required enum `supported`, `preview`, `informational`, or
  `deprecated`.
- `contract_version`: required only for API-bearing components and records the
  authoritative OpenAPI `info.version` (`1.0.0` currently), separately from
  the API repository tag.
- `migration`: optional structured map with `state` and `required`; the
  initial backend value identifies migration `004_phase5` and
  `telemetry_hourly`; it does not orchestrate migrations.
- `image`: optional string or null. If present it accepts an image reference
  with a digest (`name@sha256:<64-hex>`) or an explicitly marked floating
  reference during the deferred hardening period; the manifest must not call a
  floating tag immutable.

### CI-1 and CI-4 boundary

CI-1 owns repository-local formatting, vet, unit tests, builds, race tests, and
released common-module reproducibility. CI-4 does not repeat those complete
jobs. CI-4 owns only cross-repository identity and relationship assertions:
selected common to consumer resolution, selected API to consumer behavior,
manifest-to-ref consistency, and manifest-to-deployment selection. A CI-4
failure must identify an incompatible relationship, not merely repeat a local
unit-test failure.
