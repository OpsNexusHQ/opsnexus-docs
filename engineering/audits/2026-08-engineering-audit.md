# OpsNexus Engineering Audit

Audit date: 2026-08-15  
Audit branch: `audit/engineering-baseline-2026-08` in `opsnexus-docs`  
Scope: all nine local OpsNexus repositories, inspected read-only. No dependencies were installed and no existing file was changed.

## 1. Executive Summary

OpsNexus is a credible final-year project and a strong portfolio project: it has a coherent observability story, real Go implementation, a working React surface, PostgreSQL persistence, alerting, SSE, notifications, retention, RBAC, Docker deployment, tests in the two principal Go services, and a sensible multi-repository intent. The codebase is beyond a mock, but the evidence does not yet support calling it a production-ready infrastructure product or a mature open-source project.

The platform is currently an early-stage infrastructure product prototype. Its strongest product quality is the end-to-end vertical slice from host telemetry to persistence, alert evaluation, notification, and operator UI. Its largest engineering weakness is the lack of organization-wide delivery controls: there is no visible GitHub Actions CI, no contribution/security policy set, no automated contract or release validation, and component documentation describes capabilities and versions more confidently than the repository evidence can guarantee.

Overall assessment: architecturally promising, implementation-bearing, operationally immature. Preserve the core boundaries and harden the seams before adding more features.

## 2. Current-State Architecture

The actual platform is:

```text
Linux host
  opsnexus-agent (Go + gopsutil)
      └─ registration and periodic JSON telemetry over HTTP
          └─ opsnexus-backend (Go net/http + pgx)
              ├─ PostgreSQL migrations and JSONB telemetry persistence
              ├─ agent health and observability queries
              ├─ alert rule evaluation and incident state
              ├─ bounded notification queue -> webhook / Slack
              ├─ SSE hub -> dashboard
              └─ retention worker / hourly rollup logic
                  └─ opsnexus-dashboard (React + TypeScript + Vite)

opsnexus-common: shared Go models imported by agent and backend
opsnexus-api: OpenAPI/schema repository intended as the HTTP contract
opsnexus-deployment: Compose, PostgreSQL, backend/dashboard images, Nginx
opsnexus-cli: currently a placeholder executable
opsnexus-docs: architecture, security, ADR, release and presentation material
awesome-opsnexus: curated ecosystem index
```

Authentication is bearer API-token authentication in the backend, with SHA-256 token hashes, expiry, enabled state, and viewer/operator/admin roles. Authentication is explicitly disabled by default, and `/health` and the SSE endpoint are public. The dashboard currently does not visibly attach a bearer token in its API client, so authenticated deployment compatibility needs verification and likely a deliberate browser-token design.

Telemetry is collected by the agent every 10 seconds and sent to registration and agent-specific telemetry endpoints. The backend stores flexible metric maps as JSONB. Incoming telemetry feeds the alert engine and publishes events. The SSE hub emits telemetry, registration/status, alert lifecycle, comments, and ping events. The dashboard consumes an `EventSource` with reconnect backoff and a polling status fallback.

Alerts support sustained threshold evaluation, deduplication/cooldown behavior, firing/acknowledged/resolved lifecycle, comments, and notification delivery. Webhooks use HMAC-SHA256 signatures; Slack uses an incoming webhook provider. Retention purges raw telemetry and maintains hourly rollups according to backend configuration.

Docker Compose deploys PostgreSQL, a multi-stage backend image, and a multi-stage dashboard/Nginx image. The agent is intentionally installed independently on monitored hosts. There is no visible production TLS proxy configuration, secret manager integration, image scanning, migration gate, backup/restore procedure, or deployment smoke test.

Important source/documentation discrepancies:

- The backend README says `go run ./cmd/server`, but the repository has no `cmd/server`; it contains a tracked `server` ELF binary and no visible Go entrypoint in the inspected tree. This makes the documented source build/run path invalid or at least non-reproducible.
- The backend README contains `https.github.com/...` instead of `https://github.com/...` in its clone command.
- The deployment repository has a `v0.6.0` tag while its README and release badge say `v0.5.0`; the other repositories are tagged `v0.5.0`.
- The dashboard package version is `0.0.0` while its README presents v0.5.0.
- The agent README names `OPSNEXUS_BACKEND_URL`, `OPSNEXUS_COLLECT_INTERVAL`, and `OPSNEXUS_AGENT_NAME`; inspected agent source uses `OPSNEXUS_AGENT_BACKEND_URL`, `OPSNEXUS_AGENT_COLLECTION_INTERVAL`, and does not show the documented agent-name variable.
- The API repository calls itself the single source of truth, but no contract generation, backend route verification, or dashboard type generation is present in the repository evidence.
- The README claims/licenses MIT in most implementation repositories, but only the agent had a visible `LICENSE` file in the inspected local trees; deployment and dashboard also contain generated/local-looking artifacts (`.env` and `.env.local`) that deserve immediate provenance review even though their Git status was clean.

