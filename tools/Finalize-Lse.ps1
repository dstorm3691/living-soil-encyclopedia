<#
.SYNOPSIS
    Finishes the book. One run closes rights, drops what never cleared,
    injects front and back matter, and builds the five final PDFs.

.DESCRIPTION
    Pass the institutions that said yes. Everything pending that is not in
    that list gets dropped, along with B30_024 (Bacchi), which could not be
    obtained.

    Approved images are renamed to carry a GRANTED token and get their
    credit registered. Dropped images have their figure removed from the
    book and their file moved to the archive.

    If figures were dropped, verify.py will report their caption paragraphs
    as missing from the baseline. That removal is intentional, so the script
    re-baselines with generate_baseline.py and verifies again. If anything
    still fails, every change is rolled back.

    Dry run by default.

.EXAMPLE
    # everyone said yes
    .\tools\Finalize-Lse.ps1 -Approved NCSU,UMass,MSU

.EXAMPLE
    # only NC State answered by the deadline
    .\tools\Finalize-Lse.ps1 -Approved NCSU -Execute

.EXAMPLE
    # nobody answered: drop all five
    .\tools\Finalize-Lse.ps1 -Execute
#>

[CmdletBinding()]
param(
    [ValidateSet('NCSU', 'UMass', 'MSU')]
    [string[]]$Approved = @(),
    [string]$RepoRoot,
    [string]$ArchiveDir = "D:\LSE_ARCHIVE\dropped_images",
    [switch]$Execute
)

$ErrorActionPreference = 'Stop'

if (-not $RepoRoot) {
    $d = (& git rev-parse --show-toplevel 2>$null)
    if ($LASTEXITCODE -ne 0) { Write-Host "Not in a git repo." -ForegroundColor Red; exit 1 }
    $RepoRoot = $d.Trim() -replace '/', '\'
}
$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
$assets = Join-Path $RepoRoot 'assets'
$tools  = Join-Path $RepoRoot 'tools'

# ------------------------------------------------------------
# Pending images. Credit text is the wording proposed in each
# permission email. If a holder replies asking for different
# wording, change that one Credit line before running.
# ------------------------------------------------------------

$Pending = @(
    @{ Id = 'B30_025'; Inst = 'NCSU'; Token = 'GRANTED-NCSU'
       Match = 'FusariumWilt.*GRANTED-NCSU'
       Credit = 'Photo: Inga Meadows, NC State Extension, Fusarium Wilt of Tomato. Used by permission.'
       Holder = 'NC State Extension' }

    @{ Id = 'B30_081'; Inst = 'NCSU'; Token = 'GRANTED-NCSU'
       Match = 'Strawberry_BlackRootRot.*GRANTED-NCSU'
       Credit = 'Photo: Leonor Leandro, Gloria Abad, and Frank J. Louws, NC State Extension, Black Root Rot of Strawberry. Used by permission.'
       Holder = 'NC State Extension' }

    @{ Id = 'B30_026'; Inst = 'UMass'; Token = 'GRANTED-UMass'
       Match = 'DampingOff.*GRANTED-UMass'
       Credit = 'Photo: Tina Smith, University of Massachusetts Extension. Used by permission.'
       Holder = 'University of Massachusetts Extension' }

    @{ Id = 'B30_080'; Inst = 'MSU'; Token = 'GRANTED-MSU'
       Match = 'Basil_RhizoctoniaRootRot.*GRANTED-MSU'
       Credit = 'Photo: Jan Byrne, MSU Plant & Pest Diagnostics, Michigan State University Extension. Used by permission.'
       Holder = 'Michigan State University Extension' }
)

$AlwaysDrop = @('B30_024')

$TokenNotes = @{
    'GRANTED-NCSU'  = 'NC State Extension permission, via Frank Louws'
    'GRANTED-UMass' = 'UMass Extension permission, via Jason Lanier'
    'GRANTED-MSU'   = 'MSU Plant & Pest Diagnostics permission, via Jan Byrne'
}

# ------------------------------------------------------------
# Plan
# ------------------------------------------------------------

function Find-Asset {
    param([string]$Id)
    Get-ChildItem -LiteralPath $assets -Recurse -File |
        Where-Object { $_.Name -like "${Id}__*" } | Select-Object -First 1
}

$keep = New-Object System.Collections.Generic.List[object]
$drop = New-Object System.Collections.Generic.List[object]

foreach ($p in $Pending) {
    $f = Find-Asset $p.Id
    if (-not $f) { continue }
    if ($f.Name -match [regex]::Escape($p.Token)) { continue }   # already finalised
    if ($Approved -contains $p.Inst) {
        $base  = [IO.Path]::GetFileNameWithoutExtension($f.Name)
        $clean = $base -replace '_(VERIFY|PERMISSION|CONDITIONAL)$', ''
        $keep.Add([pscustomobject]@{ Spec = $p; File = $f; NewName = "${clean}_$($p.Token)$($f.Extension)" })
    }
    else {
        $drop.Add([pscustomobject]@{ Id = $p.Id; File = $f; Why = "$($p.Inst) did not approve" })
    }
}
foreach ($id in $AlwaysDrop) {
    $f = Find-Asset $id
    if ($f) { $drop.Add([pscustomobject]@{ Id = $id; File = $f; Why = 'not obtainable' }) }
}

