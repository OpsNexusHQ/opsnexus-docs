# CI-4 Cross-Repository Compatibility Audit

## Audit scope and method

This audit covers the current `main` state of `opsnexus-common`,
`opsnexus-agent`, `opsnexus-backend`, `opsnexus-api`, `opsnexus-dashboard`,
`opsnexus-cli`, `opsnexus-deployment`, and `opsnexus-docs`. The community
repository `awesome-opsnexus` was inspected only for architecture context; it
contains ecosystem content and no implementation dependency on the platform
components.

The audit used repository manifests, source imports and routes, the OpenAPI
files, dashboard API clients, Docker build contexts, deployment workflow
baseline values, migration files, README release references, and the existing
`opsnexus-docs/COMPATIBILITY.md` and ADR-0001.

## Actual dependency relationships

| Producer | Consumer/relationship | Evidence | Current status |
|---|---|---|---|
| `opsnexus-common` | `opsnexus-agent` | `go.mod` requires `github.com/OpsNexusHQ/opsnexus-common v0.5.0`; source imports `models` | Active released-module dependency |
| `opsnexus-common` | `opsnexus-backend` | `go.mod` requires `github.com/OpsNexusHQ/opsnexus-common v0.5.0`; handlers and repositories import `models` | Active released-module dependency |
| `opsnexus-api` | `opsnexus-backend` | OpenAPI describes the HTTP API; backend registers `/api/v1/*` routes | Intended contract relationship, with drift noted below |
| `opsnexus-api` | `opsnexus-dashboard` | Dashboard client calls `/api/v1/*` and consumes SSE; OpenAPI is documented as the source of truth | Intended consumer relationship, with drift noted below |
| `opsnexus-api` | `opsnexus-cli` | Documentation calls the CLI an API client, but the current program only prints `OpsNexus CLI` | Planned relationship; not an executable consumer today |
| `opsnexus-backend` | `opsnexus-dashboard` | Dashboard uses backend HTTP base URL, health, REST paths, and `/api/v1/events` SSE | Active runtime relationship |
| deployment | `opsnexus-backend`, `opsnexus-dashboard`, `opsnexus-common` | Compose build contexts use the parent workspace; backend imports common and dashboard/backend images are built together | Active selected deployment set |
| `opsnexus-agent` | `opsnexus-backend` | Agent registration and telemetry clients call backend HTTP paths | Active runtime relationship |
| `opsnexus-docs` | all components | Compatibility policy and release references | Governance relationship |

There is no evidence that `awesome-opsnexus` is part of a runtime or build
compatibility graph. It remains outside CI-4 validation.

## Go module findings

The agent and backend both declare exactly:

```text
github.com/OpsNexusHQ/opsnexus-common v0.5.0
```

Neither current `go.mod` contains a sibling filesystem `replace`. The migration
record states that repository-local `go.work` is optional development tooling
and is not used by repository CI. `opsnexus-common` has no external module
dependencies and declares Go 1.22.2; the agent declares Go 1.24.0 and the
backend Go 1.25.0. This is intentional toolchain variation, not a request for
a shared Go version.

The repositories currently have `v0.5.0` tags. The selected common release was
validated in CI-1 and is the supported consumer version. CI-4 should verify
declared module versions, absence of sibling replacements, checksum/module
resolution, and compilation/tests for the selected released common version.
It should not enumerate every historical common version.

## API contract findings

The authoritative contract is `opsnexus-api/api/openapi.yaml`, an OpenAPI
3.1.0 document with local schema references. It declares the v1 events,
agent-registration, telemetry, overview, agent health/metrics/analytics,
alerts, and alert-rules surfaces.

The backend currently registers additional concrete routes for notification
channels, notification deliveries, API tokens, alert comments, and related
mutations. The dashboard client calls those surfaces as well as the declared
agent, telemetry, overview, alerts, and SSE surfaces. The current OpenAPI file
does not contain all of those backend/dashboard paths. This is observed
contract drift, not a reason to silently broaden CI-4 or change schemas in this
audit.

The backend also has a `POST /api/v1/telemetry` route in addition to the
agent-specific route represented in the contract. This should be resolved by
the API owners before a claim of complete consumer-contract compatibility.

CI-4 should therefore separate:

1. OpenAPI syntax/reference and breaking-diff validation, already established
   by CI-2.
2. A narrow selected-contract consumer check for routes and response shapes
   that are actually authoritative.
