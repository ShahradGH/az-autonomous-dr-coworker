# Regional Disaster Recovery Failover Playbook (UK South -> UK West)

## 1. Pre-Flight Invariants
- **Cosmos DB Replication Lag**: Must be `<= 30.0s` before traffic cutover.
- **Private DNS Spoke Resolution**: Standby spokes in `ukwest` must resolve `privatelink.documents.azure.com` to local regional private endpoints.

## 2. Emergency Override
If `ReplicationLagSeconds > 30s`, automated Front Door origin weight shifting is vetoed and held for **Principal Azure Infrastructure & Resilience Architect** MFA sign-off.
