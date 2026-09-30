<#
.SYNOPSIS
  Writes approved figure captions and alt text into the book HTML.

.DESCRIPTION
  Reads a captions CSV with columns:
    id, old_caption, new_caption, old_alt, new_alt, flag
  Rows with an empty new_caption are skipped (use this for figures that are
  flagged for correction or removal instead of captioning).

  new_caption is inserted as HTML, so <em> for species names works.
  new_alt is plain text and is escaped.

  Every occurrence of the figure in every book is updated, so figures placed
  in two books and mirrored sections stay in sync.

  Safety: if the caption or alt currently in the book does not match
  old_caption / old_alt, that figure is skipped and reported, so a stale CSV
  can never overwrite a newer edit.

  Dry run by default: prints old -> new for every change.
  -Execute: backs up the books to .build\html_backup_captions, writes, runs verify.py.

.EXAMPLE
  .\tools\Apply-LseCaptions.ps1 -Csv .\INVENTORY\caption_batches\captions_tier1_01.csv
  .\tools\Apply-LseCaptions.ps1 -Csv .\INVENTORY\caption_batches\captions_tier1_01.csv -Execute
#>
param(
    [Parameter(Mandatory)][string[]]$Csv,
    [switch]$Execute,
    [string]$Repo = (Split-Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = 'Stop'

function Esc-Attr($s) { [System.Net.WebUtility]::HtmlEncode(([regex]::Replace($s, '<[^>]+>', ''))).Trim() }
function Norm($s) { ([regex]::Replace([System.Net.WebUtility]::HtmlDecode(([regex]::Replace($s, '<[^>]+>', ''))), '\s+', ' ')).Trim() }

$rows = @()
foreach ($c in $Csv) { $rows += Import-Csv $c -Encoding UTF8 }
$rows = @($rows | Where-Object { $_.id -and $_.new_caption })
Write-Host "Rows with a new caption: $($rows.Count)"

$books = Get-ChildItem $Repo -Filter 'LSE_BOOK_*_WORKING.html' | Sort-Object Name
$files = @{}
foreach ($b in $books) {
    $bytes = [IO.File]::ReadAllBytes($b.FullName)
    $bom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    $files[$b.FullName] = [pscustomobject]@{ Text = [IO.File]::ReadAllText($b.FullName); Bom = $bom; Changed = $false; Name = $b.Name }
}

$applied = 0; $skipped = @()
foreach ($r in $rows) {
    $id = $r.id.Trim()
    $htmlId = if ($id -match '^UCI_(\d+)$') { "UC-$($Matches[1])" } else { $id }
    $rx = [regex]('(?s)(<section class="(?:lse-figure|user-created-figure)" id="fig-' + [regex]::Escape($htmlId) + '">)(.*?)(</section>)')
    $hits = 0
    foreach ($k in @($files.Keys)) {
        $f = $files[$k]
        $ms = $rx.Matches($f.Text)
        if (-not $ms.Count) { continue }
        foreach ($m in $ms) {
            $body = $m.Groups[2].Value
            $curCap = [regex]::Match($body, '(?s)<figcaption>(.*?)</figcaption>').Groups[1].Value
            $curAlt = [regex]::Match($body, 'alt="([^"]*)"').Groups[1].Value
            if ((Norm $curCap) -ne (Norm $r.old_caption) -or ($r.old_alt -and (Norm $curAlt) -ne (Norm $r.old_alt))) {
                $skipped += "$id in $($f.Name): book text no longer matches old_caption/old_alt"
                continue
            }
        }
        if ($skipped -match "^$([regex]::Escape($id)) ") { continue }

        $newText = $rx.Replace($f.Text, {
            param($m)
            $body = $m.Groups[2].Value
            $body = [regex]::Replace($body, '(?s)<figcaption>.*?</figcaption>', { param($x) "<figcaption>$($r.new_caption.Trim())</figcaption>" })
            if ($r.new_alt) {
                $alt = Esc-Attr $r.new_alt
                $body = [regex]::Replace($body, 'alt="[^"]*"', { param($x) "alt=`"$alt`"" })
            }
            $m.Groups[1].Value + $body + $m.Groups[3].Value
        })
        $hits += $ms.Count
        if ($newText -ne $f.Text) { $f.Text = $newText; $f.Changed = $true }
        Write-Host ""
        Write-Host "$id  [$($f.Name), $($ms.Count)x]" -ForegroundColor Cyan
        Write-Host "  caption old: $(Norm $r.old_caption)" -ForegroundColor DarkGray
        Write-Host "  caption new: $($r.new_caption.Trim())"
        if ($r.new_alt) {
            Write-Host "  alt old:     $(Norm $r.old_alt)" -ForegroundColor DarkGray
            Write-Host "  alt new:     $($r.new_alt.Trim())"
        }
    }
    if ($hits) { $applied++ } elseif (-not ($skipped -match "^$([regex]::Escape($id)) ")) { $skipped += "$id : not found in any book" }
}

Write-Host ""
Write-Host "Figures updated: $applied" -ForegroundColor Green
if ($skipped) { Write-Host "Skipped:" -ForegroundColor Yellow; $skipped | Sort-Object -Unique | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow } }

if (-not $Execute) { Write-Host ""; Write-Host "Dry run. Nothing written. Add -Execute to apply." -ForegroundColor Cyan; exit 0 }

$bk = Join-Path $Repo ('.build\html_backup_captions\' + (Get-Date -Format 'yyyyMMdd_HHmmss'))
New-Item -ItemType Directory -Force -Path $bk | Out-Null
foreach ($k in $files.Keys) {
    $f = $files[$k]
    if (-not $f.Changed) { continue }
    Copy-Item $k (Join-Path $bk $f.Name)
    [IO.File]::WriteAllText($k, $f.Text, [Text.UTF8Encoding]::new($f.Bom))
    Write-Host "Wrote $($f.Name)" -ForegroundColor Green
}
Write-Host "Backup: $bk"
Write-Host ""
Push-Location $Repo
try { python verify.py } finally { Pop-Location }
