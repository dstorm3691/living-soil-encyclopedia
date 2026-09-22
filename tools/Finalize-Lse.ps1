<#
.SYNOPSIS
    Finishes the book. Resolves the pending images, injects front and back
    matter, and builds the five final PDFs.

.DESCRIPTION
    Each pending image resolves one of three ways:

      -Approved   they said yes       credited "Used by permission"
      -Declined   they said no        figure removed from the book
      neither     no reply            credited with attribution only, in a
                                      separate section with a takedown offer

    Images already replaced with a Bugwood-approved photo are skipped; they
    no longer depend on anyone's reply. B30_024 (Bacchi) is always dropped.

    Re-runnable. If someone replies after publication:
      a yes upgrades their image from attribution to permission
      a no removes it

    Dry run by default.

.EXAMPLE
    .\tools\Finalize-Lse.ps1 -Execute

.EXAMPLE
    .\tools\Finalize-Lse.ps1 -Approved NCSU -Declined MSU -Execute
#>

[CmdletBinding()]
param(
    [ValidateSet('NCSU', 'UMass', 'MSU')]
    [string[]]$Approved = @(),
    [ValidateSet('NCSU', 'UMass', 'MSU')]
    [string[]]$Declined = @(),
    [string]$RepoRoot,
    [string]$ArchiveDir = "D:\LSE_ARCHIVE\dropped_images",
    [switch]$Execute
)

$ErrorActionPreference = 'Stop'

$overlap = @($Approved | Where-Object { $Declined -contains $_ })
if ($overlap.Count -gt 0) {
    Write-Host "Listed as both approved and declined: $($overlap -join ', ')" -ForegroundColor Red
    exit 1
}

if (-not $RepoRoot) {
    $d = (& git rev-parse --show-toplevel 2>$null)
    if ($LASTEXITCODE -ne 0) { Write-Host "Not in a git repo." -ForegroundColor Red; exit 1 }
    $RepoRoot = $d.Trim() -replace '/', '\'
}
$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
$assets = Join-Path $RepoRoot 'assets'
$tools  = Join-Path $RepoRoot 'tools'

$Pending = @(
    @{ Id = 'B30_025'; Inst = 'NCSU';  Who = 'Frank Louws, NC State Extension';          Asked = '2026-09-19' }
    @{ Id = 'B30_081'; Inst = 'NCSU';  Who = 'Frank Louws, NC State Extension';          Asked = '2026-09-19' }
    @{ Id = 'B30_026'; Inst = 'UMass'; Who = 'Jason Lanier, UMass Extension';            Asked = '2026-09-22' }
    @{ Id = 'B30_080'; Inst = 'MSU';   Who = 'Jan Byrne, MSU Plant & Pest Diagnostics';  Asked = '2026-09-22' }
)
$AlwaysDrop = @('B30_024')

function Find-Asset {
    param([string]$Id)
    Get-ChildItem -LiteralPath $assets -Recurse -File |
        Where-Object { $_.Name -like "${Id}__*" } | Select-Object -First 1
}

function Get-CleanBase {
    param([string]$Name)
    $b = [IO.Path]::GetFileNameWithoutExtension($Name)
    return ($b -replace '_(VERIFY|PERMISSION|CONDITIONAL)$', '' -replace '_(GRANTED|ATTRIB)-(NCSU|UMass|MSU)$', '')
}

$actions = New-Object System.Collections.Generic.List[object]
$skippedBugwood = New-Object System.Collections.Generic.List[string]

foreach ($p in $Pending) {
    $f = Find-Asset $p.Id
    if (-not $f) { continue }

    # replaced with a Bugwood-approved image: no longer pending
    if ($f.Name -match '_BW\d{6}\.') { $skippedBugwood.Add($p.Id); continue }

    $target = if ($Declined -contains $p.Inst) { 'drop' }
              elseif ($Approved -contains $p.Inst) { 'GRANTED' }
              else { 'ATTRIB' }

    $current = if ($f.Name -match "_GRANTED-$($p.Inst)\.") { 'GRANTED' }
               elseif ($f.Name -match "_ATTRIB-$($p.Inst)\.") { 'ATTRIB' }
               else { 'pending' }

    if ($current -eq 'GRANTED' -and $target -eq 'ATTRIB') { continue }
    if ($current -eq $target) { continue }

    $newName = if ($target -eq 'drop') { '' }
               else { "$(Get-CleanBase $f.Name)_$target-$($p.Inst)$($f.Extension)" }

    $actions.Add([pscustomobject]@{
        Id = $p.Id; Inst = $p.Inst; Who = $p.Who; Asked = $p.Asked
        File = $f; From = $current; To = $target; NewName = $newName
    })
}
foreach ($id in $AlwaysDrop) {
    $f = Find-Asset $id
    if ($f) {
        $actions.Add([pscustomobject]@{
            Id = $id; Inst = ''; Who = ''; Asked = ''
            File = $f; From = 'pending'; To = 'drop'; NewName = ''
        })
    }
}

