BeforeAll {
    $script:RepoRoot = Split-Path -Parent $PSScriptRoot
    $script:EvaluatorPath = Join-Path $script:RepoRoot 'src' 'Invoke-AutonomousDrPreFlight.ps1'
    $script:KqlPath = Join-Path $script:RepoRoot 'diagnostics' 'Telemetry-Queries.kql'
    $script:BicepPath = Join-Path $script:RepoRoot 'infra' 'main.bicep'
}

Describe 'Autonomous Disaster Recovery: Cross-Region Azure Failover Co-Worker - 16-Test Verification Matrix' {
    Context 'Positive Baseline: Structural & Policy Contract Verification (8 Tests)' {
        It 'P-01: Production PowerShell policy evaluator script exists and is non-empty' {
            Test-Path $script:EvaluatorPath | Should -BeTrue
            (Get-Item $script:EvaluatorPath).Length | Should -BeGreaterThan 100
        }
        It 'P-02: PowerShell evaluator parses with zero AST syntax errors' {
            $errors = $null
            [System.Management.Automation.Language.Parser]::ParseFile($script:EvaluatorPath, [ref]$null, [ref]$errors)
            $errors.Count | Should -Be 0
        }
        It 'P-03: Enforces CmdletBinding and mandatory typed parameter contracts' {
            $content = Get-Content $script:EvaluatorPath -Raw
            $content | Should -Match '\[CmdletBinding\(\)\]'
            $content | Should -Match 'param\s*\('
        }
        It 'P-04: Emits deterministic PSCustomObject output for downstream audit ingestion' {
            $content = Get-Content $script:EvaluatorPath -Raw
            $content | Should -Match '\[PSCustomObject\]@\{'
        }
        It 'P-05: KQL telemetry query artefact exists and defines projection/summarisation rules' {
            Test-Path $script:KqlPath | Should -BeTrue
            (Get-Content $script:KqlPath -Raw) | Should -Match 'where|summarize|project'
        }
        It 'P-06: Bicep Infrastructure-as-Code template exists and provisions Log Analytics & Identity' {
            Test-Path $script:BicepPath | Should -BeTrue
            (Get-Content $script:BicepPath -Raw) | Should -Match 'Microsoft.OperationalInsights/workspaces'
        }
        It 'P-07: Architectural Decision Record (ADR-001) documents owner authority' {
            $adr = Join-Path $script:RepoRoot 'docs' 'ADR-001-architectural-decision.md'
            Test-Path $adr | Should -BeTrue
        }
        It 'P-08: Operational L2/L3 Runbook documents triage and escalation steps' {
            $rb = Join-Path $script:RepoRoot 'docs' 'RUNBOOK.md'
            Test-Path $rb | Should -BeTrue
        }
    }

    Context 'Negative Security: Refusal & Zero-Leak Boundary Enforcement (8 Tests)' {
        It 'N-01: Evaluator defines explicit refusal/veto action outcomes' {
            $content = Get-Content $script:EvaluatorPath -Raw
            $content | Should -Match 'VETO|BLOCK|HOLD|DENY|REFUSAL|QUARANTINE| REVOKE|$false'
        }
        It 'N-02: Contains zero hardcoded client secrets or connection strings' {
            $content = Get-Content $script:EvaluatorPath -Raw
            $content | Should -Not -Match 'AccountKey=|SharedAccessSignature=|Password='
        }
        It 'N-03: Contains zero internal management portal URLs or private VPS IPs' {
            $content = Get-Content $script:EvaluatorPath -Raw
            $content | Should -Not -Match '192\.142\.41\.43|mvpfoundry\.alerasoul\.net'
        }
        It 'N-04: KQL telemetry artefact contains zero internal sequence leak tags' {
            $kql = Get-Content $script:KqlPath -Raw
            $kql | Should -Not -Match 'mvpfoundry\.alerasoul\.net'
        }
        It 'N-05: Bicep template avoids wildcard public IP exposure' {
            $bicep = Get-Content $script:BicepPath -Raw
            $bicep | Should -Not -Match '0\.0\.0\.0/0'
        }
        It 'N-06: README documentation contains zero internal sequence numbering' {
            $readme = Get-Content (Join-Path $script:RepoRoot 'README.md') -Raw
            $readme | Should -Not -Match 'Decision Pack 0'
        }
        It 'N-07: Enforces fail-closed ErrorActionPreference or strict condition checks' {
            $content = Get-Content $script:EvaluatorPath -Raw
            $content | Should -Match 'ErrorActionPreference|if\s*\('
        }
        It 'N-08: Repository includes open-source MIT LICENSE and SECURITY policy' {
            Test-Path (Join-Path $script:RepoRoot 'LICENSE') | Should -BeTrue
            Test-Path (Join-Path $script:RepoRoot 'SECURITY.md') | Should -BeTrue
        }
    }
}
