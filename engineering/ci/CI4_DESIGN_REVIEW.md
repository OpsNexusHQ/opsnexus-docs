# CI-4 Cross-Repository Compatibility Design Review

## 1. Executive Summary

The CI-4 documents preserve the locked multi-repository architecture and make
several important governance decisions correctly: `opsnexus-docs` owns the
platform manifest, `opsnexus-api/api/openapi.yaml` remains authoritative, the
CLI remains informational, and the missing versioned API routes are classified
as public API debt rather than silently inferred or rewritten.

The design is not yet sufficiently executable for implementation. The manifest
schema is directionally approved but still contains placeholders and does not
define the concrete platform release record to create. More importantly, the
workflow architecture does not specify exact PR input selection, exact
consumer assertions, required/skip behavior, or how manifest-selected refs are
passed into the existing CI-3 workflow without duplicating or diverging from
it. These are implementation-level architectural decisions, not polish.

## 2. Architecture Verification

The current `main` repositories remain independently versioned:

- `opsnexus-common`: `b571c0a7ae028906d08cf108e357350dda9384d7`
- `opsnexus-agent`: `d01e925cbfe778e0c911ea7f18cce030011ef44f`
- `opsnexus-backend`: `8b1e3340fee81f52a88bde293dd0a05fbc132668`
- `opsnexus-api`: `5c25b39547d30a57f07640a79115ca5f43b9544f`
- `opsnexus-dashboard`: `fe5f4d309b09ed39fceac73ccdfbddfb1c562d97`
- `opsnexus-cli`: `d0a2e6d3fed05bcef66361112883b57fd7391d64`
- `opsnexus-deployment`: `339a9dee79c9f6b9a783525db5c2e6d7d34811eb`
- `opsnexus-docs`: `f692608bfe837f19625cc4f7208aee70c1fdfc43`

`awesome-opsnexus` has no runtime or build dependency relationship. The design
does not propose a monorepo or a shared component version. This part is sound.

## 3. Manifest Review

### Correct decisions

- Owner: `opsnexus-docs` is appropriate because it owns `COMPATIBILITY.md`,
  release policy, release records, and engineering governance.
- Location: `engineering/releases/platform-compatibility.yaml` is appropriate.
- The manifest is governance truth and does not control Go module resolution.
- Exact commit SHAs, optional tags, status, contract version, migration, and
  image metadata are represented conceptually.
- Tag/SHA agreement and existence checks are correctly required.
- Preview CLI and deferred image digests have an appropriate representation.

### Finding

The example still uses `v0.x.y`, `<reference>`, and `<immutable-40-hex-sha>`
placeholders. The audit lists current component SHAs, but the design does not
define the actual initial platform release identifier, compatibility status,
release reference, migration requirements, or exact null/deferred convention
that implementation must write. It also does not say whether the first file is
a supported release manifest or a baseline compatibility record.

This leaves a material schema/value decision during implementation.

## 4. Manifest Lifecycle

The owner, update triggers, component-owner proposal flow, review, tag/SHA
agreement, and manifest-change trigger are described. Independent component
versions and untagged/preview components are also addressed conceptually.

The lifecycle is incomplete for PR behavior: it does not specify whether a
component PR validates its proposed head SHA, the current manifest SHA, or a
manifest overlay combining both. It also does not define the required behavior
when a proposed component commit has no tag, when a tag is intentionally null,
or when an image is deferred. These choices affect whether CI can validate a
PR before merge.

## 5. Go Compatibility Review

The design correctly preserves:

- agent/backend consumption of released `opsnexus-common v0.5.0`;
- declared repository toolchains;
- module graph and checksum verification;
- build/test compatibility checks;
- rejection of sibling filesystem replacements;
- no `go.work` dependency.

The checks are somewhat broader than needed and overlap CI-1. The design does
not separate the minimum CI-4 compatibility assertion from existing repository
format/vet/test/build jobs. It should explicitly state which CI-1 results are
reused and which cross-repository assertion is new, so CI-4 does not create
duplicate expensive jobs.

## 6. API Contract Review

The transitional governance boundary is correct in principle:

- OpenAPI remains authoritative.
- CI-2 continues lint, bundle, and breaking-change validation.
- Missing A-class routes are not inferred from TypeScript or backend routes.
- Complete consumer compatibility is deferred until the routes are represented.

However, the documents contradict themselves. The design executive summary and
Section 5 still say route classification is a prerequisite, although the audit
and later design sections state it is resolved. The stale wording must be
removed before implementation.

