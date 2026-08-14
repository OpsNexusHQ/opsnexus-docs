# OpsNexus Platform Compatibility

This document separates independently versioned components from coordinated platform releases. The protected main branch is the baseline compatibility/reference branch. The phase0/governance-baseline branch is the current engineering work branch for this baseline and is not a permanent development branch.

## Current baseline

| Component | Repository | Current development ref | Latest tag | Compatibility note |
|---|---|---|---|---|
| Agent | opsnexus-agent | main | v0.5.0 | Uses shared common models and the v1 backend HTTP contract |
| Backend | opsnexus-backend | main | v0.5.0 | Serves the v1 HTTP API and PostgreSQL migrations |
| Dashboard | opsnexus-dashboard | main | v0.5.0 | Package metadata remains 0.0.0; release metadata is tracked separately |
| Common | opsnexus-common | main | v0.5.0 | Shared Go envelope/models for agent and backend |
| API | opsnexus-api | main | v0.5.0 | OpenAPI contract source; consumer validation is required before release |
| Deployment | opsnexus-deployment | main | v0.6.0 | Dockerization milestone, not a coordinated platform release |
| CLI | opsnexus-cli | main | v0.5.0 | Preview/placeholder; commands are not yet a complete supported client |
| Docs | opsnexus-docs | main (baseline reference) | v0.5.0 | Platform documentation and release records |

## Release policy

Components may be tagged independently. A platform release must publish an explicit manifest listing the exact commit SHA and tag for every component, API contract version, database migration state, image references, and rollback guidance. A component tag must not be described as a platform release without that manifest. Current engineering work may occur on phase0/governance-baseline, but release references remain pinned to exact component commits/tags.

The API path is currently v1. Additive changes should remain backward compatible. Breaking changes require a compatibility decision, coordinated consumer updates, migration notes, and release validation.

## Verification requirements

Before a coordinated release:

1. Validate OpenAPI and references.
2. Test agent, common, backend, dashboard, and CLI consumers against the selected contract.
3. Validate deployment configuration and migrations from a clean full-workspace or immutable-image input.
4. Record authentication, environment, persistence, upgrade, and rollback requirements.
5. Publish release notes linking the exact refs.
