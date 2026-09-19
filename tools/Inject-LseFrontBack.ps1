<#
.SYNOPSIS
    Injects the generated front matter and image credits into the books.

.DESCRIPTION
    Front matter goes immediately after <body>. Credits go immediately before
    </body>. Both are wrapped in marker comments, so re-running replaces the
    previous block instead of stacking duplicates.

    Credits are refused while their file still contains TODO. Front matter has
    no TODOs and can go in at any time.

    Dry run by default. Every file is backed up before it is touched, and
    verify.py runs afterwards.

.EXAMPLE
    .\Inject-LseFrontBack.ps1

.EXAMPLE
    .\Inject-LseFrontBack.ps1 -Execute

.EXAMPLE
    .\Inject-LseFrontBack.ps1 -FrontMatterOnly -Execute

.EXAMPLE
    .\Inject-LseFrontBack.ps1 -Remove -Execute
#>

[CmdletBinding()]
param(
    [string]$RepoRoot,
    [switch]$Execute,
    [switch]$FrontMatterOnly,
    [switch]$CreditsOnly,
    [switch]$Remove,
    [switch]$SkipVerify
)

$ErrorActionPreference = 'Stop'

if (-not $RepoRoot) {
    $d = (& git rev-parse --show-toplevel 2>$null)
    if ($LASTEXITCODE -ne 0) { Write-Host "Not in a git repo." -ForegroundColor Red; exit 1 }
    $RepoRoot = $d.Trim() -replace '/', '\'
}
$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
$fb = Join-Path $RepoRoot 'frontback'
$bak = Join-Path $RepoRoot '.build\html_backup'

if (-not (Test-Path -LiteralPath $fb) -and -not $Remove) {
    Write-Host "No frontback\ folder. Run Build-LseFrontBack.ps1 first." -ForegroundColor Red
    exit 1
}

$FM_BEGIN = '<!-- LSE-FRONTMATTER-BEGIN -->'
$FM_END   = '<!-- LSE-FRONTMATTER-END -->'
$CR_BEGIN = '<!-- LSE-CREDITS-BEGIN -->'
$CR_END   = '<!-- LSE-CREDITS-END -->'

Write-Host ""
Write-Host "Repo: $RepoRoot"
Write-Host "Mode: $(if ($Remove) { 'REMOVE' } elseif ($Execute) { 'EXECUTE' } else { 'DRY RUN' })" -ForegroundColor $(if ($Execute) { 'Yellow' } else { 'Cyan' })
if ($FrontMatterOnly) { Write-Host "Scope: front matter only" }
if ($CreditsOnly)     { Write-Host "Scope: credits only" }
Write-Host ""

function Remove-Block {
    param([string]$Text, [string]$Begin, [string]$End)
    $pattern = [regex]::Escape($Begin) + '.*?' + [regex]::Escape($End)
    return [regex]::Replace($Text, $pattern, '', 'Singleline') -replace '(\r?\n){3,}', "`r`n`r`n"
}

$books = Get-ChildItem -LiteralPath $RepoRoot -Filter "LSE_BOOK_*_WORKING.html" -File | Sort-Object Name
$changed = 0
$report = New-Object System.Collections.Generic.List[object]

