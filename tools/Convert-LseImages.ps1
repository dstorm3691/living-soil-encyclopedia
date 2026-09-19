<#
.SYNOPSIS
    Shrinks the book's images and rewrites the HTML to match.

.DESCRIPTION
    Three buckets:
      JPEG      shaded illustrations, no transparency, no text-heavy name
                -> re-encoded as .jpg, HTML src rewritten
      PNG-256   line art, reference cards, and anything with transparency
                -> quantized in place, HTML unchanged
      keep      already small, or not an image we touch

    Every original is copied to -BackupTo and hash-verified before anything
    is modified. Every book HTML is backed up to .build\html_backup.

    Dry run by default.

.EXAMPLE
    .\Convert-LseImages.ps1

.EXAMPLE
    .\Convert-LseImages.ps1 -BackupTo "D:\LSE_ARCHIVE\originals" -Execute

.EXAMPLE
    .\Convert-LseImages.ps1 -BackupTo "D:\LSE_ARCHIVE\originals" -Restore
#>

[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$BackupTo,
    [int]$JpegQuality = 92,
    [int]$PaletteSize = 256,
    [int]$MinKB = 150,            # below this, leave it alone
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
$htmlBak = Join-Path $RepoRoot '.build\html_backup'

# names where text crispness beats file size
$TextArt = '(?i)tree|calendar|checklist|matrix|comparison|guide|protocol|workflow|decoder|chart|reference|conversion|card|table|map|timeline|selector'

# ---------------- restore ----------------

if ($Restore) {
    if (-not $BackupTo -or -not (Test-Path -LiteralPath $BackupTo)) {
        Write-Host "-Restore needs a valid -BackupTo." -ForegroundColor Red; exit 1
    }
    $n = 0
    foreach ($b in (Get-ChildItem -LiteralPath $BackupTo -Recurse -File)) {
        $rel = $b.FullName.Substring($BackupTo.Length).TrimStart('\')
        $target = Join-Path $assets $rel
        $dir = Split-Path $target -Parent
        if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        Copy-Item -LiteralPath $b.FullName -Destination $target -Force
        # remove any .jpg we created alongside a restored .png
        $jpgTwin = [IO.Path]::ChangeExtension($target, '.jpg')
        if ($b.Extension -eq '.png' -and (Test-Path -LiteralPath $jpgTwin)) { Remove-Item -LiteralPath $jpgTwin -Force }
        $n++
    }
    Write-Host "`nRestored $n image files." -ForegroundColor Green
    Write-Host "Now restore the HTML:  git checkout -- *.html" -ForegroundColor Cyan
    Write-Host "(or copy from $htmlBak)`n" -ForegroundColor Cyan
    exit 0
}

if ($Execute -and -not $BackupTo) { Write-Host "-Execute requires -BackupTo." -ForegroundColor Red; exit 1 }

function Get-Frame {
    param([string]$Path)
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $ms = New-Object System.IO.MemoryStream(, $bytes)
    $dec = [System.Windows.Media.Imaging.BitmapDecoder]::Create(
        $ms, [System.Windows.Media.Imaging.BitmapCreateOptions]::PreservePixelFormat,
        [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad)
    $f = $dec.Frames[0]; $ms.Dispose(); return $f
}

function Test-HasAlpha {
    param($Frame)
    $fmt = $Frame.Format.ToString()
    return ($fmt -match '(?i)a(8|32|64)|bgra|rgba|pbgra')
}

# ---------------- plan ----------------

Write-Host ""
Write-Host "Assets:  $assets"
Write-Host "Mode:    $(if ($Execute) { 'EXECUTE' } else { 'DRY RUN' })" -ForegroundColor $(if ($Execute) { 'Yellow' } else { 'Cyan' })
Write-Host ""

$files = Get-ChildItem -LiteralPath $assets -Recurse -File |
         Where-Object { $_.Extension -match '(?i)\.(png|jpg|jpeg)$' }

$plan = New-Object System.Collections.Generic.List[object]
$i = 0
foreach ($f in $files) {
    $i++
    Write-Progress -Activity "Analyzing" -Status "$i / $($files.Count)" -PercentComplete (100 * $i / $files.Count)
    $kb = $f.Length / 1KB
    if ($kb -lt $MinKB) {
        $plan.Add([pscustomobject]@{ path=$f.FullName; name=$f.Name; bytes=$f.Length; bucket='keep'; why='small' })
        continue
    }
    if ($f.Extension -match '(?i)jpe?g') {
        $plan.Add([pscustomobject]@{ path=$f.FullName; name=$f.Name; bytes=$f.Length; bucket='keep'; why='already jpeg' })
        continue
    }
    try { $fr = Get-Frame -Path $f.FullName } catch {
        $plan.Add([pscustomobject]@{ path=$f.FullName; name=$f.Name; bytes=$f.Length; bucket='keep'; why='unreadable' })
        continue
    }
    if (Test-HasAlpha -Frame $fr) {
        $plan.Add([pscustomobject]@{ path=$f.FullName; name=$f.Name; bytes=$f.Length; bucket='png256'; why='transparency' })
    }
    elseif ($f.Name -match $TextArt) {
        $plan.Add([pscustomobject]@{ path=$f.FullName; name=$f.Name; bytes=$f.Length; bucket='png256'; why='text/line art' })
    }
    else {
        $plan.Add([pscustomobject]@{ path=$f.FullName; name=$f.Name; bytes=$f.Length; bucket='jpeg'; why='illustration' })
    }
}
Write-Progress -Activity "Analyzing" -Completed

foreach ($g in ($plan | Group-Object bucket | Sort-Object Count -Descending)) {
    $mb = [math]::Round((($g.Group | Measure-Object bytes -Sum).Sum / 1MB), 1)
    Write-Host ("  {0,-8} {1,4} files  {2,7} MB" -f $g.Name, $g.Count, $mb)
}
Write-Host ""
Write-Host "PNG-256 reasons:"
foreach ($g in ($plan | Where-Object { $_.bucket -eq 'png256' } | Group-Object why)) {
    Write-Host ("  {0,-16} {1}" -f $g.Name, $g.Count)
}
Write-Host ""

$invDir = Join-Path $RepoRoot 'INVENTORY'
if (Test-Path -LiteralPath $invDir) {
    $plan | Export-Csv -LiteralPath (Join-Path $invDir 'convert_plan.csv') -NoTypeInformation -Encoding UTF8
    Write-Host "Plan: $invDir\convert_plan.csv" -ForegroundColor Cyan
}

if (-not $Execute) {
    Write-Host ""
    Write-Host "DRY RUN. Nothing changed." -ForegroundColor Cyan
    Write-Host "Re-run with -BackupTo <path> -Execute" -ForegroundColor Cyan
    Write-Host ""
    exit 0
}

# ---------------- execute ----------------

if (-not (Test-Path -LiteralPath $BackupTo)) { New-Item -ItemType Directory -Path $BackupTo -Force | Out-Null }

$work = @($plan | Where-Object { $_.bucket -ne 'keep' })
$renames = @{}   # old relative src -> new relative src
$done = 0; $failed = 0; $saved = 0L
$log = New-Object System.Collections.Generic.List[object]
$n = 0

foreach ($p in $work) {
    $n++
    Write-Progress -Activity "Converting" -Status "$n / $($work.Count)" -PercentComplete (100 * $n / $work.Count)
    $rel = $p.path.Substring($assets.Length).TrimStart('\')
    $backup = Join-Path $BackupTo $rel
    $before = $p.bytes
    $res = 'ok'; $note = ''

    try {
        $bdir = Split-Path $backup -Parent
        if (-not (Test-Path -LiteralPath $bdir)) { New-Item -ItemType Directory -Path $bdir -Force | Out-Null }
        if (-not (Test-Path -LiteralPath $backup)) {
            Copy-Item -LiteralPath $p.path -Destination $backup -Force
            if ((Get-FileHash -LiteralPath $p.path).Hash -ne (Get-FileHash -LiteralPath $backup).Hash) { throw "backup mismatch" }
        }

        $src = Get-Frame -Path $p.path

        if ($p.bucket -eq 'jpeg') {
            $cv = New-Object System.Windows.Media.Imaging.FormatConvertedBitmap
            $cv.BeginInit(); $cv.Source = $src
            $cv.DestinationFormat = [System.Windows.Media.PixelFormats]::Bgr24
            $cv.EndInit()

            $enc = New-Object System.Windows.Media.Imaging.JpegBitmapEncoder
            $enc.QualityLevel = $JpegQuality
            $enc.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($cv))

            $newPath = [IO.Path]::ChangeExtension($p.path, '.jpg')
            $fs = [System.IO.File]::Open($newPath, 'Create', 'Write')
            $enc.Save($fs); $fs.Dispose()

            $newSize = (Get-Item -LiteralPath $newPath).Length
            if ($newSize -lt 512) { Remove-Item -LiteralPath $newPath -Force; throw "output too small" }

            $oldRel = ($rel -replace '\\', '/')
            $newRel = ([IO.Path]::ChangeExtension($rel, '.jpg') -replace '\\', '/')
            $renames["assets/$oldRel"] = "assets/$newRel"

            Remove-Item -LiteralPath $p.path -Force
            $saved += ($before - $newSize); $done++
            $note = "$([math]::Round($before/1KB,0)) -> $([math]::Round($newSize/1KB,0)) KB, now .jpg"
        }
        else {
            $pal = New-Object System.Windows.Media.Imaging.BitmapPalette -ArgumentList $src, $PaletteSize
            $cv = New-Object System.Windows.Media.Imaging.FormatConvertedBitmap
            $cv.BeginInit(); $cv.Source = $src
            $cv.DestinationFormat = [System.Windows.Media.PixelFormats]::Indexed8
            $cv.DestinationPalette = $pal
            $cv.EndInit()

            $enc = New-Object System.Windows.Media.Imaging.PngBitmapEncoder
            $enc.Interlace = [System.Windows.Media.Imaging.PngInterlaceOption]::Off
            $enc.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($cv))

            $tmp = "$($p.path).tmp"
            $fs = [System.IO.File]::Open($tmp, 'Create', 'Write')
            $enc.Save($fs); $fs.Dispose()

            $newSize = (Get-Item -LiteralPath $tmp).Length
            if ($newSize -lt 512) { Remove-Item -LiteralPath $tmp -Force; throw "output too small" }
            if ($newSize -lt $before * 0.95) {
                Move-Item -LiteralPath $tmp -Destination $p.path -Force
                $saved += ($before - $newSize); $done++
                $note = "$([math]::Round($before/1KB,0)) -> $([math]::Round($newSize/1KB,0)) KB"
            }
            else {
                Remove-Item -LiteralPath $tmp -Force
                $res = 'skipped, no saving'
            }
        }
    }
    catch {
        $res = 'FAILED'; $note = $_.Exception.Message; $failed++
    }
    $log.Add([pscustomobject]@{ file=$p.name; bucket=$p.bucket; result=$res; note=$note })
}
Write-Progress -Activity "Converting" -Completed

# ---------------- rewrite HTML ----------------

Write-Host ""
Write-Host "Rewriting $($renames.Count) image references in the book HTML..." -ForegroundColor Yellow

if (-not (Test-Path -LiteralPath $htmlBak)) { New-Item -ItemType Directory -Path $htmlBak -Force | Out-Null }
$stamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
$htmlChanged = 0; $refsChanged = 0

foreach ($book in (Get-ChildItem -LiteralPath $RepoRoot -Filter "*.html" -File)) {
    $text = Get-Content -LiteralPath $book.FullName -Raw
    $orig = $text
    $count = 0
    foreach ($k in $renames.Keys) {
        if ($text.Contains($k)) {
            $occurrences = ([regex]::Matches($text, [regex]::Escape($k))).Count
            $text = $text.Replace($k, $renames[$k])
            $count += $occurrences
        }
    }
    if ($text -ne $orig) {
        Copy-Item -LiteralPath $book.FullName -Destination (Join-Path $htmlBak "$($book.BaseName)_$stamp.html") -Force
        Set-Content -LiteralPath $book.FullName -Value $text -Encoding UTF8 -NoNewline
        $htmlChanged++; $refsChanged += $count
        Write-Host ("  {0,-46} {1} refs" -f $book.Name, $count)
    }
}

if (Test-Path -LiteralPath $invDir) {
    $log | Export-Csv -LiteralPath (Join-Path $invDir 'convert_log.csv') -NoTypeInformation -Encoding UTF8
    $renames.GetEnumerator() | ForEach-Object { [pscustomobject]@{ old=$_.Key; new=$_.Value } } |
        Export-Csv -LiteralPath (Join-Path $invDir 'convert_renames.csv') -NoTypeInformation -Encoding UTF8
}

$after = (Get-ChildItem -LiteralPath $assets -Recurse -File | Measure-Object Length -Sum).Sum

Write-Host ""
Write-Host "Converted:     $done" -ForegroundColor Green
if ($failed -gt 0) { Write-Host "Failed:        $failed" -ForegroundColor Red }
Write-Host "Saved:         $([math]::Round($saved/1MB,1)) MB" -ForegroundColor Green
Write-Host "assets/ now:   $([math]::Round($after/1MB,1)) MB" -ForegroundColor Green
Write-Host "HTML files:    $htmlChanged changed, $refsChanged refs rewritten"
Write-Host "Image backups: $BackupTo"
Write-Host "HTML backups:  $htmlBak"
Write-Host ""
Write-Host "Verify nothing broke:" -ForegroundColor Cyan
Write-Host '  & "$env:USERPROFILE\Downloads\Invoke-LseCensus.ps1" -SourceDir "C:\Users\dstor\Downloads" -Job Files,Images,References' -ForegroundColor Cyan
Write-Host "  Then check INVENTORY\references.md: repo missing should be 0." -ForegroundColor Cyan
Write-Host ""
Write-Host "Rebuild:  python build.py --book 1" -ForegroundColor Cyan
Write-Host "Undo:     .\Convert-LseImages.ps1 -Restore -BackupTo `"$BackupTo`"  then  git checkout -- *.html" -ForegroundColor Cyan
Write-Host ""
