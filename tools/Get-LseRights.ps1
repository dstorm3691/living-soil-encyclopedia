<#
.SYNOPSIS
    Extracts rights data from the LSE asset filenames and produces a blocker list.

.DESCRIPTION
    Reads INVENTORY/images.csv and INVENTORY/references.csv. Parses each repo
    image's filename for licence token, attribution, and status flag. Reports
    which books use each image. Writes nothing outside INVENTORY/.

    Rule that matters: an image carrying its own open licence is cleared on that
    licence. Which institution published it is irrelevant. Only images with no
    open licence fall through to the permission track.

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
    if ($LASTEXITCODE -ne 0) { Write-Host "Not in a git repo." -ForegroundColor Red; exit 1 }
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
# Licence tokens. Longest first so CC-BY-NC-SA wins over CC-BY.
# Matched after any separator, so NCSU-CC-BY-NC-SA still matches.
# ------------------------------------------------------------

$LicenseTokens = [ordered]@{
    'GRANTED-MSU' = @{ Class = 'GRANTED'; Note = 'MSU Plant & Pest Diagnostics permission, via Jan Byrne' }
    'GRANTED-UMass' = @{ Class = 'GRANTED'; Note = 'UMass Extension permission, via Jason Lanier' }
    'GRANTED-NCSU' = @{ Class = 'GRANTED'; Note = 'NC State Extension permission, via Frank Louws' }
    'BW194939'      = @{ Class = 'GRANTED'; Note = 'Bugwood image request 194939, approved 2026-09-22' }
    'BW194930'      = @{ Class = 'GRANTED'; Note = 'Bugwood image request 194930, approved' }
    'CC-BY-NC-SA'   = @{ Class = 'NC-SA'; Note = 'NonCommercial + ShareAlike' }
    'CC-BY-NC'      = @{ Class = 'NC';    Note = 'NonCommercial' }
    'CC-BY-SA-GFDL' = @{ Class = 'SA';    Note = 'ShareAlike + GFDL dual licence' }
    'CC-BY-SA-4'    = @{ Class = 'SA';    Note = 'ShareAlike 4.0' }
    'CC-BY-SA-3'    = @{ Class = 'SA';    Note = 'ShareAlike 3.0' }
    'CC-BY-SA-2'    = @{ Class = 'SA';    Note = 'ShareAlike 2.0' }
    'CC-BY-SA'      = @{ Class = 'SA';    Note = 'ShareAlike' }
    'CC-BY-4'       = @{ Class = 'BY';    Note = 'Attribution 4.0' }
    'CC-BY-3'       = @{ Class = 'BY';    Note = 'Attribution 3.0' }
    'CC-BY-2'       = @{ Class = 'BY';    Note = 'Attribution 2.0' }
    'CC-BY'         = @{ Class = 'BY';    Note = 'Attribution' }
    'CC0'           = @{ Class = 'CC0';   Note = 'Public domain dedication' }
    'USDA-PD'       = @{ Class = 'PD';    Note = 'US government work, public domain' }
    'PublicUse'     = @{ Class = 'PD?';   Note = 'Marked public use, verify the terms' }
}

$StatusTokens = [ordered]@{
    'REJECT'      = @{ Rank = 1; Note = 'Flagged unusable. Re-rule or replace.' }
    'PERMISSION'  = @{ Rank = 2; Note = 'Depends on an individual permission grant.' }
    'VERIFY'      = @{ Rank = 3; Note = 'Rights not confirmed at filing time.' }
    'CONDITIONAL' = @{ Rank = 4; Note = 'Usable under stated conditions. Record them.' }
    'HOLD'        = @{ Rank = 5; Note = 'Parked during sourcing.' }
    'LOWRES'      = @{ Rank = 6; Note = 'Resolution concern for print, not rights.' }
}

# Institutions with a recorded permission grant
$LedgerGranted = @('Clemson', 'UAEX', 'UMD')
$LedgerPending = @('NCSU', 'MSU', 'UGA', 'UMass')

function Get-LicenseToken {
    param([string]$Name)
    foreach ($k in $LicenseTokens.Keys) {
        # after any separator, so a NCSU- prefix does not block the match
        if ($Name -match ('(?i)(^|[_\-])' + [regex]::Escape($k) + '([._\-]|$)')) { return $k }
    }
    return $null
}

function Get-StatusToken {
    param([string]$Name)
    $best = $null; $rank = 99
    foreach ($k in $StatusTokens.Keys) {
        if ($Name -match ('(?i)(^|_)' + [regex]::Escape($k) + '(_|\.|$)')) {
            if ($StatusTokens[$k].Rank -lt $rank) { $best = $k; $rank = $StatusTokens[$k].Rank }
        }
    }
    return $best
}

