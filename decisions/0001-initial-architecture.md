# ADR-0001: Initial OpsNexus Architecture

## Status

Accepted

## Context

OpsNexus requires a modular architecture capable of monitoring Linux infrastructure while supporting future extensions (Docker, Kubernetes, Android, network devices).

## Decision

OpsNexus uses separate Git repositories for its major components, each independently versioned and deployable.

The backend and agent use Go as the primary implementation language for performance, single-binary deployment, and low resource consumption.

The dashboard uses React with TypeScript for a modern, interactive real-time UI.

PostgreSQL serves as the primary data store with JSONB for flexible telemetry storage.

## Repository Architecture

| Repository | Purpose |
|---|---|
| `opsnexus-agent` | Linux monitoring agent |
| `opsnexus-backend` | Go HTTP backend and API server |
| `opsnexus-dashboard` | React + TypeScript dashboard |
| `opsnexus-common` | Shared Go types and contracts |
| `opsnexus-api` | OpenAPI specification |
| `opsnexus-cli` | Command-line interface |
| `opsnexus-deployment` | Docker and deployment infrastructure |
| `opsnexus-docs` | Central documentation |
| `awesome-opsnexus` | Community resources |

## Rationale

Separate repositories provide clear ownership boundaries, independent CI/CD pipelines, simpler versioning, and future extensibility without monorepo complexity.

## Consequences

- Cross-repository coordination is required for breaking API changes.
- Shared types live in `opsnexus-common` and are imported as a Go module.
- The OpenAPI contract in `opsnexus-api` serves as the single source of truth for API design.