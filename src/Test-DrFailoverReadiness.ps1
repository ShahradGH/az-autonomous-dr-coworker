# Invoke-AutonomousDrPreFlight.ps1
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$AccountName,
    [Parameter(Mandatory)] [string]$StandbyRegion = 'UK West',
    [Parameter()] [double]$MaxRpoLagSeconds = 30.0
)

$ErrorActionPreference = 'Stop'
$metrics = Get-AzMetric -ResourceId "/subscriptions/$env:AZURE_SUBSCRIPTION_ID/resourceGroups/rg-core-data-uks/providers/Microsoft.DocumentDB/databaseAccounts/$AccountName" `
    -MetricName 'ReplicationLatency' `
    -TimeGrain 00:01:00 `
    -WarningAction SilentlyContinue

$latestLagSeconds = [math]::Round((($metrics.Data | Select-Object -Last 1).Maximum / 1000.0), 2)

if ($latestLagSeconds -gt $MaxRpoLagSeconds) {
    Write-Warning "[GATE: DENY] Standby region '$StandbyRegion' replication lag is ${latestLagSeconds}s (Ceiling: ${MaxRpoLagSeconds}s). Cutover frozen."
    return [PSCustomObject]@{
        Account        = $AccountName
        StandbyRegion  = $StandbyRegion
        LagSeconds     = $latestLagSeconds
        GateDecision   = 'VETO_RPO_BREACH'
        RequiresSignOff = $true
    }
}

return [PSCustomObject]@{
    Account        = $AccountName
    StandbyRegion  = $StandbyRegion
    LagSeconds     = $latestLagSeconds
    GateDecision   = 'HOLD_FOR_RESILIENCE_ARCHITECT_SIGN_OFF'
    RequiresSignOff = $true
}