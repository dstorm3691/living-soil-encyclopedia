<#
.SYNOPSIS
    Finds the LSE repo and the desktop working folder, then prints the exact
    census command to run next.

.DESCRIPTION
    Read-only. Walks your user profile and OneDrive, finds git repos, folders
    dense with images, and large HTML files. Changes nothing.

.EXAMPLE
    .\Find-LsePaths.ps1

.EXAMPLE
    .\Find-LsePaths.ps1 -SearchRoot "D:\"
#>

[CmdletBinding()]
param(
    [string[]]$SearchRoot,
    [int]$MaxDepth = 7
)

$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'

if (-not $SearchRoot) {
    $SearchRoot = @($env:USERPROFILE)
    if ($env:OneDrive -and (Test-Path -LiteralPath $env:OneDrive)) { $SearchRoot += $env:OneDrive }
    if ($env:OneDriveCommercial -and (Test-Path -LiteralPath $env:OneDriveCommercial)) { $SearchRoot += $env:OneDriveCommercial }
}
$SearchRoot = $SearchRoot | Select-Object -Unique

$ExcludeNames = @(
    'AppData', 'node_modules', '.git', '.venv', '__pycache__', 'Windows',
    '$Recycle.Bin', 'Program Files', 'Program Files (x86)', 'ProgramData',
    '.cache', '.vscode', '.nuget', '.gradle', 'Temp', 'Packages'
)

$ImageExt = @('.jpg', '.jpeg', '.png', '.webp', '.gif', '.tif', '.tiff', '.bmp')
$DocExt   = @('.html', '.htm', '.md')

Write-Host ""
Write-Host "Searching..." -ForegroundColor Cyan
foreach ($r in $SearchRoot) { Write-Host "  $r" -ForegroundColor DarkGray }
Write-Host ""

$repos    = New-Object System.Collections.Generic.List[string]
$imgStats = @{}
$docHits  = New-Object System.Collections.Generic.List[object]
$dirCount = 0

function Walk-Dir {
    param([string]$Path, [int]$Depth)

    if ($Depth -gt $MaxDepth) { return }

    $script:dirCount++
    if ($script:dirCount % 200 -eq 0) {
        Write-Host "  scanned $($script:dirCount) directories..." -ForegroundColor DarkGray
    }

    # git repo?
    if (Test-Path -LiteralPath (Join-Path $Path '.git')) {
        $repos.Add($Path)
    }

    # files in this directory
    try {
        $files = [System.IO.Directory]::EnumerateFiles($Path)
    }
    catch { return }

    $imgN = 0
    $imgBytes = 0L
    foreach ($f in $files) {
        $ext = [System.IO.Path]::GetExtension($f).ToLower()
        if ($ImageExt -contains $ext) {
            $imgN++
            try { $imgBytes += (New-Object System.IO.FileInfo $f).Length } catch { }
        }
        elseif ($DocExt -contains $ext) {
            try {
                $fi = New-Object System.IO.FileInfo $f
                if ($fi.Length -gt 51200) {
                    $docHits.Add([pscustomobject]@{
                        Path  = $f
                        Dir   = $Path
                        KB    = [math]::Round($fi.Length / 1KB, 0)
                        MTime = $fi.LastWriteTime
                    })
                }
            }
            catch { }
        }
    }
    if ($imgN -gt 0) {
        $imgStats[$Path] = [pscustomobject]@{ Count = $imgN; MB = [math]::Round($imgBytes / 1MB, 1) }
    }

    # recurse
    try {
        $subs = [System.IO.Directory]::EnumerateDirectories($Path)
    }
    catch { return }

    foreach ($s in $subs) {
        $name = [System.IO.Path]::GetFileName($s)
        if ($ExcludeNames -contains $name) { continue }
        if ($name.StartsWith('.') -and $name -ne '.git') { continue }
        Walk-Dir -Path $s -Depth ($Depth + 1)
    }
}

foreach ($r in $SearchRoot) {
    if (Test-Path -LiteralPath $r) { Walk-Dir -Path $r -Depth 0 }
}

Write-Host ""
Write-Host "Scanned $dirCount directories." -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------
# GIT REPOS
# ------------------------------------------------------------

