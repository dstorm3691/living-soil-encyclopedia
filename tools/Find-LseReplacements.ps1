<#
.SYNOPSIS
    For every rights-flagged image, finds clean-licensed images already on
    disk that could replace it.

.DESCRIPTION
    Reads INVENTORY/rights_parsed.csv and INVENTORY/images.csv. Matches on
    subject keywords pulled from filenames. Read-only.

.EXAMPLE
    .\Find-LseReplacements.ps1
#>

[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$InventoryDir,
    [int]$TopN = 6
)

$ErrorActionPreference = 'Stop'

if (-not $RepoRoot) {
    $d = (& git rev-parse --show-toplevel 2>$null)
    if ($LASTEXITCODE -ne 0) { Write-Host "Not in a git repo." -ForegroundColor Red; exit 1 }
    $RepoRoot = $d.Trim() -replace '/', '\'
}
$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
if (-not $InventoryDir) { $InventoryDir = Join-Path $RepoRoot 'INVENTORY' }

$rightsCsv = Join-Path $InventoryDir 'rights_parsed.csv'
$imgsCsv   = Join-Path $InventoryDir 'images.csv'
foreach ($f in @($rightsCsv, $imgsCsv)) {
    if (-not (Test-Path -LiteralPath $f)) { Write-Host "Missing $f" -ForegroundColor Red; exit 1 }
}

$rights = Import-Csv -LiteralPath $rightsCsv
$allImgs = Import-Csv -LiteralPath $imgsCsv

# Tokens that carry no subject meaning
$Noise = @(
    'lse','found','b26','b27','b28','b29','b30','hold','verify','permission','reject',
    'conditional','lowres','jpg','png','cc','by','sa','nc','pd','gfdl','usda','cc0',
    'publicuse','bugwood','0','1','2','3','4','5','us','and','the','of','uci'
)

function Get-Subject {
    param([string]$Name)
    $stem = [System.IO.Path]::GetFileNameWithoutExtension($Name)
    # split on underscores and on camelCase boundaries
    $parts = $stem -split '[_\-]+'
    $out = New-Object System.Collections.Generic.List[string]
    foreach ($p in $parts) {
        foreach ($w in ($p -creplace '([a-z0-9])([A-Z])', '$1 $2') -split ' ') {
            $lw = $w.ToLower() -replace '[^a-z]', ''
            if ($lw.Length -lt 3) { continue }
            if ($Noise -contains $lw) { continue }
            if (-not $out.Contains($lw)) { [void]$out.Add($lw) }
        }
    }
    return $out
}

# Clean = safe to use under free non-commercial, no problem flag
function Test-CleanLicense {
    param([string]$Name)
    $s = $Name
    if ($s -match '(?i)_(REJECT|VERIFY|PERMISSION|CONDITIONAL)(_|\.)') { return $false }
    if ($s -match '(?i)CC0|USDA-PD|CC-BY-[234]|CC-BY\b') {
        if ($s -match '(?i)CC-BY-NC') { return $false }
        return $true
    }
    if ($s -match '^UCI_\d+' -or $s -match '^LSE_[A-E]\d+') { return $true }  # self-created
    return $false
}

# Everything in the repo already in use
$inUse = @{}
foreach ($r in $rights) { $inUse[$r.filename.ToLower()] = $true }

# Candidate pool: any image anywhere, clean license, not already used in the book
$pool = @()
foreach ($im in $allImgs) {
    if ($inUse.ContainsKey($im.filename.ToLower())) { continue }
    if (-not (Test-CleanLicense -Name $im.filename)) { continue }
    $pool += [pscustomobject]@{
        filename = $im.filename
        path     = $im.path
        location = $im.location
        width    = [int]$im.width
        height   = [int]$im.height
        bytes    = [int64]$im.bytes
        subject  = (Get-Subject -Name $im.filename)
    }
}

Write-Host ""
Write-Host "Candidate pool (clean license, not currently in the book): $($pool.Count)" -ForegroundColor Cyan
Write-Host ""