## 3. Repository Responsibility Map

| Repository | Belongs there | Does not belong there | Dependencies / consumers |
|---|---|---|---|
| `opsnexus-agent` | Linux host collection, local config, registration, telemetry transport, lifecycle | Backend persistence, UI, alert policy, deployment orchestration | Depends on `common`; consumed by backend |
| `opsnexus-backend` | HTTP control plane, persistence, auth/RBAC, alerting, incidents, events, notifications, retention | React assets, public contract authoring, host-specific collectors | Depends on `common` and PostgreSQL; consumed by agent, dashboard, CLI, deployment |
| `opsnexus-dashboard` | Operator UI, API client, SSE client, presentation state | Database access, business rules, secrets, migrations | Consumes backend and API contract; deployed by deployment |
| `opsnexus-common` | Stable Go wire/domain models shared by Go components | UI types, database implementation, business behavior | Consumed by agent/backend; should remain small and compatibility-controlled |
| `opsnexus-api` | Versioned OpenAPI, schemas, examples, compatibility rules | Runtime handlers, generated build output without ownership | Consumed by backend, dashboard, CLI, docs and CI |
| `opsnexus-deployment` | Compose, images, runtime config templates, migrations/startup, deployment checks | Product business logic and source copies | Builds backend/dashboard; runs PostgreSQL; operational consumer of all services |
| `opsnexus-docs` | Platform architecture, operations, security, ADRs, compatibility and release docs | Unverified product claims, duplicated API definitions | Consumes all repositories; serves contributors/operators/users |
| `opsnexus-cli` | Authenticated operator/client workflows against stable API | Backend internals, duplicate domain implementation | Consumes API; currently only placeholder |
| `awesome-opsnexus` | External resources, integrations and community links | Canonical architecture or release truth | Consumes public repositories/docs |

The multi-repository model is valid, but only if the API contract, compatibility matrix, release train, ownership, and cross-repository CI are treated as first-class artifacts.

## 4. Repository Quality Ratings

Scores are evidence-based, where 1 means absent/unsafe and 10 means mature and repeatable. Testing means repository-level automated test evidence, not manual plausibility.

| Repository | Arch | Code | Org | Test | Docs | Sec | CI | Release | DX | Overall |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| `opsnexus-agent` | 7 | 7 | 7 | 7 | 7 | 5 | 1 | 5 | 6 | **5.7** |
| `opsnexus-backend` | 8 | 7 | 7 | 7 | 7 | 5 | 1 | 5 | 5 | **6.0** |
| `opsnexus-dashboard` | 7 | 7 | 7 | 2 | 6 | 4 | 1 | 4 | 6 | **4.9** |
| `opsnexus-common` | 8 | 7 | 7 | 1 | 6 | 5 | 1 | 5 | 5 | **5.0** |
| `opsnexus-api` | 8 | 6 | 7 | 1 | 6 | 5 | 1 | 5 | 5 | **4.9** |
| `opsnexus-deployment` | 7 | 6 | 6 | 1 | 6 | 4 | 1 | 4 | 5 | **4.4** |
| `opsnexus-docs` | 7 | 6 | 7 | 1 | 7 | 5 | 1 | 5 | 6 | **5.0** |
| `opsnexus-cli` | 2 | 2 | 5 | 1 | 4 | 5 | 1 | 4 | 3 | **3.0** |
| `awesome-opsnexus` | 3 | 4 | 5 | 1 | 6 | 5 | 1 | 4 | 5 | **3.8** |

## 5. Organization-Level Rating

| Area | Score | Explanation |
|---|---:|---|
| Architecture | 7/10 | Boundaries and end-to-end flow are coherent; contract and runtime seams are not governed. |
| Engineering | 6/10 | Real implementation and tests exist, but entrypoints, versioning and repeatability have gaps. |
| Product maturity | 4/10 | Useful vertical slice; defaults, upgrades, tenancy, reliability and operations are early-stage. |
| Documentation | 6/10 | Architecture/security/readmes exist, but several claims and instructions are stale or unverified. |
| Security | 4/10 | Token hashing/HMAC/RBAC are good foundations; auth-off, wildcard CORS, HTTP defaults and secret hygiene are risky. |
| DevOps | 4/10 | Compose is a useful start; no validated production pipeline, images policy, backups or observability gates. |
| CI/CD | 1/10 | No `.github/workflows` were found in the nine local repositories. |
| Open-source readiness | 3/10 | Public-looking repos and licenses in prose, but no contribution/security templates, CI, governance or consistent licensing evidence. |
| Portfolio value | 8/10 | Strong breadth and a demonstrable vertical slice; presentation improves substantially after truthfulness and quality gates are fixed. |

