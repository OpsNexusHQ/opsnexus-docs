# OpsNexus Components

## opsnexus-agent

The agent runs on monitored Linux systems.

Responsibilities:

- Collect CPU metrics (usage, cores, model)
- Collect memory metrics (total, used, available, percent)
- Collect disk metrics (total, used, free, percent)
- Collect network metrics (bytes sent/received, packets, errors)
- Collect system uptime
- Count running processes
- Report telemetry to backend via HTTP
- Register with backend on startup

Technology: Go, gopsutil/v4

## opsnexus-backend

The backend is the central control plane.

Responsibilities:

- Agent registration and heartbeat tracking
- Telemetry ingestion and persistence (PostgreSQL JSONB)
- Real-time event streaming (SSE)
- Alert engine with sustained condition evaluation
- Incident workflow (Firing → Acknowledged → Resolved)
- Notification dispatch (Webhook, Slack) with HMAC signatures
- Observability APIs (overview, health, metrics, analytics)
- Telemetry retention and hourly rollup archival
- API token authentication and RBAC

Technology: Go, net/http, pgx/v5, PostgreSQL

## opsnexus-dashboard

The web interface for infrastructure operators.

Responsibilities:

- Fleet overview with health summary
- Agent detail pages with real-time metrics
- Time-series SVG charts with range picker
- Alert management and incident timeline
- Notification channel configuration
- API token management
- Settings and system configuration

Technology: React, TypeScript, Vite

## opsnexus-common

Shared Go types and contracts used by agent and backend.

Contents:

- Agent registration models
- Telemetry models
- API request/response structures

## opsnexus-api

OpenAPI 3.1 specification and schema definitions.

Contains:

- `openapi.yaml` — Full API contract
- `schemas/` — Reusable YAML schema definitions

## opsnexus-cli

Command-line interface for interacting with OpsNexus.

Status: Placeholder for future development.

## opsnexus-deployment

Deployment infrastructure and configuration.

Contents:

- Docker Compose configurations
- Dockerfile definitions
- Environment templates
- Reverse proxy configuration

## opsnexus-docs

Central project documentation including architecture, component descriptions, security guidelines, and decision records.

## awesome-opsnexus

Community-oriented curated resources related to the OpsNexus ecosystem.