The current scope is also not executable: “one read-only overview/agent
surface” and “SSE content type” do not identify the exact endpoint, request,
expected HTTP status, JSON fields, authentication profile, timeout, or fixture
data. CI-4 cannot safely choose these during coding.

## 7. Dashboard/Backend Review

The design correctly distinguishes CI-3 static/service availability from CI-4
runtime cross-repository compatibility and does not require browser automation.
It correctly observes the compiled API base URL and nginx behavior.

The proposed dashboard/backend checks need exact assertions. The design must
select a contract-covered read-only endpoint, define the expected response
shape, state how the disposable backend/database is populated, and define an
SSE assertion or explicitly defer SSE. Without this, the check could become a
weak status-code probe or accidentally depend on the incomplete routes.

## 8. CLI Review

The CLI treatment is correct. Its current executable is a placeholder, it has
no API/common module dependency, and it should remain informational in the
manifest and non-blocking as an API consumer. No CLI implementation is needed.

## 9. Deployment Review

Reusing the CI-3 deployment mechanism is the correct direction. The design
lists the CI-3 deployment/common/backend/dashboard SHAs and says the manifest
should select them.

The implementation boundary is not precise enough: the current CI-3 workflow
hardcodes its component SHAs, while the CI-4 design says deployment consumes
manifest refs. It does not define whether CI-4 invokes CI-3 as a reusable
workflow, extracts a shared validation script, or creates a second workflow.
It also omits how the manifest-selected `opsnexus-api` ref participates, even
though API is part of the platform set but not a Docker Compose build input.
Choosing among these approaches would be a major implementation decision.

## 10. Impact Matrix Review

The repository matrix covers all repositories and correctly treats the CLI as
informational. It also correctly makes manifest changes significant.

It is not yet sufficient for path-aware implementation. For each changed
repository, the design must state whether the workflow tests the PR head, the
manifest baseline, or both. In particular:

- common changes need exact consumer refs and a proposed common ref;
- backend changes need exact API/common/dashboard/deployment refs;
- API changes need exact backend/dashboard consumer refs;
- deployment changes need the manifest-selected workspace;
- docs/manifest changes must validate every referenced ref.

“Selected set” and “path-aware triggers” do not define those inputs or required
check outcomes.

## 11. Compatibility Selection Review

The design rejects historical all-by-all matrices, which is correct. It does
not yet define a deterministic selection algorithm for PRs. There is no
explicit rule such as “start from the manifest, replace the changed component
with the PR head SHA, and retain all other manifest SHAs.” Without that rule,
different implementers could validate different platform sets while all
claiming to use the manifest.

This is a HIGH finding because it can produce false compatibility results.

## 12. Security Review

The security requirements are appropriate: immutable action and repository
refs, read-only permissions, no production secrets, no developer `.env`, and
temporary workspaces. No unsafe security design was found.

The workflow design should still state that checkout of a PR head is read-only,
that untrusted PR content is not given secrets, and that reports identify SHAs
without printing credentials. These are implementation details, not current
blockers.

## 13. Workflow Architecture Review

The four proposed names are sensible:

- `ci/compatibility-modules`
- `ci/compatibility-contract`
- `ci/compatibility-deployment`
- `ci/compatibility-manifest`

The design does not yet define for each check:

- exact trigger and path filters;
- exact manifest/PR inputs;
- whether the check is required, skipped, or not applicable;
- exact command and expected output;
- failure diagnostics;
- whether it reuses CI-1/CI-2/CI-3 workflows or duplicates them;
- how a skipped check remains safe for branch protection.

The current design therefore cannot be implemented without architectural
decisions about workflow composition and required-check semantics.

## 14. Failure Model Review

Blocking and informational categories are mostly correct. The design should
require a failure report containing repository, component, selected SHA/tag,
expected version, actual version, contract/migration involved, and the exact
failed assertion. This is not yet specified in the workflow layer.

## 15. Documentation Consistency

The two documents agree on the manifest owner, location, route classifications,
and staged API scope in their later sections. They do not fully agree with the
design's own opening sections, which still describe manifest/schema and route
classification as unresolved prerequisites. This is a MEDIUM documentation
consistency issue that should be corrected before implementation.

## 16. Definition of Done

The Definition of Done includes the right broad outcomes: manifest, immutable
refs, module and selected API compatibility, deployment reuse, security,
documentation, remote CI, review, and merge. It appropriately excludes browser
automation, historical matrices, Kubernetes, release automation, and SBOM/
provenance.

It should additionally require the exact PR selection algorithm, exact
consumer assertions, required/skip behavior, and proof that CI-4 deployment
uses the same selected refs as CI-3.

