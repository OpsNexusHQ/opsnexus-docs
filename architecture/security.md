# OpsNexus Security Architecture

Security is a core requirement of OpsNexus because the platform monitors infrastructure and can trigger notification workflows.

## Principles

- Authentication is required for management operations.
- Agents must be uniquely identified via registration.
- Agent communication should use encrypted transport (HTTPS in production).
- Secrets must never be committed to Git.
- Environment-specific configuration must remain outside source control.
- Logs must avoid exposing credentials or sensitive tokens.

## API Authentication

OpsNexus supports Bearer token authentication via the `Authorization` header.

- Tokens are SHA-256 hashed before storage in the `api_tokens` table.
- Raw tokens are shown only once at creation time.
- Authentication is controlled by `OPSNEXUS_API_AUTH_ENABLED` (default: disabled for development).

## Role-Based Access Control (RBAC)

Three roles are supported:

| Role | Permissions |
|---|---|
| `viewer` | Read-only access to agents, telemetry, alerts |
| `operator` | Viewer permissions + acknowledge alerts, manage rules, post comments |
| `admin` | Full access including token management, notification channels, system configuration |

## Notification Security

Webhook notifications include an HMAC-SHA256 signature in the `X-OpsNexus-Signature` header, allowing receivers to verify payload integrity and authenticity.

## Secrets Management

Secrets must be provided through environment variables or a dedicated secrets manager.

Never commit:

- API keys or tokens
- Database connection strings with credentials
- Private keys or certificates
- Production `.env` files
- Webhook secrets

All repositories include `.gitignore` rules to exclude `.env`, `.pem`, `.key`, and credential files.