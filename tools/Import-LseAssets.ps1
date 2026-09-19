<#
.SYNOPSIS
    Copies every image the repo's books reference but do not have, into the
    exact path the HTML already expects.

.DESCRIPTION
    Reads INVENTORY/references.csv and INVENTORY/images.csv produced by
    Invoke-LseCensus.ps1. Writes a manifest first. Copies nothing unless
    -Execute is passed. Never modifies any HTML. Never touches the source
    folders. Verifies SHA-256 after every copy.

.EXAMPLE
    # dry run, writes the manifest only
    .\Import-LseAssets.ps1

.EXAMPLE
    # review the manifest, then actually copy
    .\Import-LseAssets.ps1 -Execute
#>

[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$InventoryDir,
    [switch]$Execute
)

$ErrorActionPreference = 'Stop'

if (-not $RepoRoot) {
    $d = (& git rev-parse --show-toplevel 2>$null)
    if ($LASTEXITCODE -ne 0 -or -not $d) {
        Write-Host "Not in a git repo. Pass -RepoRoot." -ForegroundColor Red
        exit 1
    }
    $RepoRoot = $d.Trim() -replace '/', '\'
}
$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
if (-not $InventoryDir) { $InventoryDir = Join-Path $RepoRoot 'INVENTORY' }