## 6. KEEP

- Keep the explicit repository boundaries and the agent/common/backend/dashboard/deployment vertical slice.
- Keep Go for the agent and backend, React/TypeScript for the dashboard, PostgreSQL for durable state, and OpenAPI as the intended external contract.
- Keep the backend package separation: agent, telemetry, alerting, events, notifications, auth, middleware, observability, retention and database.
- Keep the agent collector decomposition and its focused tests.
- Keep backend handler/repository interfaces and unit tests; they are useful seams for integration testing.
- Keep SSE for dashboard freshness where one-way server-to-browser delivery is sufficient.
- Keep the notification queue, retry boundary, HMAC webhook signing, token hashing, expiry and RBAC concepts.
- Keep migrations as ordered SQL and JSONB for evolving telemetry, subject to indexes, validation and retention testing.
- Keep the deployment repository as the source of Compose/runtime topology rather than placing deployment logic in application repositories.
- Keep the architecture docs and ADR approach; update claims from verified behavior rather than discarding the structure.
- Keep the CLI as a separate boundary if it becomes a real API client; do not prematurely merge it into the backend.

## 7. CLEAN

The following should be corrected in small, reviewable changes:

- **Backend tracked `server` ELF / missing source entrypoint:** remove the binary only after locating or restoring the source entrypoint, and document the supported build path. A binary in a source repository is non-reproducible and obscures the actual application boundary.
- **Backend README run command and malformed clone URL:** fix because a new contributor cannot follow the documented quickstart.
- **Deployment v0.6.0 tag versus v0.5.0 README/badge:** decide whether the tag represents deployment-only work or a platform release; current presentation is misleading.
- **Dashboard `package.json` version `0.0.0`:** align it with the chosen release strategy or explicitly declare independent component versioning.
- **Agent environment-variable documentation/source mismatch:** choose one naming convention, add tests, and update README/examples.
- **Tracked/local environment artifacts:** inspect `opsnexus-deployment/.env`, dashboard `.env.local`, and generated `dist`/`node_modules` provenance. They were present in the clean worktrees; ensure no secret or machine-specific/generated content is tracked or distributed.
- **Starter assets:** dashboard `src/assets/react.svg` and `src/assets/vite.svg` appear template-derived and are not part of the product design; remove only after confirming no runtime use. The placeholder CLI main is a starter artifact until the CLI scope is implemented.
- **Typo in release topics (`postgesql`):** correct organization metadata, because it harms discoverability and polish.
- **Awesome contribution link:** it points to the docs repository root rather than a visible `CONTRIBUTING.md`; make the link real or state that contribution governance is not yet published.
- **Prose-only licenses:** add the correct license file to every repository whose README claims a license, with explicit license choice for `awesome-opsnexus` (README says CC0 while implementation repositories say MIT).

Do not clean by mass renaming or broad refactoring during the baseline; each cleanup should be tied to a verified consumer and a test.

## 8. MOVE

- Keep runtime Dockerfiles and Compose in `opsnexus-deployment`; do not move application source there. The deployment Dockerfiles currently build from the parent workspace, so the build context contract must be documented and CI-tested.
- Keep OpenAPI source in `opsnexus-api`, but move any hand-maintained duplicate endpoint/schema definitions out of docs once generated/reference documentation exists. Docs may link to the contract and explain workflows.
- Keep shared Go wire models in `opsnexus-common` only when both agent and backend need them. Backend-only alert/notification/domain models should remain in backend; do not turn common into a dumping ground.
- Move future CLI API types into generated/client-owned CLI code or common only when they are truly shared; do not import backend `internal` packages.
- Put organization-wide workflows, issue forms, PR template and CODEOWNERS at each repository root or through a maintained shared workflow. Do not centralize code ownership in docs.
- Put operator runbooks and upgrade/rollback procedures in docs; keep deployable defaults/templates in deployment.

No source-code move is required before the contract, entrypoint and CI baseline is established.

## 9. MISSING

