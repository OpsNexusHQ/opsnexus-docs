# OpsNexus Architecture Overview

## Purpose

OpsNexus is a cloud-native infrastructure monitoring and automation platform.

The initial MVP focuses on:

- Linux server monitoring
- Docker monitoring
- Infrastructure automation
- Centralized dashboards
- API-driven management

Future versions may extend the platform with:

- Android Enterprise management
- Network-device monitoring
- Additional infrastructure providers
- Additional automation integrations

## High-Level Architecture

```text
                    ┌─────────────────────┐
                    │   OpsNexus Dashboard│
                    │      Web UI         │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │    OpsNexus API     │
                    │  API Definitions    │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │  OpsNexus Backend   │
                    │    Go Services      │
                    └───────┬─────┬───────┘
                            │     │
                 ┌──────────┘     └──────────┐
                 ▼                           ▼
        ┌─────────────────┐         ┌─────────────────┐
        │ OpsNexus Agent  │         │ Docker Runtime  │
        │ Linux Monitoring│         │   Monitoring     │
        └─────────────────┘         └─────────────────┘

                 ┌───────────────────────────┐
                 │      OpsNexus Common      │
                 │ Shared Types / Contracts  │
                 └───────────────────────────┘