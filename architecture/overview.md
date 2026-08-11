# OpsNexus Architecture Overview

## Purpose

OpsNexus is a cloud-native infrastructure monitoring, observability, and incident automation platform built with Go, PostgreSQL, and React.

The current implementation (v0.5.0) includes:

- Real-time Linux server monitoring (CPU, Memory, Disk, Network, Uptime, Processes)
- Lightweight Go agent using gopsutil (< 15MB RAM)
- Go HTTP backend with PostgreSQL persistence
- Server-Sent Events (SSE) real-time streaming
- Alert engine with sustained condition evaluation
- Incident workflow (Firing → Acknowledged → Resolved)
- Webhook and Slack notification delivery
- Telemetry retention and hourly rollup archival
- API token authentication and RBAC
- React + TypeScript dark-themed dashboard

## System Architecture

```text
                          ┌───────────────┐
                          │ Linux Agent   │
                          │ gopsutil      │
                          └───────┬───────┘
                                  │ Telemetry (10s)
                                  ▼
                          ┌───────────────┐
                          │ Go Backend    │
                          └───────┬───────┘
                                  │
            ┌─────────────────────┼─────────────────────┐
            ▼                     ▼                     ▼
       PostgreSQL            Alert Engine            SSE Hub
  (agents, telemetry,      (sustained rules,            │
   alerts, comments,        ack, comments,              │
   channels, tokens,        cooldown)                   │
   telemetry_hourly)             │                      │
            │              Notification                 │
            │                 Queue                     │
            │                   │                       │
            │            ┌──────┴──────┐                │
            │            ▼             ▼                │
            │         Webhook        Slack              │
            ▼                                           ▼
     Retention Worker                            Real-Time Dashboard
     (30-day purge)                              (React + TypeScript)
```

## Data Flow

1. **Collection**: The Go agent collects system metrics every 10 seconds using gopsutil.
2. **Transport**: Metrics are sent via HTTP POST to the backend (`/api/v1/agents/{id}/telemetry`).
3. **Persistence**: The backend stores telemetry as JSONB in PostgreSQL.
4. **Alerting**: The alert engine evaluates incoming telemetry against configured rules.
5. **Notifications**: Firing/resolved alerts are dispatched to configured webhook and Slack channels.
6. **Streaming**: All events are broadcast to connected dashboard clients via SSE.
7. **Visualization**: The React dashboard renders real-time metrics, charts, and alert status.
8. **Retention**: A background worker rolls up hourly summaries and purges raw telemetry older than the configured retention period.

## Technology Stack

| Component | Technology |
|---|---|
| Agent | Go, gopsutil/v4 |
| Backend | Go, net/http, pgx/v5 |
| Database | PostgreSQL |
| Dashboard | React, TypeScript, Vite |
| Real-time | Server-Sent Events (SSE) |
| API Contract | OpenAPI 3.1 |

## Future Extensions

- OpenTelemetry (OTLP) metrics and traces ingestion
- eBPF kernel-level process and network tracing
- Kubernetes cluster monitoring
- AI-powered anomaly detection and root cause analysis
- Multi-tenancy and SaaS deployment