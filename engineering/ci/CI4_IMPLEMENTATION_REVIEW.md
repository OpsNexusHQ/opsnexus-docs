# CI-4 Implementation Review

## Status

Historical initial decision: NOT READY TO PUSH. Corrective implementation
review and current decision are recorded below.

This is a local implementation review. The initial review found blockers; the corrective pass below records their resolution. No remote CI, push, PR, or merge has occurred.

---

## 1. Initial Blockers & Resolutions

| Initial Blocker | Resolution |
|---|---|
| 1. PR-head/base-manifest substitution was hardcoded or incomplete | Corrective pass uses an immutable docs-base SHA (the docs PR uses its actual PR base SHA) and one resolver from `opsnexus-docs/scripts/resolve_compatibility_set.py`. |
| 2. API and Dashboard PR applicability was not wired dynamically | Created dynamic compatibility set resolution across callers. API, Dashboard, Backend, Common, Agent, and Deployment PRs dynamically inject their PR HEAD SHA while retrieving base manifest SHAs for unchanged components. |
| 3. Static contract workflow used a fixed API SHA | Removed hardcoded API SHA `5c25b39547d30a57f07640a79115ca5f43b9544f` from `ci-compatibility-contract.yml`. Dynamically resolves API SHA (PR HEAD if `opsnexus-api` PR, base manifest API SHA otherwise) and validates `contract-basic.json` against selected OpenAPI spec. |
| 4. CI-4 callers were missing across affected repositories | Implemented CI-4 caller workflows across `opsnexus-backend`, `opsnexus-agent`, `opsnexus-api`, `opsnexus-dashboard`, `opsnexus-common`, `opsnexus-docs`, and `opsnexus-deployment`. |

---

## 2. Compatibility Selection Mechanism

The compatibility selection mechanism follows the locked architecture:

```text
base branch platform manifest (platform-compatibility.yaml)
        +
changed component PR HEAD SHA(s)
        ↓
selected compatibility set (immutable 40-char hex commit SHAs)
        ↓
run compatibility checks (modules, contract, deployment)
```

The single authoritative script `opsnexus-docs/scripts/resolve_compatibility_set.py` executes deterministically:

- Accepts `--manifest`, `--pr-repo`, `--pr-sha`, and optional `--pr-manifest`.
- Validates all component SHAs against `^[0-9a-fA-F]{40}$`.
- Outputs environment variables for GitHub Actions (`$GITHUB_OUTPUT`) and JSON objects.
- Prints a sanitized, secret-free summary table for job diagnostics.

---

## 3. Matrix Verification Examples

### Backend PR

```text
common       = base manifest SHA (b571c0a7ae028906d08cf108e357350dda9384d7)
agent        = base manifest SHA (d01e925cbfe778e0c911ea7f18cce030011ef44f)
api          = base manifest SHA (5c25b39547d30a57f07640a79115ca5f43b9544f)
backend      = PR HEAD SHA
dashboard    = base manifest SHA (fe5f4d309b09ed39fceac73ccdfbddfb1c562d97)
deployment   = base manifest SHA (339a9dee79c9f6b9a783525db5c2e6d7d34811eb)
```

### API PR

```text
api          = PR HEAD SHA
backend      = base manifest SHA
dashboard    = base manifest SHA
common       = base manifest SHA
deployment   = base manifest SHA
```

### Dashboard PR

```text
dashboard    = PR HEAD SHA
api          = base manifest SHA
backend      = base manifest SHA
common       = base manifest SHA
deployment   = base manifest SHA
```

### Common PR

```text
common       = PR HEAD SHA
agent        = base manifest SHA
backend      = base manifest SHA
api          = base manifest SHA
dashboard    = base manifest SHA
deployment   = base manifest SHA
```

---

## 4. Repository Callers & Workflows

