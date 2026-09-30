<#
.SYNOPSIS
  Packs author figures into review batches for caption drafting.

.DESCRIPTION
  For each figure: a review-size JPEG (max 1600 px) plus a manifest entry with
  the current caption and alt text, every book it appears in, the nearest
  heading, and two paragraphs of book text before and after it.

  Output: INVENTORY\caption_batches\<set>_NN\  (images + manifest.md)
  Upload every file in one batch folder to the chat together.

  Read-only against the books. Safe to run any number of times.

.PARAMETER Set
  Tier1  the 22 high-risk figures (default)
  Rest   every author figure not in Tier 1
  All    all author figures

.EXAMPLE
  .\tools\Export-LseCaptionBatches.ps1
  .\tools\Export-LseCaptionBatches.ps1 -Set Rest
  .\tools\Export-LseCaptionBatches.ps1 -Ids LSE_D02,UCI_029
#>
param(
    [ValidateSet('Tier1','Rest','All')][string]$Set = 'Tier1',
    [string[]]$Ids,
    [int]$BatchSize = 8,
    [int]$MaxPx = 1600,
    [string]$Repo = (Split-Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$Tier1 = [ordered]@{
    'LSE_D02'='Organism/disease discrimination'; 'LSE_D03'='Organism/disease discrimination'
    'LSE_D05'='Organism/disease discrimination'; 'LSE_D15'='Organism/disease discrimination'
    'LSE_D19'='Organism/disease discrimination'; 'LSE_D20'='Organism/disease discrimination'
    'LSE_B33'='Organism/disease discrimination'; 'LSE_B03'='Organism/disease discrimination'
    'UCI_020'='Organism/disease discrimination'
    'LSE_D01'='Decision tree'; 'LSE_D04'='Decision tree'; 'LSE_B15'='Decision tree'; 'UCI_029'='Decision tree'
    'LSE_B13'='Safety'; 'LSE_A10'='Safety'; 'LSE_C06'='Safety'
    'UCI_004'='Numbers'; 'UCI_030'='Numbers'; 'LSE_B16'='Numbers'; 'LSE_B10'='Numbers'; 'LSE_E16'='Numbers'
    'UCI_025'='Contested claim'
}
$Dupes = @{
    'UCI_029'='Same content as LSE_B36 (Book 5)'; 'LSE_B36'='Same content as UCI_029 (Book 4)'
    'UCI_018'='Irrigation comparison, also UCI_022 and LSE_B30'
    'UCI_022'='Irrigation comparison, also UCI_018 and LSE_B30'
    'LSE_B30'='Irrigation comparison, also UCI_018 and UCI_022'
    'UCI_026'='Electroculture layout, also LSE_C14'; 'LSE_C14'='Electroculture layout, also UCI_026'
    'UCI_028'='Seasonal planting calendar, placed in Book 3 and Book 5'
}

function Get-CleanText($s) {
    $s = [regex]::Replace($s, '<[^>]+>', ' ')
    $s = [System.Net.WebUtility]::HtmlDecode($s)
    ([regex]::Replace($s, '\s+', ' ')).Trim()
}
function Trim-Words($s, $n) {
    $w = $s -split ' '
    if ($w.Count -le $n) { return $s }
    ($w[0..($n-1)] -join ' ') + ' ...'
}

# Load books
$books = Get-ChildItem $Repo -Filter 'LSE_BOOK_*_WORKING.html' | Sort-Object Name
if (-not $books) { throw "No LSE_BOOK_*_WORKING.html in $Repo" }
$html = @{}
foreach ($b in $books) {
    $num = [regex]::Match($b.Name, 'LSE_BOOK_(\d)').Groups[1].Value
    $html["Book $num"] = [IO.File]::ReadAllText($b.FullName)
}

# Collect every author figure occurrence
$secRx = [regex]'(?s)<section class="lse-figure" id="fig-((?:LSE_[A-Z]\d+|UCI_\d+))">(.*?)</section>'
$figs = [ordered]@{}
foreach ($book in ($html.Keys | Sort-Object)) {
    $text = $html[$book]
    foreach ($m in $secRx.Matches($text)) {
        $id = $m.Groups[1].Value
        $body = $m.Groups[2].Value
        $before = $text.Substring([math]::Max(0, $m.Index - 6000), [math]::Min(6000, $m.Index))
        $after  = $text.Substring($m.Index + $m.Length, [math]::Min(6000, $text.Length - $m.Index - $m.Length))

        $heads = [regex]::Matches($before, '(?s)<h[1-4][^>]*>(.*?)</h[1-4]>')
        $heading = if ($heads.Count) { Get-CleanText $heads[$heads.Count-1].Groups[1].Value } else { '' }

        $pb = @([regex]::Matches($before, '(?s)<p(?![^>]*figure-placement-meta)[^>]*>(.*?)</p>') |
                ForEach-Object { Get-CleanText $_.Groups[1].Value } | Where-Object { $_ })
        $pa = @([regex]::Matches($after, '(?s)<p(?![^>]*figure-placement-meta)[^>]*>(.*?)</p>') |
                ForEach-Object { Get-CleanText $_.Groups[1].Value } | Where-Object { $_ })

        $occ = [pscustomobject]@{
            Book    = $book
            Heading = $heading
            Before  = @($pb | Select-Object -Last 2)
            After   = @($pa | Select-Object -First 2)
        }
        if (-not $figs.Contains($id)) {
            $figs[$id] = [pscustomobject]@{
                Id      = $id
                Src     = [regex]::Match($body, 'src="([^"]+)"').Groups[1].Value
                Alt     = [System.Net.WebUtility]::HtmlDecode([regex]::Match($body, 'alt="([^"]*)"').Groups[1].Value)
                Caption = [regex]::Match($body, '(?s)<figcaption>(.*?)</figcaption>').Groups[1].Value
                Occ     = [System.Collections.Generic.List[object]]::new()
            }
        }
        $figs[$id].Occ.Add($occ)
    }
}
Write-Host "Author figures found: $($figs.Count)"

# Pick the set
$want = if ($Ids) { $Ids }
        elseif ($Set -eq 'Tier1') { @($Tier1.Keys) }
        elseif ($Set -eq 'Rest')  { @($figs.Keys | Where-Object { -not $Tier1.Contains($_) }) }
        else                      { @($figs.Keys) }
$missing = @($want | Where-Object { -not $figs.Contains($_) })
if ($missing) { Write-Host "Not found in any book: $($missing -join ', ')" -ForegroundColor Yellow }
$want = @($want | Where-Object { $figs.Contains($_) })

$label = if ($Ids) { 'custom' } else { $Set.ToLower() }
$root = Join-Path $Repo "INVENTORY\caption_batches"
New-Item -ItemType Directory -Force -Path $root | Out-Null

$n = 0
for ($i = 0; $i -lt $want.Count; $i += $BatchSize) {
    $n++
    $dir = Join-Path $root ('{0}_{1:D2}' -f $label, $n)
    if (Test-Path $dir) { Remove-Item $dir -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $dir | Out-Null

    $chunk = $want[$i..([math]::Min($i + $BatchSize, $want.Count) - 1)]
    $md = [System.Text.StringBuilder]::new()
    [void]$md.AppendLine("# Caption batch $label $n")
    [void]$md.AppendLine("Figures: $($chunk -join ', ')")
    [void]$md.AppendLine()

    foreach ($id in $chunk) {
        $f = $figs[$id]
        $srcPath = Join-Path $Repo ($f.Src -replace '/', '\')
        $imgName = "$id.jpg"

        if (Test-Path $srcPath) {
            $img = [System.Drawing.Image]::FromFile($srcPath)
            try {
                $scale = [math]::Min(1.0, $MaxPx / [math]::Max($img.Width, $img.Height))
                $w = [int]($img.Width * $scale); $h = [int]($img.Height * $scale)
                $bmp = New-Object System.Drawing.Bitmap $w, $h
                $g = [System.Drawing.Graphics]::FromImage($bmp)
                $g.Clear([System.Drawing.Color]::White)
                $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $g.DrawImage($img, 0, 0, $w, $h)
                $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object MimeType -eq 'image/jpeg'
                $ep = New-Object System.Drawing.Imaging.EncoderParameters 1
                $ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality), 90L
                $bmp.Save((Join-Path $dir $imgName), $codec, $ep)
                $g.Dispose(); $bmp.Dispose()
            } finally { $img.Dispose() }
        } else {
            $imgName = "MISSING: $($f.Src)"
            Write-Host "  image missing for $id : $srcPath" -ForegroundColor Red
        }

        [void]$md.AppendLine("## $id")
        [void]$md.AppendLine("- Image: $imgName")
        [void]$md.AppendLine("- Source file: $($f.Src)")
        if ($Tier1.Contains($id)) { [void]$md.AppendLine("- Tier 1: $($Tier1[$id])") }
        if ($Dupes.ContainsKey($id)) { [void]$md.AppendLine("- Duplicate: $($Dupes[$id])") }
        [void]$md.AppendLine("- Current caption: $($f.Caption)")
        [void]$md.AppendLine("- Current alt: $($f.Alt)")
        foreach ($o in $f.Occ) {
            [void]$md.AppendLine()
            [void]$md.AppendLine("### In $($o.Book), under: $($o.Heading)")
            [void]$md.AppendLine("Before:")
            foreach ($p in $o.Before) { [void]$md.AppendLine("> $(Trim-Words $p 150)") ; [void]$md.AppendLine('>') }
            [void]$md.AppendLine("After:")
            foreach ($p in $o.After)  { [void]$md.AppendLine("> $(Trim-Words $p 150)") ; [void]$md.AppendLine('>') }
        }
        [void]$md.AppendLine()
    }
    [IO.File]::WriteAllText((Join-Path $dir 'manifest.md'), $md.ToString(), [Text.UTF8Encoding]::new($false))
    Write-Host ("Batch {0:D2}: {1}" -f $n, ($chunk -join ', ')) -ForegroundColor Green
}

Write-Host ""
Write-Host "Batches in $root" -ForegroundColor Cyan
Write-Host "Upload every file in one batch folder to the chat together." -ForegroundColor Cyan
