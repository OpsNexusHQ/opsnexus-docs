
### 5.5 Security architecture

```bash

# OpsNexus Security Architecture

Security is a core requirement of OpsNexus because the platform can monitor infrastructure and execute automation tasks.

## Principles

- Authentication is required for management operations.
- Agents must be uniquely identified.
- Agent communication must use encrypted transport.
- Automation commands must be explicitly authorized.
- Secrets must never be committed to Git.
- Environment-specific configuration must remain outside source control.
- Logs must avoid exposing credentials or sensitive tokens.

## Agent Security

Each agent should have a secure identity.

The backend must validate:

- Agent identity
- Authentication credentials
- Request authorization
- Request integrity

## Automation Security

Automation capabilities must use an allowlisted command/task model rather than unrestricted remote shell execution.

## Secrets

Secrets must be provided through secure environment configuration or a dedicated secrets-management mechanism.

Never commit:

- API keys
- Access tokens
- Passwords
- Private keys
- Production credentials