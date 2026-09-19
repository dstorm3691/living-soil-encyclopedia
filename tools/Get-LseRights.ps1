<#
.SYNOPSIS
    Extracts rights data from the LSE asset filenames and produces a blocker list.

.DESCRIPTION
    Reads INVENTORY/images.csv and INVENTORY/references.csv. Parses each repo
    image's filename for license token, attribution, and status flag. Reports
    which books use each image. Writes nothing outside INVENTORY/.

.EXAMPLE
    .\Get-LseRights.ps1
#>

[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$InventoryDir
)

$ErrorActionPreference = 'Stop'

if (-not $RepoRoot) {
    $d = (& git rev-parse --show-toplevel 2>$null)
    if ($LASTEXITCODE -ne 0 -or -not $d) { Write-Host "Not in a git repo." -ForegroundColor Red; exit 1 }
    $RepoRoot = $d.Trim() -replace '/', '\'
}
$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
if (-not $InventoryDir) { $InventoryDir = Join-Path $RepoRoot 'INVENTORY' }

$imgsCsv = Join-Path $InventoryDir 'images.csv'
$refsCsv = Join-Path $InventoryDir 'references.csv'
foreach ($f in @($imgsCsv, $refsCsv)) {
    if (-not (Test-Path -LiteralPath $f)) { Write-Host "Missing $f. Run the census first." -ForegroundColor Red; exit 1 }
}

$imgs = @(Import-Csv -LiteralPath $imgsCsv | Where-Object { $_.location -eq 'repo' })
$refs = @(Import-Csv -LiteralPath $refsCsv | Where-Object { $_.from_loc -eq 'repo' -and $_.status -eq 'resolved' })

# which books use which file
$usedBy = @{}
foreach ($r in $refs) {
    if (-not $r.resolved) { continue }
    $k = $r.resolved.ToLower()
    if (-not $usedBy.ContainsKey($k)) { $usedBy[$k] = New-Object System.Collections.Generic.List[string] }
    $b = $r.from_name -replace '^LSE_BOOK_(\d)_.*$', 'Book $1'
    if ($b -eq $r.from_name) { $b = $r.from_name }
    if (-not $usedBy[$k].Contains($b)) { $usedBy[$k].Add($b) }
}

# ------------------------------------------------------------
# TOKEN TABLES
# ------------------------------------------------------------

# Ordered: longest / most specific first
$LicenseTokens = [ordered]@{
    'CC-BY-NC-SA'   = @{ Class = 'NC-SA';  Note = 'NonCommercial + ShareAlike' }
    'CC-BY-NC'      = @{ Class = 'NC';     Note = 'NonCommercial' }
    'CC-BY-SA-GFDL' = @{ Class = 'SA';     Note = 'ShareAlike + GFDL dual license' }
    'CC-BY-SA-4'    = @{ Class = 'SA';     Note = 'ShareAlike 4.0' }
    'CC-BY-SA-3'    = @{ Class = 'SA';     Note = 'ShareAlike 3.0' }
    'CC-BY-SA-2'    = @{ Class = 'SA';     Note = 'ShareAlike 2.0' }
    'CC-BY-SA'      = @{ Class = 'SA';     Note = 'ShareAlike' }
    'CC-BY-4'       = @{ Class = 'BY';     Note = 'Attribution 4.0' }
    'CC-BY-3'       = @{ Class = 'BY';     Note = 'Attribution 3.0' }
    'CC-BY-2'       = @{ Class = 'BY';     Note = 'Attribution 2.0' }
    'CC-BY'         = @{ Class = 'BY';     Note = 'Attribution' }
    'CC0'           = @{ Class = 'CC0';    Note = 'Public domain dedication' }
    'USDA-PD'       = @{ Class = 'PD';     Note = 'US government work, public domain' }
    'PublicUse'     = @{ Class = 'PD?';    Note = 'Marked public use, verify the terms' }
}

