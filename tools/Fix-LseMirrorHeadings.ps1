<#
.SYNOPSIS
    Aligns the four mirror heading pairs that verify.py flags as divergent.

.DESCRIPTION
    The section content is in sync. Only the headings differ, which means a
    reader meets the same SOP under two names in two books.

    Three pairs differ because the mirror carries an LSE catalogue number the
    canonical lacks. One pair differs in word order.

    Dry run shows every old -> new before anything changes. Nothing is edited
    without -Execute. verify.py runs afterwards.

.EXAMPLE
    .\Fix-LseMirrorHeadings.ps1

.EXAMPLE
    .\Fix-LseMirrorHeadings.ps1 -Direction AddCatalogNumber -Execute

.EXAMPLE
    .\Fix-LseMirrorHeadings.ps1 -Direction StripCatalogNumber -Execute
#>

[CmdletBinding()]
param(
    [string]$RepoRoot,
    [ValidateSet('AddCatalogNumber', 'StripCatalogNumber')]
    [string]$Direction = 'AddCatalogNumber',
    [switch]$Execute
)

$ErrorActionPreference = 'Stop'

if (-not $RepoRoot) {
    $d = (& git rev-parse --show-toplevel 2>$null)
    if ($LASTEXITCODE -ne 0) { Write-Host "Not in a git repo." -ForegroundColor Red; exit 1 }
    $RepoRoot = $d.Trim() -replace '/', '\'
}
$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
$bak = Join-Path $RepoRoot '.build\html_backup'

# The four divergent pairs, exactly as verify.py reported them.
# canonical is the Book 5 / source wording, mirror is the copy in another book.
$Pairs = @(
    @{ Canonical = 'M2-3: Mycorrhizal Inoculation at Transplant'
       Mirror    = 'LSE-163 — M2-3: Mycorrhizal Inoculation at Transplant'
       Catalog   = 'LSE-163' }

    @{ Canonical = 'M2-1: AACT Brewing Protocol'
       Mirror    = 'LSE-161 — M2-1: AACT Brewing Protocol'
       Catalog   = 'LSE-161' }

    @{ Canonical = 'LSE-232 — Seed Starting and Transplanting SOP'
       Mirror    = 'LSE-232 — SOP — Seed Starting and Transplanting'
       Catalog   = 'LSE-232' }

    @{ Canonical = 'M2-2: Foliar Spray Application SOP'
       Mirror    = 'LSE-162 — M2-2: Foliar Spray Application SOP'
       Catalog   = 'LSE-162' }
)

# Work out the single agreed wording for each pair.
foreach ($p in $Pairs) {
    if ($p.Canonical -like "$($p.Catalog)*") {
        # Pair 3: both already carry the number, only word order differs.
        # Canonical wording wins in both directions.
        $p.Target = $p.Canonical
    }
    elseif ($Direction -eq 'AddCatalogNumber') {
        $p.Target = $p.Mirror        # mirror already has the number
    }
    else {
        $p.Target = $p.Canonical     # strip the number, canonical wording wins
    }
}

Write-Host ""
Write-Host "Repo:      $RepoRoot"
Write-Host "Direction: $Direction"
Write-Host "Mode:      $(if ($Execute) { 'EXECUTE' } else { 'DRY RUN' })" -ForegroundColor $(if ($Execute) { 'Yellow' } else { 'Cyan' })
Write-Host ""

$files = Get-ChildItem -LiteralPath $RepoRoot -Filter "LSE_*.html" -File | Sort-Object Name
$plan = New-Object System.Collections.Generic.List[object]

foreach ($f in $files) {
    $html = Get-Content -LiteralPath $f.FullName -Raw
    foreach ($p in $Pairs) {
        foreach ($variant in @($p.Canonical, $p.Mirror)) {
            if ($variant -eq $p.Target) { continue }
            $n = ([regex]::Matches($html, [regex]::Escape($variant))).Count
            if ($n -gt 0) {
                $plan.Add([pscustomobject]@{
                    file = $f.Name; catalog = $p.Catalog
                    old = $variant; new = $p.Target; occurrences = $n
                })
            }
        }
    }
}

if ($plan.Count -eq 0) {
    Write-Host "Nothing to change. Headings already agree." -ForegroundColor Green
    Write-Host ""
    exit 0
}

Write-Host "Proposed changes:" -ForegroundColor Cyan
Write-Host ""
foreach ($g in ($plan | Group-Object catalog)) {
    Write-Host "  $($g.Name)" -ForegroundColor White
    foreach ($x in $g.Group) {
        Write-Host "    $($x.file)  ($($x.occurrences)x)"
        Write-Host "      old: $($x.old)" -ForegroundColor DarkYellow
        Write-Host "      new: $($x.new)" -ForegroundColor Green
    }
    Write-Host ""
}

$invDir = Join-Path $RepoRoot 'INVENTORY'
if (Test-Path -LiteralPath $invDir) {
    $plan | Export-Csv -LiteralPath (Join-Path $invDir 'mirror_heading_changes.csv') -NoTypeInformation -Encoding UTF8
}

if (-not $Execute) {
    Write-Host "DRY RUN. Nothing changed." -ForegroundColor Cyan
    Write-Host "Re-run with -Execute once the old -> new above reads correctly." -ForegroundColor Cyan
    Write-Host ""
    exit 0
}

if (-not (Test-Path -LiteralPath $bak)) { New-Item -ItemType Directory -Path $bak -Force | Out-Null }
$stamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
$changed = 0

foreach ($g in ($plan | Group-Object file)) {
    $path = Join-Path $RepoRoot $g.Name
    $html = Get-Content -LiteralPath $path -Raw
    $orig = $html
    foreach ($x in $g.Group) { $html = $html.Replace($x.old, $x.new) }
    if ($html -ne $orig) {
        $base = [IO.Path]::GetFileNameWithoutExtension($g.Name)
        Copy-Item -LiteralPath $path -Destination (Join-Path $bak "${base}_preheading_$stamp.html") -Force
        Set-Content -LiteralPath $path -Value $html -Encoding UTF8 -NoNewline
        $changed++
        Write-Host "  updated $($g.Name)" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Changed $changed file(s). Backups in $bak" -ForegroundColor Green
Write-Host ""
Write-Host "Running verify.py..." -ForegroundColor Yellow
Write-Host ""
Push-Location $RepoRoot
try { & python verify.py; $code = $LASTEXITCODE }
finally { Pop-Location }

Write-Host ""
if ($code -eq 0) {
    Write-Host "verify.py PASSED. The divergence list should now be empty." -ForegroundColor Green
}
else {
    Write-Host "verify.py FAILED. Back out:  git checkout -- *.html" -ForegroundColor Red
}
Write-Host ""