- CI in every implementation repository: format, lint, tests, build, dependency/security scan and artifact checks.
- Cross-repository compatibility CI for agent/common/backend/API/dashboard/deployment.
- Contract linting and breaking-change detection for `opsnexus-api`; generated clients/types or a checked-in compatibility matrix.
- Integration tests using PostgreSQL migrations, HTTP endpoints, auth, SSE, alerting and notification providers.
- Dashboard unit/component/browser tests and a real build/lint gate.
- CLI implementation tests and a defined supported command surface.
- `CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md`, issue forms, PR template and CODEOWNERS where ownership is meaningful.
- A real changelog/release-notes source and GitHub Release automation.
- Architecture documentation for deployment lifecycle, data retention semantics, failure modes, API compatibility and upgrade/rollback.
- Secret handling policy, auth-on production enforcement, TLS boundary, CORS policy, webhook SSRF/egress policy and token redaction tests.
- Database migration validation, backups, restore drills, indexes/performance checks and schema rollback strategy.
- Container health/readiness checks, image pinning/digest policy, vulnerability scanning, SBOM and non-root runtime validation.
- Operational metrics, structured logs with levels, trace/request correlation, alerting for queue drops, database failures and stale agents.
- Quality gates for generated OpenAPI, README links, markdown, spelling, release-version consistency and Docker Compose rendering.

## 10. Standard Repository Structure

Use repository-specific structures rather than forcing a single template.

### `opsnexus-agent`

```text
opsnexus-agent/
├── cmd/opsnexus-agent/main.go
├── internal/{agent,collector,config,transport}/
├── tests/                 # integration/black-box tests if needed
├── configs/               # safe examples only
├── scripts/
├── README.md LICENSE CONTRIBUTING.md SECURITY.md CHANGELOG.md
├── go.mod go.sum
└── .github/{workflows,dependabot.yml}
```

### `opsnexus-backend`

```text
opsnexus-backend/
├── cmd/server/main.go
├── internal/{agent,alerting,auth,config,database,events,health,middleware,notifications,observability,retention,telemetry}/
├── migrations/             # or keep under internal/database, but one canonical location
├── integration/            # PostgreSQL/HTTP integration tests
├── README.md LICENSE CONTRIBUTING.md SECURITY.md CHANGELOG.md
├── go.mod go.sum
└── .github/{workflows,dependabot.yml}
```

### `opsnexus-common`

```text
opsnexus-common/
├── models/
├── compatibility/          # optional fixtures/version policy
├── README.md LICENSE CONTRIBUTING.md CHANGELOG.md
├── go.mod go.sum
└── .github/workflows/
```

### `opsnexus-api`

```text
opsnexus-api/
├── api/openapi.yaml
├── api/schemas/
├── examples/
├── generated/               # only if generated artifacts are intentionally published
├── docs/compatibility.md
├── README.md LICENSE CONTRIBUTING.md CHANGELOG.md
└── .github/workflows/       # lint, bundle, breaking-change check
```

### `opsnexus-dashboard`

```text
opsnexus-dashboard/
├── src/{api,components,pages,types,assets}/
├── public/
├── tests/{unit,e2e}/
├── package.json package-lock.json
├── README.md LICENSE CONTRIBUTING.md SECURITY.md CHANGELOG.md
└── .github/workflows/
```

### `opsnexus-deployment`

```text
opsnexus-deployment/
├── compose/{dev,production}/
├── backend/Dockerfile
├── dashboard/{Dockerfile,nginx.conf}
├── env/.env.example
├── scripts/{validate,backup,restore,smoke}/
├── docs/{operations,upgrades,rollback}
├── README.md LICENSE SECURITY.md CHANGELOG.md
└── .github/workflows/
```

### `opsnexus-docs`

```text
opsnexus-docs/
├── architecture/
├── api/
├── operations/
├── development/
├── security/
├── releases/
├── decisions/
├── README.md LICENSE CONTRIBUTING.md SECURITY.md CHANGELOG.md
└── .github/workflows/docs.yml
```

### `opsnexus-cli`

```text
opsnexus-cli/
├── cmd/opsnexus/main.go
├── internal/{client,commands,config,output}/
├── tests/
├── README.md LICENSE CONTRIBUTING.md SECURITY.md CHANGELOG.md
└── go.mod go.sum
```

### `awesome-opsnexus`

```text
awesome-opsnexus/
├── README.md
├── CONTRIBUTING.md LICENSE
├── .github/{ISSUE_TEMPLATE,pull_request_template.md,workflows/link-check.yml}
└── .lychee.toml              # or equivalent link checker configuration
```

## 11. GitHub Organization Cleanup

Give each repository a factual one-line description and focused topics. Correct `postgesql` to `postgresql`. Mark implementation repositories as core, API/docs/deployment as platform support, CLI as preview until usable, and awesome as community. Do not archive any repository solely because it is incomplete; archive or label it only after an explicit product decision.

