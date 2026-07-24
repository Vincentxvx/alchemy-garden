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

Write-Host "Reading Claude Code usage via ccusage..."
$raw = npx -y ccusage@latest session --json
if (-not $raw) { Write-Host "ccusage returned no output."; exit 1 }

try { $json = $raw | ConvertFrom-Json }
catch {
    $dump = Join-Path $env:TEMP "ccusage-raw.txt"
    $raw | Out-File -Encoding ascii $dump
    Write-Host "Could not parse ccusage output as JSON. Raw saved to: $dump"
    exit 1
}

# ccusage nests the per-session array under .session
$entries = $json.session
if (-not $entries) { $entries = $json.data }
if (-not $entries) { $entries = $json }

$latest = $entries |
    Sort-Object { [datetime]$_.metadata.lastActivity } -Descending |
    Select-Object -First 1

if (-not $latest) { Write-Host "No sessions found."; exit 1 }

$inTok  = [int64]$latest.inputTokens
$outTok = [int64]$latest.outputTokens
$cacheR = [int64]$latest.cacheReadTokens
$cacheW = [int64]$latest.cacheCreationTokens
$cost   = [double]$latest.totalCost
$total  = if ($latest.totalTokens) { [int64]$latest.totalTokens } else { $inTok + $outTok + $cacheR + $cacheW }

$models = $latest.modelsUsed
if ($models -is [array]) { $models = ($models -join ", ") }
if (-not $models) { $models = "-" }
$models = ($models -replace "claude-", "" -replace "-\d{8}", "")

$when = ([datetime]$latest.metadata.lastActivity).ToLocalTime()
$date = $when.ToString("yyyy-MM-dd")
$costStr = if ($cost -gt 0) { "`$" + ([math]::Round($cost, 2)) } else { "-" }

$row = "| {0} | {1} | {2} | {3:N0} | {4:N0} | {5:N0} | {6:N0} | {7:N0} | {8} |" -f `
    $Phase, $date, $models, $inTok, $outTok, $cacheR, $cacheW, $total, $costStr

Write-Host ""
Write-Host ("Session {0}  (last activity {1})" -f $latest.period, $when)
Write-Host $row

Add-Content -Path $usageFile -Encoding ascii -Value $row
Write-Host ""
Write-Host "Appended to USAGE.md."