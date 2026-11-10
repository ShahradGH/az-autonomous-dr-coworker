# ADR-001: Fail-Closed Pre-Flight Verification for Cross-Region Failover

- **Status**: Accepted
- **Owner**: Principal Azure Infrastructure & Resilience Architect
- **Context**: Blind HTTP health probes flip DNS during storage degradation while database replication queues lag behind.
- **Decision**: Enforce deterministic Log Analytics KQL lag checks prior to Azure Front Door origin cutover.
