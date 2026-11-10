# ADR-001: Fail-Closed Circuit Breakers in Automated Disaster Recovery

## Status
**Accepted** | Canonical Resilience Standard

## Context & Production Friction
In multi-region enterprise cloud topologies, high-availability designs frequently implement automated disaster recovery scripts that monitor primary ingress endpoints. When web probes detect consecutive failure responses (e.g. `HTTP 503` or timeout), the standard operational pattern has been an immediate, unthrottled cutover of Azure Front Door origin routing to the standby region.

However, during real-world cloud degradations, failures are rarely clean binary severances. Degradations typically exhibit:
1. High storage latency causing asynchronous database replication lag to widen.
2. Intermittent DNS propagation delays and route table flap across ExpressRoute private peerings.
3. Partial packet loss where primary nodes still accept writes while ingress times out.

Flipping traffic to a secondary stamp when the data tier replica is 30+ seconds behind commits causes silent data loss, split-brain state divergence, and catastrophic ledger corruption.

## Decision
We prohibit blind, un-gated automated failovers across our enterprise landing zones.
All regional disaster recovery orchestrators must implement an **Autonomous Fail-Closed Circuit Breaker**:
1. Before staging any origin weight shift or DNS cutover, the orchestrator must assert that secondary database replication latency is strictly under the 30.0-second RPO ceiling.
2. If replication latency breaches 30.0 seconds or route convergence errors are detected, automated cutover is **vetoed immediately**.
3. All cutover actions must be staged in decision memory and require explicit dual-signature MFA authorization from the designated Resilience Architect.

## Consequences & Trade-Offs
- **Positive**: Eradicates split-brain database corruption and prevents overwriting uncommitted financial transactions.
- **Accepted Friction**: Adds 90 to 140 seconds of pre-flight polling and human sign-off latency to total Recovery Time Objective (RTO). In production, waiting two minutes for verified consistency is vastly superior to hours of manual database reconciliation.