function Get-Attribution {
    param([string]$Name, [string]$LicTok, [string]$StatusTok)
    $stem = [IO.Path]::GetFileNameWithoutExtension($Name)
    $toks = @($stem -split '_' | Where-Object { $_ })
    $stop = $toks.Count
    for ($i = 0; $i -lt $toks.Count; $i++) {
        if ($LicTok -and $toks[$i] -match ('(?i)' + [regex]::Escape($LicTok))) { $stop = $i; break }
        if ($StatusTok -and $toks[$i] -eq $StatusTok) { $stop = $i; break }
    }
    if ($stop -lt 1) { return '' }
    return ($toks[$stop - 1] -creplace '([a-z])([A-Z])', '$1 $2').Trim()
}

$rows = New-Object System.Collections.Generic.List[object]

foreach ($im in $imgs) {
    $name = $im.filename
    $stem = [IO.Path]::GetFileNameWithoutExtension($name)

    $family = 'third-party'
    if     ($stem -match '^UCI_\d+')      { $family = 'self-created (UCI)' }
    elseif ($stem -match '^LSE_[A-E]\d+') { $family = 'self-created (figure)' }

    $license = Get-LicenseToken -Name $stem
    $lclass  = if ($license) { $LicenseTokens[$license].Class } else { '' }
    $lnote   = if ($license) { $LicenseTokens[$license].Note }  else { '' }

    $status  = Get-StatusToken -Name $stem
    $snote   = if ($status) { $StatusTokens[$status].Note } else { '' }

    $attr = Get-Attribution -Name $name -LicTok $license -StatusTok $status

    $inst = ''
    foreach ($i2 in @('Clemson','UAEX','UMD','NCSU','MSU','UGA','UMass','VCE','Bugwood','USDA')) {
        if ($stem -match ('(?i)(^|[_\-])' + $i2 + '([_\-]|$)')) { $inst = $i2; break }
    }

    # ----------------------------------------------------------
    # VERDICT
    #
    # An open licence clears the image on its own terms. The
    # publishing institution is irrelevant once a licence is present,
    # which is why the ledger status is only consulted for images
    # that have no licence of their own.
    # ----------------------------------------------------------

    $ledger = ''
    $verdict = 'check'

    if ($family -like 'self-created*') {
        $verdict = 'self'
    }
    elseif ($status -eq 'REJECT') {
        $verdict = 'BLOCKER'
    }
    elseif ($license -and $lclass -ne 'PD?') {
        # carries its own licence
        if ($lclass -eq 'SA' -or $lclass -eq 'NC-SA') { $verdict = 'clear'; $ledger = 'open licence, ShareAlike noted' }
        elseif ($lclass -eq 'GRANTED') { $verdict = 'clear'; $ledger = 'granted, ' + $lnote }
        else { $verdict = 'clear'; $ledger = 'open licence' }
        if ($status -and $status -ne 'HOLD' -and $status -ne 'LOWRES') {
            $ledger += ", filename still flagged $status"
        }
    }
    else {
        # no licence: permission track
        if ($LedgerGranted -contains $inst) { $ledger = 'granted'; $verdict = 'clear' }
        elseif ($LedgerPending -contains $inst) { $ledger = 'PENDING - no reply on record'; $verdict = 'BLOCKER' }
        elseif ($status -eq 'PERMISSION') { $ledger = 'NO LEDGER ENTRY'; $verdict = 'BLOCKER' }
        elseif ($status -eq 'VERIFY') { $verdict = 'BLOCKER' }
        else { $verdict = 'check' }
    }

    $books = if ($usedBy.ContainsKey($im.path.ToLower())) { ($usedBy[$im.path.ToLower()] -join ', ') } else { '(unreferenced)' }

    $rows.Add([pscustomobject]@{
        filename = $name; family = $family
        license = $license; license_class = $lclass; license_note = $lnote
        status_flag = $status; status_note = $snote
        attribution = $attr; institution = $inst
        ledger = $ledger; verdict = $verdict; used_by = $books
        dims = "$($im.width)x$($im.height)"
        kb = [math]::Round([int64]$im.bytes / 1KB, 0)
        path = $im.path
    })
}

$rows | Export-Csv -LiteralPath (Join-Path $InventoryDir 'rights_parsed.csv') -NoTypeInformation -Encoding UTF8

# ------------------------------------------------------------
# REPORT
# ------------------------------------------------------------

