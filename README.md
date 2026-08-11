# OpsNexus Documentation

Central documentation repository for the [OpsNexus](https://github.com/OpsNexusHQ) infrastructure monitoring platform.

## Contents

- [Architecture Overview](architecture/overview.md) — System architecture and data flow
- [Components](architecture/components.md) — Repository and component responsibilities
- [Communication](architecture/communication.md) — Agent-to-backend protocol
- [Security](architecture/security.md) — Security architecture and principles
- [ADR-0001](decisions/0001-initial-architecture.md) — Initial architecture decision record

## Quick Links

| Repository | Description |
|---|---|
| [opsnexus-agent](https://github.com/OpsNexusHQ/opsnexus-agent) | Linux monitoring agent (Go + gopsutil) |
| [opsnexus-backend](https://github.com/OpsNexusHQ/opsnexus-backend) | Go HTTP backend, PostgreSQL, alerting, SSE |
| [opsnexus-dashboard](https://github.com/OpsNexusHQ/opsnexus-dashboard) | React + TypeScript real-time dashboard |
| [opsnexus-common](https://github.com/OpsNexusHQ/opsnexus-common) | Shared Go types and contracts |
| [opsnexus-api](https://github.com/OpsNexusHQ/opsnexus-api) | OpenAPI specification and schemas |
| [opsnexus-cli](https://github.com/OpsNexusHQ/opsnexus-cli) | Command-line interface |
| [opsnexus-deployment](https://github.com/OpsNexusHQ/opsnexus-deployment) | Docker, deployment, and infrastructure |
| [awesome-opsnexus](https://github.com/OpsNexusHQ/awesome-opsnexus) | Community resources |

## License

Part of the [OpsNexus](https://github.com/OpsNexusHQ) ecosystem.