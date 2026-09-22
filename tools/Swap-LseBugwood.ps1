<#
.SYNOPSIS
    Swaps Bugwood-approved images into the books.

.DESCRIPTION
    For each mapping: finds the downloaded Bugwood file by image number,
    copies it into assets\ under the project's naming convention, rewrites
    every HTML reference from the old file to the new one, and moves the
    old file to the archive.

    Also registers Bugwood request 194930 with Get-LseRights.ps1 and
    Build-LseFrontBack.ps1 so the rights report and the credits section
    both recognise the new files. Those edits are idempotent.

    Re-runnable. If you later download a larger version, run it again and
    it replaces the swapped file.

    Dry run by default.

.EXAMPLE
    .\tools\Swap-LseBugwood.ps1

.EXAMPLE
    .\tools\Swap-LseBugwood.ps1 -Execute
#>

[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$DownloadDir = "D:\LSE_ARCHIVE\bugwood_194930",
    [string]$ReplacedDir = "D:\LSE_ARCHIVE\replaced_images",
    [switch]$Execute
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

# ------------------------------------------------------------
# The four clear matches. Herbicide, squash and early blight
# images are deliberately excluded until their captions are
# checked against the diagnoses they would replace.
# ------------------------------------------------------------

$Map = @(
    @{ Old = 'B30_027'; Id = '5619673'
       New = 'B30_027__LSE_FOUND_B27_PEST_Cowpea_CowpeaCurculio_PodDamageLarva_BrantleeSpakesRichter-UF-Bugwood_BW194930' }
    @{ Old = 'B30_028'; Id = '5619672'
       New = 'B30_028__LSE_FOUND_B27_PEST_Cowpea_CowpeaCurculio_LarvaInPod_BrantleeSpakesRichter-UF-Bugwood_BW194930' }
    @{ Old = 'B30_029'; Id = '5619670'
       New = 'B30_029__LSE_FOUND_B27_PEST_Cowpea_CowpeaCurculio_AdultScouting_BrantleeSpakesRichter-UF-Bugwood_BW194930' }
    @{ Old = 'B30_030'; Id = '5381045'
       New = 'B30_030__LSE_FOUND_B27_PEST_Eggplant_FleaBeetle_ShotHolePittedLeaf_DavidCappaert-Bugwood_BW194930' }
)

function Get-Dims {
    param([string]$Path)
    $fs = $null
    try {
        $fs = [IO.File]::Open($Path, 'Open', 'Read', 'ReadWrite')
        $f = ([Windows.Media.Imaging.BitmapDecoder]::Create($fs, 'DelayCreation', 'None')).Frames[0]
        return "$($f.PixelWidth)x$($f.PixelHeight)"
    }
    catch { return '?' }
    finally { if ($fs) { $fs.Dispose() } }
}

Write-Host ""
Write-Host "Repo:      $RepoRoot"
Write-Host "Downloads: $DownloadDir"
Write-Host "Mode:      $(if ($Execute) { 'EXECUTE' } else { 'DRY RUN' })" -ForegroundColor $(if ($Execute) { 'Yellow' } else { 'Cyan' })
Write-Host ""

if (-not (Test-Path -LiteralPath $DownloadDir)) {
    Write-Host "Download folder not found: $DownloadDir" -ForegroundColor Red
    exit 1
}

# unpack any Bugwood zip
foreach ($z in (Get-ChildItem -LiteralPath $DownloadDir -Filter *.zip -File)) {
    $x = Join-Path $DownloadDir ([IO.Path]::GetFileNameWithoutExtension($z.Name))
    if (-not (Test-Path -LiteralPath $x)) {
        Write-Host "Unzipping $($z.Name)" -ForegroundColor DarkGray
        Expand-Archive -LiteralPath $z.FullName -DestinationPath $x -Force
    }
}

$downloads = @(Get-ChildItem -LiteralPath $DownloadDir -Recurse -File |
               Where-Object { $_.Extension -match '(?i)\.(jpe?g|png|tif)$' })

$plan = New-Object System.Collections.Generic.List[object]

foreach ($m in $Map) {
    $src = $downloads | Where-Object { $_.Name -match $m.Id } |
           Sort-Object Length -Descending | Select-Object -First 1
    $old = Get-ChildItem -LiteralPath $assets -Recurse -File |
           Where-Object { $_.Name -like "$($m.Old)__*" } | Select-Object -First 1

    $row = [ordered]@{
        old_id = $m.Old; bugwood = $m.Id
        old_file = if ($old) { $old.Name } else { '(not in assets)' }
        old_dims = if ($old) { Get-Dims $old.FullName } else { '' }
        old_kb   = if ($old) { [math]::Round($old.Length / 1KB, 0) } else { 0 }
        new_src  = if ($src) { $src.FullName } else { '' }
        new_dims = if ($src) { Get-Dims $src.FullName } else { '' }
        new_kb   = if ($src) { [math]::Round($src.Length / 1KB, 0) } else { 0 }
        new_name = if ($src) { $m.New + $src.Extension.ToLower() } else { '' }
        ok = [bool]($src -and $old)
    }
    $plan.Add([pscustomobject]$row)
}

foreach ($p in $plan) {
    $color = if ($p.ok) { 'White' } else { 'Yellow' }
    Write-Host "$($p.old_id)  <-  Bugwood $($p.bugwood)" -ForegroundColor $color
    Write-Host "    now:  $($p.old_dims.PadRight(11)) $("$($p.old_kb) KB".PadLeft(8))   $($p.old_file)"
    if ($p.new_src) {
        Write-Host "    new:  $($p.new_dims.PadRight(11)) $("$($p.new_kb) KB".PadLeft(8))   $($p.new_name)" -ForegroundColor Green
    }
    else {
        Write-Host "    new:  NOT FOUND in $DownloadDir  (no file containing $($p.bugwood))" -ForegroundColor Yellow
    }
    Write-Host ""
}

$ready = @($plan | Where-Object { $_.ok })
Write-Host "Ready to swap: $($ready.Count) of $($plan.Count)" -ForegroundColor Cyan
Write-Host ""

if (-not $Execute) {
    Write-Host "DRY RUN. Nothing changed." -ForegroundColor Cyan
    Write-Host "Open the new files and confirm each shows the right feature, then re-run with -Execute." -ForegroundColor Cyan
    Write-Host ""
    exit 0
}

# ------------------------------------------------------------
# Swap
# ------------------------------------------------------------

if (-not (Test-Path -LiteralPath $ReplacedDir)) { New-Item -ItemType Directory -Path $ReplacedDir -Force | Out-Null }
$bak = Join-Path $RepoRoot '.build\html_backup'
if (-not (Test-Path -LiteralPath $bak)) { New-Item -ItemType Directory -Path $bak -Force | Out-Null }
$stamp = (Get-Date).ToString('yyyyMMdd_HHmmss')

$books = @(Get-ChildItem -LiteralPath $RepoRoot -Filter "LSE_*.html" -File)
foreach ($b in $books) {
    Copy-Item -LiteralPath $b.FullName -Destination (Join-Path $bak "$($b.BaseName)_preswap_$stamp.html") -Force
}

foreach ($p in $ready) {
    $oldPath = Get-ChildItem -LiteralPath $assets -Recurse -File |
               Where-Object { $_.Name -eq $p.old_file } | Select-Object -First 1
    $destDir = Split-Path $oldPath.FullName -Parent
    $destPath = Join-Path $destDir $p.new_name

    Copy-Item -LiteralPath $p.new_src -Destination $destPath -Force

    $refs = 0
    foreach ($b in $books) {
        $t = Get-Content -LiteralPath $b.FullName -Raw
        if ($t.Contains($p.old_file)) {
            $refs += ([regex]::Matches($t, [regex]::Escape($p.old_file))).Count
            Set-Content -LiteralPath $b.FullName -Value $t.Replace($p.old_file, $p.new_name) -Encoding UTF8 -NoNewline
        }
    }

    if ($oldPath.FullName -ne $destPath) {
        Move-Item -LiteralPath $oldPath.FullName -Destination (Join-Path $ReplacedDir $p.old_file) -Force
    }
    Write-Host "  $($p.old_id): swapped, $refs reference(s) rewritten" -ForegroundColor Green
}

# ------------------------------------------------------------
# Register the approval with the rights and credits tools
# ------------------------------------------------------------

$rights = Join-Path $RepoRoot 'tools\Get-LseRights.ps1'
if (Test-Path -LiteralPath $rights) {
    $r = Get-Content -LiteralPath $rights -Raw
    if (-not $r.Contains("'BW194930'")) {
        $r = $r.Replace(
            '$LicenseTokens = [ordered]@{',
            "`$LicenseTokens = [ordered]@{`r`n    'BW194930'      = @{ Class = 'GRANTED'; Note = 'Bugwood image request 194930, approved' }")
        $r = $r.Replace(
            "else { `$verdict = 'clear'; `$ledger = 'open licence' }",
            "elseif (`$lclass -eq 'GRANTED') { `$verdict = 'clear'; `$ledger = 'granted, ' + `$lnote }`r`n        else { `$verdict = 'clear'; `$ledger = 'open licence' }")
        Set-Content -LiteralPath $rights -Value $r -Encoding UTF8
        Write-Host "  registered BW194930 with Get-LseRights.ps1" -ForegroundColor Green
    }
}

$front = Join-Path $RepoRoot 'tools\Build-LseFrontBack.ps1'
if (Test-Path -LiteralPath $front) {
    $f = Get-Content -LiteralPath $front -Raw
    if (-not $f.Contains('BW194930')) {
        $entries = @"
`$Agreed = @(
    @{ Match = 'CowpeaCurculio.*BW194930'
       Credit = 'Photo: Brantlee Spakes Richter, University of Florida, Bugwood.org. Used by permission (Bugwood image request 194930).'
       Holder = 'Bugwood Image Database, University of Georgia'; Status = 'granted' }

    @{ Match = 'FleaBeetle.*BW194930'
       Credit = 'Photo: David Cappaert, Bugwood.org. Used by permission (Bugwood image request 194930).'
       Holder = 'Bugwood Image Database, University of Georgia'; Status = 'granted' }

"@
        $f = $f.Replace('$Agreed = @(', $entries.TrimEnd())
        Set-Content -LiteralPath $front -Value $f -Encoding UTF8
        Write-Host "  registered Bugwood credits with Build-LseFrontBack.ps1" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Old files moved to: $ReplacedDir"
Write-Host "HTML backups:       $bak"
Write-Host ""
Write-Host "Running verify.py..." -ForegroundColor Yellow
Write-Host ""
Push-Location $RepoRoot
try { & python verify.py; $code = $LASTEXITCODE } finally { Pop-Location }
Write-Host ""
if ($code -eq 0) {
    Write-Host "PASS. Commit, then re-run the census and rights report." -ForegroundColor Green
}
else {
    Write-Host "FAILED. Back out:  git checkout -- *.html tools/  and restore assets from $ReplacedDir" -ForegroundColor Red
}
Write-Host ""
