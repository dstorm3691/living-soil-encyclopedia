<#
.SYNOPSIS
    Archives everything the finished book does not need, to a drive you choose.

.DESCRIPTION
    The repo is canonical. Everything outside it is either a duplicate, a
    superseded draft, or raw source material. This copies all of it to an
    archive folder, verifies every copy by hash, and only then offers to
    remove the originals.

    Dry run by default. Copies nothing without -Execute. Deletes nothing
    without -RemoveSource, which requires -Execute and a verified copy.

.EXAMPLE
    .\Invoke-LseArchive.ps1 -ArchiveRoot "D:\LSE_ARCHIVE"

.EXAMPLE
    .\Invoke-LseArchive.ps1 -ArchiveRoot "D:\LSE_ARCHIVE" -Execute

.EXAMPLE
    .\Invoke-LseArchive.ps1 -ArchiveRoot "D:\LSE_ARCHIVE" -Execute -RemoveSource
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ArchiveRoot,

    [string]$RepoRoot,
    [string]$InventoryDir,
    [switch]$Execute,
    [switch]$RemoveSource
)

$ErrorActionPreference = 'Stop'

if (-not $RepoRoot) {
    $d = (& git rev-parse --show-toplevel 2>$null)
    if ($LASTEXITCODE -ne 0) { Write-Host "Not in a git repo." -ForegroundColor Red; exit 1 }
    $RepoRoot = $d.Trim() -replace '/', '\'
}
$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
if (-not $InventoryDir) { $InventoryDir = Join-Path $RepoRoot 'INVENTORY' }

$filesCsv = Join-Path $InventoryDir 'files.csv'
if (-not (Test-Path -LiteralPath $filesCsv)) {
    Write-Host "Missing $filesCsv. Run the census first." -ForegroundColor Red
    exit 1
}

if ($RemoveSource -and -not $Execute) {
    Write-Host "-RemoveSource requires -Execute." -ForegroundColor Red
    exit 1
}

$all = Import-Csv -LiteralPath $filesCsv
$outside = @($all | Where-Object { $_.location -ne 'repo' })

Write-Host ""
Write-Host "Repo (canonical, untouched): $RepoRoot"
Write-Host "Archive destination:         $ArchiveRoot"
Write-Host "Mode:                        $(if ($RemoveSource) { 'EXECUTE + REMOVE SOURCE' } elseif ($Execute) { 'EXECUTE' } else { 'DRY RUN' })" -ForegroundColor $(if ($RemoveSource) { 'Red' } elseif ($Execute) { 'Yellow' } else { 'Cyan' })
Write-Host ""
Write-Host "Files outside the repo: $($outside.Count)"

# Hash of everything already in the repo. Anything matching is redundant.
$repoHashes = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
foreach ($r in ($all | Where-Object { $_.location -eq 'repo' })) {
    if ($r.sha256) { [void]$repoHashes.Add($r.sha256) }
}

$plan = New-Object System.Collections.Generic.List[object]
$seenHash = @{}

foreach ($f in $outside) {
    $reason = 'unique, archive'
    if ($f.sha256 -and $repoHashes.Contains($f.sha256)) { $reason = 'already in repo' }
    elseif ($f.sha256 -and $seenHash.ContainsKey($f.sha256)) { $reason = 'duplicate of another archived file' }
    if ($f.sha256) { $seenHash[$f.sha256] = $true }

    # Destination mirrors the source root layout so you can find things later
    $rel = $f.path -replace '^[A-Za-z]:\\', ''
    $dest = Join-Path (Join-Path $ArchiveRoot $f.location) $rel

    $plan.Add([pscustomobject]@{
        source = $f.path
        dest   = $dest
        loc    = $f.location
        bytes  = $f.bytes
        sha256 = $f.sha256
        reason = $reason
        action = if ($reason -eq 'already in repo') { 'skip' } else { 'copy' }
    })
}

$toCopy = @($plan | Where-Object { $_.action -eq 'copy' })
$skipRedundant = @($plan | Where-Object { $_.action -eq 'skip' })
$gb = [math]::Round((($toCopy | Measure-Object bytes -Sum).Sum / 1GB), 2)

