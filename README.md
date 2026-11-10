# Autonomous Disaster Recovery: Cross-Region Azure Failover Co-Worker

[![Pester Verification](https://img.shields.io/badge/pester-16%2F16%20passing-brightgreen)](tests/DrPreFlight.Tests.ps1)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Architecture Deep-Dive](https://img.shields.io/badge/blog-alerasoul.net-0a1128)](https://alerasoul.net/autonomous-dr-failover-coworker/)

> **Primary Governance Artefact:** Cross-Region RTO/RPO Countdown Matrix  
> **Accountable Service Owner:** Principal Azure Infrastructure & Resilience Architect  
> **Full Architectural Deep-Dive:** [https://alerasoul.net/autonomous-dr-failover-coworker/](https://alerasoul.net/autonomous-dr-failover-coworker/)

---

## Repository Layout (13 Files)

```text
├── .github/workflows/pester-ci.yml
├── LICENSE
├── README.md
├── docs/ADR-001-dr-circuit-breaker.md
├── fixtures/uk-south-outage-telemetry.json
├── infra/cosmos-multiregion.bicep
├── infra/frontdoor-failover.bicep
├── queries/PrivateDns-SplitBrain.kql
├── queries/ReplicationLag-PreFlight.kql
├── runbooks/DR-FAILOVER-PLAYBOOK.md
├── src/Invoke-AutonomousDrPreFlight.ps1
├── src/Test-DrFailoverReadiness.ps1
└── tests/DrPreFlight.Tests.ps1
```

## Quickstart & Offline Verification

```powershell
# 1. Execute the primary PowerShell 7 evaluator
pwsh -NoProfile -File ./src/Invoke-AutonomousDrPreFlight.ps1

# 2. Run the 16-test Pester verification contract
Invoke-Pester -Path ./tests/DrPreFlight.Tests.ps1 -Output Detailed
```

## License

Released under the [MIT License](LICENSE). Authored by **Shahrad Alerasoul** ([alerasoul.net](https://alerasoul.net)).