$StatusTokens = [ordered]@{
    'REJECT'      = @{ Rank = 1; Note = 'Flagged unusable. Replace, or re-rule if the flag predates the free non-commercial decision.' }
    'PERMISSION'  = @{ Rank = 2; Note = 'Depends on an individual permission grant. Must match LSE_RIGHTS_LEDGER.md.' }
    'VERIFY'      = @{ Rank = 3; Note = 'Rights not confirmed at filing time.' }
    'CONDITIONAL' = @{ Rank = 4; Note = 'Usable under stated conditions. Conditions must be recorded.' }
    'HOLD'        = @{ Rank = 5; Note = 'Parked during sourcing.' }
    'LOWRES'      = @{ Rank = 6; Note = 'Resolution concern for print, not a rights issue.' }
}

# Institutions with a recorded grant (from LSE_RIGHTS_LEDGER.md)
$LedgerGranted = @('Clemson', 'UAEX', 'UMD')
$LedgerPending = @('NCSU')

function Get-Tokens {
    param([string]$Name)
    $stem = [System.IO.Path]::GetFileNameWithoutExtension($Name)
    return @($stem -split '[_]+' | Where-Object { $_ })
}

$rows = New-Object System.Collections.Generic.List[object]

foreach ($im in $imgs) {
    $name = $im.filename
    $stem = [System.IO.Path]::GetFileNameWithoutExtension($name)

    # self-created figure families
    $family = 'third-party'
    if     ($stem -match '^UCI_\d+') { $family = 'self-created (UCI)' }
    elseif ($stem -match '^LSE_[A-E]\d+') { $family = 'self-created (figure)' }
    elseif ($stem -match '^B\d+_\d+') { $family = 'third-party (B-series)' }

    # license
    $license = ''; $lclass = ''; $lnote = ''
    foreach ($t in $LicenseTokens.Keys) {
        if ($stem -match ('(?i)(^|_)' + [regex]::Escape($t) + '([._\-]|$)')) {
            $license = $t; $lclass = $LicenseTokens[$t].Class; $lnote = $LicenseTokens[$t].Note
            break
        }
    }

    # status flag
    $status = ''; $srank = 99; $snote = ''
    foreach ($t in $StatusTokens.Keys) {
        if ($stem -match ('(?i)(^|_)' + [regex]::Escape($t) + '(_|$)')) {
            if ($StatusTokens[$t].Rank -lt $srank) {
                $status = $t; $srank = $StatusTokens[$t].Rank; $snote = $StatusTokens[$t].Note
            }
        }
    }

    # attribution guess: tokens between the descriptive body and the license/status
    $toks = Get-Tokens -Name $name
    $attr = ''
    if ($license -or $status) {
        $stopAt = $toks.Count
        for ($i = 0; $i -lt $toks.Count; $i++) {
            if (($license -and $toks[$i] -like "$license*") -or ($status -and $toks[$i] -eq $status)) { $stopAt = $i; break }
        }
        if ($stopAt -ge 1) { $attr = $toks[$stopAt - 1] }
        if ($stopAt -ge 2 -and $toks[$stopAt - 2] -cmatch '^[A-Z][A-Za-z\-]+$' -and $toks[$stopAt - 2].Length -gt 2) {
            $attr = "$($toks[$stopAt - 2]) / $attr"
        }
    }

    # institution detection for permission cases
    $inst = ''
    foreach ($i2 in @('Clemson', 'UAEX', 'UMD', 'NCSU', 'MSU', 'UGA', 'UMass', 'VCE', 'Bugwood', 'USDA')) {
        if ($stem -match ('(?i)(^|[_\-])' + $i2 + '([_\-]|$)')) { $inst = $i2; break }
    }

    $ledger = ''
    if ($status -eq 'PERMISSION' -or $inst) {
        if ($LedgerGranted -contains $inst) { $ledger = 'granted' }
        elseif ($LedgerPending -contains $inst) { $ledger = 'PENDING - no reply on record' }
        elseif ($inst -and $status -eq 'PERMISSION') { $ledger = 'NO LEDGER ENTRY' }
    }

    $books = if ($usedBy.ContainsKey($im.path.ToLower())) { ($usedBy[$im.path.ToLower()] -join ', ') } else { '(unreferenced)' }

    # overall verdict under FREE NON-COMMERCIAL distribution
    $verdict = 'clear'
    if     ($status -eq 'REJECT')                    { $verdict = 'BLOCKER' }
    elseif ($ledger -eq 'NO LEDGER ENTRY')           { $verdict = 'BLOCKER' }
    elseif ($ledger -like 'PENDING*')                { $verdict = 'BLOCKER' }
    elseif ($status -eq 'VERIFY' -and $ledger -ne 'granted') { $verdict = 'check' }
    elseif ($status -eq 'CONDITIONAL')               { $verdict = 'check' }
    elseif ($lclass -eq 'SA')                        { $verdict = 'check' }
    elseif ($lclass -eq 'PD?')                       { $verdict = 'check' }
    elseif ($family -like 'self-created*')           { $verdict = 'self' }
    elseif (-not $license -and -not $status)         { $verdict = 'check' }

    $rows.Add([pscustomobject]@{
        filename      = $name
        family        = $family
        license       = $license
        license_class = $lclass
        license_note  = $lnote
        status_flag   = $status
        status_note   = $snote
        attribution   = $attr
        institution   = $inst
        ledger        = $ledger
        verdict       = $verdict
        used_by       = $books
        dims          = "$($im.width)x$($im.height)"
        kb            = [math]::Round([int64]$im.bytes / 1KB, 0)
        path          = $im.path
    })
}

