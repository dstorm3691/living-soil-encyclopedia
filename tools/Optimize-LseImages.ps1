<#
.SYNOPSIS
    Shrinks the repo's images for print: resize oversized ones, quantize
    flat-colour diagram PNGs to a 256-colour palette.

.DESCRIPTION
    Most of the weight in the PDF is PNG. A diagram with 40 distinct
    colours stored as 24 or 32-bit PNG is many times larger than it needs
    to be. Quantizing to an optimal 256-colour palette is visually
    near-identical for flat artwork and typically saves 60 to 80 percent.

    Photographs are never quantized. The detector counts distinct colours
    on a downsampled copy and skips anything that looks photographic.

    Dry run by default. -Execute requires -BackupTo, and every original is
    copied and hash-verified before it is touched.

.EXAMPLE
    .\Optimize-LseImages.ps1 -Quantize

.EXAMPLE
    .\Optimize-LseImages.ps1 -Quantize -BackupTo "D:\LSE_ARCHIVE\originals" -Execute

.EXAMPLE
    # undo: copy the backups back
    .\Optimize-LseImages.ps1 -Restore -BackupTo "D:\LSE_ARCHIVE\originals"
#>

[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BackupTo,
    [int]$MaxDimension = 2000,
    [int]$JpegQuality = 88,
    [int]$PaletteSize = 256,
    [int]$PhotoColorLimit = 4000,   # more distinct colours than this = treat as photo
    [switch]$Quantize,
    [switch]$Execute,
    [switch]$Restore
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
if (-not (Test-Path -LiteralPath $assets)) { Write-Host "No assets folder." -ForegroundColor Red; exit 1 }

# ---------------- restore ----------------

if ($Restore) {
    if (-not $BackupTo -or -not (Test-Path -LiteralPath $BackupTo)) {
        Write-Host "-Restore needs a valid -BackupTo path." -ForegroundColor Red; exit 1
    }
    $n = 0
    foreach ($b in (Get-ChildItem -LiteralPath $BackupTo -Recurse -File)) {
        $rel = $b.FullName.Substring($BackupTo.Length).TrimStart('\')
        $target = Join-Path $assets $rel
        if (Test-Path -LiteralPath $target) { Copy-Item -LiteralPath $b.FullName -Destination $target -Force; $n++ }
    }
    Write-Host "`nRestored $n files from $BackupTo`n" -ForegroundColor Green
    exit 0
}

if ($Execute -and -not $BackupTo) {
    Write-Host "-Execute requires -BackupTo." -ForegroundColor Red; exit 1
}

Write-Host ""
Write-Host "Assets:        $assets"
Write-Host "Max dimension: $MaxDimension px"
Write-Host "Quantize PNGs: $(if ($Quantize) { "yes, $PaletteSize colours" } else { 'no (pass -Quantize)' })"
Write-Host "Mode:          $(if ($Execute) { 'EXECUTE' } else { 'DRY RUN' })" -ForegroundColor $(if ($Execute) { 'Yellow' } else { 'Cyan' })
Write-Host ""

# ---------------- helpers ----------------

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

function Get-ColorCount {
    <# Counts distinct colours on a downsampled copy. Fast enough, and a
       good enough signal to separate flat artwork from photographs. #>
    param($Frame, [int]$Sample = 160)
    try {
        $w = $Frame.PixelWidth; $h = $Frame.PixelHeight
        $sx = [math]::Min(1.0, $Sample / [double]$w)
        $sy = [math]::Min(1.0, $Sample / [double]$h)
        $st = New-Object System.Windows.Media.ScaleTransform -ArgumentList $sx, $sy
        $tb = New-Object System.Windows.Media.Imaging.TransformedBitmap
        $tb.BeginInit(); $tb.Source = $Frame; $tb.Transform = $st; $tb.EndInit()

        $cv = New-Object System.Windows.Media.Imaging.FormatConvertedBitmap
        $cv.BeginInit(); $cv.Source = $tb
        $cv.DestinationFormat = [System.Windows.Media.PixelFormats]::Bgr32
        $cv.EndInit()

        $sw = $cv.PixelWidth; $sh = $cv.PixelHeight
        $stride = $sw * 4
        $buf = New-Object byte[] ($stride * $sh)
        $cv.CopyPixels($buf, $stride, 0)

        $set = New-Object 'System.Collections.Generic.HashSet[int]'
        for ($i = 0; $i -lt $buf.Length; $i += 4) {
            [void]$set.Add(($buf[$i+2] -shl 16) -bor ($buf[$i+1] -shl 8) -bor $buf[$i])
        }
        # scale up: sampled area is smaller than the original
        $ratio = ($w * $h) / [double]([math]::Max($sw * $sh, 1))
        return [int]($set.Count * [math]::Min($ratio, 4))
    }
    catch { return 999999 }
}

# ---------------- plan ----------------

$files = Get-ChildItem -LiteralPath $assets -Recurse -File |
         Where-Object { $_.Extension -match '(?i)\.(jpg|jpeg|png)$' }

$plan = New-Object System.Collections.Generic.List[object]
$i = 0
foreach ($f in $files) {
    $i++
    Write-Progress -Activity "Analyzing" -Status "$i / $($files.Count)" -PercentComplete (100 * $i / $files.Count)
    try { $fr = Get-Frame -Path $f.FullName } catch { continue }

    $w = $fr.PixelWidth; $h = $fr.PixelHeight
    $isPng = $f.Extension -match '(?i)png'
    $needsResize = ([math]::Max($w, $h) -gt $MaxDimension)

    $colors = $null
    $canQuantize = $false
    if ($Quantize -and $isPng) {
        $colors = Get-ColorCount -Frame $fr
        $canQuantize = ($colors -le $PhotoColorLimit)
    }

    $action = if ($needsResize -and $canQuantize) { 'resize+quantize' }
              elseif ($needsResize) { 'resize' }
              elseif ($canQuantize) { 'quantize' }
              else { 'keep' }

    $plan.Add([pscustomobject]@{
        path = $f.FullName; name = $f.Name; ext = $f.Extension.ToLower()
        w = $w; h = $h; bytes = $f.Length
        colors = $colors; action = $action
    })
}
Write-Progress -Activity "Analyzing" -Completed

$work = @($plan | Where-Object { $_.action -ne 'keep' })
$totMB = [math]::Round((($plan | Measure-Object bytes -Sum).Sum / 1MB), 1)
$workMB = [math]::Round((($work | Measure-Object bytes -Sum).Sum / 1MB), 1)

Write-Host "Images:     $($plan.Count)  ($totMB MB)"
Write-Host "To process: $($work.Count)  ($workMB MB)"
Write-Host ""
foreach ($g in ($plan | Group-Object action | Sort-Object Count -Descending)) {
    $gmb = [math]::Round((($g.Group | Measure-Object bytes -Sum).Sum / 1MB), 1)
    Write-Host ("  {0,-18} {1,4} files  {2,7} MB" -f $g.Name, $g.Count, $gmb)
}
Write-Host ""
Write-Host "Heaviest candidates:"
foreach ($p in ($work | Sort-Object bytes -Descending | Select-Object -First 12)) {
    Write-Host ("  {0,7} KB  {1,5}x{2,-5} {3,7} colours  {4}" -f `
        [math]::Round($p.bytes/1KB,0), $p.w, $p.h, $(if ($null -ne $p.colors) { $p.colors } else { '-' }), $p.name)
}
Write-Host ""

if (-not $Execute) {
    Write-Host "DRY RUN. Nothing changed." -ForegroundColor Cyan
    Write-Host "Re-run with -BackupTo <path> -Execute" -ForegroundColor Cyan
    Write-Host ""
    exit 0
}

# ---------------- execute ----------------

if (-not (Test-Path -LiteralPath $BackupTo)) { New-Item -ItemType Directory -Path $BackupTo -Force | Out-Null }

$done = 0; $failed = 0; $saved = 0L
$log = New-Object System.Collections.Generic.List[object]
$n = 0

foreach ($p in $work) {
    $n++
    Write-Progress -Activity "Optimizing" -Status "$n / $($work.Count)" -PercentComplete (100 * $n / $work.Count)
    $rel = $p.path.Substring($assets.Length).TrimStart('\')
    $backup = Join-Path $BackupTo $rel
    $before = $p.bytes
    $res = 'ok'; $note = ''

    try {
        $bdir = Split-Path $backup -Parent
        if (-not (Test-Path -LiteralPath $bdir)) { New-Item -ItemType Directory -Path $bdir -Force | Out-Null }
        if (-not (Test-Path -LiteralPath $backup)) {
            Copy-Item -LiteralPath $p.path -Destination $backup -Force
            if ((Get-FileHash -LiteralPath $p.path).Hash -ne (Get-FileHash -LiteralPath $backup).Hash) {
                throw "backup hash mismatch"
            }
        }

        $src = Get-Frame -Path $p.path

        # resize if needed
        $stage = $src
        if ($p.action -like '*resize*') {
            $scale = $MaxDimension / [double][math]::Max($p.w, $p.h)
            $st = New-Object System.Windows.Media.ScaleTransform -ArgumentList $scale, $scale
            $tb = New-Object System.Windows.Media.Imaging.TransformedBitmap
            $tb.BeginInit(); $tb.Source = $stage; $tb.Transform = $st; $tb.EndInit()
            $stage = $tb
        }

        # encode
        if ($p.ext -match 'png') {
            if ($p.action -like '*quantize*') {
                $pal = New-Object System.Windows.Media.Imaging.BitmapPalette -ArgumentList $stage, $PaletteSize
                $cv = New-Object System.Windows.Media.Imaging.FormatConvertedBitmap
                $cv.BeginInit()
                $cv.Source = $stage
                $cv.DestinationFormat = [System.Windows.Media.PixelFormats]::Indexed8
                $cv.DestinationPalette = $pal
                $cv.EndInit()
                $stage = $cv
            }
            $enc = New-Object System.Windows.Media.Imaging.PngBitmapEncoder
            $enc.Interlace = [System.Windows.Media.Imaging.PngInterlaceOption]::Off
        }
        else {
            $enc = New-Object System.Windows.Media.Imaging.JpegBitmapEncoder
            $enc.QualityLevel = $JpegQuality
        }
        $enc.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($stage))

        $tmp = "$($p.path).tmp"
        $out = [System.IO.File]::Open($tmp, 'Create', 'Write')
        $enc.Save($out)
        $out.Dispose()

        $newSize = (Get-Item -LiteralPath $tmp).Length
        if ($newSize -lt 512) { throw "output too small, aborting this file" }

        if ($newSize -lt $before * 0.95) {
            Move-Item -LiteralPath $tmp -Destination $p.path -Force
            $saved += ($before - $newSize)
            $done++
            $note = "$([math]::Round($before/1KB,0)) -> $([math]::Round($newSize/1KB,0)) KB"
        }
        else {
            Remove-Item -LiteralPath $tmp -Force
            $res = 'skipped, under 5% saving'
        }
    }
    catch {
        $res = 'FAILED'; $note = $_.Exception.Message; $failed++
        if (Test-Path -LiteralPath "$($p.path).tmp") { Remove-Item -LiteralPath "$($p.path).tmp" -Force }
    }

    $log.Add([pscustomobject]@{ file = $p.name; action = $p.action; result = $res; note = $note })
}
Write-Progress -Activity "Optimizing" -Completed

$invDir = Join-Path $RepoRoot 'INVENTORY'
if (Test-Path -LiteralPath $invDir) {
    $log | Export-Csv -LiteralPath (Join-Path $invDir 'optimize_log.csv') -NoTypeInformation -Encoding UTF8
}

Write-Host ""
Write-Host "Changed: $done" -ForegroundColor Green
if ($failed -gt 0) { Write-Host "Failed:  $failed" -ForegroundColor Red }
Write-Host "Saved:   $([math]::Round($saved/1MB,1)) MB" -ForegroundColor Green
Write-Host "Backups: $BackupTo"
Write-Host ""
Write-Host "Rebuild and LOOK AT A FIGURE PAGE:  python build.py --book 1" -ForegroundColor Cyan
Write-Host "Undo:  .\Optimize-LseImages.ps1 -Restore -BackupTo `"$BackupTo`"" -ForegroundColor Cyan
Write-Host ""
