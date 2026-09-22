<#
.SYNOPSIS
    Generates front matter and the image credits section for each book.

.DESCRIPTION
    Reads INVENTORY\references.csv, works out which images each book uses,
    and writes ready-to-paste HTML into frontback\.

    Credits are sorted into four sections:
      Used by permission          explicit grant from the rights holder
      Reproduced with attribution permission requested, no reply at publication
      Open licence                Creative Commons or public domain
      Author-created figures

    Which section an image lands in is decided by the Status on its entry
    below, or by the licence token in its filename.

    It injects nothing. Inject-LseFrontBack.ps1 does that.

.EXAMPLE
    .\Build-LseFrontBack.ps1
#>

[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$Author = "Damon Smith",
    [int]$Year = 2026,
    [string]$License = "CC BY-SA 4.0",
    [string]$LicenseUrl = "https://creativecommons.org/licenses/by-sa/4.0/",
    [string]$RepoUrl = "https://github.com/dstorm3691/living-soil-encyclopedia"
)

$ErrorActionPreference = 'Stop'

if (-not $RepoRoot) {
    $d = (& git rev-parse --show-toplevel 2>$null)
    if ($LASTEXITCODE -ne 0) { Write-Host "Not in a git repo." -ForegroundColor Red; exit 1 }
    $RepoRoot = $d.Trim() -replace '/', '\'
}
$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
$inv = Join-Path $RepoRoot 'INVENTORY'
$out = Join-Path $RepoRoot 'frontback'
if (-not (Test-Path -LiteralPath $out)) { New-Item -ItemType Directory -Path $out -Force | Out-Null }

$refsCsv = Join-Path $inv 'references.csv'
if (-not (Test-Path -LiteralPath $refsCsv)) {
    Write-Host "Missing references.csv. Run the census first." -ForegroundColor Red; exit 1
}
$refs = @(Import-Csv -LiteralPath $refsCsv | Where-Object { $_.from_loc -eq 'repo' -and $_.status -eq 'resolved' })

# ------------------------------------------------------------
# Credit entries. First match wins, so specific entries come first.
#
# Status decides the section:
#   granted      Used by permission
#   attributed   Reproduced with attribution
#   open         Open licence
#   pending      unresolved, generates a TODO
#
# Wording for granted entries is quoted from each agreement.
# Do not reword those.
# ------------------------------------------------------------

