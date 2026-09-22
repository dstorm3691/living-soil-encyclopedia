<#
.SYNOPSIS
    Swaps Bugwood-approved images into the books.

.DESCRIPTION
    Covers two approvals:
      194930  cowpea curculio x3, eggplant flea beetle
      194939  tomato 2,4-D (Hansen), tomato glyphosate (Howard)

    For each mapping: finds the downloaded file by Bugwood image number,
    picks the largest if several exist, copies it into assets\ under the
    project naming convention, rewrites every HTML reference, and moves the
    old file to the archive.

    Registers each approval with Get-LseRights.ps1 and each credit with
    Build-LseFrontBack.ps1. Every registration is checked individually, so
    re-running never duplicates anything.

    Re-runnable. Drop a larger download in the folder and run again.

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
# Approvals
# ------------------------------------------------------------

$Requests = @(
    @{ Token = 'BW194930'; Number = '194930'; Date = '2026-09-19' }
    @{ Token = 'BW194939'; Number = '194939'; Date = '2026-09-22' }
)

# ------------------------------------------------------------
# Image swaps
# ------------------------------------------------------------

$Map = @(
    @{ Old = 'B30_022'; Id = '5333084'
       New = 'B30_022__LSE_FOUND_B27_ABIOTIC_Tomato_2-4DDrift_CuppedNewGrowth_MaryAnnHansen-VirginiaTech-Bugwood_BW194939' }
    @{ Old = 'B30_023'; Id = '5368741'
       New = 'B30_023__LSE_FOUND_B27_ABIOTIC_Tomato_GlyphosateInjury_YellowDistortedNewGrowth_NathanHoward-UKentucky-Bugwood_BW194939' }
    @{ Old = 'B30_027'; Id = '5619673'
       New = 'B30_027__LSE_FOUND_B27_PEST_Cowpea_CowpeaCurculio_PodDamageLarva_BrantleeSpakesRichter-UF-Bugwood_BW194930' }
    @{ Old = 'B30_028'; Id = '5619672'
       New = 'B30_028__LSE_FOUND_B27_PEST_Cowpea_CowpeaCurculio_LarvaInPod_BrantleeSpakesRichter-UF-Bugwood_BW194930' }
    @{ Old = 'B30_029'; Id = '5619670'
       New = 'B30_029__LSE_FOUND_B27_PEST_Cowpea_CowpeaCurculio_AdultScouting_BrantleeSpakesRichter-UF-Bugwood_BW194930' }
    @{ Old = 'B30_030'; Id = '5381045'
       New = 'B30_030__LSE_FOUND_B27_PEST_Eggplant_FleaBeetle_ShotHolePittedLeaf_DavidCappaert-Bugwood_BW194930' }
)

# ------------------------------------------------------------
# Credits, citation text copied verbatim from the Bugwood
# approval pages. Match patterns key on the new filenames.
# ------------------------------------------------------------

$Credits = @(
    @{ Match = '2-4DDrift.*BW194939'
       Credit = 'Photo: Mary Ann Hansen, Virginia Polytechnic Institute and State University, Bugwood.org. Used by permission (Bugwood image request 194939).' }
    @{ Match = 'GlyphosateInjury.*BW194939'
       Credit = 'Photo: Nathan Howard, University of Kentucky, Bugwood.org. Used by permission (Bugwood image request 194939).' }
    @{ Match = 'CowpeaCurculio.*BW194930'
       Credit = 'Photo: Brantlee Spakes Richter, University of Florida, Bugwood.org. Used by permission (Bugwood image request 194930).' }
    @{ Match = 'FleaBeetle.*BW194930'
       Credit = 'Photo: David Cappaert, Bugwood.org. Used by permission (Bugwood image request 194930).' }
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

    $newName = if ($src) { $m.New + $src.Extension.ToLower() } else { '' }
    $already = ($old -and $src -and $old.Name -eq $newName -and $old.Length -eq $src.Length)

    $plan.Add([pscustomobject]@{
        old_id   = $m.Old; bugwood = $m.Id
        old_file = if ($old) { $old.Name } else { '(not in assets)' }
        old_path = if ($old) { $old.FullName } else { '' }
        old_dims = if ($old) { Get-Dims $old.FullName } else { '' }
        old_kb   = if ($old) { [math]::Round($old.Length / 1KB, 0) } else { 0 }
        new_src  = if ($src) { $src.FullName } else { '' }
        new_dims = if ($src) { Get-Dims $src.FullName } else { '' }
        new_kb   = if ($src) { [math]::Round($src.Length / 1KB, 0) } else { 0 }
        new_name = $newName
        ok       = [bool]($src -and $old -and -not $already)
        already  = $already
    })
}

