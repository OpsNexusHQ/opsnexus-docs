# Governance Review

Review date: 2026-08-15
Branch reviewed: phase0/governance-baseline
Comparison target: each repository's local main branch

## Executive verdict

The Phase 0 governance changes are directionally approved. No runtime/source behavior, API schema, Docker behavior, tags, generated artifacts, or secrets were added.

The branch needs minor corrections before commit:

1. CODEOWNERS uses @OpsNexusHQ without local proof that it is a valid GitHub user/team with write access.
2. SECURITY files promise GitHub private vulnerability reporting, but that setting was not verified.
3. Issue templates assume bug, enhancement, and documentation labels; label existence was not verified.
4. COMPATIBILITY.md says the current development ref is main while the reviewed working ref is phase0/governance-baseline. It needs explicit baseline-ref wording.
5. The compatibility document is policy documentation, not a release manifest, because it omits exact SHAs and image digests.

## Repository-by-repository review

### opsnexus-agent

Changed files:

- LICENSE: populated the previously empty file with MIT text.
- README.md: replaced unsupported OPSNEXUS_BACKEND_URL and OPSNEXUS_COLLECT_INTERVAL with source-supported OPSNEXUS_AGENT_BACKEND_URL and OPSNEXUS_AGENT_COLLECTION_INTERVAL; documented OPSNEXUS_AGENT_LOG_LEVEL; removed unsupported OPSNEXUS_AGENT_NAME.
- CONTRIBUTING.md
- SECURITY.md
- CODE_OF_CONDUCT.md
- .github/PULL_REQUEST_TEMPLATE.md
- .github/ISSUE_TEMPLATE/bug_report.md

Diff summary: seven governance/documentation paths; README has five additions and five deletions.

Correctness: approved with minor follow-up. The README now matches internal/config/config.go constants/defaults. Governance is concise and agent-specific.

Problems: private reporting and the bug label are unverified. The PR asks for gofmt and go test, but no CI exists yet; this is a valid contributor requirement, not a false claim.

Recommended correction: verify GitHub reporting and label settings.

### opsnexus-backend

Changed files:

- README.md: corrected https.github.com to https://github.com.
- LICENSE
- CONTRIBUTING.md
- SECURITY.md
- CODE_OF_CONDUCT.md
- .github/CODEOWNERS
- .github/PULL_REQUEST_TEMPLATE.md
- .github/ISSUE_TEMPLATE/bug_report.md

Diff summary: eight governance/documentation paths; one README URL correction.

Correctness: approved with ownership follow-up. The URL is correct and the governance addresses migrations, API compatibility, auth, CORS, secrets, egress, and rollback.

Problems: @OpsNexusHQ is an unverified ownership assumption. The bug label and private reporting are also unverified.

Recommended correction: verify the CODEOWNERS principal and replace it with a real maintainer/team if necessary.

### opsnexus-dashboard

Changed files:

- LICENSE
- CONTRIBUTING.md
- SECURITY.md
- CODE_OF_CONDUCT.md
- .github/PULL_REQUEST_TEMPLATE.md
- .github/ISSUE_TEMPLATE/bug_report.md

Diff summary: six new governance paths; no README or runtime changes.

Correctness: approved with minor follow-up. The browser-security warning about VITE values, .env.local, dist, and node_modules is accurate.

Problems: bug label/private reporting are unverified. The PR requires local lint/build checks, but no workflow enforces them yet.

Recommended correction: verify settings; retain the repository-specific browser-client guidance.

### opsnexus-common

Changed files:

- LICENSE
- CONTRIBUTING.md
- SECURITY.md
- CODE_OF_CONDUCT.md
- .github/PULL_REQUEST_TEMPLATE.md
- .github/ISSUE_TEMPLATE/feature_request.md

Diff summary: six new governance paths; no README or runtime changes.

Correctness: approved. The contribution guidance appropriately limits this module to stable shared contracts and identifies agent/backend consumers.

Problems: enhancement label/private reporting are unverified.

Recommended correction: verify settings only.

### opsnexus-api

Changed files:

