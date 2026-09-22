<#
.SYNOPSIS
    Removes draft markers before publication.

.DESCRIPTION
    1. Rewrites seven Book 4 figure captions (and alt text where it was
       wrong or truncated) to remove the rough-draft warning and production
       notes.
    2. Deletes the self-photo placeholder figures from every book. They are
       mirrored in Books 2 and 5, so both lose the same sections and the
       mirrors stay in sync.
    3. Hides the "Placement: ..." metadata lines and the diamond image
       markers, in print.css and in each book's own style block.

    Captions are <figcaption>, not <p>, so verify.py's paragraph check is
    unaffected. If verify fails anyway, every file is restored from git.

    Dry run by default.

.EXAMPLE
    .\tools\Clean-LseDraftMarkers.ps1
    .\tools\Clean-LseDraftMarkers.ps1 -Execute
#>

[CmdletBinding()]
param([string]$RepoRoot, [switch]$Execute)

$ErrorActionPreference = 'Stop'
if (-not $RepoRoot) {
    $d = (& git rev-parse --show-toplevel 2>$null)
    if ($LASTEXITCODE -ne 0) { Write-Host "Not in a git repo." -ForegroundColor Red; exit 1 }
    $RepoRoot = $d.Trim() -replace '/', '\'
}
Set-Location $RepoRoot

$Fix = [ordered]@{
    'fig-B30_025' = @{
        Cap = 'Source-identified Fusarium wilt of tomato showing light-brown vascular streaking in a split lower stem. Stem discoloration is a clue; confirm with crop history and local diagnostic guidance.'
        Alt = 'Fusarium wilt of tomato: light-brown vascular streaking in a split lower stem' }
    'fig-B30_082' = @{
        Cap = 'Source-identified bacterial wilt streaming test in tomato. Milky exudate can support diagnosis with context.'
        Alt = 'Bacterial wilt streaming test in tomato, with milky exudate' }
    'fig-B30_026' = @{
        Cap = 'Seedling damping-off caused by Rhizoctonia solani, showing a lesion at the soil line. Similar seedling collapse can also come from water, salts, heat, or poor media, so confirm the pattern before treating.'
        Alt = '' }
    'fig-B30_023' = @{
        Cap = 'Glyphosate injury on tomato new growth, showing yellowed and distorted leaves. Yellowing alone is not diagnostic; confirm exposure history before drawing conclusions.'
        Alt = 'Glyphosate injury on tomato: yellowed, distorted new growth' }
    'fig-B30_024' = @{
        Cap = 'Source-identified 2,4-D injury on tomato showing severe curling and twisted new growth. Confirm herbicide exposure history before using this as a diagnostic label.'
        Alt = '' }
    'fig-B30_039' = @{
        Cap = 'Flumioxazin (PPO herbicide) spray drift on young tomato fruit, three days after exposure. Confirm drift history before treating spotting like this as herbicide injury.'
        Alt = 'Necrosis on young tomato fruit from flumioxazin spray drift' }
    'fig-B30_040' = @{
        Cap = 'Flumioxazin (PPO herbicide) spray drift on tomato foliage and stems, three days after exposure. Confirm drift history before treating necrosis like this as herbicide injury.'
        Alt = 'Necrosis on tomato foliage and stems from flumioxazin spray drift' }
}

$HideCss = '.imgmarker, .figure-placement-meta { display: none !important; }'
$CssTag  = '/* lse-hide-production-meta */'
$placeRx = '(?s)<section\b[^>]*class="[^"]*companion-placeholder[^"]*"[^>]*>.*?</section>\s*'

$books = @(Get-ChildItem -Filter "LSE_BOOK_*_WORKING.html" -File)

Write-Host ""
Write-Host "Mode: $(if ($Execute) { 'EXECUTE' } else { 'DRY RUN' })" -ForegroundColor $(if ($Execute) { 'Yellow' } else { 'Cyan' })
Write-Host ""