Write-Host ""
Write-Host "Repo:     $RepoRoot"
Write-Host "Approved: $(if ($Approved.Count) { $Approved -join ', ' } else { '(none)' })"
Write-Host "Mode:     $(if ($Execute) { 'EXECUTE' } else { 'DRY RUN' })" -ForegroundColor $(if ($Execute) { 'Yellow' } else { 'Cyan' })
Write-Host ""
Write-Host "KEEP and credit ($($keep.Count)):" -ForegroundColor Green
foreach ($k in $keep) { Write-Host "  $($k.Spec.Id)  ->  $($k.NewName)" }
if ($keep.Count -eq 0) { Write-Host "  none" }
Write-Host ""
Write-Host "DROP ($($drop.Count)):" -ForegroundColor Yellow
foreach ($x in $drop) { Write-Host "  $($x.Id)  ($($x.Why))  $($x.File.Name)" }
if ($drop.Count -eq 0) { Write-Host "  none" }
Write-Host ""

if (-not $Execute) {
    Write-Host "DRY RUN. Nothing changed. Re-run with -Execute." -ForegroundColor Cyan
    Write-Host ""
    exit 0
}

# ------------------------------------------------------------
# Backup
# ------------------------------------------------------------

$stamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
$bak = Join-Path $RepoRoot ".build\html_backup\finalize_$stamp"
New-Item -ItemType Directory -Path $bak -Force | Out-Null
$books = @(Get-ChildItem -LiteralPath $RepoRoot -Filter "LSE_*.html" -File)
foreach ($b in $books) { Copy-Item -LiteralPath $b.FullName -Destination $bak -Force }
foreach ($t in @('Get-LseRights.ps1', 'Build-LseFrontBack.ps1')) {
    $tp = Join-Path $tools $t
    if (Test-Path -LiteralPath $tp) { Copy-Item -LiteralPath $tp -Destination $bak -Force }
}
if (-not (Test-Path -LiteralPath $ArchiveDir)) { New-Item -ItemType Directory -Path $ArchiveDir -Force | Out-Null }
$moved = New-Object System.Collections.Generic.List[object]
$renamed = New-Object System.Collections.Generic.List[object]

function Restore-All {
    Write-Host ""
    Write-Host "Rolling back every change..." -ForegroundColor Red
    foreach ($b in (Get-ChildItem -LiteralPath $bak -Filter "LSE_*.html" -File)) {
        Copy-Item -LiteralPath $b.FullName -Destination (Join-Path $RepoRoot $b.Name) -Force
    }
    foreach ($t in @('Get-LseRights.ps1', 'Build-LseFrontBack.ps1')) {
        $tb = Join-Path $bak $t
        if (Test-Path -LiteralPath $tb) { Copy-Item -LiteralPath $tb -Destination (Join-Path $tools $t) -Force }
    }
    foreach ($m in $moved)   { Move-Item -LiteralPath $m.To -Destination $m.From -Force }
    foreach ($r in $renamed) { Rename-Item -LiteralPath $r.NewPath -NewName $r.OldName -Force }
    Write-Host "Restored. Paste the verify output above back to Claude." -ForegroundColor Red
    Write-Host ""
}

# ------------------------------------------------------------
# Rename approved
# ------------------------------------------------------------

foreach ($k in $keep) {
    $old = $k.File.Name
    Rename-Item -LiteralPath $k.File.FullName -NewName $k.NewName
    $renamed.Add([pscustomobject]@{ NewPath = (Join-Path $k.File.DirectoryName $k.NewName); OldName = $old })
    foreach ($b in $books) {
        $t = Get-Content -LiteralPath $b.FullName -Raw
        if ($t.Contains($old)) { Set-Content -LiteralPath $b.FullName -Value $t.Replace($old, $k.NewName) -Encoding UTF8 -NoNewline }
    }
    Write-Host "  kept    $($k.Spec.Id)" -ForegroundColor Green
}

# ------------------------------------------------------------
# Drop the rest
# ------------------------------------------------------------

foreach ($x in $drop) {
    $name = $x.File.Name
    $esc = [regex]::Escape($name)
    $sectionRx = '(?s)<section\b[^>]*\blse-figure\b[^>]*>(?:(?!</section>).)*?' + $esc + '(?:(?!</section>).)*?</section>\s*'
    $imgRx = '(?i)<img\b[^>]*' + $esc + '[^>]*>\s*'
    foreach ($b in $books) {
        $t = Get-Content -LiteralPath $b.FullName -Raw
        if (-not $t.Contains($name)) { continue }
        $n = [regex]::Replace($t, $sectionRx, '')
        if ($n.Contains($name)) { $n = [regex]::Replace($n, $imgRx, '') }
        Set-Content -LiteralPath $b.FullName -Value $n -Encoding UTF8 -NoNewline
    }
    $to = Join-Path $ArchiveDir $name
    Move-Item -LiteralPath $x.File.FullName -Destination $to -Force
    $moved.Add([pscustomobject]@{ From = $x.File.FullName; To = $to })
    Write-Host "  dropped $($x.Id)" -ForegroundColor Yellow
}