foreach ($book in $books) {
    if ($book.Name -notmatch 'LSE_BOOK_(\d)_') { continue }
    $num = $Matches[1]

    $html = Get-Content -LiteralPath $book.FullName -Raw
    $orig = $html
    $didFM = 'no'; $didCR = 'no'

    # always strip existing blocks first, so this is idempotent
    $html = Remove-Block -Text $html -Begin $FM_BEGIN -End $FM_END
    $html = Remove-Block -Text $html -Begin $CR_BEGIN -End $CR_END

    if (-not $Remove) {

        # ---- front matter ----
        if (-not $CreditsOnly) {
            $fmFile = Join-Path $fb "BOOK_${num}_frontmatter.html"
            if (Test-Path -LiteralPath $fmFile) {
                $fmText = (Get-Content -LiteralPath $fmFile -Raw).Trim()
                if ($fmText -match 'TODO') {
                    $didFM = 'REFUSED, contains TODO'
                }
                else {
                    $block = "$FM_BEGIN`r`n$fmText`r`n$FM_END`r`n"
                    if ($html -match '(?is)(<body[^>]*>)') {
                        $html = [regex]::Replace($html, '(?is)(<body[^>]*>)', "`$1`r`n$block", 1)
                        $didFM = 'injected'
                    }
                    else { $didFM = 'no <body> tag found' }
                }
            }
            else { $didFM = 'no source file' }
        }

        # ---- credits ----
        if (-not $FrontMatterOnly) {
            $crFile = Join-Path $fb "BOOK_${num}_credits.html"
            if (Test-Path -LiteralPath $crFile) {
                $crText = (Get-Content -LiteralPath $crFile -Raw).Trim()
                if ($crText -match 'TODO') {
                    $didCR = 'REFUSED, contains TODO'
                }
                else {
                    $block = "`r`n$CR_BEGIN`r`n$crText`r`n$CR_END`r`n"
                    if ($html -match '(?is)</body>') {
                        $html = [regex]::Replace($html, '(?is)</body>', "$block</body>", 1)
                        $didCR = 'injected'
                    }
                    else { $didCR = 'no </body> tag found' }
                }
            }
            else { $didCR = 'no source file' }
        }
    }

    $delta = ($html -ne $orig)
    $report.Add([pscustomobject]@{
        book = "Book $num"; frontmatter = $didFM; credits = $didCR
        changed = $(if ($delta) { 'yes' } else { 'no' })
    })

    if ($Execute -and $delta) {
        if (-not (Test-Path -LiteralPath $bak)) { New-Item -ItemType Directory -Path $bak -Force | Out-Null }
        $stamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
        Copy-Item -LiteralPath $book.FullName -Destination (Join-Path $bak "$($book.BaseName)_preinject_$stamp.html") -Force
        Set-Content -LiteralPath $book.FullName -Value $html -Encoding UTF8 -NoNewline
        $changed++
    }
}

$report | Format-Table -AutoSize | Out-String | Write-Host

$refused = @($report | Where-Object { $_.frontmatter -like 'REFUSED*' -or $_.credits -like 'REFUSED*' })
if ($refused.Count -gt 0) {
    Write-Host "Refused because TODOs remain: $($refused.Count) book(s)." -ForegroundColor Yellow
    Write-Host "See frontback\_TODO.md. Fix, re-run Build-LseFrontBack.ps1, then try again." -ForegroundColor Yellow
    Write-Host ""
}

if (-not $Execute) {
    Write-Host "DRY RUN. No HTML changed." -ForegroundColor Cyan
    Write-Host "Re-run with -Execute" -ForegroundColor Cyan
    Write-Host ""
    exit 0
}

Write-Host "Modified $changed book file(s)." -ForegroundColor Green
Write-Host "Backups: $bak" -ForegroundColor Green
Write-Host ""

if ($SkipVerify) { exit 0 }

Write-Host "Running verify.py..." -ForegroundColor Yellow
Write-Host ""
Push-Location $RepoRoot
try { & python verify.py; $code = $LASTEXITCODE }
finally { Pop-Location }

Write-Host ""
if ($code -eq 0) {
    Write-Host "verify.py PASSED. Safe to commit." -ForegroundColor Green
    Write-Host "  python build.py --book 1" -ForegroundColor Cyan
}
else {
    Write-Host "verify.py FAILED. Back out before doing anything else:" -ForegroundColor Red
    Write-Host "  git checkout -- *.html" -ForegroundColor Red
    Write-Host "  (or .\Inject-LseFrontBack.ps1 -Remove -Execute)" -ForegroundColor Red
}
Write-Host ""
