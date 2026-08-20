# CI-4 Completion Record

## Result

CI-4 Cross-Repository Compatibility is merged and remotely validated.

## Merged PRs

| Repository | PR | Merge SHA |
| --- | ---: | --- |
| opsnexus-docs | #4 | `b54bde59f0e4c581e1362c520882730040e90b1d` |
| opsnexus-deployment | #3 | `57e51a823bb00389de633f83719a784c9de17b60` |
| opsnexus-common | #3 | `6a14c223dfd81e0906cf0006b1af3c6a990ac957` |
| opsnexus-agent | #3 | `3b4717ceaf253f1cb4437eb9bf5838602497dc48` |
| opsnexus-backend | #3 | `bc03c5fecc523163717f936d05b35763ef808e5e` |
| opsnexus-api | #3 | `f642c49af60f57af1a2a8fa9f494ee80b7e3db99` |
| opsnexus-dashboard | #3 | `fb5adb7690871d6685e300103e191058086e215b` |

## Remote validation

The stable compatibility layers passed:

- `ci/compatibility-manifest`: run `31914974426`
- `ci/compatibility-modules`: common run `31915611868`; agent run `31915610481`
- `ci/compatibility-contract`: docs bootstrap run `31914974426`; API run `31915498941`
- `ci/compatibility-deployment`: deployment run `31915482389`; backend run `31915501723`; dashboard run `31915505179`

The deployment validations also passed the existing configuration, build, PostgreSQL/migration, backend restart, dashboard smoke, live assertion, and cleanup checks.

## Compatibility behavior

Compatibility selection uses immutable component revisions and the reviewed platform manifest. The common-module validation exercised the selected common revision for its consumers. Static contract validation and live contract assertions share the approved assertion profile; live assertions run inside the single reusable CI-3 Compose lifecycle.

## Limitations

Local Docker, Ruby, and writable Go module-cache limitations remained; remote GitHub Actions supplied the authoritative live validation. Floating image tags remain a documented reproducibility limitation. Public API routes classified as A but not yet represented in OpenAPI remain compatibility debt; CI-4 currently validates only the contract-covered surface.

## Next gate

CI-5 Security/Dependency Scanning is next. Phase 1 product work must wait until the remaining Phase 0 foundation gates are complete.