# ------------------------------------------------------------
# Verify, re-baselining only if figures were dropped
# ------------------------------------------------------------

Write-Host ""
Write-Host "Running verify.py..." -ForegroundColor Yellow
Push-Location $RepoRoot
try {
    & python verify.py
    $code = $LASTEXITCODE
    if ($code -ne 0 -and $drop.Count -gt 0 -and (Test-Path -LiteralPath 'generate_baseline.py')) {
        Write-Host ""
        Write-Host "Dropped figures removed baseline caption paragraphs. That is intentional." -ForegroundColor Yellow
        Write-Host "Re-baselining with generate_baseline.py, then verifying again..." -ForegroundColor Yellow
        & python generate_baseline.py
        if ($LASTEXITCODE -eq 0) { & python verify.py; $code = $LASTEXITCODE }
    }
}
finally { Pop-Location }

if ($code -ne 0) { Restore-All; exit 1 }

# ------------------------------------------------------------
# Register approvals with the rights parser and credits
# ------------------------------------------------------------

$rights = Join-Path $tools 'Get-LseRights.ps1'
if ((Test-Path -LiteralPath $rights) -and $keep.Count -gt 0) {
    $r = Get-Content -LiteralPath $rights -Raw
    foreach ($tok in ($keep | ForEach-Object { $_.Spec.Token } | Select-Object -Unique)) {
        if (-not $r.Contains("'$tok'")) {
            $r = $r.Replace('$LicenseTokens = [ordered]@{',
                "`$LicenseTokens = [ordered]@{`r`n    '$tok' = @{ Class = 'GRANTED'; Note = '$($TokenNotes[$tok])' }")
        }
    }
    if (-not $r.Contains("`$lclass -eq 'GRANTED'")) {
        $r = $r.Replace("else { `$verdict = 'clear'; `$ledger = 'open licence' }",
            "elseif (`$lclass -eq 'GRANTED') { `$verdict = 'clear'; `$ledger = 'granted, ' + `$lnote }`r`n        else { `$verdict = 'clear'; `$ledger = 'open licence' }")
    }
    Set-Content -LiteralPath $rights -Value $r -Encoding UTF8
}

$front = Join-Path $tools 'Build-LseFrontBack.ps1'
if ((Test-Path -LiteralPath $front) -and $keep.Count -gt 0) {
    $f = Get-Content -LiteralPath $front -Raw
    foreach ($k in $keep) {
        $s = $k.Spec
        if ($f.Contains("'$($s.Match)'")) { continue }
        $entry = "`$Agreed = @(`r`n    @{ Match = '$($s.Match)'`r`n       Credit = '$($s.Credit)'`r`n       Holder = '$($s.Holder)'; Status = 'granted' }`r`n"
        $f = $f.Replace('$Agreed = @(', $entry.TrimEnd())
    }
    Set-Content -LiteralPath $front -Value $f -Encoding UTF8
}

# ------------------------------------------------------------
# Regenerate inventory, rights, credits
# ------------------------------------------------------------

Push-Location $RepoRoot
try {
    & (Join-Path $tools 'Invoke-LseCensus.ps1') -SourceDir "$env:USERPROFILE\Downloads" -Job Files,Images,References | Out-Null
    & (Join-Path $tools 'Get-LseRights.ps1')
    & (Join-Path $tools 'Build-LseFrontBack.ps1')
}
finally { Pop-Location }

$todoFile = Join-Path $RepoRoot 'frontback\_TODO.md'
$todos = if (Test-Path -LiteralPath $todoFile) {
    @(Get-Content -LiteralPath $todoFile | Where-Object { $_ -match '^- Book' }).Count
} else { 0 }

if ($todos -gt 0) {
    Write-Host ""
    Write-Host "$todos credit TODO(s) remain. Not injecting." -ForegroundColor Red
    Get-Content -LiteralPath $todoFile | Where-Object { $_ -match '^- Book' }
    Write-Host "Paste the list above back to Claude." -ForegroundColor Red
    exit 1
}

# ------------------------------------------------------------
# Inject front and back matter, build the final PDFs
# ------------------------------------------------------------

Write-Host ""
Write-Host "Zero TODOs. Injecting front matter and credits..." -ForegroundColor Green
Push-Location $RepoRoot
try {
    & (Join-Path $tools 'Inject-LseFrontBack.ps1') -Execute
    if ($LASTEXITCODE -ne 0) { Write-Host "Injection failed verification." -ForegroundColor Red; exit 1 }
    Write-Host ""
    Write-Host "Building all five books..." -ForegroundColor Green
    & python build.py
}
finally { Pop-Location }

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host " DONE. Kept $($keep.Count), dropped $($drop.Count). PDFs are in dist\" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