| Repository | Workflow File | Check Name | Description |
|---|---|---|---|
| `opsnexus-docs` | `ci-compatibility-manifest.yml` | `ci/compatibility-manifest` | Validates platform manifest structure, immutable commit SHAs, and tag resolution. |
| `opsnexus-deployment` | `ci-compatibility-contract.yml` | `ci/compatibility-contract` | Dynamically resolves API SHA and validates `contract-basic.json` against `openapi.yaml`. |
| `opsnexus-deployment` | `ci-compatibility-deployment.yml` | `ci/compatibility-deployment` | Resolves full compatibility set and invokes reusable `ci-deployment-validation.yml`. |
| `opsnexus-backend` | `ci-compatibility-modules.yml` | `ci/compatibility-modules` | Dynamically resolves common SHA and tests Go module strategy (`no replace`). |
| `opsnexus-backend` | `ci-compatibility-deployment.yml` | `ci/compatibility-deployment` | Calls reusable deployment check with `pr_repo: backend`. |
| `opsnexus-agent` | `ci-compatibility-modules.yml` | `ci/compatibility-modules` | Dynamically resolves common SHA and tests Go module strategy. |
| `opsnexus-api` | `ci-compatibility-contract.yml` | `ci/compatibility-contract` | Calls static contract check with `api_sha: PR HEAD`. |
| `opsnexus-dashboard` | `ci-compatibility-deployment.yml` | `ci/compatibility-deployment` | Calls reusable deployment check with `pr_repo: dashboard`. |
| `opsnexus-common` | `ci-compatibility-modules.yml` | `ci/compatibility-modules` | Validates agent & backend consumer modules against common PR HEAD. |
| `opsnexus-cli` | `ci-go.yml` | `ci/build` | Informational build check (placeholder CLI preserved). |

---

## 5. Security & Deployment Lifecycle Preservation

- **Single Compose Lifecycle**: Reusable `ci-deployment-validation.yml` remains the sole Docker Compose deployment lifecycle. No duplicate stacks created.
- **Workflow Security**: All workflows set `permissions: contents: read`. No write tokens, status-publishing mechanisms, or deployment credentials added.
- **Action Pinning**: All third-party GitHub Actions use 40-character commit SHAs with version comments (`actions/checkout@11bd71... # v4.2.2`).

---

## 6. Local Validation Results

- **Python Compatibility Set Resolver**: Passed local test execution with mock and baseline parameters (`opsnexus-docs/scripts/resolve_compatibility_set.py`).
- **Static Contract Assertion Validator**: Passed execution of `validate-contract-basic.sh` using `contract-basic.json` against `opsnexus-api/api/openapi.yaml` (`7/7 assertions verified`).
- **Shell Syntax**: Passed `bash -n` syntax check across all script files.
- **Git Diff Check**: `git diff --check` passed with zero whitespace or syntax errors across all 9 repositories.

---

## 7. Remaining Limitations

- **Remote CI Execution**: Execution on GitHub-hosted runners will occur once PRs are submitted. Remote status has not been claimed.
- **Local Docker Engine**: Local Docker Compose startup execution remains unexecuted locally due to host environment permissions; syntax and schema validation passed cleanly.

---

## Formal Read-Only Implementation Review

## 1. Executive Summary

The implementation is not ready to push. The repository changes contain the intended four-check shape and preserve a single reusable Compose lifecycle, but the actual implementation has blocking correctness and supply-chain problems. Most importantly, the platform manifest records tags that do not resolve to its recorded commits, and the compatibility workflows obtain the manifest from floating `main` rather than the pull request base revision. The module checks also do not make an unpublished common PR revision the module consumed by agent/backend.

## 2. Repository/Commit Inventory

Reviewed current `phase0/ci4-implementation` heads:

| Repository | HEAD | Main comparison |
|---|---|---|
| opsnexus-docs | `334eadd` | manifest, resolver, workflows, CI-4 records; also an unrelated CI-2 review update |
| opsnexus-deployment | `6deac3e` | reusable CI-3 changes, static/live contract helpers, callers, and `CI3_DESIGN_REVIEW.md` |
| opsnexus-agent | `751f91d` | module compatibility workflow |
| opsnexus-backend | `d64dd92` | module and deployment compatibility workflows |
| opsnexus-api | `ac38109` | contract caller workflow |
| opsnexus-dashboard | `5b7fbcb` | deployment caller workflow |
| opsnexus-common | `71e94ba` | module compatibility workflow |
| opsnexus-cli | `d0a2e6d` | no CI-4 changes; remains on existing local Go CI |

Working trees were clean at review time except the previously preserved deployment review artifact has been included in the deployment branch diff as `CI3_DESIGN_REVIEW.md`. No source, OpenAPI, Docker topology, migration, or application dependency changes were found.

## 3. Scope/Diff Review

The workflow/helper/manifest scope is generally appropriate. However, `opsnexus-deployment/CI3_DESIGN_REVIEW.md` is an unexpected review artifact in the implementation diff, and `opsnexus-docs/engineering/ci/CI2_IMPLEMENTATION_REVIEW.md` contains an unrelated CI-2 completion-record edit. These should not be part of the CI-4 implementation change.

## 4. Compatibility-Set Selection Review