$Agreed = @(
    @{ Match = 'DampingOff.*BW194941'
       Credit = 'Photo: R.J. Reynolds Tobacco Company, Bugwood.org. Used by permission (Bugwood image request 194941).'
       Holder = 'Bugwood Image Database, University of Georgia'; Status = 'granted' }

    # ---- Bugwood, requests 194930 and 194939 ----
    @{ Match = '2-4DDrift.*BW194939'
       Credit = 'Photo: Mary Ann Hansen, Virginia Polytechnic Institute and State University, Bugwood.org. Used by permission (Bugwood image request 194939).'
       Holder = 'Bugwood Image Database, University of Georgia'; Status = 'granted' }
    @{ Match = 'GlyphosateInjury.*BW194939'
       Credit = 'Photo: Nathan Howard, University of Kentucky, Bugwood.org. Used by permission (Bugwood image request 194939).'
       Holder = 'Bugwood Image Database, University of Georgia'; Status = 'granted' }
    @{ Match = 'CowpeaCurculio.*BW194930'
       Credit = 'Photo: Brantlee Spakes Richter, University of Florida, Bugwood.org. Used by permission (Bugwood image request 194930).'
       Holder = 'Bugwood Image Database, University of Georgia'; Status = 'granted' }
    @{ Match = 'FleaBeetle.*BW194930'
       Credit = 'Photo: David Cappaert, Bugwood.org. Used by permission (Bugwood image request 194930).'
       Holder = 'Bugwood Image Database, University of Georgia'; Status = 'granted' }

    # ---- NC State, open licence displayed on the source page ----
    @{ Match = 'FlumioxazinDrift.*NCSU'
       Credit = 'Photo: B. Lassiter, NC State Extension, Protoporphyrinogen Oxidase Inhibitors. CC BY-NC-SA 4.0.'
       Holder = 'NC State Extension'; Status = 'open' }

    # ---- Outcomes for the four pending requests ----
    # Finalize-Lse.ps1 renames each file with GRANTED-* or ATTRIB-*.
    @{ Match = 'FusariumWilt.*GRANTED-NCSU'
       Credit = 'Photo: Inga Meadows, NC State Extension, Fusarium Wilt of Tomato. Used by permission.'
       Holder = 'NC State Extension'; Status = 'granted' }
    @{ Match = 'FusariumWilt.*ATTRIB-NCSU'
       Credit = 'Photo: Inga Meadows, NC State Extension, Fusarium Wilt of Tomato.'
       Holder = 'NC State Extension'; Status = 'attributed' }

    @{ Match = 'Strawberry_BlackRootRot.*GRANTED-NCSU'
       Credit = 'Photo: Leonor Leandro, Gloria Abad, and Frank J. Louws, NC State Extension, Black Root Rot of Strawberry. Used by permission.'
       Holder = 'NC State Extension'; Status = 'granted' }
    @{ Match = 'Strawberry_BlackRootRot.*ATTRIB-NCSU'
       Credit = 'Photo: Leonor Leandro, Gloria Abad, and Frank J. Louws, NC State Extension, Black Root Rot of Strawberry.'
       Holder = 'NC State Extension'; Status = 'attributed' }

    @{ Match = 'DampingOff.*GRANTED-UMass'
       Credit = 'Photo: Tina Smith, University of Massachusetts Extension. Used by permission.'
       Holder = 'University of Massachusetts Extension'; Status = 'granted' }
    @{ Match = 'DampingOff.*ATTRIB-UMass'
       Credit = 'Photo: Tina Smith, University of Massachusetts Extension.'
       Holder = 'University of Massachusetts Extension'; Status = 'attributed' }

    @{ Match = 'Basil_RhizoctoniaRootRot.*GRANTED-MSU'
       Credit = 'Photo: Jan Byrne, MSU Plant & Pest Diagnostics, Michigan State University Extension. Used by permission.'
       Holder = 'Michigan State University Extension'; Status = 'granted' }
    @{ Match = 'Basil_RhizoctoniaRootRot.*ATTRIB-MSU'
       Credit = 'Photo: Jan Byrne, MSU Plant & Pest Diagnostics, Michigan State University Extension, Vegetable garden issues.'
       Holder = 'Michigan State University Extension'; Status = 'attributed' }

    # ---- Clemson ----
    @{ Match = 'Okra_StinkBugDamage.*Clemson'
       Credit = 'Photo: Barbara H. Smith, &copy;2018 HGIC, Clemson Extension. Used by permission.'
       Holder = 'Clemson Extension HGIC'; Status = 'granted' }

    # ---- Arkansas ----
    @{ Match = 'BacterialWilt_StreamingTest.*UAEX'
       Credit = 'Photo: Sherrie Smith, University of Arkansas Division of Agriculture, Cooperative Extension Service &mdash; Arkansas Plant Health Clinic. Used by permission.'
       Holder = 'University of Arkansas Division of Agriculture'; Status = 'granted' }

    # ---- University of Maryland ----
    @{ Match = 'Squash_PesticideBurn.*UMD|Squash_.*Phytotoxicity.*UMD'
       Credit = 'Photo: Jon Traunfeld, University of Maryland Extension &mdash; Home &amp; Garden Information Center, Fertilizer or Pesticide Burn on Vegetable Leaves, retrieved June 4, 2026.'
       Holder = 'University of Maryland Extension / HGIC'; Status = 'granted' }
    @{ Match = 'Bean_PesticideBurn.*UMD|Bean_.*ScorchedLeaves.*UMD|Bean_.*LeafScorch.*UMD'
       Credit = 'Photo: HGIC, University of Maryland Extension &mdash; Home &amp; Garden Information Center, Fertilizer or Pesticide Burn on Vegetable Leaves, retrieved June 4, 2026.'
       Holder = 'University of Maryland Extension / HGIC'; Status = 'granted' }
    @{ Match = 'ColdFreezeDamage.*UMD|ColdInjury.*UMD|WhiteLeaves.*UMD'
       Credit = 'Photo: Jon Traunfeld, University of Maryland Extension &mdash; Home &amp; Garden Information Center, Key to Common Problems of Tomatoes, retrieved June 4, 2026.'
       Holder = 'University of Maryland Extension / HGIC'; Status = 'granted' }
    @{ Match = 'FertilizerBurn.*UMD|Phenoxy.*UMD'
       Credit = 'Photo: Jon Traunfeld, University of Maryland Extension &mdash; Home &amp; Garden Information Center, Key to Common Problems of Tomatoes, retrieved June 4, 2026.'
       Holder = 'University of Maryland Extension / HGIC'; Status = 'granted' }
    @{ Match = 'HighTunnel.*UMD|ColdDamage.*Tunnel'
       Credit = 'Photo: Jerry Brust, University of Maryland Extension, Cold Damage to High Tunnel and Greenhouse Vegetables, retrieved June 4, 2026.'
       Holder = 'University of Maryland Extension'; Status = 'granted' }

    # ---- Still pending: generate a TODO until Finalize-Lse.ps1 runs ----
    @{ Match = 'FusariumWilt.*NCSU'
       Credit = 'TODO: permission requested from Frank Louws 2026-09-19. Run Finalize-Lse.ps1.'
       Holder = 'NC State Extension'; Status = 'pending' }
    @{ Match = 'Strawberry_BlackRootRot.*NCSU'
       Credit = 'TODO: permission requested from Frank Louws 2026-09-19. Run Finalize-Lse.ps1.'
       Holder = 'NC State Extension'; Status = 'pending' }
    @{ Match = 'DampingOff.*UMass'
       Credit = 'TODO: permission requested from Jason Lanier 2026-09-22. Run Finalize-Lse.ps1.'
       Holder = 'University of Massachusetts Extension'; Status = 'pending' }
    @{ Match = 'Basil_RhizoctoniaRootRot.*MSU'
       Credit = 'TODO: permission requested from Jan Byrne 2026-09-22. Run Finalize-Lse.ps1.'
       Holder = 'Michigan State University Extension'; Status = 'pending' }
)