Protect `main`: required pull request, at least one review, passing required checks, no force pushes, no deletion, and stale approval dismissal for relevant code. Use CODEOWNERS for API/backend/deployment/security-sensitive paths once maintainers are known. Add issue forms for bug, feature, security (the security form must not request public disclosure), and documentation; add a PR template with scope, tests, compatibility, migration and rollback sections.

Enable private vulnerability reporting, Dependabot/Renovate, secret scanning/push protection where available, signed release tags for production, and least-privilege GitHub Actions permissions. Publish Actions artifacts, container provenance/SBOM and release notes only from protected workflows.

## 12. README Strategy

- Organization README: product positioning, supported status, architecture diagram, quick demo, project maturity, repositories, roadmap and contribution/security links.
- Repository README: purpose, supported scope, prerequisites, exact quickstart, configuration table matching source, tests, build, compatibility, release status and links.
- Developer docs: local environment, dependency versions, migrations, test fixtures, code conventions, branch/PR workflow and debugging.
- Operator docs: production Compose, TLS, secrets, backups, restore, upgrades, rollback, retention, capacity and incident response.
- Architecture docs: component boundaries, data flow, failure modes, API compatibility and ADRs, with claims verified against source.
- API docs: generated from `opsnexus-api`, including auth, errors, examples, event schemas and compatibility policy.

## 13. CI/CD Strategy

All workflows should pin actions to reviewed major versions or SHAs, use least privilege, cache safely, and upload test/build evidence.

| Repository | Required pipeline |
|---|---|
| Go agent | `gofmt` check, `go vet`, lint, unit/race tests, coverage threshold, build for supported Linux targets, dependency scan, artifact smoke test |
| Go backend | same Go gates plus migration lint, PostgreSQL service integration tests, API/auth/SSE/alert/notification tests, race test, container build and health smoke test |
| common | format/vet/lint/tests, public API compatibility check, module build and tagged-module verification |
| API | YAML/OpenAPI lint, bundle/resolve refs, schema validation, breaking-change check against previous release, generated-doc drift check |
| dashboard | lockfile install, TypeScript build, ESLint, unit/component tests, browser smoke test, production build, dependency and bundle checks |
| deployment | Compose config validation, Dockerfile lint, build backend/dashboard images, non-root/healthcheck/security scan, smoke stack with PostgreSQL, secret/example checks |
| docs | Markdown/link/spell checks, diagram/reference checks, version/link consistency and optional docs-site build |
| CLI | format/vet/lint/unit tests, API contract fixtures, build/package binaries for supported platforms, help/command smoke test |

Add a scheduled cross-repository workflow that checks the pinned compatibility matrix. A release workflow should run only after all repository workflows and deployment smoke tests pass.

## 14. Release and Versioning Strategy

The evidence shows `v0.5.0` tags across eight repositories and `v0.6.0` additionally on deployment. The docs and most badges call v0.5.0 current; the dashboard package is `0.0.0`; README roadmaps call Docker and OTLP v0.6.0 even though Docker is already tagged in deployment. This is a release-governance problem, not a reason for code refactoring.

Use independently versioned components internally, with a synchronized platform release manifest. This fits the separate repositories and lets the API/common modules evolve under compatibility rules. A platform release such as `OpsNexus 0.6.0` should name exact component versions/commits, supported combinations, migration requirements, and deployment image digests. Do not imply that every repository tag is a complete platform release.

Recommended policy:

- SemVer for API/common and user-visible components; document pre-1.0 compatibility explicitly.
- API version path remains `/api/v1`; additive changes are preferred, breaking changes require a new contract/version and migration plan.
- Release tags are created by automation from protected branches; GitHub Releases contain generated notes and the compatibility matrix.
- Each component has a real changelog or generated release notes. Docs has a platform release index.
- First reconcile the existing `v0.6.0` deployment tag: either reclassify it as deployment preview in documentation or issue the platform release only after gates pass.

## 15. Development Phases

The proposed order is retained but tightened around reliability and governance.

### Phase 0 — Engineering Baseline

Repository truth, entrypoints, licenses, CI, contract ownership, security defaults, version policy, Compose validation, tests and documentation alignment.

### Phase 1 — Docker Monitoring

Container discovery/metrics in the agent or a clearly owned collector boundary, normalized models, backend persistence/querying, dashboard display and retention impact.

### Phase 2 — Production Agent

Stable installation/service packaging, secure enrollment, retries/backpressure, upgrade/rollback, resource budgets, Linux support matrix and agent health.

### Phase 3 — Deployment 1.0

Repeatable Compose production profile, TLS boundary, secrets, migrations, backups/restores, health/readiness, image provenance and upgrade/rollback.

### Phase 4 — Dashboard 1.0

Authenticated browser flow, contract-generated types, accessibility, loading/error/empty states, browser tests, responsive operator workflows and safe configuration UX.