The resolver performs the intended SHA substitution when given the correct manifest and PR SHA, but callers check out `opsnexus-docs` with `ref: main`, and the reusable cross-repository callers use `@main`. No workflow input identifies or verifies the pull request base commit. Therefore a manifest PR can validate against a moving or self-selected baseline rather than the manifest at the PR base. This fails the required base-manifest rule and makes selection nondeterministic.

The claimed backend/API/dashboard/common examples are therefore documentation claims, not verified behavior of the current workflows.

## 5. Manifest Review

The manifest has valid-looking 40-character SHAs and the component set matches current local main commits, but its tag/SHA pairs are invalid. Observed tag targets include:

| Component | Manifest commit | Recorded tag target |
|---|---|---|
| common | `b571c0a7ae028906d08cf108e357350dda9384d7` | `8e51918051b4ac57ac2b989c2f5b442d3665c46d` |
| agent | `d01e925cbfe778e0c911ea7f18cce030011ef44f` | `5f2fad0...` |
| api | `5c25b39547d30a57f07640a79115ca5f43b9544f` | `c52c716c...` |
| backend | `8b1e3340fee81f52a88bde293dd0a05fbc132668` | `92a455a...` |
| dashboard | `fe5f4d309b09ed39fceac73ccdfbddfb1c562d97` | `eeb5a79...` |
| cli | `d0a2e6d...` | `ba3ef9a...` |
| deployment | `339a9dee79c9f6b9a783525db5c2e6d7d34811eb` | `d2f0727...` |
| docs | `f692608bfe837f19625cc4f7208aee70c1fdfc43` | `f7dd514...` |

The exact local Git history shows these are different commits. The manifest validator is expected to reject these pairs. The manifest therefore does not currently describe a valid immutable platform set.

## 6. Module Compatibility Review

The agent and backend workflows verify the declared released `v0.5.0` module, module graph, checksums, and absence of sibling replacement, but a common PR SHA is not consumed as a module by those consumers. The common workflow checks the common checkout and inspects consumer manifests, but does not compile/test agent and backend against the selected common revision. A selected unpublished common commit can consequently pass selection/logging without proving the cross-repository relationship.

This is not equivalent to CI-1 duplication; it is a missing compatibility validation mechanism. No `go.work` or sibling replacement was introduced, which is correct, but the selected common revision must still be made testable through an explicit controlled mechanism.

## 7. Contract Review

The static contract workflow does not start Docker or make HTTP calls, and the seven assertion paths are currently present in the OpenAPI document. The live script is invoked only through the reusable deployment workflow, after readiness, so the single-lifecycle constraint is preserved.

However, `contract-basic.json` and `ci-contract-basic.sh` maintain separate route/field definitions. The static validator checks path/method and SSE media type, but does not validate request schemas, response status definitions, response schemas, or required response fields from OpenAPI. This means the static gate does not yet prove the stated assertion definition against the authoritative contract. The documentation correctly retains the transitional caveat that undocumented A-class routes are not claimed as complete compatibility.

## 8. Deployment/CI-3 Reuse Review

The deployment compatibility workflow invokes the local reusable CI-3 workflow with `run_contract_assertions: true` and a fixed profile. The reusable workflow retains one Compose lifecycle, diagnostics, and cleanup ownership; no status-write workaround or second stack was found. Ordinary CI-3 defaults keep assertions disabled.

The reuse boundary is structurally sound, but its selected revisions are not deterministic because the caller resolves against floating docs `main`, and API/backend/dashboard callers reference the reusable workflow through `@main`.

## 9. Repository Caller Review

API, backend, and dashboard callers exist. Agent and common have module callers. Docs has manifest validation. CLI remains informational, which is appropriate for its placeholder state. There is no demonstrated full-platform deployment invocation for a manifest change, and the deployment caller itself does not establish a base-revision manifest. The impact matrix is therefore not fully enforced by the current workflow set.

## 10. Security Review

New local action uses are SHA-pinned and workflows generally request `contents: read`; no secrets, status writes, or arbitrary assertion shell inputs were found. The principal supply-chain issue is cross-repository `@main` usage and `ref: main` manifest checkout. These mutable references are incompatible with the established immutable-action and deterministic-reference policy.

## 11. Workflow Check Semantics

The four named checks exist in the implementation, but applicability is not fully reliable. The resolver does not independently establish the PR base manifest, and common module compatibility can report success without consuming the selected common PR revision. Consequently, a green check would not always mean the documented relationship was validated.

## 12. Diagnostics