foreach ($p in $plan) {
    $color = if ($p.already) { 'DarkGray' } elseif ($p.ok) { 'White' } else { 'Yellow' }
    Write-Host "$($p.old_id)  <-  Bugwood $($p.bugwood)" -ForegroundColor $color
    Write-Host "    now:  $($p.old_dims.PadRight(11)) $("$($p.old_kb) KB".PadLeft(8))   $($p.old_file)"
    if ($p.already) {
        Write-Host "    already swapped, same file. Skipping." -ForegroundColor DarkGray
    }
    elseif ($p.new_src) {
        Write-Host "    new:  $($p.new_dims.PadRight(11)) $("$($p.new_kb) KB".PadLeft(8))   $($p.new_name)" -ForegroundColor Green
    }
    else {
        Write-Host "    new:  NOT FOUND (no file containing $($p.bugwood) in $DownloadDir)" -ForegroundColor Yellow
    }
    Write-Host ""
}

$ready = @($plan | Where-Object { $_.ok })
$done  = @($plan | Where-Object { $_.already })
Write-Host "Ready to swap: $($ready.Count)   Already done: $($done.Count)   Missing: $($plan.Count - $ready.Count - $done.Count)" -ForegroundColor Cyan
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
if ($ready.Count -gt 0) {
    foreach ($b in $books) {
        Copy-Item -LiteralPath $b.FullName -Destination (Join-Path $bak "$($b.BaseName)_preswap_$stamp.html") -Force
    }
}

foreach ($p in $ready) {
    $destDir  = Split-Path $p.old_path -Parent
    $destPath = Join-Path $destDir $p.new_name

    if ($p.old_path -eq $destPath) {
        # same name, just a larger source: overwrite in place
        Copy-Item -LiteralPath $p.old_path -Destination (Join-Path $ReplacedDir "$($p.old_file).$stamp") -Force
        Copy-Item -LiteralPath $p.new_src -Destination $destPath -Force
        Write-Host "  $($p.old_id): upgraded in place" -ForegroundColor Green
        continue
    }

    Copy-Item -LiteralPath $p.new_src -Destination $destPath -Force

    $refs = 0
    foreach ($b in $books) {
        $t = Get-Content -LiteralPath $b.FullName -Raw
        if ($t.Contains($p.old_file)) {
            $refs += ([regex]::Matches($t, [regex]::Escape($p.old_file))).Count
            Set-Content -LiteralPath $b.FullName -Value $t.Replace($p.old_file, $p.new_name) -Encoding UTF8 -NoNewline
        }
    }

    Move-Item -LiteralPath $p.old_path -Destination (Join-Path $ReplacedDir $p.old_file) -Force
    Write-Host "  $($p.old_id): swapped, $refs reference(s) rewritten" -ForegroundColor Green
}

# ------------------------------------------------------------
# Register approvals with the rights parser
# ------------------------------------------------------------

$rights = Join-Path $RepoRoot 'tools\Get-LseRights.ps1'
if (Test-Path -LiteralPath $rights) {
    $r = Get-Content -LiteralPath $rights -Raw
    $changed = $false

    foreach ($q in $Requests) {
        if (-not $r.Contains("'$($q.Token)'")) {
            $r = $r.Replace(
                '$LicenseTokens = [ordered]@{',
                "`$LicenseTokens = [ordered]@{`r`n    '$($q.Token)'      = @{ Class = 'GRANTED'; Note = 'Bugwood image request $($q.Number), approved $($q.Date)' }")
            $changed = $true
            Write-Host "  registered $($q.Token) with Get-LseRights.ps1" -ForegroundColor Green
        }
    }

    if (-not $r.Contains("`$lclass -eq 'GRANTED'")) {
        $r = $r.Replace(
            "else { `$verdict = 'clear'; `$ledger = 'open licence' }",
            "elseif (`$lclass -eq 'GRANTED') { `$verdict = 'clear'; `$ledger = 'granted, ' + `$lnote }`r`n        else { `$verdict = 'clear'; `$ledger = 'open licence' }")
        $changed = $true
    }

    if ($changed) { Set-Content -LiteralPath $rights -Value $r -Encoding UTF8 }
}

# ------------------------------------------------------------
# Register credits with the front and back matter generator
# ------------------------------------------------------------

$front = Join-Path $RepoRoot 'tools\Build-LseFrontBack.ps1'
if (Test-Path -LiteralPath $front) {
    $f = Get-Content -LiteralPath $front -Raw
    $inserted = 0

    foreach ($c in $Credits) {
        if ($f.Contains("'$($c.Match)'")) { continue }
        $entry = "`$Agreed = @(`r`n    @{ Match = '$($c.Match)'`r`n       Credit = '$($c.Credit)'`r`n       Holder = 'Bugwood Image Database, University of Georgia'; Status = 'granted' }`r`n"
        $f = $f.Replace('$Agreed = @(', $entry.TrimEnd())
        $inserted++
    }

    if ($inserted -gt 0) {
        Set-Content -LiteralPath $front -Value $f -Encoding UTF8
        Write-Host "  registered $inserted credit(s) with Build-LseFrontBack.ps1" -ForegroundColor Green
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
    Write-Host "FAILED. Back out:  git checkout -- *.html tools/   and restore assets from $ReplacedDir" -ForegroundColor Red
}
Write-Host ""