### Phase 5 — Alerting 1.0

Explicit rule semantics, evaluation guarantees, deduplication, incident state machine, notification delivery policy, silence/escalation, audit trail and operational metrics.

### Phase 6 — Automation

Safe action model, approvals, idempotency, dry run, audit logs, least privilege, rate limits and rollback for any remediation.

### Phase 7 — OpenTelemetry

OTLP ingestion and normalized storage/correlation, resource attributes, trace/metric semantics, quotas, retention and interoperability tests.

### Phase 8 — Kubernetes

DaemonSet/operator boundary, cluster/RBAC model, upgrade strategy, cardinality controls, multi-tenant isolation and Kubernetes deployment validation.

### Phase 9 — Intelligent Operations

Anomaly/RCA assistance only after data quality, explanations, privacy, evaluation, human approval and failure-safe behavior are established.

## 16. Definition of Done

Every phase is done only when the relevant implementation is merged behind reviewed design, unit and integration tests pass, cross-repository contracts are validated, documentation and examples match behavior, security review is recorded, deployment/smoke validation passes, logs/metrics/health signals exist, release notes and compatibility are published, and rollback or disablement is tested where state or automation changes.

Phase-specific gates:

- **Phase 0:** all nine repos have status/ownership/license truth, required CI and policy files, documented entrypoints, clean version matrix, API lint/compatibility check, and a passing baseline release candidate.
- **Phase 1:** container metrics are collected on supported runtimes, fixtures cover missing/permission/error cases, end-to-end data reaches UI/alerts, cardinality and retention are documented, and disabling the collector is safe.
- **Phase 2:** signed or integrity-checked packages install on the support matrix, enrollment is secure, retry/offline behavior is bounded, upgrade and rollback are exercised, and agent resource budgets are measured.
- **Phase 3:** a fresh host can deploy from documented commands, secrets/TLS/auth are production-safe, migrations and backups are tested, health checks detect dependency failure, images are scanned, and rollback is rehearsed.
- **Phase 4:** authenticated workflows work against the versioned API, accessibility and browser smoke tests pass, generated types are current, error states are usable, and no token is exposed in unsafe browser storage/logs.
- **Phase 5:** rule/incident transitions are deterministic under retries, notification delivery is observable and idempotent enough for the stated guarantee, silencing/escalation is tested, and alert loss/duplication behavior is documented.
- **Phase 6:** every action has authorization, approval/dry-run/idempotency/audit controls, bounded execution and tested rollback; disabled automation cannot execute.
- **Phase 7:** OTLP conformance fixtures, limits, auth, resource mapping, storage/retention and dashboard/API compatibility pass; unsupported signals fail clearly.
- **Phase 8:** supported Kubernetes versions, RBAC, upgrades, uninstall, failure recovery, cardinality and namespace/tenant boundaries are tested in a disposable cluster.
- **Phase 9:** model evaluation, data/privacy controls, explanations, human override, rate limits, monitoring and safe fallback are proven before production enablement.

## 17. Engineering Workflow

```text
Issue -> Plan -> Branch -> Implement -> Test -> Review -> Commit -> PR
      -> CI -> Review -> Merge -> Release -> Observe -> Retrospective
```

Every issue identifies affected repositories, contract/version impact, security and rollback. Branch from protected `main`; keep commits scoped and conventional. A PR includes evidence, migrations, docs, compatibility, screenshots where relevant, and operational impact. Required CI and review gates run before merge. Releases are coordinated by a compatibility manifest, then monitored with a rollback decision and post-release record.

## 18. NeoCode Comparison

No NeoCode repository or local checkout was present in the supplied workspace, and no network comparison was requested or used. Therefore this section is a comparison framework, not a claim about NeoCode's actual implementation. A precise comparison must be performed when a canonical NeoCode URL or checkout is supplied.

OpsNexus should adopt from a mature reference project only verifiable practices: clear repository ownership, contributor onboarding, automated CI, quality gates, reproducible builds, release notes, issue/PR templates, generated API documentation, security reporting, screenshots/demo paths and a compatibility matrix. It should not copy another project's runtime topology, language choices, repository count, data model, deployment assumptions, or architecture without a demonstrated OpsNexus requirement. The appropriate target is NeoCode-like project hygiene where useful, while preserving OpsNexus's agent/common/API/backend/dashboard boundaries.

## 19. Priority Matrix

Complexity: S (days), M (about 1–2 weeks), L (multi-week), XL (cross-repository/program).

