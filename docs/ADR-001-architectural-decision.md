# ADR-001: Autonomous Disaster Recovery: Cross-Region Azure Failover Co-Worker

## Status
Accepted

## Service Owner & Sign-Off Authority
Principal Azure Infrastructure & Resilience Architect

## Dominant Artefact
Cross-Region RTO/RPO Countdown Matrix

## Decision & Refusal Boundary
All production state mutations must pass deterministic pre-flight policy evaluation in `src/Invoke-AutonomousDrPreFlight.ps1` and satisfy the 16-test Pester verification contract in `tests/Boundary-Verification.Tests.ps1` before execution.
