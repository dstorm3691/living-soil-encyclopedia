<#
.SYNOPSIS
    Builds compressed variants of a few sample images so you can look at
    them before committing to a format.

.DESCRIPTION
    Writes original, 256-colour PNG, and JPEG at several qualities into
    .build\image_compare\<name>\ and prints a size table. Changes nothing
    in assets\.

    Open the folders, zoom to 100%, and check two things:
      - line art and labels: still crisp?
      - shaded areas: any banding or blotching?

.EXAMPLE
    .\Compare-LseImageOptions.ps1

.EXAMPLE
    .\Compare-LseImageOptions.ps1 -Samples 6
#>

[CmdletBinding()]
param(
    [string]$RepoRoot,
    [int]$Samples = 4,
    [string[]]$Files,
    [int[]]$JpegQualities = @(92, 85),
    [int]$PaletteSize = 256
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
$assets = Join-Path $RepoRoot 'assets'
$outRoot = Join-Path $RepoRoot '.build\image_compare'

if (Test-Path -LiteralPath $outRoot) { Remove-Item -LiteralPath $outRoot -Recurse -Force }
New-Item -ItemType Directory -Path $outRoot -Force | Out-Null

function Get-Frame {
    param([string]$Path)
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $ms = New-Object System.IO.MemoryStream(, $bytes)
    $dec = [System.Windows.Media.Imaging.BitmapDecoder]::Create(
        $ms,
        [System.Windows.Media.Imaging.BitmapCreateOptions]::PreservePixelFormat,
        [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad)
    $f = $dec.Frames[0]
    $ms.Dispose()
    return $f
}

# ---- pick samples ----
if ($Files) {
    $picks = foreach ($f in $Files) {
        $p = Get-ChildItem -LiteralPath $assets -Recurse -File -Filter "*$f*" | Select-Object -First 1
        if ($p) { $p }
    }
}
else {
    $pngs = Get-ChildItem -LiteralPath $assets -Recurse -File -Filter "*.png" | Sort-Object Length -Descending
    # deliberately mix: text-heavy diagrams and shaded illustrations
    $textish = @($pngs | Where-Object { $_.Name -match '(?i)tree|calendar|checklist|matrix|comparison|guide|protocol|workflow|decoder' } | Select-Object -First ([math]::Ceiling($Samples/2)))
    $arty    = @($pngs | Where-Object { $_.Name -notmatch '(?i)tree|calendar|checklist|matrix|comparison|guide|protocol|workflow|decoder' } | Select-Object -First ([math]::Floor($Samples/2)))
    $picks = @($textish + $arty)
}

if (-not $picks) { Write-Host "No samples found." -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "Writing variants to: $outRoot"
Write-Host ""

$rows = New-Object System.Collections.Generic.List[object]

foreach ($p in $picks) {
    $base = [System.IO.Path]::GetFileNameWithoutExtension($p.Name)
    $dir = Join-Path $outRoot $base
    New-Item -ItemType Directory -Path $dir -Force | Out-Null

    Copy-Item -LiteralPath $p.FullName -Destination (Join-Path $dir "0_original.png") -Force
    $origKB = [math]::Round($p.Length / 1KB, 0)

    $src = Get-Frame -Path $p.FullName
    $kind = if ($p.Name -match '(?i)tree|calendar|checklist|matrix|comparison|guide|protocol|workflow|decoder') { 'text/line art' } else { 'illustration' }

    Write-Host ("{0}  [{1}]  {2}x{3}  {4} KB" -f $base, $kind, $src.PixelWidth, $src.PixelHeight, $origKB)

    # quantized PNG
    $qKB = $null
    try {
        $pal = New-Object System.Windows.Media.Imaging.BitmapPalette -ArgumentList $src, $PaletteSize
        $cv = New-Object System.Windows.Media.Imaging.FormatConvertedBitmap
        $cv.BeginInit()
        $cv.Source = $src
        $cv.DestinationFormat = [System.Windows.Media.PixelFormats]::Indexed8
        $cv.DestinationPalette = $pal
        $cv.EndInit()

        $enc = New-Object System.Windows.Media.Imaging.PngBitmapEncoder
        $enc.Interlace = [System.Windows.Media.Imaging.PngInterlaceOption]::Off
        $enc.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($cv))
        $f = [System.IO.File]::Open((Join-Path $dir "1_png${PaletteSize}.png"), 'Create', 'Write')
        $enc.Save($f); $f.Dispose()
        $qKB = [math]::Round((Get-Item (Join-Path $dir "1_png${PaletteSize}.png")).Length / 1KB, 0)
        Write-Host ("   PNG-{0,-3}  {1,7} KB   {2,5}% of original" -f $PaletteSize, $qKB, [math]::Round(100*$qKB/$origKB,0))
    }
    catch { Write-Host "   PNG quantize failed: $($_.Exception.Message)" -ForegroundColor Yellow }

    # JPEG variants
    $jKB = @{}
    foreach ($q in $JpegQualities) {
        try {
            $enc = New-Object System.Windows.Media.Imaging.JpegBitmapEncoder
            $enc.QualityLevel = $q
            $enc.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($src))
            $path = Join-Path $dir "2_jpeg$q.jpg"
            $f = [System.IO.File]::Open($path, 'Create', 'Write')
            $enc.Save($f); $f.Dispose()
            $kb = [math]::Round((Get-Item $path).Length / 1KB, 0)
            $jKB[$q] = $kb
            Write-Host ("   JPEG {0,-3}  {1,7} KB   {2,5}% of original" -f $q, $kb, [math]::Round(100*$kb/$origKB,0))
        }
        catch { Write-Host "   JPEG $q failed" -ForegroundColor Yellow }
    }

    $rows.Add([pscustomobject]@{
        file = $base; kind = $kind
        original_kb = $origKB
        png_quant_kb = $qKB
        jpeg92_kb = $jKB[92]
        jpeg85_kb = $jKB[85]
    })
    Write-Host ""
}

$rows | Export-Csv -LiteralPath (Join-Path $outRoot 'comparison.csv') -NoTypeInformation -Encoding UTF8

$totO = ($rows | Measure-Object original_kb -Sum).Sum
$totQ = ($rows | Where-Object { $_.png_quant_kb } | Measure-Object png_quant_kb -Sum).Sum
$tot92 = ($rows | Where-Object { $_.jpeg92_kb } | Measure-Object jpeg92_kb -Sum).Sum

Write-Host "----------------------------------------------------"
Write-Host ("Across $($rows.Count) samples:")
Write-Host ("  original     {0,8} KB" -f $totO)
if ($totQ)  { Write-Host ("  PNG-$PaletteSize    {0,8} KB   ({1}% of original)" -f $totQ, [math]::Round(100*$totQ/$totO,0)) }
if ($tot92) { Write-Host ("  JPEG 92      {0,8} KB   ({1}% of original)" -f $tot92, [math]::Round(100*$tot92/$totO,0)) }
Write-Host ""
Write-Host "Now open the folders and compare at 100% zoom:" -ForegroundColor Cyan
Write-Host "  explorer `"$outRoot`"" -ForegroundColor Cyan
Write-Host ""
Write-Host "Check line art for blurred labels, and shaded areas for banding." -ForegroundColor Cyan
Write-Host ""
