[CmdletBinding()]
param(
    [switch]$SkipInstall,
    [switch]$SkipBuild
)

$ErrorActionPreference = 'Stop'
$projectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))

function Test-Command {
    param([Parameter(Mandatory)][string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Invoke-InDirectory {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][scriptblock]$Action
    )

    Push-Location -LiteralPath $Path
    try {
        & $Action
        if ($LASTEXITCODE -ne 0) {
            throw "Command failed in $Path with exit code $LASTEXITCODE"
        }
    }
    finally {
        Pop-Location
    }
}

$missing = [System.Collections.Generic.List[string]]::new()
foreach ($tool in @('node', 'npm', 'flutter', 'dart')) {
    if (-not (Test-Command $tool)) {
        $missing.Add($tool)
    }
}

if ($missing.Count -gt 0) {
    Write-Warning "Missing tools: $($missing -join ', '). Available suites will still run."
}

if ((Test-Command 'node') -and (Test-Command 'npm')) {
    Invoke-InDirectory (Join-Path $projectRoot 'admin') {
        if (-not $SkipInstall) { npm install }
        npm run lint
        npm test
        if (-not $SkipBuild) { npm run build }
    }
}

if ((Test-Command 'flutter') -and (Test-Command 'dart')) {
    Invoke-InDirectory (Join-Path $projectRoot 'mobile') {
        if (-not $SkipInstall) { flutter pub get }
        dart format --output=none --set-exit-if-changed .
        flutter analyze --fatal-infos
        flutter test --coverage
    }
}

if (Test-Command 'deno') {
    Invoke-InDirectory $projectRoot {
        deno fmt --check supabase/functions
        deno check supabase/functions/*/index.ts
    }
}
else {
    Write-Warning 'Deno is not installed; Edge Function format/type checks were skipped.'
}

if (Test-Command 'supabase') {
    Invoke-InDirectory $projectRoot {
        supabase db reset
        supabase test db
    }
}
else {
    Write-Warning 'Supabase CLI is not installed; database reset and pgTAP tests were skipped.'
}

Write-Host 'Verification completed for all installed toolchains.' -ForegroundColor Green
