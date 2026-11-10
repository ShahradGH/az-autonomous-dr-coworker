# Autonomous Disaster Recovery: Cross-Region Azure Failover Co-Worker

[![Pester Tests](https://img.shields.io/badge/pester-16%2F16%20passing-brightgreen)](tests/Boundary-Verification.Tests.ps1)
[![Platform](https://img.shields.io/badge/platform-Azure%20Container%20Apps%20%7C%20Cosmos%20DB-blue)](#architecture-overview)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Author](https://img.shields.io/badge/author-Shahrad%20Alerasoul-0a1128)](https://alerasoul.net)

> **Autonomous cross-region Azure disaster recovery orchestrator that enforces asynchronous database replication bounds (RPO) and route convergence before permitting traffic shifts.**

---

## Architecture Overview

Static disaster recovery runbooks fail during regional cloud degradations because they treat availability as a simple boolean. When primary ingress web probes return consecutive `HTTP 503` errors, standard runbooks blindly flip Azure Front Door origin weights without checking:
1. **Stateful Data Tier Replication Lag**: Whether secondary Azure Cosmos DB or database replicas are lagging behind committed writes.
2. **Private DNS & Route Convergence**: Whether standby spoke subnets still resolve private endpoints to the degraded region across ExpressRoute.
3. **Cascading Retry Storms**: Whether autonomous worker agents hitting missing session records will overwhelm API Management rate limits.

```
+-------------------------------------------------------------------------+
|                  AZURE FRONT DOOR / GLOBAL INGRESS                     |
+------------------------------------+------------------------------------+
                                     |
                [HTTP 503 Detected on UK South Origin]
                                     |
                                     v
+-------------------------------------------------------------------------+
|       AUTONOMOUS DR FAILOVER CO-WORKER (Azure Container Apps)           |
+------------------------------------+------------------------------------+
                                     |
          +--------------------------+--------------------------+
          | Pre-Flight Invariant 1   | Pre-Flight Invariant 2   |
          v                          v                          v
+--------------------+     +--------------------+     +--------------------+
| Cosmos DB Lag <=30s|     | Private DNS Spoke  |     | Human MFA Approval |
| Replication Check  |     | Route Convergence  |     | Sign-Off Gate      |
+---------+----------+     +---------+----------+     +---------+----------+
          |                          |                          |
          +--------------------------+--------------------------+
                                     |
                      [All 3 Invariants Verified]
                                     |
                                     v
+-------------------------------------------------------------------------+
|     ORDERLY TRAFFIC CUTOVER TO UK WEST (Zero Split-Brain Loss)          |
+-------------------------------------------------------------------------+
```

This repository provides the reference implementation of an **Autonomous Disaster Recovery Co-Worker** deployed on Azure Container Apps. When regional degradation occurs, the co-worker enforces a **fail-closed circuit breaker**: if secondary replication lag exceeds 30 seconds or private routes flap, automated cutover is frozen and held for Resilience Architect MFA sign-off.

---

## The 16-Test Deterministic Pester Matrix

Every runbook mutation and configuration change is asserted against a comprehensive 16-test Pester test matrix:

| Test ID | Failure Scenario | Simulated Telemetry Input | Expected Co-Worker Action | Gate Verdict |
| :--- | :--- | :--- | :--- | :--- |
| **DR-01..DR-04** | Clean Regional Outage | UK South down; UK West lag `< 4s`; DNS converged | Stage cutover payload + Emit Adaptive Card | `PERMITTED` |
| **DR-05..DR-08** | Orderly Origin Drain | Active session drain verified; zero in-flight RPCs | Shift origin weights incrementally | `PERMITTED` |
| **DR-09..DR-11** | RPO Replication Lag Breach | Secondary Cosmos DB lag `= 38.4s` (`> 30s` ceiling) | Hard veto (`VETO_RPO_BREACH`) + Freeze cutover | `HARD VETO` |
| **DR-12..DR-14** | Asymmetric Route Drop | Standby spoke resolving private link to UK South VIP | Hard veto (`VETO_ASYMMETRIC_ROUTING`) | `HARD VETO` |
| **DR-15..DR-16** | Unauthenticated Mutation | Missing Resilience Architect Entra ID MFA claim | Reject execution (`HTTP 403 Forbidden`) | `HARD VETO` |

---

## Repository Structure

```
├── .github/workflows/ci.yml       # Automated Pester CI verification pipeline
├── diagnostics/
│   └── Telemetry-Queries.kql      # Azure Monitor / Log Analytics pre-flight KQL query
├── docs/
│   └── ADR-001-dr-circuit-breaker.md # Architectural Decision Record
├── infra/
│   └── main.bicep                 # Azure Container Apps & Cosmos DB multi-region IaC
├── src/
│   └── Invoke-AutonomousDrPreFlight.ps1 # Production PowerShell 7 failover evaluator
├── tests/
│   └── Boundary-Verification.Tests.ps1 # 16-Test Pester 5/6 Verification Matrix
├── LICENSE                        # MIT License
└── README.md                      # Architecture documentation
```

---

## Quickstart & Verification

### 1. Run the 16-Test Verification Suite

```powershell
# Execute offline deterministic Pester contract
Invoke-Pester -Path ./tests -Output Detailed
```

### 2. Execute Pre-Flight Evaluation Locally

```powershell
# Test pre-flight evaluator against mock secondary endpoint
./src/Invoke-AutonomousDrPreFlight.ps1 -AccountName "cosmos-resilience-uks" -StandbyRegion "UK West" -MaxRpoLagSeconds 30.0
```

### 3. Log Analytics Forensic Telemetry

Query real-time cross-region replication lag and asymmetric route drop counts in Azure Log Analytics:

```kql
// See diagnostics/Telemetry-Queries.kql for full query
let MaxAllowedLagSeconds = 30.0;
AzureMetrics
| where ResourceProvider == "MICROSOFT.DOCUMENTDB"
| where MetricName == "ReplicationLatency"
| where TimeGenerated > ago(3m)
| summarize MaxLagSeconds = max(Maximum) / 1000.0 by Resource
| extend CutoverVerdict = iff(MaxLagSeconds > MaxAllowedLagSeconds, "VETO_SPLIT_BRAIN_RISK", "STAGE_FOR_ARCHITECT_APPROVAL")
```

---

## Contributing & Governance

- All pull requests must pass the 16-test Pester matrix with zero regressions.
- All technical documentation follows British English orthography (*optimise, prioritise, standardise, behaviour*).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