Selected SHA summaries are printed without secrets, and live assertion failures include route-level failures. The selection diagnostics are useful, but they cannot compensate for selecting the wrong manifest revision. Contract diagnostics also do not expose the missing schema-level comparison because that comparison is not implemented.

## 13. Documentation Consistency

The current review text claims that all HIGH blockers are resolved and that callers retrieve base manifest SHAs. The actual workflows contradict those claims through floating `main` references and incomplete common-PR consumption. The historical blocker narrative is retained, but the current status must remain not ready until the implementation is corrected.

## 14. Findings

| Severity | Finding |
|---|---|
| BLOCKER | Manifest tag/SHA pairs do not agree for the recorded platform components; the manifest validator should fail and the selected platform set is not valid. |
| HIGH | Compatibility callers read a floating `opsnexus-docs` `main` manifest instead of the PR base revision; manifest PRs can influence their own baseline. |
| HIGH | Cross-repository reusable workflow callers use `@main`, leaving deployment/contract implementation mutable. |
| HIGH | Agent/backend module checks do not consume an unpublished selected common PR SHA; common validation does not compile/test the selected consumers against that SHA. |
| HIGH | Static contract validation is weaker than the declared contract gate and the live script duplicates the assertion definition. |
| HIGH | CI-4 scope includes the committed `CI3_DESIGN_REVIEW.md` artifact and an unrelated CI-2 review edit. |
| MEDIUM | Manifest/resolver logic is duplicated between docs and deployment, increasing drift risk. |
| MEDIUM | No complete manifest-change path was evidenced that runs the full selected deployment compatibility validation. |
| LOW | Common’s extra resolver job creates an additional non-stable job alongside the stable compatibility check. |
| INFORMATIONAL | Local Docker execution was not performed; this is not itself a blocker, but remote validation is still required after fixes. |

## 15. Required Fixes

1. Correct or remove tag fields so every present tag resolves to its manifest commit; retain only evidence-backed values.
2. Resolve the base manifest from the actual pull request base SHA and reject self-referential/moving baselines. Pin reusable cross-repository workflow refs to reviewed immutable commits.
3. Implement a controlled, non-`go.work` mechanism that makes the selected common revision the module consumed by agent/backend, and compile/test those consumers against it.
4. Make the assertion specification authoritative for both static validation and live execution, and validate operations, statuses, request/response schemas, required fields, and SSE media type against the selected OpenAPI.
5. Remove the unrelated CI3 review artifact and CI-2 documentation change from the CI-4 implementation scope.
6. Ensure manifest changes invoke the complete applicable compatibility set, including deployment validation, without introducing a second Compose lifecycle.

## 16. Historical Final Decision

NOT READY TO PUSH

## 17. Corrective implementation pass

The following review findings were corrected without changing application,
OpenAPI, Docker, migration, dependency, or runtime files:

| Finding | Root cause | Corrective change | Validation | Status |
|---|---|---|---|---|
| Manifest tag/SHA mismatch | Release tags had been copied onto current untagged snapshot commits. | The baseline records `tag: null` for those preview snapshots; the validator dereferences annotated or lightweight tags and fails on mismatch. | Local tag targets were compared against every manifest entry. | Resolved |
| Floating `main` refs | Callers used docs `main` and deployment `@main`. | Callers use immutable docs/deployment SHAs; docs PR validation uses its actual PR base SHA, while other repositories use the reviewed immutable docs-base SHA. | Repository-wide CI-4 search finds no `ref: main` or `@main`. | Resolved |
| Common PR SHA not consumed | The selected SHA was printed but consumers still used their committed release requirement. | A CI-only temporary copy runs Go download/get at the selected SHA, verifies Go `Origin.Hash`, then runs module verification and tests. | Script syntax passed; network-backed Go execution remains remote validation. | Resolved pending remote CI |
| Duplicated contract assertions | The shell executor carried its own route/field list. | `contract-basic.json` is the only assertion definition; static OpenAPI validation and the live Python executor both consume it. | Static validator passed all 7 assertions against the current OpenAPI. | Resolved |
| Unrelated CI-2/CI-3 files | Historical artifacts entered the implementation diff. | CI-2 content is restored to main; `CI3_DESIGN_REVIEW.md` is untracked and preserved locally, not committed. | Diff scope and status checks. | Resolved |
| Duplicated resolver | Deployment carried a second resolver implementation. | Deployment callers now use the immutable docs resolver. | No deployment resolver file remains. | Resolved |
| Manifest changes lacked full validation | Docs manifest workflow only validated fields. | Manifest validation fans out to module, static contract, and reusable deployment compatibility jobs. | Workflow structure reviewed; remote execution remains required. | Resolved pending remote CI |

