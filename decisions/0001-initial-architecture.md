# ADR-0001: Initial OpsNexus Architecture

## Status

Accepted

## Context

OpsNexus requires a modular architecture capable of monitoring Linux infrastructure and Docker while supporting future infrastructure integrations.

## Decision

OpsNexus will use separate repositories for its major components.

The backend and agent will use Go as the primary implementation language.

The initial MVP will focus on:

1. Linux monitoring
2. Docker monitoring
3. Infrastructure automation
4. Centralized API
5. Web dashboard

## Repository Architecture

- opsnexus-agent
- opsnexus-backend
- opsnexus-dashboard
- opsnexus-common
- opsnexus-docs
- opsnexus-deployment
- opsnexus-cli
- opsnexus-api
- awesome-opsnexus

## Rationale

Separate repositories provide clear ownership boundaries, independent development, simpler deployment, and future extensibility.

## Future Extensions

The architecture should support additional monitoring and management modules without changing the core MVP architecture.