$outCsv = Join-Path $InventoryDir 'rights_parsed.csv'
$rows | Export-Csv -LiteralPath $outCsv -NoTypeInformation -Encoding UTF8

# ------------------------------------------------------------
# REPORT
# ------------------------------------------------------------

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("# Rights, Parsed From Filenames")
[void]$sb.AppendLine()
[void]$sb.AppendLine("Generated: $((Get-Date).ToString('u'))")
[void]$sb.AppendLine()
[void]$sb.AppendLine("Publication model: **free, non-commercial, unpaywalled**. Under that model,")
[void]$sb.AppendLine("CC-BY-NC is permitted. ShareAlike still needs a deliberate decision.")
[void]$sb.AppendLine()
[void]$sb.AppendLine("This is parsed from filenames, which may be stale. ``LSE_RIGHTS_LEDGER.md``")
[void]$sb.AppendLine("is authoritative where the two disagree.")
[void]$sb.AppendLine()

$blockers = @($rows | Where-Object { $_.verdict -eq 'BLOCKER' })
$checks   = @($rows | Where-Object { $_.verdict -eq 'check' })
$clear    = @($rows | Where-Object { $_.verdict -eq 'clear' })
$self     = @($rows | Where-Object { $_.verdict -eq 'self' })

[void]$sb.AppendLine("| verdict | count |")
[void]$sb.AppendLine("|---|---:|")
[void]$sb.AppendLine("| BLOCKER, must resolve before publishing | $($blockers.Count) |")
[void]$sb.AppendLine("| check, needs a decision or confirmation | $($checks.Count) |")
[void]$sb.AppendLine("| clear | $($clear.Count) |")
[void]$sb.AppendLine("| self-created | $($self.Count) |")
[void]$sb.AppendLine("| **total repo images** | **$($rows.Count)** |")
[void]$sb.AppendLine()

