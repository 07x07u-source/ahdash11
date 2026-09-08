[CmdletBinding()]
param(
    [Parameter()]
    [string]$EnvironmentFile = (Join-Path $PSScriptRoot '..\mobile\.env')
)

$ErrorActionPreference = 'Stop'
$projectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$mobileRoot = Join-Path $projectRoot 'mobile'
$resolvedEnvironmentFile = [System.IO.Path]::GetFullPath($EnvironmentFile)

if (-not (Test-Path -LiteralPath $resolvedEnvironmentFile -PathType Leaf)) {
    throw 'Production environment file is required.'
}

foreach ($line in Get-Content -LiteralPath $resolvedEnvironmentFile) {
    if ($line -match '^\s*#' -or $line -notmatch '=') { continue }
    $parts = $line -split '=', 2
    $name = $parts[0].Trim()
    if ($name -notmatch '^[A-Z][A-Z0-9_]*$') { continue }
    $value = $parts[1].Trim().Trim('"').Trim("'")
    [Environment]::SetEnvironmentVariable($name, $value, 'Process')
}

Push-Location -LiteralPath $projectRoot
try {
    node scripts/check-release-integrations.mjs --env-file $resolvedEnvironmentFile
    if ($LASTEXITCODE -ne 0) {
        throw 'Production configuration validation failed. Release APK was not built.'
    }
}
finally {
    Pop-Location
}

Push-Location -LiteralPath $mobileRoot
try {
    flutter build apk --release "--dart-define-from-file=$resolvedEnvironmentFile"
    if ($LASTEXITCODE -ne 0) {
        throw "Release APK build failed with exit code $LASTEXITCODE."
    }
}
finally {
    Pop-Location
}
