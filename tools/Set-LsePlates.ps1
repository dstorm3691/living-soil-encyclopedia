<#
.SYNOPSIS
    Marks tall or square figures as full-page plates.

.DESCRIPTION
    A height cap squeezes portrait and square diagrams hardest, and those
    are the ones that leave half-empty pages. This adds class="plate" to
    those sections so print.css gives them a full page on purpose.

    Wide landscape figures are left alone. They fit the cap fine.

    Dry run by default. -Execute backs up every file it touches first.

.EXAMPLE
    .\Set-LsePlates.ps1

.EXAMPLE
    .\Set-LsePlates.ps1 -Execute
#>

[CmdletBinding()]
param(
    [string]$RepoRoot,
    [double]$AspectThreshold = 1.25,   # width/height below this = plate candidate
    [switch]$Execute,
    [switch]$Clear                     # remove all plate classes instead
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

if (-not $RepoRoot) {
    $d = (& git rev-parse --show-toplevel 2>$null)
    if ($LASTEXITCODE -ne 0) { Write-Host "Not in a git repo." -ForegroundColor Red; exit 1 }
    $RepoRoot = $d.Trim() -replace '/', '\'
}
$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path

function Get-Dims {
    param([string]$Path)
    $fs = $null
    try {
        $fs = [System.IO.File]::Open($Path, 'Open', 'Read', 'ReadWrite')
        $dec = [System.Windows.Media.Imaging.BitmapDecoder]::Create(
            $fs,
            [System.Windows.Media.Imaging.BitmapCreateOptions]::DelayCreation,
            [System.Windows.Media.Imaging.BitmapCacheOption]::None)
        $f = $dec.Frames[0]
        return @{ w = $f.PixelWidth; h = $f.PixelHeight }
    }
    catch { return $null }
    finally { if ($fs) { $fs.Dispose() } }
}

$books = Get-ChildItem -LiteralPath $RepoRoot -Filter "LSE_BOOK_*_WORKING.html" -File | Sort-Object Name

Write-Host ""
Write-Host "Repo:      $RepoRoot"
Write-Host "Threshold: width/height < $AspectThreshold becomes a plate"
Write-Host "Mode:      $(if ($Clear) { 'CLEAR PLATES' } elseif ($Execute) { 'EXECUTE' } else { 'DRY RUN' })" -ForegroundColor $(if ($Execute) { 'Yellow' } else { 'Cyan' })
Write-Host ""

# section.lse-figure ... </section>, non greedy
$sectionRx = [regex]'(?is)<section\b([^>]*class="[^"]*lse-figure[^"]*"[^>]*)>(.*?)</section>'
$srcRx     = [regex]'(?i)<img[^>]*\bsrc\s*=\s*"([^"]+)"'
$classRx   = [regex]'(?i)class\s*=\s*"([^"]*)"'

$report = New-Object System.Collections.Generic.List[object]
$changedFiles = 0

foreach ($book in $books) {
    $html = Get-Content -LiteralPath $book.FullName -Raw
    $plates = 0; $keeps = 0; $unknown = 0

    $new = $sectionRx.Replace($html, {
        param($m)
        $attrs = $m.Groups[1].Value
        $body  = $m.Groups[2].Value

        $cm = $classRx.Match($attrs)
        $classes = if ($cm.Success) { $cm.Groups[1].Value } else { 'lse-figure' }
        $hasPlate = $classes -match '\bplate\b'

        if ($Clear) {
            if ($hasPlate) {
                $newClasses = ($classes -replace '\bplate\b', '').Trim() -replace '\s+', ' '
                $script:anyChange = $true
                return "<section" + $classRx.Replace($attrs, "class=`"$newClasses`"", 1) + ">" + $body + "</section>"
            }
            return $m.Value
        }

        $sm = $srcRx.Match($body)
        if (-not $sm.Success) { $script:unknownLocal++; return $m.Value }

        $rel = $sm.Groups[1].Value -replace '/', '\'
        $full = Join-Path $RepoRoot $rel
        if (-not (Test-Path -LiteralPath $full)) { $script:unknownLocal++; return $m.Value }

        $d = Get-Dims -Path $full
        if (-not $d -or $d.h -eq 0) { $script:unknownLocal++; return $m.Value }

        $aspect = [math]::Round($d.w / $d.h, 2)
        $name = Split-Path $rel -Leaf

        if ($aspect -lt $AspectThreshold) {
            $script:plateLocal++
            $report.Add([pscustomobject]@{
                book = $book.Name; figure = $name
                dims = "$($d.w)x$($d.h)"; aspect = $aspect; verdict = 'PLATE'
            })
            if (-not $hasPlate) {
                $newClasses = ($classes + ' plate').Trim()
                return "<section" + $classRx.Replace($attrs, "class=`"$newClasses`"", 1) + ">" + $body + "</section>"
            }
            return $m.Value
        }
        else {
            $script:keepLocal++
            $report.Add([pscustomobject]@{
                book = $book.Name; figure = $name
                dims = "$($d.w)x$($d.h)"; aspect = $aspect; verdict = 'inline'
            })
            return $m.Value
        }
    })

    $plates  = $script:plateLocal;  $script:plateLocal = 0
    $keeps   = $script:keepLocal;   $script:keepLocal = 0
    $unknown = $script:unknownLocal; $script:unknownLocal = 0

    $delta = ($new -ne $html)
    Write-Host ("{0,-46} plates {1,3}   inline {2,3}   unresolved {3,2}   {4}" -f `
        $book.Name, $plates, $keeps, $unknown, $(if ($delta) { 'CHANGED' } else { 'no change' }))

    if ($Execute -and $delta) {
        $bak = Join-Path $RepoRoot ".build\html_backup"
        if (-not (Test-Path -LiteralPath $bak)) { New-Item -ItemType Directory -Path $bak -Force | Out-Null }
        $stamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
        Copy-Item -LiteralPath $book.FullName -Destination (Join-Path $bak "$($book.BaseName)_$stamp.html") -Force
        Set-Content -LiteralPath $book.FullName -Value $new -Encoding UTF8 -NoNewline
        $changedFiles++
    }
}

Write-Host ""

$plateList = @($report | Where-Object { $_.verdict -eq 'PLATE' })
Write-Host "Figures that become full-page plates: $($plateList.Count)" -ForegroundColor Cyan
Write-Host ""
foreach ($p in ($plateList | Sort-Object aspect | Select-Object -First 25)) {
    Write-Host ("  {0,6}  {1,-11}  {2}" -f $p.aspect, $p.dims, $p.figure)
}
if ($plateList.Count -gt 25) { Write-Host "  ... and $($plateList.Count - 25) more" }
Write-Host ""

$invDir = Join-Path $RepoRoot 'INVENTORY'
if (Test-Path -LiteralPath $invDir) {
    $report | Export-Csv -LiteralPath (Join-Path $invDir 'plate_decisions.csv') -NoTypeInformation -Encoding UTF8
    Write-Host "Report: $invDir\plate_decisions.csv" -ForegroundColor Cyan
}

if (-not $Execute) {
    Write-Host ""
    Write-Host "DRY RUN. No HTML changed." -ForegroundColor Cyan
    Write-Host "Re-run with -Execute. Originals back up to .build\html_backup" -ForegroundColor Cyan
    Write-Host ""
    exit 0
}

Write-Host ""
Write-Host "Modified $changedFiles book files. Backups in .build\html_backup" -ForegroundColor Green
Write-Host "Rebuild: python build.py --book 1" -ForegroundColor Cyan
Write-Host "Undo:    .\Set-LsePlates.ps1 -Clear -Execute   (or git checkout the html)" -ForegroundColor Cyan
Write-Host ""