[void]$sb.AppendLine("## BLOCKERS")
[void]$sb.AppendLine()
if ($blockers.Count -eq 0) { [void]$sb.AppendLine("None.") }
foreach ($b in ($blockers | Sort-Object status_flag, filename)) {
    [void]$sb.AppendLine("### ``$($b.filename)``")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("- **Why:** $(if ($b.status_flag) { "$($b.status_flag) — $($b.status_note)" } else { 'no rights basis found' })")
    if ($b.ledger) { [void]$sb.AppendLine("- **Ledger:** $($b.ledger)") }
    if ($b.license) { [void]$sb.AppendLine("- **License in filename:** $($b.license) ($($b.license_note))") }
    if ($b.institution) { [void]$sb.AppendLine("- **Institution:** $($b.institution)") }
    [void]$sb.AppendLine("- **Used by:** $($b.used_by)")
    [void]$sb.AppendLine("- **Decision:** [ ]")
    [void]$sb.AppendLine()
}

[void]$sb.AppendLine("## CHECK")
[void]$sb.AppendLine()
[void]$sb.AppendLine("| file | license | flag | attribution | used by | decision |")
[void]$sb.AppendLine("|---|---|---|---|---|---|")
foreach ($c in ($checks | Sort-Object license_class, filename)) {
    [void]$sb.AppendLine("| ``$($c.filename)`` | $($c.license) | $($c.status_flag) | $($c.attribution) | $($c.used_by) | [ ] |")
}
[void]$sb.AppendLine()

[void]$sb.AppendLine("## ShareAlike images")
[void]$sb.AppendLine()
[void]$sb.AppendLine("One decision covers all of these: whether the book counts as a collection")
[void]$sb.AppendLine("(SA does not reach your text) or a derivative (it does). Decide once, record it.")
[void]$sb.AppendLine()
[void]$sb.AppendLine("| file | license | used by |")
[void]$sb.AppendLine("|---|---|---|")
foreach ($s in ($rows | Where-Object { $_.license_class -eq 'SA' } | Sort-Object filename)) {
    [void]$sb.AppendLine("| ``$($s.filename)`` | $($s.license) | $($s.used_by) |")
}
[void]$sb.AppendLine()

[void]$sb.AppendLine("## By license")
[void]$sb.AppendLine()
[void]$sb.AppendLine("| license | class | count |")
[void]$sb.AppendLine("|---|---|---:|")
foreach ($g in ($rows | Group-Object license | Sort-Object Count -Descending)) {
    $cls = ($g.Group[0]).license_class
    $nm = if ($g.Name) { $g.Name } else { '(none in filename)' }
    [void]$sb.AppendLine("| $nm | $cls | $($g.Count) |")
}
[void]$sb.AppendLine()

[void]$sb.AppendLine("## Unreferenced repo images")
[void]$sb.AppendLine()
$unref = @($rows | Where-Object { $_.used_by -eq '(unreferenced)' })
[void]$sb.AppendLine("$($unref.Count) images are in the repo but no book points at them.")
[void]$sb.AppendLine()
foreach ($u in ($unref | Sort-Object filename)) { [void]$sb.AppendLine("- ``$($u.filename)``") }
[void]$sb.AppendLine()

$outMd = Join-Path $InventoryDir 'rights_blockers.md'
$sb.ToString() | Set-Content -LiteralPath $outMd -Encoding UTF8

Write-Host ""
Write-Host "Repo images parsed: $($rows.Count)" -ForegroundColor Cyan
Write-Host ""
Write-Host ("  BLOCKER      {0}" -f $blockers.Count) -ForegroundColor $(if ($blockers.Count) { 'Red' } else { 'Green' })
Write-Host ("  check        {0}" -f $checks.Count) -ForegroundColor Yellow
Write-Host ("  clear        {0}" -f $clear.Count) -ForegroundColor Green
Write-Host ("  self-created {0}" -f $self.Count) -ForegroundColor Green
Write-Host ""
if ($blockers.Count -gt 0) {
    Write-Host "Blockers:" -ForegroundColor Red
    foreach ($b in $blockers) { Write-Host ("  [{0,-11}] {1}" -f $b.status_flag, $b.filename) }
    Write-Host ""
}
Write-Host "Report: $outMd" -ForegroundColor Cyan
Write-Host "Data:   $outCsv" -ForegroundColor Cyan
Write-Host ""