$LicenseNames = @{
    'CC0'           = @{ Name = 'CC0 1.0 (public domain dedication)'; Url = 'https://creativecommons.org/publicdomain/zero/1.0/' }
    'USDA-PD'       = @{ Name = 'Public domain (US government work)'; Url = '' }
    'PublicUse'     = @{ Name = 'Released for public use'; Url = '' }
    'CC-BY-2'       = @{ Name = 'CC BY 2.0'; Url = 'https://creativecommons.org/licenses/by/2.0/' }
    'CC-BY-3'       = @{ Name = 'CC BY 3.0'; Url = 'https://creativecommons.org/licenses/by/3.0/' }
    'CC-BY-4'       = @{ Name = 'CC BY 4.0'; Url = 'https://creativecommons.org/licenses/by/4.0/' }
    'CC-BY-SA-2'    = @{ Name = 'CC BY-SA 2.0'; Url = 'https://creativecommons.org/licenses/by-sa/2.0/' }
    'CC-BY-SA-3'    = @{ Name = 'CC BY-SA 3.0'; Url = 'https://creativecommons.org/licenses/by-sa/3.0/' }
    'CC-BY-SA-4'    = @{ Name = 'CC BY-SA 4.0'; Url = 'https://creativecommons.org/licenses/by-sa/4.0/' }
    'CC-BY-SA-GFDL' = @{ Name = 'CC BY-SA / GFDL dual licence'; Url = 'https://creativecommons.org/licenses/by-sa/3.0/' }
    'CC-BY-NC-SA'   = @{ Name = 'CC BY-NC-SA'; Url = 'https://creativecommons.org/licenses/by-nc-sa/4.0/' }
}

function Get-LicenseToken {
    param([string]$Name)
    foreach ($k in @('CC-BY-NC-SA','CC-BY-SA-GFDL','CC-BY-SA-4','CC-BY-SA-3','CC-BY-SA-2',
                     'CC-BY-4','CC-BY-3','CC-BY-2','CC0','USDA-PD','PublicUse')) {
        if ($Name -match ('(?i)(^|[_\-])' + [regex]::Escape($k))) { return $k }
    }
    return $null
}

function Get-Photographer {
    param([string]$Name, [string]$LicTok)
    $stem = [IO.Path]::GetFileNameWithoutExtension($Name)
    $toks = @($stem -split '_' | Where-Object { $_ })
    $stop = $toks.Count
    for ($i = 0; $i -lt $toks.Count; $i++) {
        if ($LicTok -and $toks[$i] -like "$LicTok*") { $stop = $i; break }
        if ($toks[$i] -match '(?i)^(VERIFY|PERMISSION|REJECT|CONDITIONAL|LOWRES|HOLD)$') { $stop = $i; break }
    }
    if ($stop -lt 1) { return '' }
    $cand = $toks[$stop - 1]
    return (($cand -creplace '([a-z])([A-Z])', '$1 $2') -replace '-', ' ').Trim()
}

