<#
.SYNOPSIS
    Syncs Azure Networking articles from a local azure-docs-pr clone into raw/articles/.

.DESCRIPTION
    Copies networking service article folders from azure-docs-pr into raw/articles/
    and updates raw/manifest.json with sync metadata.

.PARAMETER SourceRepo
    Path to your local azure-docs-pr clone. Defaults to C:\GitHub\azure-docs-pr

.PARAMETER Services
    Array of service folder names to sync. Defaults to all 13 networking services.

.EXAMPLE
    .\sync-raw.ps1
    .\sync-raw.ps1 -SourceRepo D:\repos\azure-docs-pr
    .\sync-raw.ps1 -Services @('virtual-network', 'expressroute')
#>

[CmdletBinding()]
param(
    [string]$SourceRepo = 'C:\GitHub\azure-docs-pr',
    [string[]]$Services = @(
        'networking',
        'virtual-network',
        'expressroute',
        'vpn-gateway',
        'firewall',
        'application-gateway',
        'load-balancer',
        'nat-gateway',
        'bastion',
        'private-link',
        'ddos-protection',
        'dns',
        'network-watcher',
        'frontdoor',
        'traffic-manager',
        'virtual-wan',
        'route-server',
        'web-application-firewall',
        'firewall-manager',
        'virtual-network-manager',
        'internet-peering',
        'peering-service',
        'network-function-manager'
    )
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path $PSScriptRoot -Parent
$RawArticlesDir = Join-Path $RepoRoot 'raw\articles'
$ManifestPath = Join-Path $RepoRoot 'raw\manifest.json'

# Validate source repo
if (-not (Test-Path $SourceRepo)) {
    Write-Error "azure-docs-pr not found at: $SourceRepo`nSet -SourceRepo to your local clone path."
    exit 1
}

$manifest = Get-Content $ManifestPath | ConvertFrom-Json
$syncDate = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
$articlesSynced = @()

foreach ($service in $Services) {
    $sourceDir = Join-Path $SourceRepo "articles\$service"
    $destDir = Join-Path $RawArticlesDir $service

    if (-not (Test-Path $sourceDir)) {
        Write-Warning "Service folder not found, skipping: $sourceDir"
        continue
    }

    Write-Host "Syncing: $service" -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null

    $mdFiles = Get-ChildItem -Path $sourceDir -Filter '*.md' -Recurse
    foreach ($file in $mdFiles) {
        $relativePath = $file.FullName.Substring($SourceRepo.Length + 1).Replace('\', '/')
        $destFile = Join-Path $destDir ($file.FullName.Substring($sourceDir.Length + 1))

        # Ensure dest subdirectory exists
        $destFileDir = Split-Path $destFile -Parent
        New-Item -ItemType Directory -Path $destFileDir -Force | Out-Null

        Copy-Item -Path $file.FullName -Destination $destFile -Force

        # Extract ms.date from frontmatter
        $content = Get-Content $file.FullName -Raw
        $msDate = $null
        if ($content -match 'ms\.date:\s*([\d/]+)') {
            $msDate = $Matches[1]
        }

        $articlesSynced += [PSCustomObject]@{
            path        = "raw/articles/$relativePath"
            source_path = $relativePath
            service     = $service
            ms_date     = $msDate
            synced_at   = $syncDate
            wiki_page   = $null
        }
    }

    Write-Host "  Synced $($mdFiles.Count) articles" -ForegroundColor Green
}

# Update manifest
$manifest.last_sync = $syncDate
$manifest.articles = $articlesSynced
$manifest | ConvertTo-Json -Depth 5 | Set-Content $ManifestPath

$total = $articlesSynced.Count
Write-Host "`nSync complete: $total articles across $($Services.Count) services" -ForegroundColor Green
Write-Host "Manifest updated: $ManifestPath"
Write-Host "`nNext step: Ask Atlas to compile wiki pages from the synced articles."
