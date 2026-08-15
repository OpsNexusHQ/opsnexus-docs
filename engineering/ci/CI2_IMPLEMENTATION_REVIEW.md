# CI2 Implementation Review

## Original findings

The pre-push review classified the implementation as NOT READY TO PUSH because GitHub Actions used floating major tags, the API breaking-change baseline used an unverified `v0.5.0` tag, and npm-based CI tools did not lock transitive dependencies.

## Fixes performed

- Pinned `actions/checkout` to `11bd71901bbe5b1630ceea73d27597364c9af683` (`v4.2.2`).
- Pinned `actions/setup-node` to `49933ea5288caeca8642d1e84afbd3f7d6820020` (`v4.4.0`).
- Pinned `lycheeverse/lychee-action` to `7da8ec1fc4e01b5a12062ac6c589c10a4ce70d67` (`v2.0.0`).
- Verified the API tag `v0.5.0` resolves locally to `c52c716c9d456f6314f06b1f11f71f7bc9caa654`.
- Added a CI assertion that the tag resolves to that exact commit before archiving the baseline.
- Retained the explicit Redocly and markdownlint package versions. No application dependencies were changed.
- Retained bounded lychee retries without suppressing failures.

## Validation results

- Dashboard: `npm ci`, `npm run lint`, and `npm run build` passed.
- API: baseline tag resolution passed locally. Redocly validation and bundling were attempted but the local npm/network operation did not complete in the available environment.
- Docs: markdownlint validation was attempted but the local npm/network operation did not complete in the available environment.
- `git diff --check` passed for the corrective changes.
- No source, runtime, API schema, Docker, deployment, or application dependency changes were made.

## Remaining non-blocking concerns

Direct npm package versions remain explicit, but their transitive dependency graphs are not lockfile-pinned. This remains a documented follow-up and was not expanded into CI-2.

External link checking remains network-dependent by design and retains bounded retries with failure propagation.

## Final decision

READY TO PUSH

## Remote CI correction

The first remote CI run found two command-level issues: oasdiff 1.26.1 requires positional base and revision arguments, and the GitHub-hosted runner did not provide ripgrep. The API workflow now uses positional oasdiff arguments, and the docs consistency checks now use the runner-provided POSIX grep command. Both checks retain strict failure behavior.

## CI-2 completion record

| Repository | PR | Squash merge SHA | Final remote CI run |
|---|---:|---|---|
| opsnexus-dashboard | #2 | `fe5f4d309b09ed39fceac73ccdfbddfb1c562d97` | `31903569161` — green |
| opsnexus-api | #2 | `5c25b39547d30a57f07640a79115ca5f43b9544f` | `31903737304` — green |
| opsnexus-docs | #3 | `f692608bfe837f19625cc4f7208aee70c1fdfc43` | `31903746807` — green |

Final stable checks:

- Dashboard: `ci/npm-install`, `ci/web-lint`, `ci/web-build`
- API: `ci/api-contract`, `ci/api-bundle`, `ci/api-breaking-change`
- Docs: `ci/docs-validate`, `ci/link-check`

All three PRs were squash-merged after remote CI passed. Local `main` matches `origin/main` for each repository and all three working trees are clean. No post-merge `main` workflow run was triggered because these workflows use pull-request and manual triggers only.

The remaining non-blocking limitation is that direct npm tool versions are explicit while their transitive dependency graphs are not fully lockfile-pinned. This remains outside CI-2 scope. CI-3 deployment validation is the next phase.
