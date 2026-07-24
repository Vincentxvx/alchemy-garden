# log-usage.ps1 - append the latest Claude Code session's token usage to USAGE.md
# Usage:  .\scripts\log-usage.ps1 "Phase 1"

param(
    [Parameter(Mandatory = $true)][string]$Phase
)

$ErrorActionPreference = "Stop"

$repo      = Split-Path -Parent $PSScriptRoot
$usageFile = Join-Path $repo "USAGE.md"

if (-not (Test-Path $usageFile)) {
    Write-Host "USAGE.md not found at $usageFile"
    exit 1
}

Write-Host "Reading Claude Code usage via ccusage (first run downloads the package)..."
$raw = npx -y ccusage@latest session --json
if (-not $raw) {
    Write-Host "ccusage returned no output."
    exit 1
}

try {
    $json = $raw | ConvertFrom-Json
} catch {
    $dump = Join-Path $env:TEMP "ccusage-raw.txt"
    $raw | Out-File -Encoding ascii $dump
    Write-Host "Could not parse ccusage output as JSON. Raw output saved to: $dump"
    exit 1
}

$entries = if ($json.data) { $json.data } else { $json }

$mine = $entries | Where-Object { ($_ | ConvertTo-Json -Compress -Depth 6) -like "*alchemy-garden*" }
if (-not $mine) { $mine = $entries }
$latest = $mine | Select-Object -Last 1

if (-not $latest) {
    Write-Host "No sessions found. Have you run a Claude Code session in this repo yet?"
    exit 1
}

function Get-Field($obj, [string[]]$names) {
    foreach ($n in $names) {
        if ($null -ne $obj.$n) { return $obj.$n }
    }
    return 0
}

$inTok  = Get-Field $latest @("inputTokens", "input_tokens")
$outTok = Get-Field $latest @("outputTokens", "output_tokens")
$cacheR = Get-Field $latest @("cacheReadTokens", "cacheReadInputTokens", "cache_read_input_tokens")
$cacheW = Get-Field $latest @("cacheCreationTokens", "cacheCreationInputTokens", "cache_creation_input_tokens")
$cost   = Get-Field $latest @("totalCost", "costUSD", "cost")
$models = Get-Field $latest @("modelsUsed", "models", "model")

if ($models -is [array]) { $models = ($models -join ", ") }
if (-not $models) { $models = "-" }
$models = ($models -replace "claude-", "" -replace "-\d{8}", "")

if (($inTok -eq 0) -and ($outTok -eq 0)) {
    $dump = Join-Path $env:TEMP "ccusage-session.json"
    $latest | ConvertTo-Json -Depth 8 | Out-File -Encoding ascii $dump
    Write-Host "Found a session but no recognizable token fields."
    Write-Host "Saved that session's JSON to: $dump"
    Write-Host "Send that file's contents to Claude and the field names can be fixed."
    exit 1
}

$total = [int64]$inTok + [int64]$outTok + [int64]$cacheR + [int64]$cacheW
$date  = Get-Date -Format "yyyy-MM-dd"
$costStr = if ($cost -gt 0) { "`$" + ([math]::Round([double]$cost, 2)) } else { "-" }

$row = "| {0} | {1} | {2} | {3:N0} | {4:N0} | {5:N0} | {6:N0} | {7:N0} | {8} |" -f `
    $Phase, $date, $models, [int64]$inTok, [int64]$outTok, [int64]$cacheR, [int64]$cacheW, $total, $costStr

Add-Content -Path $usageFile -Encoding ascii -Value $row

Write-Host ""
Write-Host "Appended to USAGE.md:"
Write-Host $row