Write-Host ""
Write-Host "  to archive:            $($toCopy.Count)  ($gb GB)"
Write-Host "  redundant (in repo):   $($skipRedundant.Count)"
Write-Host ""
Write-Host "By source root:"
foreach ($g in ($toCopy | Group-Object loc | Sort-Object Count -Descending)) {
    $g_gb = [math]::Round((($g.Group | Measure-Object bytes -Sum).Sum / 1GB), 2)
    Write-Host ("  {0,-38} {1,6} files  {2,6} GB" -f $g.Name, $g.Count, $g_gb)
}
Write-Host ""

$manifestPath = Join-Path $InventoryDir 'archive_manifest.csv'
$plan | Export-Csv -LiteralPath $manifestPath -NoTypeInformation -Encoding UTF8
Write-Host "Manifest: $manifestPath" -ForegroundColor Cyan
Write-Host ""

if (-not $Execute) {
    Write-Host "DRY RUN. Nothing copied." -ForegroundColor Cyan
    Write-Host "Review the manifest, then re-run with -Execute" -ForegroundColor Cyan
    Write-Host ""
    exit 0
}

if (-not (Test-Path -LiteralPath $ArchiveRoot)) {
    New-Item -ItemType Directory -Path $ArchiveRoot -Force | Out-Null
}

Write-Host "Copying $($toCopy.Count) files..." -ForegroundColor Yellow
$copied = 0; $verified = 0; $failed = 0
$log = New-Object System.Collections.Generic.List[object]
$n = 0

foreach ($p in $toCopy) {
    $n++
    if ($n % 25 -eq 0) {
        Write-Progress -Activity "Archiving" -Status "$n / $($toCopy.Count)" -PercentComplete (100 * $n / $toCopy.Count)
    }
    $res = 'copied'; $note = ''
    try {
        $dir = Split-Path $p.dest -Parent
        if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        Copy-Item -LiteralPath $p.source -Destination $p.dest -Force
        $copied++
        if ($p.sha256) {
            $after = (Get-FileHash -LiteralPath $p.dest -Algorithm SHA256).Hash
            if ($after -eq $p.sha256) { $verified++; $res = 'verified' }
            else { $res = 'HASH MISMATCH'; $failed++ }
        }
        else { $res = 'copied, not hashed' }
    }
    catch {
        $res = 'FAILED'; $note = $_.Exception.Message; $failed++
    }
    $log.Add([pscustomobject]@{ source = $p.source; dest = $p.dest; result = $res; note = $note })
}
Write-Progress -Activity "Archiving" -Completed

$logPath = Join-Path $InventoryDir 'archive_log.csv'
$log | Export-Csv -LiteralPath $logPath -NoTypeInformation -Encoding UTF8

Write-Host ""
Write-Host "Copied:   $copied" -ForegroundColor Green
Write-Host "Verified: $verified" -ForegroundColor Green
if ($failed -gt 0) { Write-Host "Failed:   $failed" -ForegroundColor Red }
Write-Host "Log: $logPath"
Write-Host ""

if (-not $RemoveSource) {
    Write-Host "Sources left in place." -ForegroundColor Cyan
    Write-Host "Open the archive, confirm it looks right, then re-run with -RemoveSource." -ForegroundColor Cyan
    Write-Host ""
    exit 0
}

if ($failed -gt 0) {
    Write-Host "Not removing sources: $failed files failed to copy or verify." -ForegroundColor Red
    exit 1
}

Write-Host "About to delete $verified source files that are verified present in the archive." -ForegroundColor Red
Write-Host "The repo is untouched. Type DELETE to proceed." -ForegroundColor Red
$confirm = Read-Host "Confirm"
if ($confirm -cne 'DELETE') {
    Write-Host "Cancelled. Nothing deleted." -ForegroundColor Cyan
    exit 0
}

$removed = 0; $kept = 0
foreach ($e in $log) {
    if ($e.result -ne 'verified') { $kept++; continue }
    try { Remove-Item -LiteralPath $e.source -Force; $removed++ }
    catch { $kept++ }
}

Write-Host ""
Write-Host "Removed: $removed" -ForegroundColor Green
Write-Host "Kept:    $kept (unverified or locked)" -ForegroundColor Yellow
Write-Host ""