3. An explicit blocking compatibility decision for any contract drift found
   while aligning the API source and consumers.

CI-4 must not generate clients or infer a complete contract from TypeScript
call sites.

## Dashboard/backend findings

The dashboard compiles `VITE_API_BASE_URL`, defaulting to
`http://localhost:8080`. Its client calls backend health, agent, telemetry,
overview, alert, notification, token, and SSE endpoints. The deployment nginx
serves static content and does not proxy `/api`; the deployment validation
therefore correctly tests static reachability and backend health separately.

The dashboard has meaningful runtime assumptions about JSON fields such as
agent status, overview counts, alert status, telemetry records, and SSE event
types. Existing TypeScript build/lint validation checks the dashboard code but
does not prove live backend response compatibility. CI-4 should add a small,
deterministic contract/smoke layer only for selected supported flows; browser
automation is not necessary for the current architecture.

## CLI findings

`opsnexus-cli` has no dependency on `opsnexus-api` or `opsnexus-common` in its
`go.mod`. Its current `cmd/opsnexus/main.go` only prints `OpsNexus CLI`. The
repository documentation describes it as a preview/placeholder. It must be
represented in the compatibility matrix, but it should be informational until
it has an actual API client and supported command contract.

## Deployment findings

The merged CI-3 workflow explicitly selects this known-good set:

| Component | Exact commit |
|---|---|
| deployment | `262c78fa28d6a1ebc63363012802b348375712f4` |
| common | `b571c0a7ae028906d08cf108e357350dda9384d7` |
| backend | `8b1e3340fee81f52a88bde293dd0a05fbc132668` |
| dashboard | `fe5f4d309b09ed39fceac73ccdfbddfb1c562d97` |

Compose builds backend and dashboard from a temporary parent workspace and
pulls `postgres:16-alpine`. The deployment is independently versioned; its
`v0.6.0` tag is documented as a deployment milestone, not a coordinated
platform release. CI-4 should consume these exact references through a
manifest or checked-in compatibility input, not replace CI-3's immutable
selection with floating branches.

## Version and documentation drift

Observed differences are not all errors:

| Finding | Classification | CI-4 treatment |
|---|---|---|
| Components have independent `v0.5.0` tags while deployment is `v0.6.0` | Intentional independent versioning | Preserve; require a platform manifest for coordinated releases |
| Dashboard package version is `0.0.0` while README/release metadata says `v0.5.0` | Documented metadata distinction | Validate against release metadata, not npm package version alone |
| API source is `1.0.0` while repository release metadata is `v0.5.0` | Independent contract/package versioning; needs explicit mapping | Record API contract version separately in the platform manifest |
| OpenAPI omits backend/dashboard notification, token, and comment paths | Actual contract drift | Blocking for a complete compatibility claim; resolve through API-owner decision |
| CLI is documented as preview/placeholder and has no API dependency | Intentional unsupported capability | Informational/non-blocking until CLI becomes a client |
| Deployment image tags are floating | Compatibility/reproducibility debt | Detect/report in CI-4; image digest hardening remains later scope |

No current canonical machine-readable platform manifest was found. The
existing `COMPATIBILITY.md` is the human-readable policy and matrix.

## Audit risks and resolved implementation decisions

1. The API A-class routes remain contract debt: they must be added to the
   authoritative OpenAPI contract before a complete consumer-compatibility
   claim, but their governance classification is resolved.
2. The canonical manifest owner, location, schema, and update/review policy are
   resolved below. It references exact SHAs/tags and does not control runtime
   dependency versions.
3. Selected consumer checks use a small exact-set workspace, released module
   versions, and immutable API/deployment references; CI-4 does not use a full
   historical version matrix.
4. Authentication-disabled deployment smoke values are suitable for CI, but
   authenticated consumer behavior is not yet covered by a deterministic
   compatibility test.

## Recommended CI-4 shape

The minimal useful validation layers are:

- module compatibility: agent/backend against released common, no sibling
  replacement;
- API contract compatibility: validate and bundle the authoritative contract,
  then run a selected consumer route/shape check;
- deployment-set compatibility: validate the exact manifest revisions through
  the existing CI-3 workspace and smoke path;
- release metadata consistency: validate that every manifest component has an
  existing immutable ref and that documented contract/migration/image fields
  are present.