$refsCsv = Join-Path $InventoryDir 'references.csv'
$imgsCsv = Join-Path $InventoryDir 'images.csv'
foreach ($f in @($refsCsv, $imgsCsv)) {
    if (-not (Test-Path -LiteralPath $f)) {
        Write-Host "Missing $f. Run Invoke-LseCensus.ps1 first." -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "Repo:      $RepoRoot"
Write-Host "Inventory: $InventoryDir"
Write-Host "Mode:      $(if ($Execute) { 'EXECUTE' } else { 'DRY RUN' })" -ForegroundColor $(if ($Execute) { 'Yellow' } else { 'Cyan' })
Write-Host ""

$refs = Import-Csv -LiteralPath $refsCsv
$imgs = Import-Csv -LiteralPath $imgsCsv

$imgByPath = @{}
foreach ($i in $imgs) { $imgByPath[$i.path] = $i }

$imgByLeaf = @{}
foreach ($i in $imgs) {
    $k = $i.filename.ToLower()
    if (-not $imgByLeaf.ContainsKey($k)) { $imgByLeaf[$k] = New-Object System.Collections.Generic.List[object] }
    $imgByLeaf[$k].Add($i)
}

# ------------------------------------------------------------
# BUILD MANIFEST
# ------------------------------------------------------------

$work = @($refs | Where-Object {
    $_.from_loc -eq 'repo' -and
    $_.status -eq 'broken-found-elsewhere' -and
    $_.resolved -and
    $_.best_candidate
})

Write-Host "Repo references needing an image: $($work.Count)"

$manifest = New-Object System.Collections.Generic.List[object]
$seenTargets = @{}
$skippedOutside = 0

foreach ($r in $work) {
    $target = $r.resolved
    if (-not $target.StartsWith($RepoRoot, [StringComparison]::OrdinalIgnoreCase)) {
        $skippedOutside++
        continue
    }
    if ($seenTargets.ContainsKey($target.ToLower())) {
        $seenTargets[$target.ToLower()].refs++
        continue
    }

    $leaf = (Split-Path $target -Leaf).ToLower()
    $cands = if ($imgByLeaf.ContainsKey($leaf)) { $imgByLeaf[$leaf] } else { @() }

    # Prefer the largest pixel area, then the largest file, then repo-adjacent roots
    $pick = @($cands | Sort-Object `
        @{ Expression = { [int]$_.width * [int]$_.height }; Descending = $true },
        @{ Expression = { [int64]$_.bytes }; Descending = $true }) | Select-Object -First 1

    if (-not $pick) { $pick = $imgByPath[$r.best_candidate] }
    if (-not $pick) { continue }

    $distinct = @($cands | Group-Object sha256 | Where-Object { $_.Name }).Count

    $row = [pscustomobject]@{
        target        = $target
        target_rel    = $target.Substring($RepoRoot.Length).TrimStart('\')
        source        = $pick.path
        source_loc    = $pick.location
        dims          = "$($pick.width)x$($pick.height)"
        kb            = [math]::Round([int64]$pick.bytes / 1KB, 0)
        sha256        = $pick.sha256
        candidates    = @($cands).Count
        distinct_hashes = $distinct
        review        = if ($distinct -gt 1) { 'REVIEW' } else { '' }
        refs          = 1
        metadata      = $pick.exif_source
    }
    $manifest.Add($row)
    $seenTargets[$target.ToLower()] = $row
}

$manifestPath = Join-Path $InventoryDir 'asset_import_manifest.csv'
$manifest | Export-Csv -LiteralPath $manifestPath -NoTypeInformation -Encoding UTF8

$totalMB = [math]::Round((($manifest | Measure-Object kb -Sum).Sum / 1024), 1)
$review = @($manifest | Where-Object { $_.review -eq 'REVIEW' })
$dirs = @($manifest | ForEach-Object { Split-Path $_.target -Parent } | Select-Object -Unique)

Write-Host ""
Write-Host "Unique images to import: $($manifest.Count)"
Write-Host "Total size:              $totalMB MB"
Write-Host "Target directories:      $($dirs.Count)"
if ($skippedOutside -gt 0) {
    Write-Host "Skipped (target outside repo): $skippedOutside" -ForegroundColor Yellow
}
if ($review.Count -gt 0) {
    Write-Host "Flagged REVIEW (same filename, different content): $($review.Count)" -ForegroundColor Yellow
}
Write-Host ""
Write-Host "Source roots:"
foreach ($g in ($manifest | Group-Object source_loc | Sort-Object Count -Descending)) {
    Write-Host ("  {0,-40} {1}" -f $g.Name, $g.Count)
}
Write-Host ""
Write-Host "Target directories:"
foreach ($d in ($dirs | Sort-Object)) {
    $n = @($manifest | Where-Object { (Split-Path $_.target -Parent) -eq $d }).Count
    Write-Host ("  {0,-60} {1}" -f $d.Substring($RepoRoot.Length).TrimStart('\'), $n)
}
Write-Host ""

if ($review.Count -gt 0) {
    Write-Host "REVIEW cases (a filename matched more than one distinct image):" -ForegroundColor Yellow
    foreach ($r in ($review | Select-Object -First 20)) {
        Write-Host ("  {0}  -> picked {1} ({2})" -f $r.target_rel, (Split-Path $r.source -Leaf), $r.dims)
    }
    if ($review.Count -gt 20) { Write-Host "  ... and $($review.Count - 20) more, see the manifest" }
    Write-Host ""
    Write-Host "The pick is the largest by pixel area. Check these in the manifest before executing." -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "Manifest: $manifestPath" -ForegroundColor Cyan
Write-Host ""

if (-not $Execute) {
    Write-Host "DRY RUN. Nothing copied." -ForegroundColor Cyan
    Write-Host "Review the manifest, then re-run with -Execute" -ForegroundColor Cyan
    Write-Host ""
    exit 0
}

# ------------------------------------------------------------
# EXECUTE
# ------------------------------------------------------------

Write-Host "Copying..." -ForegroundColor Yellow
Write-Host ""

$copied = 0; $failed = 0; $skipped = 0
$log = New-Object System.Collections.Generic.List[object]
$n = 0

foreach ($m in $manifest) {
    $n++
    if ($n % 10 -eq 0) {
        Write-Progress -Activity "Importing assets" -Status "$n / $($manifest.Count)" -PercentComplete (100 * $n / $manifest.Count)
    }

    $result = 'copied'; $note = ''

    try {
        if (Test-Path -LiteralPath $m.target) {
            $existing = (Get-FileHash -LiteralPath $m.target -Algorithm SHA256).Hash
            if ($existing -eq $m.sha256) { $result = 'already-present'; $skipped++ }
            else { $result = 'skipped-differs'; $note = 'target exists with different content, left alone'; $skipped++ }
        }
        else {
            $dir = Split-Path $m.target -Parent
            if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
            Copy-Item -LiteralPath $m.source -Destination $m.target -Force
            $after = (Get-FileHash -LiteralPath $m.target -Algorithm SHA256).Hash
            if ($after -ne $m.sha256) {
                $result = 'FAILED-hash-mismatch'
                $note = "expected $($m.sha256) got $after"
                $failed++
            }
            else { $copied++ }
        }
    }
    catch {
        $result = 'FAILED'
        $note = $_.Exception.Message
        $failed++
    }

    $log.Add([pscustomobject]@{
        target = $m.target; source = $m.source; result = $result; note = $note
    })
}

Write-Progress -Activity "Importing assets" -Completed

$logPath = Join-Path $InventoryDir 'asset_import_log.csv'
$log | Export-Csv -LiteralPath $logPath -NoTypeInformation -Encoding UTF8

Write-Host ""
Write-Host "Copied:  $copied" -ForegroundColor Green
Write-Host "Skipped: $skipped"
if ($failed -gt 0) { Write-Host "FAILED:  $failed" -ForegroundColor Red }
Write-Host ""
Write-Host "Log: $logPath"
Write-Host ""
Write-Host "Next: re-run the census to confirm the repo now resolves." -ForegroundColor Cyan
Write-Host '  & "$env:USERPROFILE\Downloads\Invoke-LseCensus.ps1" -SourceDir "C:\Users\dstor\OneDrive\Desktop\LSE_FINAL_IMAGE_AND_SPLIT_FIX","C:\Users\dstor\Downloads","C:\Users\dstor\Desktop"' -ForegroundColor Cyan
Write-Host ""
Write-Host "Then check the REPO ONLY table in INVENTORY\references.md. Missing should be 0." -ForegroundColor Cyan
Write-Host ""