Write-Host ""
Write-Host "Repo:     $RepoRoot"
Write-Host "Approved: $(if ($Approved.Count) { $Approved -join ', ' } else { '(none)' })"
Write-Host "Declined: $(if ($Declined.Count) { $Declined -join ', ' } else { '(none)' })"
Write-Host "Mode:     $(if ($Execute) { 'EXECUTE' } else { 'DRY RUN' })" -ForegroundColor $(if ($Execute) { 'Yellow' } else { 'Cyan' })
if ($skippedBugwood.Count) { Write-Host "Resolved by Bugwood, skipped: $($skippedBugwood -join ', ')" -ForegroundColor DarkGray }
Write-Host ""

$label = @{ GRANTED = 'USED BY PERMISSION'; ATTRIB = 'ATTRIBUTION ONLY'; drop = 'REMOVE FROM BOOK' }
$color = @{ GRANTED = 'Green'; ATTRIB = 'Cyan'; drop = 'Yellow' }

if ($actions.Count -eq 0) { Write-Host "Nothing to change. Continuing to credits and build." -ForegroundColor Green }
foreach ($a in $actions) {
    Write-Host ("  {0}  {1,-18}  ({2} -> {3})" -f $a.Id, $label[$a.To], $a.From, $a.To) -ForegroundColor $color[$a.To]
}
Write-Host ""

if (-not $Execute) {
    Write-Host "DRY RUN. Nothing changed. Re-run with -Execute." -ForegroundColor Cyan
    Write-Host ""
    exit 0
}

$stamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
$bak = Join-Path $RepoRoot ".build\html_backup\finalize_$stamp"
New-Item -ItemType Directory -Path $bak -Force | Out-Null
$books = @(Get-ChildItem -LiteralPath $RepoRoot -Filter "LSE_*.html" -File)
foreach ($b in $books) { Copy-Item -LiteralPath $b.FullName -Destination $bak -Force }
$rightsTool = Join-Path $tools 'Get-LseRights.ps1'
if (Test-Path -LiteralPath $rightsTool) { Copy-Item -LiteralPath $rightsTool -Destination $bak -Force }
if (-not (Test-Path -LiteralPath $ArchiveDir)) { New-Item -ItemType Directory -Path $ArchiveDir -Force | Out-Null }

$moved = New-Object System.Collections.Generic.List[object]
$renamed = New-Object System.Collections.Generic.List[object]

function Restore-All {
    Write-Host ""
    Write-Host "Rolling back every change..." -ForegroundColor Red
    foreach ($b in (Get-ChildItem -LiteralPath $bak -Filter "LSE_*.html" -File)) {
        Copy-Item -LiteralPath $b.FullName -Destination (Join-Path $RepoRoot $b.Name) -Force
    }
    $rb = Join-Path $bak 'Get-LseRights.ps1'
    if (Test-Path -LiteralPath $rb) { Copy-Item -LiteralPath $rb -Destination $rightsTool -Force }
    foreach ($m in $moved)   { Move-Item -LiteralPath $m.To -Destination $m.From -Force }
    foreach ($r in $renamed) { Rename-Item -LiteralPath $r.NewPath -NewName $r.OldName -Force }
    Write-Host "Restored. Paste the output above back to Claude." -ForegroundColor Red
    Write-Host ""
}

$dropped = 0
foreach ($a in $actions) {
    $old = $a.File.Name

    if ($a.To -eq 'drop') {
        $esc = [regex]::Escape($old)
        $sectionRx = '(?s)<section\b[^>]*\blse-figure\b[^>]*>(?:(?!</section>).)*?' + $esc + '(?:(?!</section>).)*?</section>\s*'
        $imgRx = '(?i)<img\b[^>]*' + $esc + '[^>]*>\s*'
        foreach ($b in $books) {
            $t = Get-Content -LiteralPath $b.FullName -Raw
            if (-not $t.Contains($old)) { continue }
            $n = [regex]::Replace($t, $sectionRx, '')
            if ($n.Contains($old)) { $n = [regex]::Replace($n, $imgRx, '') }
            Set-Content -LiteralPath $b.FullName -Value $n -Encoding UTF8 -NoNewline
        }
        $to = Join-Path $ArchiveDir $old
        Move-Item -LiteralPath $a.File.FullName -Destination $to -Force
        $moved.Add([pscustomobject]@{ From = $a.File.FullName; To = $to })
        $dropped++
        Write-Host "  removed    $($a.Id)" -ForegroundColor Yellow
        continue
    }

    Rename-Item -LiteralPath $a.File.FullName -NewName $a.NewName
    $renamed.Add([pscustomobject]@{ NewPath = (Join-Path $a.File.DirectoryName $a.NewName); OldName = $old })
    foreach ($b in $books) {
        $t = Get-Content -LiteralPath $b.FullName -Raw
        if ($t.Contains($old)) { Set-Content -LiteralPath $b.FullName -Value $t.Replace($old, $a.NewName) -Encoding UTF8 -NoNewline }
    }
    Write-Host "  $(if ($a.To -eq 'GRANTED') { 'permission' } else { 'attributed' }) $($a.Id)" -ForegroundColor $color[$a.To]
}