- LICENSE
- CONTRIBUTING.md
- SECURITY.md
- CODE_OF_CONDUCT.md
- .github/CODEOWNERS
- .github/PULL_REQUEST_TEMPLATE.md
- .github/ISSUE_TEMPLATE/feature_request.md

Diff summary: seven new governance paths; no schema or README changes.

Correctness: approved with ownership follow-up. Templates correctly treat OpenAPI edits as compatibility-sensitive and identify backend/dashboard/agent/CLI consumers.

Problems: @OpsNexusHQ is unverified. The validation checklist is aspirational because no workflow exists, but it does not falsely claim that CI already validates OpenAPI.

Recommended correction: verify the CODEOWNERS principal and later implement the promised validation workflow.

### opsnexus-deployment

Changed files:

- README.md: changed the badge/link from v0.5.0 to v0.6.0 and clarified that v0.6.0 is a deployment-component milestone, not a platform release.
- LICENSE
- CONTRIBUTING.md
- SECURITY.md
- CODE_OF_CONDUCT.md
- .github/CODEOWNERS
- .github/PULL_REQUEST_TEMPLATE.md
- .github/ISSUE_TEMPLATE/bug_report.md

Diff summary: eight governance/documentation paths; README has three additions and one deletion.

Correctness: approved with wording follow-up. The v0.6.0 tag exists on deployment and corresponds to Dockerization.

Problems: @OpsNexusHQ, bug label, and private reporting are unverified. The compatibility reference is prose rather than a direct link.

Recommended correction: verify ownership/settings and make the compatibility reference a direct docs link.

### opsnexus-docs

Changed files:

- README.md: added the compatibility-document link.
- COMPATIBILITY.md: added component/tag/release policy and verification requirements.
- LICENSE
- CONTRIBUTING.md
- SECURITY.md
- CODE_OF_CONDUCT.md
- .github/CODEOWNERS
- .github/PULL_REQUEST_TEMPLATE.md
- .github/ISSUE_TEMPLATE/documentation.yml
- ENGINEERING_AUDIT.md and P0_VERIFICATION.md: pre-existing untracked audit artifacts, not modified by this review.

Diff summary: eight Phase 0 governance/documentation paths plus the two pre-existing untracked audit files.

Correctness: conditionally approved. The compatibility policy usefully separates independently tagged components from coordinated releases.

Problems:

- COMPATIBILITY.md calls main the current development ref while all reviewed checkouts are on phase0/governance-baseline. Clarify that main is the baseline compatibility ref.
- CODEOWNERS references /P0_VERIFICATION.md, which is currently untracked. The path should only be governed if that file is intentionally committed.
- @OpsNexusHQ and the documentation label are unverified.
- The compatibility table is not a reproducible release manifest because it omits exact SHAs/digests.

Recommended correction: clarify ref terminology, decide the audit-file commit scope, and validate ownership/settings.

### opsnexus-cli

Changed files:

- LICENSE
- CONTRIBUTING.md
- SECURITY.md
- CODE_OF_CONDUCT.md
- .github/PULL_REQUEST_TEMPLATE.md
- .github/ISSUE_TEMPLATE/feature_request.md

Diff summary: six new governance paths; no README or runtime changes.

Correctness: approved. The contribution policy correctly keeps the CLI as an API client and avoids backend-internal coupling.

Problems: enhancement label/private reporting are unverified.

Recommended correction: verify settings only.

### awesome-opsnexus

Changed files:

- LICENSE: added a CC0 1.0 notice matching the README.
- CONTRIBUTING.md
- SECURITY.md
- CODE_OF_CONDUCT.md
- .github/PULL_REQUEST_TEMPLATE.md
- .github/ISSUE_TEMPLATE/link_report.md

Diff summary: six new governance paths; no README or runtime changes.

Correctness: approved. The files are appropriately focused on curated links, relevance, maintenance, and safety.

Problems: documentation label/private reporting are unverified. The CC0 file is a short notice rather than full canonical legal text. The pre-existing README contribution link points to the docs repository root rather than a direct guide.

Recommended correction: verify settings and optionally standardize the full CC0 text.

## Cross-repository consistency

Positive:

