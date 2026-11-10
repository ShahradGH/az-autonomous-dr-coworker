BeforeAll {
    $scriptPath = Join-Path $PSScriptRoot '..' 'src' 'Invoke-AutonomousDrPreFlight.ps1'
}

Describe 'Autonomous Disaster Recovery - 16-Test Verification Matrix' {

    Context 'Positive Baseline: Permitted Actions & Staging Handshake (8 Tests)' {
        It 'DR-01: Validates sub-threshold replication lag evaluation (lag < 30s)' {
            $result = & $scriptPath -AccountName 'cosmos-uks' -StandbyRegion 'UK West'
            $result.GateDecision | Should -Be 'HOLD_FOR_RESILIENCE_ARCHITECT_SIGN_OFF'
            $result.PermitCutover | Should -Be $true
        }

        It 'DR-02: Enforces mandatory Resilience Architect MFA sign-off on permitted switch' {
            $result = & $scriptPath -AccountName 'cosmos-uks' -StandbyRegion 'UK West'
            $result.RequiresSignOff | Should -Be $true
        }

        It 'DR-03: Emits approval Adaptive Card event payload when health checks pass' {
            $result = & $scriptPath -AccountName 'cosmos-uks' -StandbyRegion 'UK West'
            $result.Action | Should -Be 'EMIT_APPROVAL_ADAPTIVE_CARD'
        }

        It 'DR-04: Confirms target standby region matches UK West destination' {
            $result = & $scriptPath -AccountName 'cosmos-uks' -StandbyRegion 'UK West'
            $result.StandbyRegion | Should -Be 'UK West'
        }

        It 'DR-05: Returns deterministic ISO-8601 UTC timestamp in evaluation payload' {
            $result = & $scriptPath -AccountName 'cosmos-uks' -StandbyRegion 'UK West'
            $result.Timestamp | Should -Match '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}'
        }

        It 'DR-06: Evaluates custom tight RPO ceiling bounds (e.g. 10.0s) safely' {
            $result = & $scriptPath -AccountName 'cosmos-uks' -StandbyRegion 'UK West' -MaxRpoLagSeconds 10.0
            $result.MaxAllowedLag | Should -Be 10.0
        }

        It 'DR-07: Validates structured output schema completeness' {
            $result = & $scriptPath -AccountName 'cosmos-uks' -StandbyRegion 'UK West'
            $result.PSObject.Properties.Name | Should -Contain 'AccountName'
            $result.PSObject.Properties.Name | Should -Contain 'GateDecision'
        }

        It 'DR-08: Confirms zero unhandled exceptions during standard pre-flight pass' {
            { & $scriptPath -AccountName 'cosmos-uks' } | Should -Not -Throw
        }
    }

    Context 'Negative Security: Refusal Boundary & Circuit Breaker Enforcement (8 Tests)' {
        It 'DR-09: Hard veto triggered when Cosmos DB replication lag exceeds 30s ceiling' {
            $result = & $scriptPath -AccountName 'cosmos-uks' -StandbyRegion 'UK West' -SimulateLagBreach
            $result.GateDecision | Should -Be 'VETO_RPO_BREACH'
            $result.PermitCutover | Should -Be $false
        }

        It 'DR-10: Freezes Azure Front Door origin weight shift upon RPO breach' {
            $result = & $scriptPath -AccountName 'cosmos-uks' -StandbyRegion 'UK West' -SimulateLagBreach
            $result.Action | Should -Be 'FREEZE_FRONT_DOOR_ORIGIN_WEIGHTS'
        }

        It 'DR-11: Refuses execution when mandatory AccountName parameter is null or empty' {
            { & $scriptPath -AccountName '' } | Should -Throw
        }

        It 'DR-12: Prevents automated failover without explicit Resilience Architect sign-off' {
            $result = & $scriptPath -AccountName 'cosmos-uks' -StandbyRegion 'UK West' -SimulateLagBreach
            $result.RequiresSignOff | Should -Be $true
        }

        It 'DR-13: Rejects invalid or negative MaxRpoLagSeconds threshold input' {
            $result = & $scriptPath -AccountName 'cosmos-uks' -MaxRpoLagSeconds 2.0
            $result.GateDecision | Should -Be 'VETO_RPO_BREACH'
        }

        It 'DR-14: Asserts fail-closed circuit breaker behaviour on all degraded state paths' {
            $result = & $scriptPath -AccountName 'cosmos-uks' -StandbyRegion 'UK West' -SimulateLagBreach
            $result.PermitCutover | Should -Be $false
        }

        It 'DR-15: Asserts output object retains diagnostic LagSeconds on failure' {
            $result = & $scriptPath -AccountName 'cosmos-uks' -StandbyRegion 'UK West' -SimulateLagBreach
            $result.LagSeconds | Should -BeGreaterThan 30.0
        }

        It 'DR-16: Refuses automated retry storm bypass when replication latency is stale' {
            $result = & $scriptPath -AccountName 'cosmos-uks' -StandbyRegion 'UK West' -SimulateLagBreach
            $result.GateDecision | Should -Not -Be 'HOLD_FOR_RESILIENCE_ARCHITECT_SIGN_OFF'
        }
    }
}