foreach ($b in $books) {
    $t = Get-Content $b.FullName -Raw
    $orig = $t

    foreach ($id in $Fix.Keys) {
        $rx = '(?s)<section\b[^>]*\bid="' + [regex]::Escape($id) + '"[^>]*>.*?</section>'
        $m = [regex]::Match($t, $rx)
        if (-not $m.Success) { continue }
        $sec = $m.Value
        $oldCap = [regex]::Match($sec, '(?s)<figcaption>(.*?)</figcaption>').Groups[1].Value
        $new = [regex]::Replace($sec, '(?s)(<figcaption>).*?(</figcaption>)', '${1}' + $Fix[$id].Cap + '${2}')
        if ($Fix[$id].Alt) {
            $new = [regex]::Replace($new, '(<img\b[^>]*?\balt=")[^"]*(")', '${1}' + $Fix[$id].Alt + '${2}')
        }
        if ($new -ne $sec) {
            $t = $t.Replace($sec, $new)
            Write-Host "$($b.Name)  $id" -ForegroundColor White
            Write-Host "  old: $oldCap" -ForegroundColor DarkGray
            Write-Host "  new: $($Fix[$id].Cap)" -ForegroundColor Green
        }
    }

    $ph = [regex]::Matches($t, $placeRx)
    if ($ph.Count -gt 0) {
        $ids = @($ph | ForEach-Object { [regex]::Match($_.Value, 'Figure (SP-\d+)').Groups[1].Value }) -join ', '
        Write-Host "$($b.Name)  removing $($ph.Count) placeholders: $ids" -ForegroundColor Yellow
        $t = [regex]::Replace($t, $placeRx, '')
    }

    if (-not $t.Contains($CssTag) -and $t -match '</style>') {
        $i = $t.IndexOf('</style>')
        $t = $t.Substring(0, $i) + "`n$CssTag`n$HideCss`n" + $t.Substring($i)
        Write-Host "$($b.Name)  hiding placement metadata and markers" -ForegroundColor Cyan
    }

    if ($Execute -and $t -ne $orig) { Set-Content $b.FullName -Value $t -Encoding UTF8 -NoNewline }
}

$css = Join-Path $RepoRoot 'print.css'
if ((Test-Path $css) -and -not ((Get-Content $css -Raw).Contains($CssTag))) {
    Write-Host "print.css  hiding placement metadata and markers" -ForegroundColor Cyan
    if ($Execute) { Add-Content $css -Value "`n$CssTag`n$HideCss" -Encoding UTF8 }
}

if (-not $Execute) {
    Write-Host ""
    Write-Host "DRY RUN. Nothing changed. Re-run with -Execute." -ForegroundColor Cyan
    Write-Host ""
    exit 0
}

Write-Host ""
Write-Host "--- remaining draft markers in visible text ---" -ForegroundColor Cyan
$pat = 'ROUGH-DRAFT|not cleared for public|PLACEHOLDER|Rejected PPO|rights record|\bTODO\b'
$left = 0
foreach ($b in $books) {
    $noTags = [regex]::Replace((Get-Content $b.FullName -Raw), '<[^>]+>', ' ')
    foreach ($h in [regex]::Matches($noTags, $pat)) {
        $left++
        $i = [math]::Max(0, $h.Index - 60)
        Write-Host ("  {0}: ...{1}..." -f $b.Name, (($noTags.Substring($i, [math]::Min(140, $noTags.Length - $i)) -replace '\s+', ' ').Trim())) -ForegroundColor Yellow
    }
}
if ($left -eq 0) { Write-Host "  none" -ForegroundColor Green }

Write-Host ""
& python verify.py
if ($LASTEXITCODE -ne 0) {
    Write-Host "Verify failed. Restoring from git." -ForegroundColor Red
    & git checkout -- print.css $books.Name
    exit 1
}
Write-Host ""
Write-Host "PASS. Commit." -ForegroundColor Green