| Priority | Repository | Change | Reason | Dependency | Complexity |
|---|---|---|---|---|---|
| P0 | all | Add CI, protected-main policy, secret scanning and dependency scanning | Current changes can merge without automated evidence | ownership and workflow baseline | L |
| P0 | backend | Restore/document real source entrypoint; remove/justify tracked binary | Source build is not reproducible | locate canonical server main | M |
| P0 | deployment/backend | Make auth, CORS, TLS and secrets production-safe | Current defaults permit unsafe exposure | deployment profile design | M |
| P0 | deployment | Determine `.env`/generated artifact provenance and prevent secret leakage | Clean status does not prove safe distribution | repository history review | S |
| P0 | API/backend/dashboard | Establish contract validation and compatibility matrix | Prevent silent seam breakage | API ownership decision | L |
| P1 | all | Add LICENSE/policy/contributor/security/changelog baseline | Open-source readiness and disclosure path | organization governance | M |
| P1 | all | Reconcile v0.5/v0.6/package versions and release policy | Current public state is contradictory | platform release decision | M |
| P1 | backend/deployment | PostgreSQL integration, migration, backup/restore and Compose smoke tests | Core persistence/deployment risk is untested | CI runner services | L |
| P1 | dashboard | Add unit/browser tests and authenticated API-token strategy | UI is untested and auth compatibility is unclear | contract/auth decision | L |
| P1 | agent | Align environment variable names and add transport auth/retry policy | README and source disagree; production transport needs hardening | API enrollment design | M |
| P1 | backend | Add security tests for CORS, SSRF/egress, auth-on, token lifecycle and rate limits | Monitoring/notification systems handle sensitive control paths | threat model | L |
| P2 | common/API | Versioned fixtures and generated client/type workflow | Reduce duplicated models and drift | contract pipeline | M |
| P2 | docs | Split operator/developer/API/release docs and link checker | Improve truthful onboarding and operations | version matrix | M |
| P2 | deployment | Image pinning, non-root, healthchecks, SBOM and vulnerability gates | Supply-chain and runtime quality | CI | M |
| P2 | CLI | Define scope and implement first read-only authenticated commands | Current repository is only a placeholder | stable API/auth | L |
| P2 | backend | Instrument queue drops, DB failures, request latency and retention outcomes | Operability of existing features | metrics conventions | M |
| P3 | dashboard | Remove unused template assets and improve UX polish | Cleanup after usage proof | source usage check | S |
| P3 | awesome | Add link checking and clarify CC0/contribution governance | Community repository hygiene | license decision | S |
| P3 | platform | Evaluate OTel, Kubernetes, automation and intelligent operations | Avoid premature scope expansion | all prior reliability gates | XL |

## 20. Exact Execution Order

1. Freeze feature scope on the audit branch and preserve the current evidence.
2. Create an owner/compatibility inventory for all nine repositories; verify repository history for env/generated artifacts.
3. Establish organization governance: licenses, security reporting, contribution/PR/issue templates, CODEOWNERS and protected `main`.
4. Restore and document the backend source entrypoint; correct quickstarts and obvious links.
5. Decide component versus platform versioning, reconcile the deployment `v0.6.0` tag, and publish a compatibility matrix.
6. Make `opsnexus-api` the enforceable contract source: lint, bundle, examples, breaking-change check and fixtures.
7. Align `opsnexus-common`, backend, agent and dashboard payload/auth/event semantics against that contract.
8. Add per-repository CI gates, then cross-repository compatibility and deployment smoke workflows.
9. Harden runtime defaults: auth-on production profile, explicit CORS, TLS/secret guidance, safe webhook egress, token handling and rate limits.
10. Add PostgreSQL integration/migration/backup-restore tests and Compose health/readiness/rollback validation.
11. Add dashboard tests and a safe authenticated browser/API strategy; validate SSE reconnection and event schemas.
12. Add image supply-chain gates and operational telemetry/runbooks.
13. Implement the CLI only against the stable contract, starting with read-only commands.
14. Release a truthful platform `0.6.0` from protected branches with notes, digests, migrations, compatibility and rollback.
15. Only after the baseline is reliable, implement Docker monitoring, then production agent/deployment/dashboard/alerting improvements.
16. Treat automation, OTel, Kubernetes and intelligent operations as gated later phases, not parallel speculative refactors.

## 21. Final Engineering Assessment

**Is OpsNexus currently architecturally sound?** Mostly yes at prototype scale. The core flow and boundaries are coherent, but contract enforcement, deployment reproducibility, authentication defaults and operational guarantees are not mature enough for a production claim.

**Is the multi-repository model correct?** Yes, conditionally. It matches independent component lifecycles and the existing domain boundaries. It becomes a liability without cross-repository CI, compatibility policy, owners and coordinated releases.

