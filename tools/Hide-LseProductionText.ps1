<#
.SYNOPSIS
  Hides production text that currently prints in the PDFs. No book text is changed.

.DESCRIPTION
  1. Adds class="production-note" to paragraphs that are production text:
       - "Internal provisional anchors: ..." paragraphs
       - paragraphs made up only of [IMAGE ...] placeholders
     Only bare <p> tags are tagged. A paragraph that mixes placeholders with
     real text is reported, never touched.
  2. Appends one CSS block to print.css (once) that hides:
       - .production-note
       - mirror notices ("Synchronized mirror - do not edit independently")
       - figure ID headings above images ("Figure LSE_D01", "Figure B30_068", "Figure UC-004"),
         at any heading level h3 to h6

  Text stays in the HTML, so verify.py paragraph and mirror checks still pass.

  Dry run by default. -Execute backs up the books and print.css to
  .build\html_backup_hide\<timestamp>, writes, and runs verify.py.

.EXAMPLE
  .\tools\Hide-LseProductionText.ps1
  .\tools\Hide-LseProductionText.ps1 -Execute
#>
param(
    [switch]$Execute,
    [string]$Repo = (Split-Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = 'Stop'

$marker = '/* lse-hide-production-text */'
$markerEnd = '/* end lse-hide-production-text */'
$css = @"
$marker
.production-note,
.mirror-notice,
.lse-figure > h3, .lse-figure > h4, .lse-figure > h5, .lse-figure > h6,
.inline-figure > h3, .inline-figure > h4, .inline-figure > h5, .inline-figure > h6,
.user-created-figure > h3, .user-created-figure > h4, .user-created-figure > h5, .user-created-figure > h6 { display: none !important; }
$markerEnd
"@

$anchorRx = [regex]'<p>(\s*<strong>Internal provisional anchors:</strong>.*?)</p>'
$imgOnlyRx = [regex]'<p>((?:\s*\[IMAGE[^\]]*\])+\s*)</p>'
$mixedRx = [regex]'(?s)<p(?:\s[^>]*)?>((?:(?!</p>).)*?\[IMAGE(?:(?!</p>).)*?)</p>'

$books = Get-ChildItem $Repo -Filter 'LSE_BOOK_*_WORKING.html' | Sort-Object Name
$plan = @()
$files = [ordered]@{}
foreach ($b in $books) {
    $bytes = [IO.File]::ReadAllBytes($b.FullName)
    $bom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    $t = [IO.File]::ReadAllText($b.FullName)

    $nA = $anchorRx.Matches($t).Count
    $nI = $imgOnlyRx.Matches($t).Count
    $nImgTotal = ([regex]::Matches($t, '\[IMAGE')).Count

    $new = $anchorRx.Replace($t, '<p class="production-note">$1</p>')
    $new = $imgOnlyRx.Replace($new, '<p class="production-note">$1</p>')

    # Anything with [IMAGE left in a paragraph that is not tagged
    $left = @($mixedRx.Matches($new) | Where-Object { $_.Value -notmatch '^<p class="production-note">' })

    $plan += [pscustomobject]@{
        Book = $b.Name -replace '_WORKING\.html$', ''
        Anchors = $nA
        PlaceholderParas = $nI
        PlaceholderMarks = $nImgTotal
        Untagged = $left.Count
    }
    foreach ($l in $left) {
        $s = [regex]::Replace($l.Value, '<[^>]+>', ' ')
        Write-Host "  NOT TAGGED ($($b.Name)): $($s.Substring(0, [math]::Min(200, $s.Length)))" -ForegroundColor Yellow
    }
    $files[$b.FullName] = [pscustomobject]@{ Name = $b.Name; Old = $t; New = $new; Bom = $bom }
}

$plan | Format-Table -AutoSize

$printCss = Join-Path $Repo 'print.css'
$cssText = [IO.File]::ReadAllText($printCss)
# Replace an existing block (with or without end marker) or append a new one
$blockRx = [regex]('(?s)\r?\n?' + [regex]::Escape($marker) + '.*?(?:' + [regex]::Escape($markerEnd) + '|\}\s*$|\}(?=\s*\r?\n))')
$newCssText = if ($blockRx.IsMatch($cssText)) { $blockRx.Replace($cssText, "`n" + $css.TrimEnd(), 1) } else { $cssText.TrimEnd() + "`n`n" + $css.TrimEnd() + "`n" }
$cssNeeded = ($newCssText -ne $cssText)
Write-Host "print.css block: $(if (-not $cssNeeded) {'already current'} elseif ($blockRx.IsMatch($cssText)) {'will be replaced'} else {'will be added'})"

$totalUntagged = ($plan | Measure-Object Untagged -Sum).Sum
if ($totalUntagged) { Write-Host "$totalUntagged paragraph(s) with [IMAGE mixed into real text. These stay visible; tell Claude." -ForegroundColor Yellow }

if (-not $Execute) { Write-Host ""; Write-Host "Dry run. Nothing written. Add -Execute to apply." -ForegroundColor Cyan; exit 0 }

$bk = Join-Path $Repo ('.build\html_backup_hide\' + (Get-Date -Format 'yyyyMMdd_HHmmss'))
New-Item -ItemType Directory -Force -Path $bk | Out-Null
foreach ($k in $files.Keys) {
    $f = $files[$k]
    if ($f.New -eq $f.Old) { continue }
    Copy-Item $k (Join-Path $bk $f.Name)
    [IO.File]::WriteAllText($k, $f.New, [Text.UTF8Encoding]::new($f.Bom))
    Write-Host "Wrote $($f.Name)" -ForegroundColor Green
}
if ($cssNeeded) {
    Copy-Item $printCss (Join-Path $bk 'print.css')
    [IO.File]::WriteAllText($printCss, $newCssText, [Text.UTF8Encoding]::new($false))
    Write-Host "Updated hide rules in print.css" -ForegroundColor Green
}
Write-Host "Backup: $bk"
Write-Host ""
Push-Location $Repo
try { python verify.py } finally { Pop-Location }
