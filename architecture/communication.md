# OpsNexus Communication

## Agent to Backend

The Linux agent communicates with the OpsNexus backend through HTTP APIs.

```text
Linux Server
     │
     ├── POST /api/v1/agents/register    (startup registration)
     ├── POST /api/v1/agents/{id}/telemetry  (periodic metrics, every 10s)
     │
     ▼
OpsNexus Backend
     │
     ├── PostgreSQL  (persistence)
     ├── Alert Engine  (evaluation)
     └── SSE Hub  (broadcast to dashboard)
```

## Registration Flow

1. Agent starts and reads configuration (backend URL, collection interval).
2. Agent sends `POST /api/v1/agents/register` with hostname, OS, arch, and version.
3. Backend returns an agent ID.
4. Agent stores the ID and begins the telemetry collection loop.

## Telemetry Flow

1. Agent collects system metrics using gopsutil (CPU, Memory, Disk, Network, Uptime, Processes).
2. Agent sends `POST /api/v1/agents/{id}/telemetry` with a JSON payload containing the snapshot.
3. Backend persists telemetry as JSONB in the `telemetry` table.
4. Backend triggers alert evaluation on the incoming snapshot.
5. Backend broadcasts a `telemetry.updated` SSE event to all connected dashboard clients.

## Real-Time Events (SSE)

The backend exposes `GET /api/v1/events` as a Server-Sent Events stream.

Event types:

| Event | Description |
|---|---|
| `telemetry.updated` | New telemetry snapshot received |
| `agent.registered` | New agent registered |
| `agent.status_changed` | Agent health transition |
| `alert.firing` | Alert condition triggered |
| `alert.acknowledged` | Alert acknowledged by operator |
| `alert.resolved` | Alert condition cleared |
| `alert.comment_added` | Incident comment posted |

## Notification Delivery

When alerts fire or resolve, the backend dispatches notifications to configured channels:

1. Webhook: HTTP POST with JSON payload and HMAC-SHA256 signature (`X-OpsNexus-Signature`).
2. Slack Webhook: Slack-formatted message payload via incoming webhook URL.

Delivery uses a bounded worker queue with exponential backoff retry (up to 3 attempts).