Write-Host "=== GIT REPOSITORIES ===" -ForegroundColor Yellow
Write-Host ""
if ($repos.Count -eq 0) {
    Write-Host "  None found. If the repo is on another drive, re-run with -SearchRoot 'D:\'" -ForegroundColor Red
}
else {
    $repoRows = foreach ($r in $repos) {
        $imgHere = ($imgStats.Keys | Where-Object { $_ -eq $r -or $_ -like "$r\*" } |
                    ForEach-Object { $imgStats[$_].Count } | Measure-Object -Sum).Sum
        $docHere = ($docHits | Where-Object { $_.Dir -eq $r -or $_.Dir -like "$r\*" }).Count
        [pscustomobject]@{
            Path       = $r
            BigDocs    = $docHere
            Images     = [int]$imgHere
            LooksLikeLSE = if ($r -match '(?i)soil|lse|encyclo|garden') { 'YES' } else { '' }
        }
    }
    $repoRows | Sort-Object BigDocs -Descending | Format-Table -AutoSize | Out-String | Write-Host
}

# ------------------------------------------------------------
# IMAGE-DENSE FOLDERS
# ------------------------------------------------------------

Write-Host "=== TOP IMAGE FOLDERS ===" -ForegroundColor Yellow
Write-Host ""
$imgStats.GetEnumerator() |
    Sort-Object { $_.Value.Count } -Descending |
    Select-Object -First 25 |
    ForEach-Object {
        [pscustomobject]@{
            Images = $_.Value.Count
            MB     = $_.Value.MB
            Folder = $_.Key
        }
    } | Format-Table -AutoSize | Out-String | Write-Host

$totalImg = ($imgStats.Values | Measure-Object Count -Sum).Sum
Write-Host "  Total images across all scanned folders: $totalImg" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------
# LARGE MANUSCRIPT FILES
# ------------------------------------------------------------

Write-Host "=== LARGE HTML / MD FILES (>50 KB) ===" -ForegroundColor Yellow
Write-Host ""
$docHits | Sort-Object KB -Descending | Select-Object -First 30 |
    ForEach-Object {
        [pscustomobject]@{
            KB    = $_.KB
            MTime = $_.MTime.ToString('yyyy-MM-dd')
            File  = [System.IO.Path]::GetFileName($_.Path)
            Dir   = $_.Dir
        }
    } | Format-Table -AutoSize | Out-String | Write-Host

Write-Host "  Total large doc files found: $($docHits.Count)" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------
# NEXT COMMAND
# ------------------------------------------------------------

Write-Host "=== NEXT ===" -ForegroundColor Green
Write-Host ""

$bestRepo = $null
if ($repos.Count -gt 0) {
    $bestRepo = ($repos | Sort-Object {
        ($docHits | Where-Object { $_.Dir -like "$_\*" -or $_.Dir -eq $_ }).Count
    } -Descending | Select-Object -First 1)
    $lseRepo = $repos | Where-Object { $_ -match '(?i)soil|lse|encyclo|garden' } | Select-Object -First 1
    if ($lseRepo) { $bestRepo = $lseRepo }
}

$bestImg = $imgStats.GetEnumerator() | Sort-Object { $_.Value.Count } -Descending | Select-Object -First 1

Write-Host "Pick the repo and the image folder from the tables above, then run:"
Write-Host ""
if ($bestRepo -and $bestImg) {
    Write-Host "  cd `"$bestRepo`"" -ForegroundColor White
    Write-Host "  .\Invoke-LseCensus.ps1 -DesktopDir `"$($bestImg.Key)`"" -ForegroundColor White
}
else {
    Write-Host "  cd `"<repo path from the first table>`"" -ForegroundColor White
    Write-Host "  .\Invoke-LseCensus.ps1 -DesktopDir `"<image folder from the second table>`"" -ForegroundColor White
}
Write-Host ""
Write-Host "The suggestion above is a guess based on folder names. Check it against"
Write-Host "the tables before running. If the image folder has subfolders, point"
Write-Host "-DesktopDir at the PARENT folder, not one of the subfolders."
Write-Host ""