$blockers = @($rows | Where-Object { $_.verdict -eq 'BLOCKER' })
$checks   = @($rows | Where-Object { $_.verdict -eq 'check' })
$clear    = @($rows | Where-Object { $_.verdict -eq 'clear' })
$self     = @($rows | Where-Object { $_.verdict -eq 'self' })

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("# Rights, Parsed From Filenames")
[void]$sb.AppendLine()
[void]$sb.AppendLine("Generated: $((Get-Date).ToString('u'))")
[void]$sb.AppendLine()
[void]$sb.AppendLine("Publication model: **free, non-commercial, unpaywalled**. CC BY-NC and")
[void]$sb.AppendLine("CC BY-NC-SA are therefore permitted. ShareAlike applies to the image,")
[void]$sb.AppendLine("not to the book's text.")
[void]$sb.AppendLine()
[void]$sb.AppendLine("An image with its own open licence is cleared on that licence regardless")
[void]$sb.AppendLine("of which institution published it. ``LSE_RIGHTS_LEDGER.md`` is")
[void]$sb.AppendLine("authoritative where this disagrees with it.")
[void]$sb.AppendLine()
[void]$sb.AppendLine("| verdict | count |")
[void]$sb.AppendLine("|---|---:|")
[void]$sb.AppendLine("| BLOCKER | $($blockers.Count) |")
[void]$sb.AppendLine("| check | $($checks.Count) |")
[void]$sb.AppendLine("| clear | $($clear.Count) |")
[void]$sb.AppendLine("| self-created | $($self.Count) |")
[void]$sb.AppendLine("| **total** | **$($rows.Count)** |")
[void]$sb.AppendLine()

[void]$sb.AppendLine("## BLOCKERS")
[void]$sb.AppendLine()
if ($blockers.Count -eq 0) { [void]$sb.AppendLine("None.") }
foreach ($b in ($blockers | Sort-Object filename)) {
    [void]$sb.AppendLine("### ``$($b.filename)``")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("- **Why:** $(if ($b.status_flag) { "$($b.status_flag) — $($b.status_note)" } else { 'no licence found' })")
    if ($b.ledger) { [void]$sb.AppendLine("- **Ledger:** $($b.ledger)") }
    if ($b.institution) { [void]$sb.AppendLine("- **Institution:** $($b.institution)") }
    [void]$sb.AppendLine("- **Used by:** $($b.used_by)")
    [void]$sb.AppendLine("- **Decision:** [ ]")
    [void]$sb.AppendLine()
}

[void]$sb.AppendLine("## CHECK")
[void]$sb.AppendLine()
[void]$sb.AppendLine("| file | licence | flag | attribution | used by |")
[void]$sb.AppendLine("|---|---|---|---|---|")
foreach ($c in ($checks | Sort-Object filename)) {
    [void]$sb.AppendLine("| ``$($c.filename)`` | $($c.license) | $($c.status_flag) | $($c.attribution) | $($c.used_by) |")
}
[void]$sb.AppendLine()

[void]$sb.AppendLine("## Cleared, but the filename still carries a stale flag")
[void]$sb.AppendLine()
[void]$sb.AppendLine("Rename these so the filename stops contradicting the rights position.")
[void]$sb.AppendLine()
[void]$sb.AppendLine("| file | licence | stale flag |")
[void]$sb.AppendLine("|---|---|---|")
foreach ($c in ($clear | Where-Object { $_.ledger -like '*still flagged*' } | Sort-Object filename)) {
    [void]$sb.AppendLine("| ``$($c.filename)`` | $($c.license) | $($c.status_flag) |")
}
[void]$sb.AppendLine()

[void]$sb.AppendLine("## ShareAlike images")
[void]$sb.AppendLine()
[void]$sb.AppendLine("| file | licence | used by |")
[void]$sb.AppendLine("|---|---|---|")
foreach ($s in ($rows | Where-Object { $_.license_class -eq 'SA' -or $_.license_class -eq 'NC-SA' } | Sort-Object filename)) {
    [void]$sb.AppendLine("| ``$($s.filename)`` | $($s.license) | $($s.used_by) |")
}
[void]$sb.AppendLine()

[void]$sb.AppendLine("## By licence")
[void]$sb.AppendLine()
[void]$sb.AppendLine("| licence | class | count |")
[void]$sb.AppendLine("|---|---|---:|")
foreach ($g in ($rows | Group-Object license | Sort-Object Count -Descending)) {
    $nm = if ($g.Name) { $g.Name } else { '(none in filename)' }
    [void]$sb.AppendLine("| $nm | $(($g.Group[0]).license_class) | $($g.Count) |")
}
[void]$sb.AppendLine()

$sb.ToString() | Set-Content -LiteralPath (Join-Path $InventoryDir 'rights_blockers.md') -Encoding UTF8

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
    foreach ($b in ($blockers | Sort-Object filename)) {
        Write-Host ("  [{0,-11}] {1}" -f $(if ($b.status_flag) { $b.status_flag } else { 'no licence' }), $b.filename)
    }
    Write-Host ""
}
$stale = @($clear | Where-Object { $_.ledger -like '*still flagged*' })
if ($stale.Count -gt 0) {
    Write-Host "Cleared but filename still flagged (rename these): $($stale.Count)" -ForegroundColor Yellow
    foreach ($s in $stale) { Write-Host "  $($s.filename)" }
    Write-Host ""
}
Write-Host "Report: $InventoryDir\rights_blockers.md" -ForegroundColor Cyan
Write-Host ""