## 17. Findings Table

| Severity | Finding | Impact |
|---|---|---|
| HIGH | Deterministic PR compatibility selection is unspecified: the design does not say how a PR head is combined with manifest refs. | CI may validate the wrong component set and report false compatibility. |
| HIGH | Workflow inputs, applicability, required/skip semantics, and exact commands are unspecified for all four checks. | Implementation requires major workflow architecture decisions and may create unsafe branch-protection behavior. |
| HIGH | CI-4 deployment reuse versus duplication is unresolved, and API's manifest ref participation is unspecified. | CI-4 could diverge from the proven CI-3 deployment validation. |
| HIGH | Dashboard/backend consumer assertions are not concrete enough to implement: endpoint, response shape, fixtures, auth, and SSE behavior are unspecified. | The compatibility gate could be weak, flaky, or test the wrong contract. |
| MEDIUM | Manifest example and initial platform record retain placeholders and do not define the initial release/baseline semantics. | The first machine-readable manifest cannot be created deterministically. |
| MEDIUM | Design opening sections contain stale “prerequisite unresolved” language after the decisions were approved. | Reviewers may interpret the implementation boundary inconsistently. |
| MEDIUM | Go compatibility scope may duplicate CI-1 without identifying the new cross-repository assertion. | Unnecessary CI cost and unstable ownership of failures. |
| LOW | Failure diagnostics and report fields are described only at a high level. | Compatibility failures may be harder to triage. |
| INFORMATIONAL | Independent versions, placeholder CLI, and floating image tags are correctly retained as intentional/deferred states. | No corrective action required for CI-4 design. |

## 18. Required Changes

Before implementation:

1. Define the exact manifest initial record semantics and values, including
   platform version/release identifier, migration requirements, release-note
   reference, and explicit null/deferred image representation.
2. Define the deterministic PR selection algorithm, preferably manifest refs
   with the changed repository replaced by the immutable PR head SHA; define
   how multi-repository changes and manifest changes are handled.
3. Define each stable check's trigger, exact inputs, commands/assertions,
   applicability, required/skip behavior, and diagnostics.
4. Choose the composable mechanism by which CI-4 invokes or shares CI-3
   deployment validation, and specify how API's exact manifest ref is checked.
5. Specify the exact contract-covered endpoint, JSON assertions, test data,
   auth mode, and SSE decision for dashboard/backend compatibility.
6. Remove stale prerequisite language and align the executive summary,
   transitional API scope, and Definition of Done.

## 19. Resolution of Original Findings

The design-resolution task addressed the review findings as follows:

| Original finding | Resolution status |
|---|---|
| PR compatibility-set selection unspecified | Resolved: base manifest plus immutable PR head for changed components only; manifest PRs use the complete manifest set. |
| Workflow inputs/applicability/skip semantics unspecified | Resolved: four-check table defines inputs, affected paths, success, blocking, and not-applicable behavior. |
| CI-3 reuse versus duplication unresolved | Resolved: `workflow_call` with four explicit revision inputs; CI-3 remains the sole deployment validator. |
| Dashboard/backend assertions insufficiently concrete | Resolved: exact contract-covered registration, telemetry, health, metrics, overview, alerts, and SSE assertions with fixtures/timeouts. |
| Manifest release semantics contained placeholders | Resolved: platform/component/version/tag/SHA/status/contract/migration/image semantics are explicit. |
| Stale prerequisite language | Resolved in the design executive summary, API section, and implementation boundary. |
| CI-1 versus CI-4 overlap unclear | Resolved: CI-1 owns local quality; CI-4 owns cross-repository identity and relationship checks. |

## 20. Remaining design caveat

The A-class routes remain public API debt and are intentionally outside the
initial contract gate until represented in OpenAPI. This is an explicit staged
scope, not an unresolved route classification. The initial gate is therefore
not allowed to claim complete public API compatibility.

## 21. Final Decision

READY FOR CI-4 IMPLEMENTATION

The resolved documents now define deterministic compatibility selection,
workflow inputs and applicability, reusable CI-3 deployment composition, exact
contract-covered assertions, manifest semantics, and the CI-1/CI-4 boundary.

Implementation may proceed without making those architectural decisions during
coding. The eventual CI-4 implementation must preserve the staged API scope
and must not claim complete public consumer compatibility until the A-class
routes are represented in OpenAPI.

## 22. Scope Confirmation

This review created only this review artifact. It did not create the machine-
readable manifest, modify OpenAPI, change backend/dashboard/CLI code, add
workflows, modify Docker files, commit, push, create PRs, or merge anything.