The API drift finding is now classified and has an explicit staged treatment:
module, manifest, deployment, and contract-covered consumer checks may be
implemented; the complete API consumer claim remains deferred until the
A-class routes are represented in OpenAPI.

## Resolved decision: manifest ownership and schema

Repository evidence confirms that `opsnexus-docs` already owns
`COMPATIBILITY.md`, release policy, release presentation material, architecture
records, and engineering audits. It is therefore the canonical governance
owner. The approved future location is:

```text
opsnexus-docs/engineering/releases/platform-compatibility.yaml
```

The initial schema is intentionally small. It has a platform record and a
`components` map. Each component entry records `version`, immutable `commit`,
and `tag` when one exists. API entries may record `contract_version`; backend
entries may record `migration`; deployment-image fields may record an image
reference or digest. The platform record records the platform version,
compatibility status, migration requirements, release reference, and image
information where applicable. This file is governance/release truth; it does
not replace component `go.mod` or package versioning and does not control
runtime dependency resolution.

The initial reviewed baseline uses current repository `main` SHAs as a
pre-release compatibility snapshot. Repository release metadata remains
independent; the machine-readable manifest records `tag: null` unless a tag
resolves exactly to the selected commit.

| Component | Version/tag evidence | Main SHA | Additional manifest data |
|---|---|---|---|
| `opsnexus-common` | `v0.5.0` metadata; manifest `tag: null` | `b571c0a7ae028906d08cf108e357350dda9384d7` | shared Go module |
| `opsnexus-agent` | `v0.5.0` metadata; manifest `tag: null` | `d01e925cbfe778e0c911ea7f18cce030011ef44f` | consumes common `v0.5.0` |
| `opsnexus-backend` | `v0.5.0` metadata; manifest `tag: null` | `8b1e3340fee81f52a88bde293dd0a05fbc132668` | migration `004_phase5` / `telemetry_hourly` |
| `opsnexus-api` | `v0.5.0` metadata; manifest `tag: null` | `5c25b39547d30a57f07640a79115ca5f43b9544f` | OpenAPI `3.1.0`, `info.version: 1.0.0` |
| `opsnexus-dashboard` | `v0.5.0` release metadata; npm `0.0.0`; manifest `tag: null` | `fe5f4d309b09ed39fceac73ccdfbddfb1c562d97` | compiled API base URL |
| `opsnexus-cli` | `v0.5.0` metadata; manifest `tag: null` | `d0a2e6d3fed05bcef66361112883b57fd7391d64` | compatibility `informational` |
| `opsnexus-deployment` | `v0.6.0` metadata; manifest `tag: null` | `339a9dee79c9f6b9a783525db5c2e6d7d34811eb` | current CI-3 Compose set |
| `opsnexus-docs` | `v0.5.0` metadata; manifest `tag: null` | `f692608bfe837f19625cc4f7208aee70c1fdfc43` | compatibility/release records |

The manifest is updated when a supported component revision, API contract,
migration state, deployment image, or coordinated platform release changes.
The component owner proposes the change; affected component owners review it;
the docs/release owner verifies that every SHA exists and that a supplied tag
resolves to that SHA. A manifest change is itself a CI-4 compatibility trigger.
The file evolves through normal reviewed PR history; its immutable history is
the release record.

For PR validation, the base-branch manifest is the default set. A changed
component is replaced only by its immutable PR head SHA; unchanged components
remain at manifest SHAs. Manifest PRs validate the complete set. This policy
prevents floating or arbitrary dependency selection.

CI-1 remains responsible for repository-local Go quality. CI-4 adds only the
cross-repository module relationship checks, selected contract assertions,
manifest identity checks, and manifest-selected deployment invocation.

## Resolved decision: API route classification

The table below compares backend registrations and dashboard call sites with
the current `opsnexus-api/api/openapi.yaml`. Locations are repository-relative.
The classification is based on implementation comments, the backend README's
“Key API Endpoints”, dashboard usage, docs architecture/release descriptions,
and authentication middleware—not merely on omission from OpenAPI.

