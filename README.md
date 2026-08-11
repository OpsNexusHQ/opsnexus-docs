# OpsNexus Documentation (`opsnexus-docs`)

[![Release](https://img.shields.io/badge/release-v0.5.0-blue.svg)](https://github.com/OpsNexusHQ/opsnexus-docs/releases/tag/v0.5.0)
[![Documentation](https://img.shields.io/badge/docs-v0.5.0-success.svg)](https://github.com/OpsNexusHQ/opsnexus-docs)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

Central documentation portal for **OpsNexus**, a cloud-native infrastructure monitoring, observability, and incident automation platform.

---

## 🏛️ System Architecture Overview

```text
┌────────────────┐        HTTP Telemetry (10s)        ┌────────────────┐
│  Linux Agent   ├───────────────────────────────────►│   Go Backend   │
│(opsnexus-agent)│                                    └───────┬────────┘
└────────────────┘                                            │
                                         ┌────────────────────┼────────────────────┐
                                         ▼                    ▼                    ▼
                                    PostgreSQL           Alert Engine           SSE Hub
                              (agents, telemetry,       (sustained rules,          │
                               alerts, comments,         ack, comments)            │
                               channels, tokens,              │                    │
                               telemetry_hourly)              ▼                    │
                                         │            Notification Queue           │
                                         │            & Worker Pool                │
                                         │                    │                    │
                                         │            ┌───────┴───────┐            │
                                         │            ▼               ▼            │
                                         │         Webhook          Slack          │
                                         ▼                                         ▼
                                  Retention Worker                          Real-Time Dashboard
                                  (30d purge / rollup)                      (React + TypeScript)
```

---

## 📚 Documentation Directory

- [Architecture Overview](architecture/overview.md) — End-to-end data flow, components, and technology stack.
- [Component Responsibilities](architecture/components.md) — Individual repository roles in the OpsNexus ecosystem.
- [Agent & Backend Protocol](architecture/communication.md) — Registration, telemetry payload contracts, and SSE event streaming.
- [Security & RBAC Architecture](architecture/security.md) — Authentication middleware, token hashing, HMAC webhook verification, and RBAC rules.
- [ADR-0001: Architectural Decisions](decisions/0001-initial-architecture.md) — Multi-repo layout, technology stack choices, and design rationale.

---

## 🔗 OpsNexus Ecosystem Repositories

| Repository | Role & Primary Technology |
|---|---|
| [`opsnexus-agent`](https://github.com/OpsNexusHQ/opsnexus-agent) | Linux Metric Collector (Go, `gopsutil`) |
| [`opsnexus-backend`](https://github.com/OpsNexusHQ/opsnexus-backend) | Core API Control Plane (Go, PostgreSQL, SSE) |
| [`opsnexus-dashboard`](https://github.com/OpsNexusHQ/opsnexus-dashboard) | DevOps Operator UI (React 19, TypeScript, Vite) |
| [`opsnexus-api`](https://github.com/OpsNexusHQ/opsnexus-api) | API Contract & Schema Definitions (OpenAPI 3.1) |
| [`opsnexus-common`](https://github.com/OpsNexusHQ/opsnexus-common) | Shared Data Models & Go Contracts |
| [`opsnexus-cli`](https://github.com/OpsNexusHQ/opsnexus-cli) | Command-Line Management Utility |
| [`opsnexus-deployment`](https://github.com/OpsNexusHQ/opsnexus-deployment) | Docker Compose & Production Setup |
| [`opsnexus-docs`](https://github.com/OpsNexusHQ/opsnexus-docs) | Platform Documentation Portal |
| [`awesome-opsnexus`](https://github.com/OpsNexusHQ/awesome-opsnexus) | Community Guides & Integration Ecosystem |

---

## 🖼️ UI Previews & Visuals

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│ ⬡ OpsNexus  ▦ Overview   ⬡ Agents   🔔 Alerts (2)   ⚙️ Settings   ● Live     │
├─────────────────────────────────────────────────────────────────────────────┤
│ FLEET OVERVIEW                                                              │
│ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐         │
│ │ Total Agents │ │ Healthy      │ │ Stale        │ │ Active Alerts│         │
│ │ 12           │ │ 10           │ │ 1            │ │ 2 Firing     │         │
│ └──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘         │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🗺️ Platform Roadmap

- **v0.5.0 (Current)**: Linux System Metric Collection, SSE Real-Time Streaming, Alert Engine, Incident Workflow (Ack/Comments), Webhooks & Slack Notifications, Retention & Rollups, RBAC API Auth.
- **v0.6.0 (Next)**: Docker Container Monitoring, OpenTelemetry (OTLP) gRPC Ingest, CLI Completion, Agent Auto-Update.
- **v1.0.0 (Target)**: eBPF Network Flow Tracing, AI-assisted Anomaly Detection & Incident Root Cause Analysis, Kubernetes DaemonSet Operator, SaaS Multi-Tenancy.

---

## 📄 License

Part of the [OpsNexus](https://github.com/OpsNexusHQ) ecosystem. Licensed under the MIT License.