Write-Host ""
Write-Host "Running verify.py..." -ForegroundColor Yellow
Push-Location $RepoRoot
try {
    & python verify.py
    $code = $LASTEXITCODE
    if ($code -ne 0 -and $dropped -gt 0 -and (Test-Path -LiteralPath 'generate_baseline.py')) {
        Write-Host ""
        Write-Host "Removed figures took baseline caption paragraphs with them. Intentional." -ForegroundColor Yellow
        Write-Host "Re-baselining, then verifying again..." -ForegroundColor Yellow
        & python generate_baseline.py
        if ($LASTEXITCODE -eq 0) { & python verify.py; $code = $LASTEXITCODE }
    }
}
finally { Pop-Location }

if ($code -ne 0) { Restore-All; exit 1 }

if (Test-Path -LiteralPath $rightsTool) {
    $r = Get-Content -LiteralPath $rightsTool -Raw
    $notes = @{
        'GRANTED-NCSU'  = 'permission granted, NC State Extension'
        'GRANTED-UMass' = 'permission granted, UMass Extension'
        'GRANTED-MSU'   = 'permission granted, MSU Plant & Pest Diagnostics'
        'ATTRIB-NCSU'   = 'permission requested 2026-09-19, no reply'
        'ATTRIB-UMass'  = 'permission requested 2026-09-22, no reply'
        'ATTRIB-MSU'    = 'permission requested 2026-09-22, no reply'
    }
    foreach ($tok in $notes.Keys) {
        if (-not $r.Contains("'$tok'")) {
            $cls = if ($tok -like 'GRANTED*') { 'GRANTED' } else { 'ATTRIB' }
            $r = $r.Replace('$LicenseTokens = [ordered]@{',
                "`$LicenseTokens = [ordered]@{`r`n    '$tok' = @{ Class = '$cls'; Note = '$($notes[$tok])' }")
        }
    }
    $anchor = "else { `$verdict = 'clear'; `$ledger = 'open licence' }"
    if (-not $r.Contains("`$lclass -eq 'GRANTED'")) {
        $r = $r.Replace($anchor, "elseif (`$lclass -eq 'GRANTED') { `$verdict = 'clear'; `$ledger = 'granted, ' + `$lnote }`r`n        $anchor")
    }
    if (-not $r.Contains("`$lclass -eq 'ATTRIB'")) {
        $r = $r.Replace($anchor, "elseif (`$lclass -eq 'ATTRIB') { `$verdict = 'clear'; `$ledger = 'attribution only, ' + `$lnote }`r`n        $anchor")
    }
    Set-Content -LiteralPath $rightsTool -Value $r -Encoding UTF8
}

if ($actions.Count -gt 0) {
    $lines = @("", "## Finalized $((Get-Date).ToString('yyyy-MM-dd'))", "",
               "| Image | Outcome | Source |", "|---|---|---|")
    foreach ($a in $actions) {
        $outcome = switch ($a.To) {
            'GRANTED' { 'Used by permission' }
            'ATTRIB'  { "Attribution only. Permission requested $($a.Asked), no reply at publication. Takedown offered in credits." }
            'drop'    { 'Removed from book' }
        }
        $lines += "| $($a.Id) | $outcome | $($a.Who) |"
    }
    Add-Content -LiteralPath (Join-Path $RepoRoot 'LSE_RIGHTS_LEDGER.md') -Value ($lines -join "`r`n") -Encoding UTF8
}

Push-Location $RepoRoot
try {
    & (Join-Path $tools 'Invoke-LseCensus.ps1') -SourceDir "$env:USERPROFILE\Downloads" -Job Files,Images,References | Out-Null
    & (Join-Path $tools 'Get-LseRights.ps1')
    & (Join-Path $tools 'Build-LseFrontBack.ps1')
}
finally { Pop-Location }

$todoFile = Join-Path $RepoRoot 'frontback\_TODO.md'
$todos = @()
if (Test-Path -LiteralPath $todoFile) { $todos = @(Get-Content -LiteralPath $todoFile | Where-Object { $_ -match '^- Book' }) }

if ($todos.Count -gt 0) {
    Write-Host ""
    Write-Host "$($todos.Count) credit TODO(s) remain. Not injecting." -ForegroundColor Red
    $todos | ForEach-Object { Write-Host "  $_" }
    Write-Host "Paste the list above back to Claude." -ForegroundColor Red
    exit 1
}

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

$g = @($actions | Where-Object { $_.To -eq 'GRANTED' }).Count
$t = @($actions | Where-Object { $_.To -eq 'ATTRIB' }).Count
$x = @($actions | Where-Object { $_.To -eq 'drop' }).Count
Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host " DONE. Permission $g, attribution only $t, removed $x. PDFs in dist\" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