$problems = @($rights | Where-Object { $_.verdict -eq 'BLOCKER' -or $_.verdict -eq 'check' })
Write-Host "Rights-flagged images to find replacements for: $($problems.Count)"
Write-Host ""

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("# Replacement Candidates")
[void]$sb.AppendLine()
[void]$sb.AppendLine("Generated: $((Get-Date).ToString('u'))")
[void]$sb.AppendLine()
[void]$sb.AppendLine("For each rights-flagged image, clean-licensed images already on disk")
[void]$sb.AppendLine("ranked by subject-keyword overlap. A high score means the filenames")
[void]$sb.AppendLine("describe similar subjects. It does not mean the photo is equivalent.")
[void]$sb.AppendLine("**Look at any candidate before swapping it in.**")
[void]$sb.AppendLine()
[void]$sb.AppendLine("Candidate pool size: $($pool.Count)")
[void]$sb.AppendLine()
[void]$sb.AppendLine("---")
[void]$sb.AppendLine()

$anyFound = 0
$noneFound = New-Object System.Collections.Generic.List[string]

foreach ($p in ($problems | Sort-Object verdict, filename)) {
    $subj = Get-Subject -Name $p.filename
    $scored = @()
    foreach ($c in $pool) {
        $overlap = @($subj | Where-Object { $c.subject -contains $_ })
        if ($overlap.Count -ge 2) {
            $scored += [pscustomobject]@{
                score = $overlap.Count
                terms = ($overlap -join ', ')
                cand  = $c
            }
        }
    }
    $top = @($scored | Sort-Object @{E={$_.score};D=$true}, @{E={$_.cand.width * $_.cand.height};D=$true} | Select-Object -First $TopN)

    [void]$sb.AppendLine("## [$($p.verdict)] ``$($p.filename)``")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("- Problem: $(if ($p.status_flag) { $p.status_flag } else { 'no clear license' })$(if ($p.ledger) { " ($($p.ledger))" })")
    [void]$sb.AppendLine("- License in filename: $(if ($p.license) { $p.license } else { 'none' })")
    [void]$sb.AppendLine("- Used by: $($p.used_by)")
    [void]$sb.AppendLine("- Subject terms: $(($subj) -join ', ')")
    [void]$sb.AppendLine()

    if ($top.Count -eq 0) {
        [void]$sb.AppendLine("**No candidate on disk.** Source externally or drop.")
        [void]$sb.AppendLine()
        $noneFound.Add($p.filename)
    }
    else {
        $anyFound++
        [void]$sb.AppendLine("| score | matched on | candidate | dims | loc |")
        [void]$sb.AppendLine("|---:|---|---|---|---|")
        foreach ($t in $top) {
            [void]$sb.AppendLine("| $($t.score) | $($t.terms) | ``$($t.cand.filename)`` | $($t.cand.width)x$($t.cand.height) | $($t.cand.location) |")
        }
        [void]$sb.AppendLine()
        [void]$sb.AppendLine("CHOICE: [ ]  (filename, or ``none``, or ``drop``)")
        [void]$sb.AppendLine()
    }
    [void]$sb.AppendLine("---")
    [void]$sb.AppendLine()
}

[void]$sb.AppendLine("## No on-disk candidate")
[void]$sb.AppendLine()
[void]$sb.AppendLine("These need an external source or have to be dropped. Best free sources")
[void]$sb.AppendLine("for plant pathology and horticulture imagery:")
[void]$sb.AppendLine()
[void]$sb.AppendLine("- **USDA ARS Image Gallery** — US government work, public domain")
[void]$sb.AppendLine("- **Bugwood Image Database** — mostly CC-BY, check each image's terms")
[void]$sb.AppendLine("- **Wikimedia Commons** — filter to CC0, CC-BY, or CC-BY-SA")
[void]$sb.AppendLine("- **Flickr** — filter to Commercial use and mods allowed")
[void]$sb.AppendLine()
foreach ($n in $noneFound) { [void]$sb.AppendLine("- ``$n``") }
[void]$sb.AppendLine()

$out = Join-Path $InventoryDir 'replacement_candidates.md'
$sb.ToString() | Set-Content -LiteralPath $out -Encoding UTF8

Write-Host "With on-disk candidates: $anyFound" -ForegroundColor Green
Write-Host "With none:               $($noneFound.Count)" -ForegroundColor Yellow
Write-Host ""
Write-Host "Report: $out" -ForegroundColor Cyan
Write-Host ""
