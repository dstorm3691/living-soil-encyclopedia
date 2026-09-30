<#
.SYNOPSIS
  Compresses the five built LSE PDFs in dist\ with Ghostscript.

.DESCRIPTION
  Only touches dist\LSE_Book_*.pdf. Other files in dist\ are listed and ignored.

  Dry run by default: compresses into .build\pdf_compressed and reports
  size and page count, touches nothing in dist\.
  -Execute: moves the originals to .build\pdf_uncompressed and puts the
  compressed files in dist\ under the same names.

  A file is only swapped if the page count is unchanged and the result
  is smaller. Anything else is reported and the original is kept.

  Images are downsampled to -Dpi (default 200) only when they exceed
  1.5x that resolution. Fonts are subset and compressed.

.EXAMPLE
  .\tools\Compress-LsePdf.ps1
  .\tools\Compress-LsePdf.ps1 -Execute
  .\tools\Compress-LsePdf.ps1 -Dpi 250 -Execute
#>
param(
    [switch]$Execute,
    [int]$Dpi = 200,
    [string]$Repo = (Split-Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = 'Stop'

# Find Ghostscript
$gs = Get-Command gswin64c.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
if (-not $gs) {
    $gs = Get-ChildItem 'C:\Program Files\gs\*\bin\gswin64c.exe' -ErrorAction SilentlyContinue |
          Sort-Object FullName -Descending | Select-Object -First 1 -ExpandProperty FullName
}
if (-not $gs) {
    Write-Host "Ghostscript not found in C:\Program Files\gs. Install the latest gs*w64.exe from" -ForegroundColor Red
    Write-Host "  https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/latest" -ForegroundColor Yellow
    exit 1
}

function Get-PageCount($path) {
    $p = $path -replace '\\', '/'
    $out = & $gs '-q' '-dNODISPLAY' '-dNOSAFER' '-c' "($p) (r) file runpdfbegin pdfpagecount = quit" 2>$null
    $n = 0
    if ([int]::TryParse(($out | Select-Object -Last 1), [ref]$n)) { return $n }
    return $null
}

$dist = Join-Path $Repo 'dist'
$work = Join-Path $Repo '.build\pdf_compressed'
$keep = Join-Path $Repo '.build\pdf_uncompressed'
New-Item -ItemType Directory -Force -Path $work | Out-Null

$pdfs = Get-ChildItem $dist -Filter 'LSE_Book_*.pdf' -File | Sort-Object Name
if (-not $pdfs) { Write-Host "No LSE_Book_*.pdf in $dist. Run python build.py first." -ForegroundColor Red; exit 1 }

$other = Get-ChildItem $dist -File | Where-Object { $_.Name -notlike 'LSE_Book_*.pdf' }
if ($other) {
    Write-Host ""
    Write-Host "Ignored, not part of the book set: $($other.Name -join ', ')" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Ghostscript: $gs"
Write-Host "Image resolution: $Dpi dpi"
Write-Host "Mode: $(if ($Execute) {'EXECUTE'} else {'DRY RUN'})"
Write-Host ""

$rows = @()
foreach ($pdf in $pdfs) {
    $out = Join-Path $work $pdf.Name
    if (Test-Path $out) { Remove-Item $out -Force }

    $gsArgs = @(
        '-sDEVICE=pdfwrite'
        '-dCompatibilityLevel=1.7'
        '-dNOPAUSE'
        '-dBATCH'
        '-dQUIET'
        '-dDetectDuplicateImages=true'
        '-dSubsetFonts=true'
        '-dCompressFonts=true'
        '-dDownsampleColorImages=true'
        '-dColorImageDownsampleType=/Bicubic'
        "-dColorImageResolution=$Dpi"
        '-dColorImageDownsampleThreshold=1.5'
        '-dDownsampleGrayImages=true'
        '-dGrayImageDownsampleType=/Bicubic'
        "-dGrayImageResolution=$Dpi"
        '-dGrayImageDownsampleThreshold=1.5'
        '-dDownsampleMonoImages=false'
        "-sOutputFile=$out"
        $pdf.FullName
    )

    Write-Host "Compressing $($pdf.Name)..." -NoNewline
    $t = [Diagnostics.Stopwatch]::StartNew()
    $log = & $gs @gsArgs 2>&1
    Write-Host " $([math]::Round($t.Elapsed.TotalSeconds,1))s"

    $before = $pdf.Length
    $after  = if (Test-Path $out) { (Get-Item $out).Length } else { 0 }
    if (-not $after -and $log) { $log | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkYellow } }

    $pBefore = Get-PageCount $pdf.FullName
    $pAfter  = if ($after) { Get-PageCount $out } else { $null }

    $status = if (-not $after) { 'FAILED' }
              elseif ($null -eq $pBefore -or $null -eq $pAfter) { 'PAGES UNKNOWN' }
              elseif ($pBefore -ne $pAfter) { 'PAGE MISMATCH' }
              elseif ($after -ge $before) { 'NOT SMALLER' }
              else { 'OK' }

    $rows += [pscustomobject]@{
        File    = $pdf.Name
        Pages   = "$pBefore -> $pAfter"
        Before  = '{0:N1} MB' -f ($before / 1MB)
        After   = '{0:N1} MB' -f ($after / 1MB)
        Saved   = if ($after) { '{0:N0}%' -f ((1 - $after / $before) * 100) } else { '' }
        Status  = $status
        _src    = $pdf.FullName
        _out    = $out
        _before = $before
        _after  = $after
    }
}

$rows | Select-Object File, Pages, Before, After, Saved, Status | Format-Table -AutoSize

$tb = ($rows | Measure-Object _before -Sum).Sum
$ta = ($rows | Where-Object Status -eq 'OK' | Measure-Object _after -Sum).Sum +
      ($rows | Where-Object Status -ne 'OK' | Measure-Object _before -Sum).Sum
Write-Host ('Total: {0:N0} MB -> {1:N0} MB' -f ($tb / 1MB), ($ta / 1MB))

$bad = $rows | Where-Object Status -ne 'OK'
if ($bad) {
    Write-Host "Not swapped, originals kept: $($bad.File -join ', ')" -ForegroundColor Yellow
}

if (-not $Execute) {
    Write-Host ""
    Write-Host "Dry run. Compressed copies are in $work" -ForegroundColor Cyan
    Write-Host "Open one and zoom into a diagnostic photo before running with -Execute." -ForegroundColor Cyan
    exit 0
}

New-Item -ItemType Directory -Force -Path $keep | Out-Null
foreach ($r in ($rows | Where-Object Status -eq 'OK')) {
    Move-Item $r._src (Join-Path $keep (Split-Path $r._src -Leaf)) -Force
    Move-Item $r._out $r._src -Force
    Write-Host "Swapped  $($r.File)" -ForegroundColor Green
}
Write-Host ""
Write-Host "Originals: $keep" -ForegroundColor Green
