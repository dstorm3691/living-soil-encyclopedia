<#
.SYNOPSIS
    Generates front matter and the image credits section for each book.

.DESCRIPTION
    Reads INVENTORY\references.csv, works out which images each book uses,
    and writes ready-to-paste HTML into frontback\ for review.

    It injects nothing. You read the output, fix the TODOs, then paste.

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
# Exact agreed credit strings. Quoted agreements. Do not reword.
# ------------------------------------------------------------

$Agreed = @(
    @{ Match = 'CowpeaCurculio.*BW194930'
       Credit = 'Photo: Brantlee Spakes Richter, University of Florida, Bugwood.org. Used by permission (Bugwood image request 194930).'
       Holder = 'Bugwood Image Database, University of Georgia'; Status = 'granted' }

    @{ Match = 'FleaBeetle.*BW194930'
       Credit = 'Photo: David Cappaert, Bugwood.org. Used by permission (Bugwood image request 194930).'
       Holder = 'Bugwood Image Database, University of Georgia'; Status = 'granted' }
    @{ Match = 'Okra_StinkBugDamage.*Clemson'
       Credit = 'Photo: Barbara H. Smith, &copy;2018 HGIC, Clemson Extension. Used by permission.'
       Holder = 'Clemson Extension HGIC'; Status = 'granted' }

    @{ Match = 'BacterialWilt_StreamingTest.*UAEX'
       Credit = 'Photo: Sherrie Smith, University of Arkansas Division of Agriculture, Cooperative Extension Service &mdash; Arkansas Plant Health Clinic. Used by permission.'
       Holder = 'University of Arkansas Division of Agriculture'; Status = 'granted' }

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

    @{ Match = 'FlumioxazinDrift.*NCSU'
       Credit = 'Photo: B. Lassiter, NC State Extension, Protoporphyrinogen Oxidase Inhibitors. CC BY-NC-SA 4.0.'
       Holder = 'NC State Extension'; Status = 'open licence' }

    @{ Match = 'Basil_RhizoctoniaRootRot.*MSU'
       Credit = 'TODO: no permission on record for this image. Confirm or remove.'
       Holder = 'Michigan State University Extension'; Status = 'NOT GRANTED' }

    @{ Match = 'Strawberry_BlackRootRot.*NCSU'
       Credit = 'TODO: request sent, no reply on record. Confirm or remove.'
       Holder = 'NC State Extension'; Status = 'NOT GRANTED' }

    @{ Match = 'FlumioxazinDrift.*NCSU'
       Credit = 'TODO: flagged REJECT under the old commercial plan. Re-rule now that the book is free, then write the credit.'
       Holder = 'NC State Extension'; Status = 'NEEDS RULING' }

    @{ Match = 'FusariumWilt.*NCSU'
       Credit = 'TODO: rights never confirmed. Include in the NC State follow-up.'
       Holder = 'NC State Extension'; Status = 'NEEDS RULING' }
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
    $pretty = ($cand -creplace '([a-z])([A-Z])', '$1 $2') -replace '-', ' '
    return $pretty.Trim()
}

$books = Get-ChildItem -LiteralPath $RepoRoot -Filter "LSE_BOOK_*_WORKING.html" -File | Sort-Object Name

Write-Host ""
Write-Host "Writing to: $out"
Write-Host ""

$allTodos = New-Object System.Collections.Generic.List[string]

