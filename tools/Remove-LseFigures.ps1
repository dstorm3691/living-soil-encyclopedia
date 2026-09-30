<#
.SYNOPSIS
  Pulls author figures from the books.

.DESCRIPTION
  Removes every <section class="lse-figure" id="fig-ID">...</section> for the
  given ids, in every book, so mirrored sections and figures placed in two
  books stay in sync. The image files stay on disk for the v1.1 redraw.

  Dry run by default. For each figure it reports where it sits, and anything
  that will be left pointing at it:
    - links to #fig-ID (verify.py will fail on these)
    - prose that mentions the figure by id or short label (e.g. "D.3")
  Prose is never changed by this script.

  -Execute: backs up the books to .build\html_backup_figures\<timestamp>,
  removes the figures, appends to INVENTORY\pulled_figures.md, runs verify.py.

.EXAMPLE
  .\tools\Remove-LseFigures.ps1 -Ids LSE_D02,LSE_D03 -Reason "Photoreal AI imagery"
  .\tools\Remove-LseFigures.ps1 -Ids LSE_D02,LSE_D03 -Reason "Photoreal AI imagery" -Execute
#>
param(
    [Parameter(Mandatory)][string[]]$Ids,
    [Parameter(Mandatory)][string]$Reason,
    [switch]$Execute,
    [string]$Repo = (Split-Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = 'Stop'

function Get-CleanText($s) {
    $s = [regex]::Replace($s, '<[^>]+>', ' ')
    $s = [System.Net.WebUtility]::HtmlDecode($s)
    ([regex]::Replace($s, '\s+', ' ')).Trim()
}

$books = Get-ChildItem $Repo -Filter 'LSE_BOOK_*_WORKING.html' | Sort-Object Name
$files = [ordered]@{}
foreach ($b in $books) {
    $bytes = [IO.File]::ReadAllBytes($b.FullName)
    $bom = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    $files[$b.FullName] = [pscustomobject]@{
        Name = $b.Name; Text = [IO.File]::ReadAllText($b.FullName); Bom = $bom; Changed = $false
    }
}

$log = [System.Collections.Generic.List[string]]::new()
$notFound = @(); $warnLinks = 0

foreach ($id in $Ids) {
    $id = $id.Trim()
    $htmlId = if ($id -match '^UCI_(\d+)$') { "UC-$($Matches[1])" } else { $id }
    $secRx = [regex]('(?s)<section class="(?:lse-figure|user-created-figure)" id="fig-' + [regex]::Escape($htmlId) + '">.*?</section>')

    # Short label: LSE_D03 -> D.3 / D3 / D03
    $short = $null
    $sm = [regex]::Match($id, '^LSE_([A-Z])0*(\d+)$')
    if ($sm.Success) { $short = "$($sm.Groups[1].Value)\.?0*$($sm.Groups[2].Value)" }

    Write-Host ""
    Write-Host "== $id" -ForegroundColor Cyan
    $found = 0; $src = ''

    foreach ($k in $files.Keys) {
        $f = $files[$k]
        $ms = $secRx.Matches($f.Text)
        foreach ($m in $ms) {
            $found++
            if (-not $src) { $src = [regex]::Match($m.Value, 'src="([^"]+)"').Groups[1].Value }
            $before = $f.Text.Substring([math]::Max(0, $m.Index - 6000), [math]::Min(6000, $m.Index))
            $heads = @([regex]::Matches($before, '(?s)<h([1-4])[^>]*>(.*?)</h\1>') |
                       ForEach-Object { Get-CleanText $_.Groups[2].Value } | Where-Object { $_ -notmatch '^Figure ' })
            $heading = if ($heads.Count) { $heads[$heads.Count-1] } else { '(no heading found)' }
            Write-Host "  remove from $($f.Name), under: $heading"
        }

        # Links that will dangle
        $links = [regex]::Matches($f.Text, 'href="[^"]*#fig-' + [regex]::Escape($htmlId) + '"')
        if ($links.Count) {
            $warnLinks += $links.Count
            Write-Host "  LINK: $($links.Count) link(s) to #fig-$htmlId in $($f.Name). verify.py will fail until these are handled." -ForegroundColor Red
        }

        # Prose mentions outside the figure itself
        $prose = $secRx.Replace($f.Text, '')
        $pats = @([regex]::Escape($id), [regex]::Escape($htmlId)) | Select-Object -Unique
        if ($short) { $pats += "(?<![\w.])(?:Figure\s+|Fig\.\s*|see\s+)?$short(?![\w.]*\d)" }
        foreach ($p in $pats) {
            foreach ($pm in [regex]::Matches($prose, $p)) {
                $ctxStart = [math]::Max(0, $pm.Index - 150)
                $ctx = Get-CleanText $prose.Substring($ctxStart, [math]::Min(300, $prose.Length - $ctxStart))
                Write-Host "  PROSE ($($f.Name)): ...$ctx..." -ForegroundColor Yellow
            }
        }

        if ($ms.Count) {
            $f.Text = $secRx.Replace($f.Text, '')
            $f.Changed = $true
        }
    }

    if (-not $found) {
        $notFound += $id
        Write-Host "  not found. Different markup, or already removed." -ForegroundColor Yellow
    } else {
        $log.Add("| $id | $found | $src | $Reason | $(Get-Date -Format yyyy-MM-dd) |")
    }
}

Write-Host ""
Write-Host "Figures to remove: $($log.Count)   Not found: $($notFound.Count)" -ForegroundColor Green
if ($notFound) { Write-Host "Not found: $($notFound -join ', ')" -ForegroundColor Yellow }
if ($warnLinks) { Write-Host "Links that will break: $warnLinks. Tell Claude before running -Execute." -ForegroundColor Red }

if (-not $Execute) {
    Write-Host ""
    Write-Host "Dry run. Nothing written. Yellow PROSE lines are text that mentions a pulled figure;" -ForegroundColor Cyan
    Write-Host "those need an old -> new decision, this script never edits prose." -ForegroundColor Cyan
    exit 0
}

$bk = Join-Path $Repo ('.build\html_backup_figures\' + (Get-Date -Format 'yyyyMMdd_HHmmss'))
New-Item -ItemType Directory -Force -Path $bk | Out-Null
foreach ($k in $files.Keys) {
    $f = $files[$k]
    if (-not $f.Changed) { continue }
    Copy-Item $k (Join-Path $bk $f.Name)
    [IO.File]::WriteAllText($k, $f.Text, [Text.UTF8Encoding]::new($f.Bom))
    Write-Host "Wrote $($f.Name)" -ForegroundColor Green
}
Write-Host "Backup: $bk"

$ledger = Join-Path $Repo 'INVENTORY\pulled_figures.md'
if (-not (Test-Path $ledger)) {
    $head = "# Figures pulled from the books`r`n`r`nImage files are kept on disk for redraw.`r`n`r`n| Figure | Occurrences | Source file | Reason | Pulled |`r`n|---|---:|---|---|---|"
    [IO.File]::WriteAllText($ledger, $head + "`r`n", [Text.UTF8Encoding]::new($false))
}
[IO.File]::AppendAllText($ledger, ($log -join "`r`n") + "`r`n", [Text.UTF8Encoding]::new($false))
Write-Host "Logged: $ledger"
Write-Host ""

Push-Location $Repo
try { python verify.py } finally { Pop-Location }