| Method | Route | Backend implementation | Dashboard usage | Auth/semantics evidence | Classification and decision |
|---|---|---|---|---|---|
| GET | `/health` | `opsnexus-backend/internal/server/server.go:67`, `internal/health` | `src/api/client.ts:50` | Database-aware operational health; deployment CI requires HTTP 200 and database `ok` | **B — internal/operational endpoint**. Keep outside the public OpenAPI contract; validate separately in deployment/health checks. |
| POST | `/api/v1/telemetry` | `internal/server/server.go:72`, `internal/telemetry/handler.go:104` | None | Handler comment says it accepts telemetry reported by an agent; rate-limited write | **A — authoritative public API**. It is an agent/backend protocol surface and must be added to OpenAPI in a later API-owner change. |
| GET | `/api/v1/agents/{id}/telemetry/latest` | `internal/server/server.go:78`, `internal/telemetry/handler.go:134` | `src/api/agents.ts:39` | Dashboard consumes latest telemetry response | **A — authoritative public API**. Add to OpenAPI before claiming complete dashboard contract coverage. |
| GET | `/api/v1/agents/{id}/metrics/history` | `internal/server/server.go:82`, `internal/observability/handler.go:35` | `src/api/agents.ts:32` | Dashboard consumes historical metrics | **A — authoritative public API**. Add to OpenAPI with its response/query semantics. |
| GET | `/api/v1/alerts/{id}/comments` | `internal/server/server.go:90`, `internal/alerting/handler.go:116` | `src/api/alerts.ts:72` | Incident comments are documented in backend/docs release material; read endpoint is unauthenticated when auth is disabled and subject to global auth policy otherwise | **A — authoritative public API**. Add to OpenAPI. |
| POST | `/api/v1/alerts/{id}/comments` | `server.go:91`, `internal/alerting/handler.go:142` | `src/api/alerts.ts:77` | Operator role required; dashboard posts incident comments | **A — authoritative public API**. Add to OpenAPI with auth/request/response semantics. |
| GET | `/api/v1/notification-channels` | `server.go:97`, `internal/notifications/handler.go:71` | `src/api/notifications.ts:27` | Backend README lists notification channels; dashboard Settings reads them | **A — authoritative public API**. Add to OpenAPI. |
| POST | `/api/v1/notification-channels` | `server.go:98`, `internal/notifications/handler.go:86` | `src/api/notifications.ts:32` | Operator role required; dashboard creates channels | **A — authoritative public API**. Add to OpenAPI. |
| DELETE | `/api/v1/notification-channels/{id}` | `server.go:99`, `internal/notifications/handler.go:118` | `src/api/notifications.ts:39` | Operator role required; dashboard deletes channels | **A — authoritative public API**. Add to OpenAPI. |
| POST | `/api/v1/notification-channels/{id}/test` | `server.go:100`, `internal/notifications/handler.go:138` | `src/api/notifications.ts:45` | Operator role required; dashboard tests webhook/Slack channels | **A — authoritative public API**. Add to OpenAPI. |
| GET | `/api/v1/notification-deliveries` | `server.go:101`, `internal/notifications/handler.go:194` | `src/api/notifications.ts:50` | Operator role required; dashboard reads delivery history | **A — authoritative public API**. Add to OpenAPI. |
| GET | `/api/v1/tokens` | `server.go:105`, `internal/auth` token handler | `src/api/auth.ts:14` | Admin role required; dashboard token-management page reads tokens | **A — authoritative public API**. Add to OpenAPI with raw-token disclosure constraints. |
| POST | `/api/v1/tokens` | `server.go:106`, `internal/auth` token handler | `src/api/auth.ts:19` | Admin role required; dashboard creates tokens | **A — authoritative public API**. Add to OpenAPI with one-time raw-token semantics. |
| DELETE | `/api/v1/tokens/{id}` | `server.go:107`, `internal/auth` token handler | `src/api/auth.ts:26` | Admin role required; dashboard deletes tokens | **A — authoritative public API**. Add to OpenAPI. |

No observed route is classified C or D. The `/health` route is the only B
classification because repository documentation and deployment behavior define
it as an operational database-aware health probe rather than a versioned
business API. Every missing `/api/v1/*` route is classified A because it is
implemented as a versioned HTTP surface, used by the dashboard or agent, and/or
described as supported functionality in repository documentation.

## Final API contract governance decision

`opsnexus-api/api/openapi.yaml` remains authoritative. The A-class routes are
known compatibility debt: they must be represented there before CI-4 can claim
complete API consumer compatibility. This decision does not modify the API,
backend, or dashboard. CI-2 remains responsible for OpenAPI lint, bundling, and
breaking-change checks. CI-4 may implement module and deployment compatibility
layers now, but its full API consumer gate must be limited to contract-covered
surfaces until the A routes are added and reviewed.