foreach ($book in $books) {
    if ($book.Name -notmatch 'LSE_BOOK_(\d)_(.+?)_WORKING\.html') { continue }
    $num = $Matches[1]
    $rawTitle = ($Matches[2] -replace '_', ' ')
    $titleTC = (Get-Culture).TextInfo.ToTitleCase($rawTitle.ToLower())

    $used = @($refs | Where-Object { $_.from_name -eq $book.Name } |
              ForEach-Object { Split-Path $_.resolved -Leaf } |
              Select-Object -Unique | Sort-Object)

    $institutional = New-Object System.Collections.Generic.List[object]
    $cc = New-Object System.Collections.Generic.List[object]
    $authorMade = New-Object System.Collections.Generic.List[string]

    foreach ($f in $used) {
        if ($f -match '^(UCI_|LSE_[A-E]\d)') { $authorMade.Add($f); continue }

        $hit = $null
        foreach ($a in $Agreed) { if ($f -match $a.Match) { $hit = $a; break } }
        if ($hit) {
            $institutional.Add([pscustomobject]@{ file = $f; holder = $hit.Holder; credit = $hit.Credit; status = $hit.Status })
            if ($hit.Credit -match 'TODO') { $allTodos.Add("Book ${num}: ${f}  ->  $($hit.Credit)") }
            continue
        }

        $tok = Get-LicenseToken -Name $f
        $who = Get-Photographer -Name $f -LicTok $tok
        if (-not $tok) { $allTodos.Add("Book ${num}: ${f}  ->  no licence in filename, needs a credit") }
        $cc.Add([pscustomobject]@{
            file = $f
            who  = if ($who) { $who } else { 'TODO_PHOTOGRAPHER' }
            lic  = $tok
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
     credited individually in the Image Credits section. Several appear by
     permission granted specifically for free, non-commercial educational use.
     Those permissions cover this work only. They do not transfer to anyone who
     reuses this text under the licence above, and anyone doing so must clear
     those photographs independently or remove them.</p>

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

    if ($institutional.Count -gt 0) {
        [void]$sb.AppendLine("  <h2>Used by permission</h2>")
        [void]$sb.AppendLine("  <p>Reproduced with the permission of the holders, granted for free")
        [void]$sb.AppendLine("     non-commercial educational use. Wording is as agreed with each holder.</p>")
        foreach ($g in ($institutional | Group-Object holder | Sort-Object Name)) {
            [void]$sb.AppendLine("  <h3>$($g.Name)</h3>")
            [void]$sb.AppendLine("  <ul>")
            foreach ($x in $g.Group) { [void]$sb.AppendLine("    <li>$($x.credit)</li>") }
            [void]$sb.AppendLine("  </ul>")
        }
        [void]$sb.AppendLine()
    }

    if ($cc.Count -gt 0) {
        [void]$sb.AppendLine("  <h2>Open licence</h2>")
        [void]$sb.AppendLine("  <ul>")
        foreach ($x in ($cc | Sort-Object who, file)) {
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

    Write-Host ("Book {0}  {1,-28} {2,3} images: {3} permission, {4} open licence, {5} author" -f `
        $num, $titleTC, $used.Count, $institutional.Count, $cc.Count, $authorMade.Count)
}

# ---------- TODO report ----------

$todoPath = Join-Path $out "_TODO.md"
$t = New-Object System.Text.StringBuilder
[void]$t.AppendLine("# Credits TODOs")
[void]$t.AppendLine()
[void]$t.AppendLine("Fix these before pasting anything into the books.")
[void]$t.AppendLine()
if ($allTodos.Count -eq 0) { [void]$t.AppendLine("None.") }
foreach ($x in ($allTodos | Select-Object -Unique | Sort-Object)) { [void]$t.AppendLine("- $x") }
[void]$t.AppendLine()
[void]$t.AppendLine("## Known blanks")
[void]$t.AppendLine()
[void]$t.AppendLine("- **June 4, 2026** appears in every UMD credit. UMD asked for page title plus")
[void]$t.AppendLine("  retrieval date instead of a live URL, because their URLs change. Pick the")
[void]$t.AppendLine("  date you retrieved them and use it everywhere.")
[void]$t.AppendLine("- **MSU basil root rot** has no permission on record. Send the request or remove.")
[void]$t.AppendLine("- **NC State strawberry black root rot** was requested and never answered.")
[void]$t.AppendLine("- **NC State flumioxazin drift, two images** were flagged REJECT when the plan")
[void]$t.AppendLine("  was to sell the book. CC BY-NC-SA is fine for a free edition. Re-rule them.")
[void]$t.AppendLine("- **NC State Fusarium wilt** rights were never confirmed.")
[void]$t.AppendLine("- **TODO_PHOTOGRAPHER** means the filename had no name before the licence")
[void]$t.AppendLine("  token. Check the original source.")
$t.ToString() | Set-Content -LiteralPath $todoPath -Encoding UTF8

Write-Host ""
Write-Host "TODOs: $($allTodos.Count)" -ForegroundColor $(if ($allTodos.Count) { 'Yellow' } else { 'Green' })
Write-Host "Review: $todoPath" -ForegroundColor Cyan
Write-Host "Output: $out" -ForegroundColor Cyan
Write-Host ""
Write-Host "Nothing was injected. Read the files, fix the TODOs, then paste." -ForegroundColor Cyan
Write-Host ""