**Biggest engineering weakness:** absence of automated organization-level quality and compatibility gates, compounded by documentation/version drift.

**Biggest product strength:** a demonstrable end-to-end operator experience from real host metrics through alerting, incident workflow, notification and real-time dashboard updates.

**What should we NOT touch?** Do not rewrite the core backend package decomposition, replace Go/React/PostgreSQL, collapse repositories for aesthetics, or add OTel/Kubernetes/AI before the baseline gates. Preserve the existing vertical slice while hardening it.

**What must be fixed before v0.6?** Reproducible backend entrypoint/build, truthful version/release policy, contract validation, CI, licenses/security/contribution paths, production-safe auth/CORS/secrets, deployment smoke/migration checks, dashboard tests/auth strategy, and agent configuration alignment.

**What should be built after v0.6?** Production agent packaging and Docker monitoring first, followed by deployment/dashboard/alerting reliability. Then OTel and Kubernetes based on measured demand; automation and intelligent operations last.

**What would make OpsNexus look serious?** A fresh-clone quickstart that works, protected branches, green CI across all repositories, contract-driven compatibility, reproducible images and releases, visible security/contribution policy, tested upgrades/backups/rollback, honest maturity labels, and an operator-grade demo backed by real evidence.

## Appendix A — Repository Audit Record

All nine repositories were inspected locally. At audit time, all were clean. `opsnexus-agent`, `opsnexus-backend`, `opsnexus-dashboard`, `opsnexus-common`, `opsnexus-api`, `opsnexus-deployment`, `opsnexus-cli`, and `awesome-opsnexus` were on `main`; `opsnexus-docs` was on `audit/engineering-baseline-2026-08`. All remotes matched their expected `OpsNexusHQ` repositories.

| Repository | Latest observed commit | Tags | Tests | CI | Key finding |
|---|---|---|---:|---|---|
| agent | `0dc93c9` docs update | `v0.5.0` | 6 Go test files | none | strongest collector/transport test base; env docs drift |
| backend | `70055fc` docs update | `v0.5.0` | 12 Go test files | none | substantial implementation; source entrypoint/build documentation problem |
| dashboard | `c233dc0` telemetry fix | `v0.5.0` | none found | none | good UI breadth; no tests; package version `0.0.0` |
| common | `fd673e6` docs update | `v0.5.0` | none found | none | small and coherent; public model compatibility ungoverned |
| API | `712c158` docs update | `v0.5.0` | none found | none | useful OpenAPI base; not enforced against consumers |
| deployment | `d2f0727` Docker stack | `v0.5.0`, `v0.6.0` | none found | none | useful Compose topology; version/default/security drift |
| docs | `47184e6` release kit | `v0.5.0` | n/a | none | architecture/security foundation; claims need continuous verification |
| CLI | `fafae86` docs update | `v0.5.0` | none found | none | placeholder only |
| awesome | `2522f6b` docs update | `v0.5.0` | n/a | none | useful index; governance/link/license inconsistency |

## Appendix B — Top 10 Findings

1. No GitHub Actions workflows were found in any of the nine repositories.
2. The backend source entrypoint is not present as documented; a tracked ELF binary is present instead.
3. The API contract is not enforced against backend/dashboard/agent consumers.
4. Public version state is inconsistent: platform v0.5.0 claims coexist with deployment v0.6.0 and dashboard `0.0.0`.
5. Authentication is disabled by default and CORS is wildcard by default; production profile enforcement is missing.
6. Deployment has configuration/artifact provenance concerns and no automated migration/backup/restore/smoke validation.
7. Agent environment variable names in README and source do not match.
8. Dashboard has meaningful functionality but no repository tests and no visible browser/auth compatibility gate.
9. Contribution, security, license-file, changelog and release-governance evidence is incomplete or inconsistent.
10. The architecture is a sound prototype vertical slice and should be hardened rather than rewritten or collapsed into a monorepo.

## Appendix C — Audit Completion Report

- Repositories audited: **9**
- Repositories not fully inspectable: **none of the nine local checkouts**. NeoCode was not available locally, so its comparison is explicitly limited to a framework and requires a canonical reference for factual comparison.
- Assumptions: the local checkouts and current Git refs represent the intended audit state; no external GitHub settings, releases, issues, branch protections, CI history, or runtime environments were inspected; no dependencies were installed or tests/builds executed; a clean worktree does not establish that local/generated artifacts are absent from Git history or package distribution.
- Exact files changed: `opsnexus-docs/ENGINEERING_AUDIT.md` only.
- Final Git status: current branch `audit/engineering-baseline-2026-08`; working tree has one added file, `ENGINEERING_AUDIT.md`; no existing file was modified, deleted, or renamed.