- All repositories now have contribution, security, conduct, and PR entry points.
- Implementation repositories use MIT; awesome-opsnexus uses CC0, matching its README.
- Templates prohibit credentials, host data, tokens, and generated artifacts.
- Governance is repository-specific rather than a mechanically identical template.

Inconsistencies:

- Security files uniformly refer to GitHub private reporting without verifying the setting.
- Issue templates assume labels without verifying them.
- Four CODEOWNERS files use the same unverified organization principal.
- COMPATIBILITY.md uses main as a development ref while the active branch is the Phase 0 branch.

## License consistency

opsnexus-agent originally had an empty LICENSE and now has full MIT text. Backend, dashboard, common, API, deployment, docs, and CLI have consistent MIT files. awesome-opsnexus has a CC0 1.0 notice consistent with its README.

No incorrect license owner or repository license URL was added. The only note is the abbreviated CC0 notice.

## Contribution/security consistency

The files are concise and do not duplicate architecture or runtime policy. The main enforceability gaps are external: GitHub private reporting must be enabled, labels must exist, and maintainers/triage ownership must be defined.

Security guidance such as HTTPS, auth, CORS, egress, backups, and image scanning is advisory and intentionally not enforced by this branch because runtime code and CI are out of scope.

## CODEOWNERS validation

CODEOWNERS was added to backend, API, deployment, and docs. All listed paths exist or are valid repository-root paths.

The principal @OpsNexusHQ cannot be proven as a valid CODEOWNERS user/team with write access using local Git data. Verify it through GitHub settings/API and replace it with a real maintainer/team if necessary.

The docs entry /P0_VERIFICATION.md depends on a currently untracked file. Decide whether that file is part of the commit before retaining the rule.

## README/documentation consistency

Verified correct:

- Agent environment names now match source.
- Backend clone URL is valid.
- Deployment v0.6.0 is described as a component milestone.
- Docs README links to COMPATIBILITY.md.

Remaining:

- Clarify baseline-ref wording in COMPATIBILITY.md.
- Make deployment's compatibility reference a direct link.
- The pre-existing awesome contribution link points to the docs root.
- The API README still calls OpenAPI the single source of truth although enforcement is not automated; this is pre-existing.
- COMPATIBILITY.md is policy, not a release manifest.

No incorrect new repository name, URL, command, or branch name was found.

## Required corrections before commit

1. Verify @OpsNexusHQ as a valid CODEOWNERS principal with write access, or replace it.
2. Verify private vulnerability reporting or change SECURITY wording to conditional language.
3. Verify/create bug, enhancement, and documentation labels.
4. Clarify that main is the baseline compatibility ref, not the active Phase 0 branch.
5. Decide whether P0_VERIFICATION.md is part of the governance commit before retaining its CODEOWNERS entry.
6. Optionally replace the abbreviated CC0 notice with canonical full text.

## Approved changes

Subject to the corrections above:

- license additions/correction;
- repository-specific contribution, security, and conduct policies;
- PR and maturity-appropriate issue templates;
- agent environment-variable documentation correction;
- backend clone URL correction;
- deployment component-release clarification;
- compatibility policy and docs index link.

## Final validation

- Repositories reviewed: 9.
- Source/runtime files changed: 0.
- Governance files changed/created: LICENSE files, CONTRIBUTING.md, SECURITY.md, CODE_OF_CONDUCT.md, CODEOWNERS where justified, PR templates, and issue templates/forms listed above.
- Documentation files changed/created: agent/backend/deployment/docs README changes and COMPATIBILITY.md.
- Secrets found: 0.
- Machine-specific data added: 0.
- git diff --check: passed for all repositories.
- Markdown/link tools: markdownlint, markdown-link-check, lychee, and vale were unavailable locally.
- Manual local project-link check: passed after excluding existing node_modules and dist.
- Runtime behavior changed: no.
- Tags changed: no.
- Commits, pushes, merges: none.
- Current branch: phase0/governance-baseline in every repository.
- Git status: expected Phase 0 changes in all repositories; opsnexus-docs also retains pre-existing untracked ENGINEERING_AUDIT.md and P0_VERIFICATION.md. This report is the only file created by this review.