The corrective local classification is:

READY FOR CI-4 IMPLEMENTATION REVIEW

The first manifest is a documented bootstrap case because the current main
branch predates the manifest. The docs workflow validates the candidate as the
initial set; subsequent component and manifest PRs require the immutable base
manifest file and never fall back to a moving branch.

## 18. Final corrective review

### Corrective Executive Summary

The corrective implementation preserves one resolver, one contract
specification, and one reusable CI-3 Compose lifecycle. No application or
deployment behavior was changed.

### 2. Commit Inventory

| Repository | Final local commit |
|---|---|
| opsnexus-docs | `aac512e53819de6f0ae4f92addb74ea8e704adac` |
| opsnexus-deployment | `4ce856cfc6239ae81b90107dfb10292b71793032` |
| opsnexus-agent | `6ac9bd428a657d69bcfb0456606a5af6de09305d` |
| opsnexus-backend | `2f71375dbcccddc14cc7213c2270fb871079c85d` |
| opsnexus-common | `aece6299882ece534e6566e4a66ea762791fc751` |
| opsnexus-api | `cb60e7c61b4b6c4e98478c45f5063fcee5e9f031` |
| opsnexus-dashboard | `9792f2a8a3fd7f2117f9ecdff5ee9601458cd28b` |

### 3. Scope Review

Committed diffs contain only CI-4 workflows, helpers, the manifest, the
shared assertion specification, the CI-3 reusable interface, and CI-4 records.
The deployment `CI3_DESIGN_REVIEW.md` remains untracked, unchanged, and is not
in the diff.

### 4. Manifest Review

All eight component commits are 40-character SHAs present in local Git
history. Current snapshot commits intentionally use `tag: null` and
`preview`/`informational` status; any future tag is checked against the exact
commit, including annotated tags. API contract and backend migration fields
are validated.

### 5. Compatibility Resolver Review

`opsnexus-docs/scripts/resolve_compatibility_set.py` is the sole resolver.
Component PRs use the immutable reviewed docs-base SHA plus the PR HEAD for
the changed component. Docs manifest PRs compare the immutable base manifest
with the candidate manifest; the first manifest is an explicit bootstrap case.

### 6. Module Compatibility

The common PR workflow checks out the selected common SHA. Agent/backend
validation copies consumers to temporary directories, runs Go download/get at
that exact SHA, verifies `Origin.Hash`, then runs `go mod verify` and tests.
No committed `replace` or `go.work` is used.

### 7. Static Contract

`contract-basic.json` is the sole assertion definition. The static validator
checks all seven approved operations against the selected OpenAPI, including
request fields, response status/schema fields, content types, and SSE media.
It performs no Docker or HTTP execution.

### 8. Live Contract

The reusable deployment workflow loads the same JSON through its fixed
`contract-basic` profile only after readiness. Failures propagate and cleanup
remains unconditional.

### 9. CI-3 Reuse

CI-3 remains the only owner of Compose setup, builds, PostgreSQL readiness,
migrations, health/restart checks, dashboard readiness, diagnostics, and
cleanup. Contract mode defaults to disabled.

### 10. Deployment Compatibility

`ci/compatibility-deployment` resolves one set and passes exact deployment,
common, backend, and dashboard SHAs to the reusable workflow. Manifest changes
fan out to modules, static contract validation, and deployment validation.

### 11. Repository Callers

Callers exist for common, agent, backend, API, dashboard, deployment, and
docs. CLI remains represented as informational in the manifest and has no
artificial API gate.

### 12. Security

CI-4 actions and cross-repository workflow references are SHA-pinned. Workflows
use read-only contents permissions, persist no checkout credentials, accept no
arbitrary shell command input, and require no secrets.

### 13. Documentation

Historical blockers remain above. Current documentation records the staged API
state: CI-4 validates only contract-covered routes; undocumented A-class
routes remain compatibility debt and complete public API compatibility is not
claimed.

### 14. Validation Evidence

YAML parsing, shell syntax, manifest SHA/tag checks, resolver substitution,
static contract validation, and `git diff --check` passed locally. Ruby was
unavailable, and Go module execution could not write the local module cache;
Docker/live execution remains remote validation.

### 15. Findings

No BLOCKER or HIGH findings remain. The local Ruby/Go/Docker limitations are
validation limitations, not implementation findings.

### 16. Required Fixes

None before implementation review. Remote CI must still validate network-backed
module resolution and live deployment behavior.

### 17. Final Decision

READY TO PUSH