$books = Get-ChildItem -LiteralPath $RepoRoot -Filter "LSE_BOOK_*_WORKING.html" -File | Sort-Object Name

Write-Host ""
Write-Host "Writing to: $out"
Write-Host ""

$allTodos = New-Object System.Collections.Generic.List[string]

foreach ($book in $books) {
    if ($book.Name -notmatch 'LSE_BOOK_(\d)_(.+?)_WORKING\.html') { continue }
    $num = $Matches[1]
    $titleTC = (Get-Culture).TextInfo.ToTitleCase(($Matches[2] -replace '_', ' ').ToLower())

    $used = @($refs | Where-Object { $_.from_name -eq $book.Name } |
              ForEach-Object { Split-Path $_.resolved -Leaf } |
              Select-Object -Unique | Sort-Object)

    $granted    = New-Object System.Collections.Generic.List[object]
    $attributed = New-Object System.Collections.Generic.List[object]
    $openFixed  = New-Object System.Collections.Generic.List[string]
    $cc         = New-Object System.Collections.Generic.List[object]
    $authorMade = New-Object System.Collections.Generic.List[string]

    foreach ($f in $used) {
        if ($f -match '^(UCI_|LSE_[A-E]\d)') { $authorMade.Add($f); continue }

        $hit = $null
        foreach ($a in $Agreed) { if ($f -match $a.Match) { $hit = $a; break } }

        if ($hit) {
            if ($hit.Credit -match 'TODO') { $allTodos.Add("Book ${num}: ${f}  ->  $($hit.Credit)") }
            $row = [pscustomobject]@{ holder = $hit.Holder; credit = $hit.Credit }
            switch ($hit.Status) {
                'granted'    { $granted.Add($row) }
                'attributed' { $attributed.Add($row) }
                'open'       { $openFixed.Add($hit.Credit) }
                default      { $granted.Add($row) }
            }
            continue
        }

        $tok = Get-LicenseToken -Name $f
        $who = Get-Photographer -Name $f -LicTok $tok
        if (-not $tok) { $allTodos.Add("Book ${num}: ${f}  ->  no licence in filename, needs a credit") }
        $cc.Add([pscustomobject]@{
            who = if ($who) { $who } else { 'TODO_PHOTOGRAPHER' }
            licName = if ($tok -and $LicenseNames.ContainsKey($tok)) { $LicenseNames[$tok].Name } else { 'TODO_LICENCE' }
            licUrl  = if ($tok -and $LicenseNames.ContainsKey($tok)) { $LicenseNames[$tok].Url } else { '' }
        })
    }

    # ---------- front matter ----------
    $bookLine = "The Living Soil Encyclopedia, Book ${num}: ${titleTC}"
    $subLine  = "The Living Soil Encyclopedia &middot; Book ${num} of 5"

    $fm = @"
<!-- ============ FRONT MATTER, Book ${num} ============ -->

<section class="title-page">
  <h1>${titleTC}</h1>
  <p class="subtitle">${subLine}</p>
  <p class="byline">${Author}</p>
</section>

<section class="copyright-page">
  <p>${bookLine}</p>
  <p>Text and original figures &copy; ${Year} ${Author}.</p>

  <p>This work is released under a
     <a href="${LicenseUrl}">Creative Commons Attribution-ShareAlike 4.0 International licence (${License})</a>.
     You are free to share and adapt it so long as you give credit and license
     your contributions under the same terms.</p>

  <p><strong>This edition is free.</strong> It is not sold, carries no advertising,
     and generates no revenue.</p>

  <p>Photographs by third parties are licensed separately from the text and are
     credited individually in the Image Credits section. Some appear under open
     licences, some by permission granted for free, non-commercial educational
     use, and some with attribution only. Each is marked there.</p>

  <p>The licence above covers the text and the author's own figures. It does not
     and cannot extend to any third-party photograph. If you reuse this work, you
     are responsible for clearing each photograph independently or removing it.</p>

  <p>Nothing here is professional agronomic, medical, or regulatory advice. Test
     amendments on a small scale before applying them broadly, and follow all
     product labels and local regulations.</p>

  <p>Source, errata, and the current edition: <a href="${RepoUrl}">${RepoUrl}</a></p>
</section>
"@
    $fm | Set-Content -LiteralPath (Join-Path $out "BOOK_${num}_frontmatter.html") -Encoding UTF8

    # ---------- credits ----------
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("<!-- ============ IMAGE CREDITS, Book ${num} ============ -->")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine('<section class="image-credits">')
    [void]$sb.AppendLine("  <h1>Image Credits</h1>")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("  <p>Figures and diagrams are by the author unless credited below.</p>")
    [void]$sb.AppendLine()

    if ($granted.Count -gt 0) {
        [void]$sb.AppendLine("  <h2>Used by permission</h2>")
        [void]$sb.AppendLine("  <p>Reproduced with the permission of the rights holders, granted for free")
        [void]$sb.AppendLine("     non-commercial educational use. Wording is as agreed with each holder.</p>")
        foreach ($g in ($granted | Group-Object holder | Sort-Object Name)) {
            [void]$sb.AppendLine("  <h3>$($g.Name)</h3>")
            [void]$sb.AppendLine("  <ul>")
            foreach ($x in $g.Group) { [void]$sb.AppendLine("    <li>$($x.credit)</li>") }
            [void]$sb.AppendLine("  </ul>")
        }
        [void]$sb.AppendLine()
    }

    if ($attributed.Count -gt 0) {
        [void]$sb.AppendLine("  <h2>Reproduced with attribution</h2>")
        [void]$sb.AppendLine("  <p>These photographs are reproduced with attribution for free, non-commercial")
        [void]$sb.AppendLine("     educational use. Permission was requested from each source; no reply had")
        [void]$sb.AppendLine("     been received at publication. Any rights holder who would prefer an image")
        [void]$sb.AppendLine("     removed can open an issue at <a href=`"${RepoUrl}/issues`">${RepoUrl}/issues</a>")
        [void]$sb.AppendLine("     and it will be taken down.</p>")
        foreach ($g in ($attributed | Group-Object holder | Sort-Object Name)) {
            [void]$sb.AppendLine("  <h3>$($g.Name)</h3>")
            [void]$sb.AppendLine("  <ul>")
            foreach ($x in $g.Group) { [void]$sb.AppendLine("    <li>$($x.credit)</li>") }
            [void]$sb.AppendLine("  </ul>")
        }
        [void]$sb.AppendLine()
    }

    if ($openFixed.Count -gt 0 -or $cc.Count -gt 0) {
        [void]$sb.AppendLine("  <h2>Open licence</h2>")
        [void]$sb.AppendLine("  <ul>")
        foreach ($o in ($openFixed | Select-Object -Unique)) { [void]$sb.AppendLine("    <li>$o</li>") }
        foreach ($x in ($cc | Sort-Object who)) {
            $lic = if ($x.licUrl) { "<a href=`"$($x.licUrl)`">$($x.licName)</a>" } else { $x.licName }
            [void]$sb.AppendLine("    <li>Photo: $($x.who). $lic.</li>")
        }
        [void]$sb.AppendLine("  </ul>")
        [void]$sb.AppendLine()
    }

    [void]$sb.AppendLine("  <h2>Author-created figures</h2>")
    [void]$sb.AppendLine("  <p>$($authorMade.Count) diagrams and illustrations in this book were created by the")
    [void]$sb.AppendLine("     author and fall under the licence on the copyright page.</p>")
    [void]$sb.AppendLine('</section>')

    $sb.ToString() | Set-Content -LiteralPath (Join-Path $out "BOOK_${num}_credits.html") -Encoding UTF8

    Write-Host ("Book {0}  {1,-28} {2,3} images: {3} permission, {4} attributed, {5} open, {6} author" -f `
        $num, $titleTC, $used.Count, $granted.Count, $attributed.Count, ($openFixed.Count + $cc.Count), $authorMade.Count)
}

$todoPath = Join-Path $out "_TODO.md"
$t = New-Object System.Text.StringBuilder
[void]$t.AppendLine("# Credits TODOs")
[void]$t.AppendLine()
if ($allTodos.Count -eq 0) { [void]$t.AppendLine("None.") }
foreach ($x in ($allTodos | Select-Object -Unique | Sort-Object)) { [void]$t.AppendLine("- $x") }
$t.ToString() | Set-Content -LiteralPath $todoPath -Encoding UTF8

Write-Host ""
Write-Host "TODOs: $(@($allTodos | Select-Object -Unique).Count)" -ForegroundColor $(if ($allTodos.Count) { 'Yellow' } else { 'Green' })
Write-Host "Review: $todoPath" -ForegroundColor Cyan
Write-Host ""

