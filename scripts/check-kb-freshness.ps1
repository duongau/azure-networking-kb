#!/usr/bin/env pwsh
#
# check-kb-freshness.ps1 — KB Staleness Detector
#
# Compares the newest ms.date in each service's raw source articles against
# the "Last compiled" date embedded in each wiki page header. Flags wiki pages
# where source articles are newer than the compiled page.
#
# Usage:
#   .\scripts\check-kb-freshness.ps1              # full report
#   .\scripts\check-kb-freshness.ps1 -Service nat-gateway   # single service
#   .\scripts\check-kb-freshness.ps1 -Threshold 30          # flag if >30 days stale
#
[CmdletBinding()]
param(
    [string]$Service = "",
    [int]$Threshold = 0,  # days; 0 = flag any source newer than compiled date
    [switch]$StaleOnly
)

$RepoRoot   = Split-Path $PSScriptRoot -Parent
$RawDir     = Join-Path $RepoRoot "raw\articles"
$WikiDir    = Join-Path $RepoRoot "wiki"
$ServicesDir = Join-Path $WikiDir "services"

# Raw folder name → wiki filename overrides (when they differ)
$WikiPageOverrides = @{
    "firewall"        = "azure-firewall.md"
    "frontdoor"       = "front-door.md"
    "network-manager" = "virtual-network-manager.md"
    "networking"      = $null  # cross-service source only; no dedicated wiki page
    "ddos"            = "ddos-protection.md"
}

# ── Helpers ────────────────────────────────────────────────────────────────

function Get-FrontmatterDate([string]$FilePath, [string]$Field) {
    $content = Get-Content $FilePath -TotalCount 20 -ErrorAction SilentlyContinue
    foreach ($line in $content) {
        if ($line -match "^$Field\s*:\s*(.+)$") {
            $val = $Matches[1].Trim().Trim('"').Trim("'")
            try { return [datetime]::Parse($val) } catch { return $null }
        }
    }
    return $null
}

function Get-WikiCompiledDate([string]$FilePath) {
    $content = Get-Content $FilePath -TotalCount 5 -ErrorAction SilentlyContinue
    foreach ($line in $content) {
        # Matches: **Compiled:** 2026-04-10  OR  Compiled: 2026-04-10
        if ($line -match '\*{0,2}Compiled:\*{0,2}\s*(\d{4}-\d{2}-\d{2})') {
            try { return [datetime]::Parse($Matches[1]) } catch { return $null }
        }
    }
    return $null
}

function Get-NewestArticleDate([string]$ServiceDir) {
    $articles = Get-ChildItem $ServiceDir -Recurse -Filter "*.md" -ErrorAction SilentlyContinue
    $newest = $null
    foreach ($a in $articles) {
        $d = Get-FrontmatterDate $a.FullName "ms.date"
        if ($d -and ($null -eq $newest -or $d -gt $newest)) { $newest = $d }
    }
    return $newest
}

# ── Discover services ──────────────────────────────────────────────────────

$services = if ($Service) {
    @($Service)
} else {
    Get-ChildItem $RawDir -Directory | Select-Object -ExpandProperty Name
}

# ── Scan ──────────────────────────────────────────────────────────────────

$results = @()
$today   = [datetime]::Today

foreach ($svc in $services) {
    $rawSvcDir  = Join-Path $RawDir $svc

    # Resolve wiki page path — check overrides first, then default to $svc.md
    $wikiFilename = if ($WikiPageOverrides.ContainsKey($svc)) {
        $WikiPageOverrides[$svc]  # null means intentionally skip
    } else {
        "$svc.md"
    }
    $wikiPage = if ($wikiFilename) { Join-Path $ServicesDir $wikiFilename } else { $null }

    if (-not (Test-Path $rawSvcDir)) { continue }

    # Skip cross-service folders that intentionally have no wiki page
    if ($null -eq $wikiPage) {
        if (-not $StaleOnly) {
            $results += [PSCustomObject]@{
                Service       = $svc
                Articles      = (Get-ChildItem $rawSvcDir -Recurse -Filter "*.md" -ErrorAction SilentlyContinue).Count
                NewestSource  = "—"
                WikiCompiled  = "—"
                Status        = "ℹ️  source only (no wiki page)"
            }
        }
        continue
    }

    $newestSource = Get-NewestArticleDate $rawSvcDir
    $compiledDate = if (Test-Path $wikiPage) { Get-WikiCompiledDate $wikiPage } else { $null }

    $articleCount = (Get-ChildItem $rawSvcDir -Recurse -Filter "*.md" -ErrorAction SilentlyContinue).Count

    $status = if (-not (Test-Path $wikiPage)) {
        "❌ no wiki page"
    } elseif (-not $compiledDate) {
        "⚠️  no compiled date"
    } elseif (-not $newestSource) {
        "⚠️  no ms.date in sources"
    } elseif ($newestSource -gt $compiledDate.AddDays($Threshold)) {
        $lagDays = ($newestSource - $compiledDate).Days
        "🔴 stale ($lagDays days behind)"
    } else {
        "✅ current"
    }

    $results += [PSCustomObject]@{
        Service       = $svc
        Articles      = $articleCount
        NewestSource  = if ($newestSource) { $newestSource.ToString("yyyy-MM-dd") } else { "—" }
        WikiCompiled  = if ($compiledDate)  { $compiledDate.ToString("yyyy-MM-dd")  } else { "—" }
        Status        = $status
    }
}

# ── Output ────────────────────────────────────────────────────────────────

$filtered = if ($StaleOnly) { $results | Where-Object { $_.Status -notlike "✅*" } } else { $results }

Write-Host ""
Write-Host "Azure Networking KB — Freshness Report" -ForegroundColor Cyan
Write-Host "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor DarkGray
Write-Host "Threshold: $($Threshold) days" -ForegroundColor DarkGray
Write-Host ""

$filtered | Format-Table -AutoSize

$staleCount   = ($results | Where-Object { $_.Status -like "*stale*" }).Count
$missingCount = ($results | Where-Object { $_.Status -like "*no wiki*" }).Count
$currentCount = ($results | Where-Object { $_.Status -like "✅*" }).Count

Write-Host "Summary: $currentCount current · $staleCount stale · $missingCount no page" -ForegroundColor $(
    if ($staleCount -gt 0 -or $missingCount -gt 0) { "Yellow" } else { "Green" }
)
Write-Host ""

if ($staleCount -gt 0) {
    Write-Host "To recompile stale pages, ask Atlas:" -ForegroundColor Yellow
    $results | Where-Object { $_.Status -like "*stale*" } | ForEach-Object {
        $svc = $_.Service
        $fname = if ($WikiPageOverrides.ContainsKey($svc) -and $WikiPageOverrides[$svc]) {
            $WikiPageOverrides[$svc]
        } else {
            "$svc.md"
        }
        Write-Host "  Atlas, recompile wiki/services/$fname" -ForegroundColor DarkYellow
    }
    Write-Host ""
}
