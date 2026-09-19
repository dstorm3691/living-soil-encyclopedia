<#
.SYNOPSIS
    LSE Phase 0 census. Read-only inventory across the repo and every
    scattered source folder.

.DESCRIPTION
    Writes only into the output directory. Creates, edits, renames, moves and
    deletes nothing else. Runs on Windows PowerShell 5.1 and PowerShell 7+.
    Imaging uses WIC (PresentationCore), not System.Drawing.

.EXAMPLE
    cd C:\Users\dstor\lse-repo
    & "$env:USERPROFILE\Downloads\Invoke-LseCensus.ps1" -SourceDir `
      "C:\Users\dstor\OneDrive\Desktop\LSE_FINAL_IMAGE_AND_SPLIT_FIX", `
      "C:\Users\dstor\Downloads", `
      "C:\Users\dstor\Desktop"

.EXAMPLE
    # keep everything, including unrelated files
    .\Invoke-LseCensus.ps1 -SourceDir "C:\some\folder" -NoRelevanceFilter
#>

[CmdletBinding()]
param(
    [string]$RepoRoot,

    [Parameter(Mandatory = $true)]
    [string[]]$SourceDir,

    [string]$OutputDir,

    [ValidateSet('All', 'Files', 'Manuscripts', 'Images', 'References', 'Rights', 'Canonical')]
    [string[]]$Job = @('All'),

    [int]$NearDupThreshold = 8,

    [int]$HashMaxMB = 400,

    [switch]$NoRelevanceFilter,

    [string[]]$ExtraRelevancePattern
)

$ProgressPreference = 'Continue'
$script:StartTime = Get-Date
$script:LogLines = New-Object System.Collections.Generic.List[string]

function Write-Log {
    param([string]$Message)
    $line = "[$((Get-Date).ToString('HH:mm:ss'))] $Message"
    $script:LogLines.Add($line)
    Write-Host $line
}

function Test-Job {
    param([string]$Name)
    return ($Job -contains 'All' -or $Job -contains $Name)
}

# ============================================================
# ROOTS
# ============================================================

if (-not $RepoRoot) {
    $detected = $null
    try {
        $detected = (& git rev-parse --show-toplevel 2>$null)
        if ($LASTEXITCODE -ne 0) { $detected = $null }
    }
    catch { $detected = $null }
    if ($detected) { $RepoRoot = $detected.Trim() -replace '/', '\' }
    else {
        Write-Host "`nNo git repo detected here. cd into the repo, or pass -RepoRoot.`n" -ForegroundColor Red
        exit 1
    }
}

if (-not (Test-Path -LiteralPath $RepoRoot)) {
    Write-Host "RepoRoot not found: $RepoRoot" -ForegroundColor Red
    exit 1
}
$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path

$Roots = New-Object System.Collections.Generic.List[object]
$Roots.Add([pscustomobject]@{ Path = $RepoRoot; Label = 'repo' })

$usedLabels = @{ 'repo' = $true }
foreach ($s in $SourceDir) {
    if (-not (Test-Path -LiteralPath $s)) {
        Write-Host "SourceDir not found, skipping: $s" -ForegroundColor Yellow
        continue
    }
    $p = (Resolve-Path -LiteralPath $s).Path
    $nested = $false
    foreach ($existing in $Roots) {
        if ($p -eq $existing.Path) { $nested = $true; break }
        if ($p.StartsWith($existing.Path + '\', [StringComparison]::OrdinalIgnoreCase)) {
            Write-Host "Skipping '$p' (inside '$($existing.Path)')" -ForegroundColor Yellow
            $nested = $true; break
        }
    }
    if ($nested) { continue }

    $label = (Split-Path $p -Leaf) -replace '[^A-Za-z0-9_\-]', '_'
    if (-not $label) { $label = 'root' }
    $base = $label; $k = 2
    while ($usedLabels.ContainsKey($label)) { $label = "$base$k"; $k++ }
    $usedLabels[$label] = $true
    $Roots.Add([pscustomobject]@{ Path = $p; Label = $label })
}

if (-not $OutputDir) { $OutputDir = Join-Path $RepoRoot 'INVENTORY' }
if (-not (Test-Path -LiteralPath $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null }
$OutputDir = (Resolve-Path -LiteralPath $OutputDir).Path

Write-Log "PowerShell: $($PSVersionTable.PSVersion)"
Write-Log "Output:     $OutputDir"
foreach ($r in $Roots) { Write-Log "Root [$($r.Label)]: $($r.Path)" }
Write-Log "Jobs:       $($Job -join ', ')"
Write-Log "Relevance filter: $(if ($NoRelevanceFilter) { 'OFF' } else { 'ON' })"

# ============================================================
# EXCLUSIONS AND RELEVANCE
# ============================================================

$ExcludeDirNames = @(
    '.git', 'node_modules', '__pycache__', '.venv', 'venv', 'INVENTORY', 'dist',
    '_ARCHIVE', 'anaconda3', '.ipynb_checkpoints', '.vscode', '.idea', '.cache',
    'site-packages', 'AppData', '.conda', '.npm', '.nuget'
)
$ExcludeDirPatterns = @(
    'CrystalDiskInfo*', 'AD02-PT-*', '*Introduction-to-Data-Science*',
    'Zoom', 'Telemetry', 'MicrosoftEdge*', 'Steam*'
)
$ExcludeExt = @(
    '.exe', '.msi', '.dll', '.sys', '.iso', '.zip', '.7z', '.rar', '.cab',
    '.whl', '.pyd', '.lib', '.obj', '.pdb', '.tmp', '.log', '.mp4', '.mov', '.mkv'
)

# A file is LSE-relevant if it lives in the repo, or its full path matches
# any of these. Broad on purpose. Anything dropped is logged so you can check.
$RelevancePatterns = @(
    '*lse*', '*living*soil*', '*living_soil*', '*encyclopedia*', '*permaculture*',
    '*garden*', '*compost*', '*soil*', '*companion*', '*volume_*', '*volume *',
    '*book_1*', '*book_2*', '*book_3*', '*book_4*', '*book_5*', '*book1*',
    '*manuscript*', '*chapter*', '*figure*', '*assets*', '*crop*', '*guild*',
    '*amendment*', '*microbe*', '*ipm*', '*diagnostic*', '*inoculant*', '*herb*',
    '*foundations*', '*field_guide*', '*field guide*', '*sop*', '*batch_*',
    '*phase_*', '*checkpoint*', '*citation*', '*bibliograph*'
)
if ($ExtraRelevancePattern) { $RelevancePatterns += $ExtraRelevancePattern }

$ImageExt = @('.jpg', '.jpeg', '.png', '.webp', '.gif', '.tif', '.tiff', '.svg', '.bmp')
$TextExt  = @('.html', '.htm', '.md', '.txt', '.csv', '.json', '.css', '.py')

function Test-ExcludedPath {
    param([string]$FullPath)
    foreach ($seg in $FullPath.Split('\')) {
        if ($ExcludeDirNames -contains $seg) { return $true }
        foreach ($pat in $ExcludeDirPatterns) { if ($seg -like $pat) { return $true } }
    }
    return $false
}

function Test-Relevant {
    param([string]$FullPath, [string]$Label)
    if ($NoRelevanceFilter) { return $true }
    if ($Label -eq 'repo') { return $true }
    $lower = $FullPath.ToLower()
    foreach ($pat in $RelevancePatterns) { if ($lower -like $pat) { return $true } }
    return $false
}

# ============================================================
# JOB 1: FILE CENSUS
# ============================================================

$filesCsv = Join-Path $OutputDir 'files.csv'

if (Test-Job 'Files') {
    Write-Log "JOB 1: file census"

    $gitTracked = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    Push-Location $RepoRoot
    try {
        $tracked = & git ls-files 2>$null
        if ($LASTEXITCODE -eq 0 -and $tracked) {
            foreach ($t in $tracked) { [void]$gitTracked.Add((Join-Path $RepoRoot ($t -replace '/', '\'))) }
        }
        Write-Log "  git-tracked files in repo: $($gitTracked.Count)"
    }
    finally { Pop-Location }

    $rows = New-Object System.Collections.Generic.List[object]
    $dropped = New-Object System.Collections.Generic.List[object]
    $seenPaths = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    $hashLimit = $HashMaxMB * 1MB

    foreach ($r in $Roots) {
        Write-Log "  walking [$($r.Label)] $($r.Path)"
        $all = Get-ChildItem -LiteralPath $r.Path -Recurse -File -Force -ErrorAction SilentlyContinue
        $i = 0; $kept = 0; $skipped = 0
        foreach ($f in $all) {
            $i++
            if ($i % 200 -eq 0) {
                Write-Progress -Activity "File census [$($r.Label)]" -Status "$i seen, $kept kept" -PercentComplete -1
            }
            if (Test-ExcludedPath -FullPath $f.FullName) { continue }
            $ext = $f.Extension.ToLower()
            if ($ExcludeExt -contains $ext) { continue }
            if ($f.Name -in @('Thumbs.db', 'desktop.ini', '.DS_Store')) { continue }
            if (-not $seenPaths.Add($f.FullName)) { continue }

            if (-not (Test-Relevant -FullPath $f.FullName -Label $r.Label)) {
                $skipped++
                $dropped.Add([pscustomobject]@{
                    path = $f.FullName; location = $r.Label; ext = $ext
                    bytes = $f.Length; mtime = $f.LastWriteTimeUtc.ToString('yyyy-MM-ddTHH:mm:ssZ')
                })
                continue
            }

            $hash = ''
            if ($f.Length -le $hashLimit) {
                try { $hash = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256 -ErrorAction Stop).Hash }
                catch { Write-Log "  UNREADABLE: $($f.FullName)" }
            }

            $gt = 'n-a'
            if ($r.Label -eq 'repo') { $gt = if ($gitTracked.Contains($f.FullName)) { 'yes' } else { 'no' } }

            $rows.Add([pscustomobject]@{
                path = $f.FullName; location = $r.Label; ext = $ext
                bytes = $f.Length; mtime = $f.LastWriteTimeUtc.ToString('yyyy-MM-ddTHH:mm:ssZ')
                sha256 = $hash; git_tracked = $gt
            })
            $kept++
        }
        Write-Progress -Activity "File census [$($r.Label)]" -Completed
        Write-Log "    $kept kept, $skipped dropped as not-LSE, of $i seen"
    }

    $rows | Export-Csv -LiteralPath $filesCsv -NoTypeInformation -Encoding UTF8
    $dropped | Export-Csv -LiteralPath (Join-Path $OutputDir 'excluded_by_relevance.csv') -NoTypeInformation -Encoding UTF8
    Write-Log "  wrote files.csv ($($rows.Count) rows) and excluded_by_relevance.csv ($($dropped.Count) rows)"

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("# File Summary")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("Generated: $((Get-Date).ToString('u'))")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("Relevance filter: $(if ($NoRelevanceFilter) { 'OFF' } else { 'ON' }). Dropped files are listed in ``excluded_by_relevance.csv`` — skim it once to confirm nothing real was cut.")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("## Roots")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("| label | path |")
    [void]$sb.AppendLine("|---|---|")
    foreach ($r in $Roots) { [void]$sb.AppendLine("| $($r.Label) | ``$($r.Path)`` |") }
    [void]$sb.AppendLine()

    [void]$sb.AppendLine("## Repo contents (the thing that matters)")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("| file | KB | git | mtime |")
    [void]$sb.AppendLine("|---|---:|---|---|")
    foreach ($f in ($rows | Where-Object { $_.location -eq 'repo' } | Sort-Object { [int64]$_.bytes } -Descending)) {
        [void]$sb.AppendLine("| ``$($f.path.Substring($RepoRoot.Length).TrimStart('\'))`` | $([math]::Round([int64]$f.bytes / 1KB, 0)) | $($f.git_tracked) | $($f.mtime) |")
    }
    [void]$sb.AppendLine()

    [void]$sb.AppendLine("## By location")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("| location | files | total MB |")
    [void]$sb.AppendLine("|---|---:|---:|")
    foreach ($g in ($rows | Group-Object location | Sort-Object Count -Descending)) {
        $mb = [math]::Round((($g.Group | Measure-Object bytes -Sum).Sum / 1MB), 1)
        [void]$sb.AppendLine("| $($g.Name) | $($g.Count) | $mb |")
    }
    [void]$sb.AppendLine()

    [void]$sb.AppendLine("## By extension")
    [void]$sb.AppendLine()
    $locNames = @($Roots | ForEach-Object { $_.Label })
    [void]$sb.AppendLine("| ext | files | MB | $($locNames -join ' | ') |")
    [void]$sb.AppendLine("|---|---:|---:|$(('---:|' * $locNames.Count))")
    foreach ($g in ($rows | Group-Object ext | Sort-Object Count -Descending)) {
        $mb = [math]::Round((($g.Group | Measure-Object bytes -Sum).Sum / 1MB), 1)
        $cells = foreach ($ln in $locNames) { @($g.Group | Where-Object { $_.location -eq $ln }).Count }
        [void]$sb.AppendLine("| $($g.Name) | $($g.Count) | $mb | $($cells -join ' | ') |")
    }
    [void]$sb.AppendLine()

    [void]$sb.AppendLine("## Directories holding LSE material")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("| files | MB | imgs | bigdocs | directory |")
    [void]$sb.AppendLine("|---:|---:|---:|---:|---|")
    foreach ($d in ($rows | Group-Object { Split-Path $_.path -Parent } | Sort-Object { ($_.Group | Measure-Object bytes -Sum).Sum } -Descending)) {
        $imgs = @($d.Group | Where-Object { $ImageExt -contains $_.ext }).Count
        $big  = @($d.Group | Where-Object { @('.html', '.htm', '.md') -contains $_.ext -and [int64]$_.bytes -gt 51200 }).Count
        if ($imgs -lt 3 -and $big -lt 1) { continue }
        $mb = [math]::Round((($d.Group | Measure-Object bytes -Sum).Sum / 1MB), 1)
        [void]$sb.AppendLine("| $($d.Count) | $mb | $imgs | $big | ``$($d.Name)`` |")
    }
    [void]$sb.AppendLine()

    $sb.ToString() | Set-Content -LiteralPath (Join-Path $OutputDir 'files_summary.md') -Encoding UTF8
    Write-Log "  wrote files_summary.md"
}

if (-not (Test-Path -LiteralPath $filesCsv)) {
    Write-Host "files.csv not found. Run with -Job Files first." -ForegroundColor Red
    exit 1
}
$AllFiles = Import-Csv -LiteralPath $filesCsv

# ============================================================
# JOB 2: MANUSCRIPT FINGERPRINTING
# ============================================================

function Get-PlainText {
    param([string]$Html)
    $t = $Html -replace '(?s)<script.*?</script>', ' '
    $t = $t -replace '(?s)<style.*?</style>', ' '
    $t = $t -replace '(?s)<!--.*?-->', ' '
    $t = $t -replace '<[^>]+>', ' '
    $t = $t -replace '&[a-zA-Z#0-9]+;', ' '
    return ($t -replace '\s+', ' ').Trim()
}

function Get-WordCount {
    param([string]$Text)
    if (-not $Text) { return 0 }
    return @($Text.Split(' ', [StringSplitOptions]::RemoveEmptyEntries)).Count
}

function Get-NormalizedStem {
    param([string]$Name)
    $s = $Name.ToLower()
    $s = $s -replace '\.(html|htm|md|pdf)$', ''
    $s = $s -replace '[_\- ]*(edited|source|final|draft|clean|copy|new|old|backup|bak|candidate|working|fixed|hold\d*)\b', ''
    $s = $s -replace '[_\- ]*v?\d{1,3}[\._\-]\d{1,3}([\._\-]\d{1,4})?', ''
    $s = $s -replace '\b(m\d-\d)\b', ''
    $s = $s -replace '\(\d+\)', ''
    $s = $s -replace '\d{4}[-_]?\d{2}[-_]?\d{2}', ''
    $s = $s -replace '[^a-z0-9]+', ' '
    $s = $s -replace '\s+', ' '
    $s = $s.Trim()
    if (-not $s) { $s = '(unnamed)' }
    return $s
}

$manuCsv = Join-Path $OutputDir 'manuscripts.csv'

if (Test-Job 'Manuscripts') {
    Write-Log "JOB 2: manuscript fingerprinting"

    $cands = @($AllFiles | Where-Object {
        @('.html', '.htm', '.md', '.pdf') -contains $_.ext -and [int64]$_.bytes -gt 51200
    })
    Write-Log "  candidates: $($cands.Count)"

    $mrows = New-Object System.Collections.Generic.List[object]
    $c = 0
    foreach ($cd in $cands) {
        $c++
        Write-Progress -Activity "Manuscript fingerprint" -Status "$c / $($cands.Count)" -PercentComplete (100 * $c / [math]::Max($cands.Count, 1))

        $o = [ordered]@{
            path = $cd.path; location = $cd.location; ext = $cd.ext
            bytes = $cd.bytes; mtime = $cd.mtime; git_tracked = $cd.git_tracked
            sha256 = $cd.sha256
            title = ''; h1 = ''; words = 0; h2 = 0; h3 = 0; imgs = 0
            toc = 'no'; anchors_ok = 'n-a'; anchors_broken = 0
            first_headings = ''; last_headings = ''
            markers = ''; stem = ''
        }

        $fn = Split-Path $cd.path -Leaf
        $mk = @()
        foreach ($m in @('_EDITED', '_SOURCE', '_FINAL', '_WORKING', '_CLEAN', 'PRINT_READY', 'HOLD', 'TOC_FIXED', 'WIDTH_FIXED', 'INJECTED', 'MERGED', 'M4-1', 'M4-3', 'M4-4', 'M3-4', 'candidate', 'ASSEMBLED')) {
            if ($fn -match [regex]::Escape($m)) { $mk += $m }
        }
        if ($fn -match '\d{4}[-_]?\d{2}[-_]?\d{2}') { $mk += 'datestamp' }
        if ($fn -match '\(\d+\)') { $mk += 'numbered-copy' }
        if ($fn -match '(?i)v\d+[_\.]\d+') { $mk += 'version-number' }
        $o.markers = ($mk -join '; ')
        $o.stem = Get-NormalizedStem -Name $fn

        if ($cd.ext -eq '.pdf') {
            $o.title = '(pdf, not parsed)'
            $mrows.Add([pscustomobject]$o)
            continue
        }

        try { $html = Get-Content -LiteralPath $cd.path -Raw -Encoding UTF8 -ErrorAction Stop }
        catch {
            Write-Log "  UNREADABLE: $($cd.path)"
            $mrows.Add([pscustomobject]$o)
            continue
        }

        if ($html -match '(?is)<title[^>]*>(.*?)</title>') { $o.title = ($Matches[1] -replace '\s+', ' ').Trim() }
        if ($html -match '(?is)<h1[^>]*>(.*?)</h1>') { $o.h1 = (Get-PlainText -Html $Matches[1]) }

        # FIXED: parenthesize before splitting, otherwise the args bind to the function
        $plain = Get-PlainText -Html $html
        $o.words = Get-WordCount -Text $plain

        $o.h2 = ([regex]::Matches($html, '(?i)<h2[\s>]')).Count
        $o.h3 = ([regex]::Matches($html, '(?i)<h3[\s>]')).Count
        $o.imgs = ([regex]::Matches($html, '(?i)<img[\s>]')).Count

        $heads = @()
        foreach ($m in [regex]::Matches($html, '(?is)<h2[^>]*>(.*?)</h2>')) { $heads += (Get-PlainText -Html $m.Groups[1].Value) }
        if ($heads.Count -eq 0) {
            foreach ($m in [regex]::Matches($html, '(?m)^##\s+(.+)$')) { $heads += $m.Groups[1].Value.Trim() }
        }
        $o.first_headings = (@($heads | Select-Object -First 5) -join ' | ')
        $o.last_headings  = (@($heads | Select-Object -Last 5) -join ' | ')

        $anchorRefs = @([regex]::Matches($html, 'href\s*=\s*["'']#([^"'']+)["'']') | ForEach-Object { $_.Groups[1].Value })
        if ($anchorRefs.Count -gt 3) {
            $o.toc = 'yes'
            $idSet = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
            foreach ($m in [regex]::Matches($html, 'id\s*=\s*["'']([^"'']+)["'']')) { [void]$idSet.Add($m.Groups[1].Value) }
            $missing = @($anchorRefs | Where-Object { -not $idSet.Contains($_) }).Count
            $o.anchors_broken = $missing
            $o.anchors_ok = "$($anchorRefs.Count - $missing)/$($anchorRefs.Count)"
        }

        $mrows.Add([pscustomobject]$o)
    }
    Write-Progress -Activity "Manuscript fingerprint" -Completed

    $mrows | Export-Csv -LiteralPath $manuCsv -NoTypeInformation -Encoding UTF8

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("# Manuscript Version Families")
    [void]$sb.AppendLine()
    $fams = $mrows | Group-Object stem | Sort-Object Count -Descending
    $multi = @($fams | Where-Object { $_.Count -gt 1 }).Count
    [void]$sb.AppendLine("**Families:** $(@($fams).Count). **Contested:** $multi")
    [void]$sb.AppendLine()

    [void]$sb.AppendLine("## Repo manuscripts, ranked")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("| file | words | h2/h3 | imgs | anchors | broken |")
    [void]$sb.AppendLine("|---|---:|---|---:|---|---:|")
    foreach ($m in ($mrows | Where-Object { $_.location -eq 'repo' } | Sort-Object { [int]$_.words } -Descending)) {
        [void]$sb.AppendLine("| ``$(Split-Path $m.path -Leaf)`` | $($m.words) | $($m.h2)/$($m.h3) | $($m.imgs) | $($m.anchors_ok) | $($m.anchors_broken) |")
    }
    [void]$sb.AppendLine()

    foreach ($f in $fams) {
        [void]$sb.AppendLine("### $($f.Name)")
        [void]$sb.AppendLine()
        [void]$sb.AppendLine("| file | loc | words | h2/h3 | imgs | anchors | mtime | git | markers |")
        [void]$sb.AppendLine("|---|---|---:|---|---:|---|---|---|---|")
        foreach ($m in ($f.Group | Sort-Object mtime -Descending)) {
            [void]$sb.AppendLine("| ``$(Split-Path $m.path -Leaf)`` | $($m.location) | $($m.words) | $($m.h2)/$($m.h3) | $($m.imgs) | $($m.anchors_ok) | $($m.mtime) | $($m.git_tracked) | $($m.markers) |")
        }
        [void]$sb.AppendLine()
        if ($f.Count -gt 1) {
            $wmin = ($f.Group | Measure-Object words -Minimum).Minimum
            $wmax = ($f.Group | Measure-Object words -Maximum).Maximum
            $identical = @($f.Group | Group-Object sha256 | Where-Object { $_.Count -gt 1 }).Count
            [void]$sb.AppendLine("Word spread: $wmin to $wmax (delta $($wmax - $wmin))")
            if ($identical -gt 0) { [void]$sb.AppendLine("Byte-identical subsets: $identical. Free wins, keep one.") }
            [void]$sb.AppendLine()
            foreach ($m in $f.Group) {
                [void]$sb.AppendLine("- ``$(Split-Path $m.path -Leaf)`` [$($m.location)]")
                [void]$sb.AppendLine("  - first: $($m.first_headings)")
                [void]$sb.AppendLine("  - last:  $($m.last_headings)")
            }
            [void]$sb.AppendLine()
        }
        [void]$sb.AppendLine("RULING: [ ]")
        [void]$sb.AppendLine()
        [void]$sb.AppendLine("---")
        [void]$sb.AppendLine()
    }

    $sb.ToString() | Set-Content -LiteralPath (Join-Path $OutputDir 'manuscripts.md') -Encoding UTF8
    Write-Log "  wrote manuscripts.md and manuscripts.csv ($($mrows.Count) candidates, $multi contested)"
}

# ============================================================
# JOB 3: IMAGE CENSUS (WIC)
# ============================================================

$imagesCsv = Join-Path $OutputDir 'images.csv'

if (Test-Job 'Images') {
    Write-Log "JOB 3: image census"

    try {
        Add-Type -AssemblyName PresentationCore -ErrorAction Stop
        Add-Type -AssemblyName WindowsBase -ErrorAction Stop
    }
    catch {
        Write-Host "Could not load PresentationCore." -ForegroundColor Red
        exit 1
    }

    function Get-ImageFacts {
        param([string]$Path)
        $result = [ordered]@{ width = 0; height = 0; dhash = ''; has_exif = 'no'; exif_source = '' }
        $fs = $null
        try {
            $fs = [System.IO.File]::Open($Path, 'Open', 'Read', 'ReadWrite')
            $dec = [System.Windows.Media.Imaging.BitmapDecoder]::Create(
                $fs,
                [System.Windows.Media.Imaging.BitmapCreateOptions]::DelayCreation,
                [System.Windows.Media.Imaging.BitmapCacheOption]::None)
            $frame = $dec.Frames[0]
            $result.width  = $frame.PixelWidth
            $result.height = $frame.PixelHeight
            try {
                $md = $frame.Metadata
                if ($md) {
                    $bits = @()
                    try { if ($md.Author)    { $bits += ($md.Author -join ' ') } } catch { }
                    try { if ($md.Copyright) { $bits += $md.Copyright } }          catch { }
                    try { if ($md.Title)     { $bits += $md.Title } }              catch { }
                    try { if ($md.Comment)   { $bits += $md.Comment } }            catch { }
                    $bits = @($bits | Where-Object { $_ -and $_.ToString().Trim() })
                    if ($bits.Count -gt 0) {
                        $result.has_exif = 'yes'
                        $result.exif_source = ((($bits -join ' / ') -replace '[,\r\n]', ' ') -replace '\s+', ' ').Trim()
                    }
                }
            }
            catch { }
        }
        catch {
            if ($fs) { $fs.Dispose() }
            return $result
        }
        finally { if ($fs) { $fs.Dispose(); $fs = $null } }

        if ($result.width -lt 9 -or $result.height -lt 8) { return $result }

        $fs2 = $null
        try {
            $fs2 = [System.IO.File]::Open($Path, 'Open', 'Read', 'ReadWrite')
            $bi = New-Object System.Windows.Media.Imaging.BitmapImage
            $bi.BeginInit()
            $bi.StreamSource = $fs2
            $bi.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
            $bi.CreateOptions = [System.Windows.Media.Imaging.BitmapCreateOptions]::IgnoreColorProfile
            if ($result.width -ge $result.height) { $bi.DecodePixelWidth = 72 } else { $bi.DecodePixelHeight = 72 }
            $bi.EndInit()

            $gray = New-Object System.Windows.Media.Imaging.FormatConvertedBitmap
            $gray.BeginInit()
            $gray.Source = $bi
            $gray.DestinationFormat = [System.Windows.Media.PixelFormats]::Gray8
            $gray.EndInit()

            $w = $gray.PixelWidth; $h = $gray.PixelHeight
            if ($w -lt 9 -or $h -lt 8) { return $result }

            $stride = $w
            $buf = New-Object byte[] ($stride * $h)
            $gray.CopyPixels($buf, $stride, 0)

            $sb = New-Object System.Text.StringBuilder
            for ($gy = 0; $gy -lt 8; $gy++) {
                $sy = [int][math]::Floor((($gy + 0.5) * $h) / 8.0)
                if ($sy -ge $h) { $sy = $h - 1 }
                $rowBase = $sy * $stride
                for ($gx = 0; $gx -lt 8; $gx++) {
                    $x1 = [int][math]::Floor((($gx + 0.5) * $w) / 9.0)
                    $x2 = [int][math]::Floor((($gx + 1.5) * $w) / 9.0)
                    if ($x1 -ge $w) { $x1 = $w - 1 }
                    if ($x2 -ge $w) { $x2 = $w - 1 }
                    [void]$sb.Append($(if ($buf[$rowBase + $x1] -gt $buf[$rowBase + $x2]) { '1' } else { '0' }))
                }
            }
            $result.dhash = $sb.ToString()
        }
        catch { }
        finally { if ($fs2) { $fs2.Dispose() } }
        return $result
    }

    $imgFiles = @($AllFiles | Where-Object { $ImageExt -contains $_.ext })
    Write-Log "  images found: $($imgFiles.Count)"

    $irows = New-Object System.Collections.Generic.List[object]
    $n = 0
    foreach ($f in $imgFiles) {
        $n++
        if ($n % 20 -eq 0) { Write-Progress -Activity "Image census" -Status "$n / $($imgFiles.Count)" -PercentComplete (100 * $n / $imgFiles.Count) }
        $facts = if ($f.ext -eq '.svg') { [ordered]@{ width = 0; height = 0; dhash = ''; has_exif = 'no'; exif_source = '' } }
                 else { Get-ImageFacts -Path $f.path }
        $irows.Add([pscustomobject]@{
            path = $f.path; location = $f.location; filename = (Split-Path $f.path -Leaf)
            bytes = $f.bytes; width = $facts.width; height = $facts.height
            mtime = $f.mtime; sha256 = $f.sha256; dhash = $facts.dhash
            dup_group = ''; near_group = ''
            has_exif = $facts.has_exif; exif_source = $facts.exif_source
        })
    }
    Write-Progress -Activity "Image census" -Completed

    $dg = 0
    foreach ($g in ($irows | Group-Object sha256 | Where-Object { $_.Count -gt 1 -and $_.Name })) {
        $dg++
        foreach ($m in $g.Group) { $m.dup_group = "D$dg" }
    }
    Write-Log "  exact duplicate groups: $dg"

    function Get-Hamming {
        param([string]$A, [string]$B, [int]$Max)
        $d = 0
        for ($i = 0; $i -lt 64; $i++) { if ($A[$i] -ne $B[$i]) { $d++; if ($d -gt $Max) { return 99 } } }
        return $d
    }

    $reps = New-Object System.Collections.Generic.List[object]
    $seenDup = @{}
    foreach ($r in $irows) {
        if (-not $r.dhash) { continue }
        if ($r.dup_group) {
            if ($seenDup.ContainsKey($r.dup_group)) { continue }
            $seenDup[$r.dup_group] = $true
        }
        $reps.Add($r)
    }

    $ng = 0; $assigned = @{}
    for ($i = 0; $i -lt $reps.Count; $i++) {
        if ($i % 25 -eq 0) { Write-Progress -Activity "Near-duplicate clustering" -Status "$i / $($reps.Count)" -PercentComplete (100 * $i / [math]::Max($reps.Count, 1)) }
        if ($assigned.ContainsKey($reps[$i].path)) { continue }
        $cluster = New-Object System.Collections.Generic.List[object]
        $cluster.Add($reps[$i])
        for ($j = $i + 1; $j -lt $reps.Count; $j++) {
            if ($assigned.ContainsKey($reps[$j].path)) { continue }
            if ((Get-Hamming -A $reps[$i].dhash -B $reps[$j].dhash -Max $NearDupThreshold) -le $NearDupThreshold) { $cluster.Add($reps[$j]) }
        }
        if ($cluster.Count -gt 1) {
            $ng++; $tag = "N$ng"
            $tagDup = @{}; $clusterPaths = @{}
            foreach ($cc in $cluster) {
                $assigned[$cc.path] = $tag; $clusterPaths[$cc.path] = $true
                if ($cc.dup_group) { $tagDup[$cc.dup_group] = $true }
            }
            foreach ($r in $irows) {
                if ($clusterPaths.ContainsKey($r.path) -or ($r.dup_group -and $tagDup.ContainsKey($r.dup_group))) { $r.near_group = $tag }
            }
        }
    }
    Write-Progress -Activity "Near-duplicate clustering" -Completed
    Write-Log "  near-duplicate groups: $ng"

    $irows | Export-Csv -LiteralPath $imagesCsv -NoTypeInformation -Encoding UTF8

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("# Image Duplicate Groups")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("**Exact duplicate groups:** $dg")
    [void]$sb.AppendLine("**Near duplicate groups:** $ng (Hamming <= $NearDupThreshold)")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("## Images by location")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("| location | images | MB |")
    [void]$sb.AppendLine("|---|---:|---:|")
    foreach ($g in ($irows | Group-Object location | Sort-Object Count -Descending)) {
        [void]$sb.AppendLine("| $($g.Name) | $($g.Count) | $([math]::Round((($g.Group | Measure-Object bytes -Sum).Sum / 1MB), 1)) |")
    }
    [void]$sb.AppendLine()

    [void]$sb.AppendLine("## Exact duplicates")
    [void]$sb.AppendLine()
    foreach ($g in ($irows | Where-Object { $_.dup_group } | Group-Object dup_group | Sort-Object { [int64]$_.Group[0].bytes } -Descending)) {
        [void]$sb.AppendLine("### $($g.Name) ($($g.Count) copies)")
        [void]$sb.AppendLine()
        [void]$sb.AppendLine("| path | loc | dims | KB |")
        [void]$sb.AppendLine("|---|---|---|---:|")
        foreach ($m in ($g.Group | Sort-Object location, path)) {
            [void]$sb.AppendLine("| ``$($m.path)`` | $($m.location) | $($m.width)x$($m.height) | $([math]::Round([int64]$m.bytes / 1KB, 0)) |")
        }
        [void]$sb.AppendLine()
    }

    [void]$sb.AppendLine("## Near duplicates")
    [void]$sb.AppendLine()
    foreach ($g in ($irows | Where-Object { $_.near_group } | Group-Object near_group | Sort-Object Count -Descending)) {
        [void]$sb.AppendLine("### $($g.Name) ($($g.Count) members)")
        [void]$sb.AppendLine()
        [void]$sb.AppendLine("| path | loc | dims | KB | metadata |")
        [void]$sb.AppendLine("|---|---|---|---:|---|")
        foreach ($m in ($g.Group | Sort-Object { [int]$_.width * [int]$_.height } -Descending)) {
            [void]$sb.AppendLine("| ``$($m.path)`` | $($m.location) | $($m.width)x$($m.height) | $([math]::Round([int64]$m.bytes / 1KB, 0)) | $($m.exif_source) |")
        }
        [void]$sb.AppendLine()
        [void]$sb.AppendLine("KEEP: ")
        [void]$sb.AppendLine()
    }

    $sb.ToString() | Set-Content -LiteralPath (Join-Path $OutputDir 'image_groups.md') -Encoding UTF8
    Write-Log "  wrote images.csv and image_groups.md"
}

# ============================================================
# JOB 4: REFERENCE RECONCILIATION
# ============================================================

if (Test-Job 'References') {
    Write-Log "JOB 4: reference reconciliation"

    if (-not (Test-Path -LiteralPath $imagesCsv)) {
        Write-Host "images.csv not found. Run -Job Images first." -ForegroundColor Red
        exit 1
    }
    $Images = Import-Csv -LiteralPath $imagesCsv

    $byLeaf = @{}
    foreach ($im in $Images) {
        $k = $im.filename.ToLower()
        if (-not $byLeaf.ContainsKey($k)) { $byLeaf[$k] = New-Object System.Collections.Generic.List[object] }
        $byLeaf[$k].Add($im)
    }

    $htmlFiles = @($AllFiles | Where-Object { @('.html', '.htm', '.css', '.md') -contains $_.ext })
    $refs = New-Object System.Collections.Generic.List[object]
    $referenced = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)

    $patterns = @(
        '(?i)<img[^>]+src\s*=\s*["'']([^"'']+)["'']',
        '(?i)url\(\s*["'']?([^"''\)]+)["'']?\s*\)',
        '!\[[^\]]*\]\(([^\)\s]+)'
    )

    $k = 0
    foreach ($h in $htmlFiles) {
        $k++
        Write-Progress -Activity "Reference scan" -Status "$k / $($htmlFiles.Count)" -PercentComplete (100 * $k / [math]::Max($htmlFiles.Count, 1))
        try { $lines = Get-Content -LiteralPath $h.path -Encoding UTF8 -ErrorAction Stop } catch { continue }
        $dir = Split-Path $h.path -Parent

        for ($ln = 0; $ln -lt $lines.Count; $ln++) {
            foreach ($p in $patterns) {
                foreach ($m in [regex]::Matches($lines[$ln], $p)) {
                    $src = $m.Groups[1].Value.Trim()
                    if ($src -match '^(https?:|data:|#|mailto:)') { continue }
                    $srcClean = (($src -split '[?#]')[0]) -replace '/', '\'
                    if (-not $srcClean) { continue }

                    $full = $null
                    try { $full = [System.IO.Path]::GetFullPath((Join-Path $dir $srcClean)) } catch { }
                    $exists = ($full -and (Test-Path -LiteralPath $full))
                    if ($exists) { [void]$referenced.Add($full) }

                    $leaf = (Split-Path $srcClean -Leaf).ToLower()
                    $cands = if ($byLeaf.ContainsKey($leaf)) { $byLeaf[$leaf] } else { @() }
                    $candLocs = (@($cands | ForEach-Object { $_.location } | Select-Object -Unique) -join '+')

                    $status = if ($exists) { 'resolved' }
                              elseif (@($cands).Count -ge 1) { 'broken-found-elsewhere' }
                              else { 'broken-nomatch' }

                    $refs.Add([pscustomobject]@{
                        from_file = $h.path; from_loc = $h.location; from_name = (Split-Path $h.path -Leaf)
                        line = $ln + 1; raw_src = $src; resolved = $full; status = $status
                        cand_count = @($cands).Count; cand_locs = $candLocs
                        best_candidate = if (@($cands).Count -ge 1) { (@($cands | Sort-Object { [int]$_.width * [int]$_.height } -Descending)[0]).path } else { '' }
                    })
                }
            }
        }
    }
    Write-Progress -Activity "Reference scan" -Completed
    $refs | Export-Csv -LiteralPath (Join-Path $OutputDir 'references.csv') -NoTypeInformation -Encoding UTF8

    $orphans = @($Images | Where-Object { -not $referenced.Contains($_.path) })
    $repoRefs = @($refs | Where-Object { $_.from_loc -eq 'repo' })

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("# Reference Reconciliation")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("## REPO ONLY (this is the number that matters)")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("| repo file | refs | resolved | missing | recoverable |")
    [void]$sb.AppendLine("|---|---:|---:|---:|---:|")
    foreach ($g in ($repoRefs | Group-Object from_name | Sort-Object Count -Descending)) {
        $ok   = @($g.Group | Where-Object { $_.status -eq 'resolved' }).Count
        $miss = @($g.Group | Where-Object { $_.status -ne 'resolved' }).Count
        $rec  = @($g.Group | Where-Object { $_.status -eq 'broken-found-elsewhere' }).Count
        [void]$sb.AppendLine("| ``$($g.Name)`` | $($g.Count) | $ok | $miss | $rec |")
    }
    [void]$sb.AppendLine()
    $repoMiss = @($repoRefs | Where-Object { $_.status -ne 'resolved' })
    $repoRec  = @($repoRefs | Where-Object { $_.status -eq 'broken-found-elsewhere' })
    [void]$sb.AppendLine("**Repo references total:** $($repoRefs.Count). **Missing:** $($repoMiss.Count). **Recoverable from another root:** $($repoRec.Count).")
    [void]$sb.AppendLine()
    if ($repoRec.Count -gt 0) {
        [void]$sb.AppendLine("Where the missing repo images actually live:")
        [void]$sb.AppendLine()
        [void]$sb.AppendLine("| source root | images needed |")
        [void]$sb.AppendLine("|---|---:|")
        foreach ($g in ($repoRec | Group-Object cand_locs | Sort-Object Count -Descending)) {
            [void]$sb.AppendLine("| $($g.Name) | $($g.Count) |")
        }
        [void]$sb.AppendLine()
    }

    [void]$sb.AppendLine("## Repo missing references, in full")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("| from | line | src | found at |")
    [void]$sb.AppendLine("|---|---:|---|---|")
    foreach ($r in ($repoMiss | Sort-Object from_name, line)) {
        [void]$sb.AppendLine("| ``$($r.from_name)`` | $($r.line) | ``$($r.raw_src)`` | ``$($r.best_candidate)`` |")
    }
    [void]$sb.AppendLine()

    [void]$sb.AppendLine("## All roots, summary")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("| location | resolved | broken-recoverable | broken-nomatch |")
    [void]$sb.AppendLine("|---|---:|---:|---:|")
    foreach ($g in ($refs | Group-Object from_loc | Sort-Object Name)) {
        $a = @($g.Group | Where-Object { $_.status -eq 'resolved' }).Count
        $b = @($g.Group | Where-Object { $_.status -eq 'broken-found-elsewhere' }).Count
        $c2 = @($g.Group | Where-Object { $_.status -eq 'broken-nomatch' }).Count
        [void]$sb.AppendLine("| $($g.Name) | $a | $b | $c2 |")
    }
    [void]$sb.AppendLine()

    foreach ($rt in $Roots) {
        $set = @($orphans | Where-Object { $_.location -eq $rt.Label })
        [void]$sb.AppendLine("## Orphans in [$($rt.Label)] ($($set.Count))")
        [void]$sb.AppendLine()
        [void]$sb.AppendLine("| path | dims | KB |")
        [void]$sb.AppendLine("|---|---|---:|")
        foreach ($o in ($set | Sort-Object path)) {
            [void]$sb.AppendLine("| ``$($o.path)`` | $($o.width)x$($o.height) | $([math]::Round([int64]$o.bytes / 1KB, 0)) |")
        }
        [void]$sb.AppendLine()
    }

    $sb.ToString() | Set-Content -LiteralPath (Join-Path $OutputDir 'references.md') -Encoding UTF8
    Write-Log "  wrote references.md and references.csv"
    Write-Log "  REPO: $($repoRefs.Count) refs, $($repoMiss.Count) missing, $($repoRec.Count) recoverable elsewhere"
}

# ============================================================
# JOB 5: RIGHTS GAP
# ============================================================

if (Test-Job 'Rights') {
    Write-Log "JOB 5: rights scan"

    $kw = 'license|licence|credit|attribution|permission|CC-BY|CC0|public domain|copyright|rights holder|used by permission'
    $textFiles = @($AllFiles | Where-Object { $TextExt -contains $_.ext -and [int64]$_.bytes -lt 10MB })

    $hits = New-Object System.Collections.Generic.List[object]
    foreach ($t in $textFiles) {
        try {
            $found = Select-String -LiteralPath $t.path -Pattern $kw -AllMatches -ErrorAction Stop
            if ($found) {
                $hits.Add([pscustomobject]@{
                    path = $t.path; location = $t.location; ext = $t.ext
                    count = @($found).Count
                    sample = ((@($found | Select-Object -First 3 | ForEach-Object { $_.Line.Trim() }) -join ' // '))
                })
            }
        }
        catch { }
    }

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("# Rights Gap")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("> Free, non-commercial, unpaywalled. LSE_RIGHTS_LEDGER.md is authoritative")
    [void]$sb.AppendLine("> for the nine institutional-permission images.")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("## Files containing rights keywords")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("| file | loc | hits | sample |")
    [void]$sb.AppendLine("|---|---|---:|---|")
    foreach ($h in ($hits | Sort-Object count -Descending | Select-Object -First 80)) {
        $s = $h.sample
        if ($s.Length -gt 140) { $s = $s.Substring(0, 140) + '...' }
        [void]$sb.AppendLine("| ``$($h.path)`` | $($h.location) | $($h.count) | $($s -replace '\|', '\|') |")
    }
    [void]$sb.AppendLine()

    if (Test-Path -LiteralPath $imagesCsv) {
        $Images = Import-Csv -LiteralPath $imagesCsv
        [void]$sb.AppendLine("## Images carrying embedded attribution metadata")
        [void]$sb.AppendLine()
        [void]$sb.AppendLine("| filename | metadata | loc |")
        [void]$sb.AppendLine("|---|---|---|")
        foreach ($im in ($Images | Where-Object { $_.has_exif -eq 'yes' } | Sort-Object filename)) {
            [void]$sb.AppendLine("| ``$($im.filename)`` | $($im.exif_source -replace '\|', '\|') | $($im.location) |")
        }
        [void]$sb.AppendLine()
        $noExif = @($Images | Where-Object { $_.has_exif -ne 'yes' }).Count
        [void]$sb.AppendLine("**Images with no embedded attribution:** $noExif.")
        [void]$sb.AppendLine()
    }

    $sb.ToString() | Set-Content -LiteralPath (Join-Path $OutputDir 'rights_gap.md') -Encoding UTF8
    Write-Log "  wrote rights_gap.md ($($hits.Count) files with rights keywords)"
}

# ============================================================
# JOB 6: CANONICAL DRAFT
# ============================================================

if (Test-Job 'Canonical') {
    Write-Log "JOB 6: canonical draft"

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("# CANONICAL")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("One ruling per contested item. Fill in every ``RULING`` line.")
    [void]$sb.AppendLine("Write the letter of the winner, e.g. ``RULING: A``.")
    [void]$sb.AppendLine("Nothing is deleted. Losers move to ``_ARCHIVE/``.")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("---")
    [void]$sb.AppendLine()

    $ruleCount = 0

    if (Test-Path -LiteralPath $manuCsv) {
        $M = Import-Csv -LiteralPath $manuCsv
        [void]$sb.AppendLine("# Part 1: Manuscript versions")
        [void]$sb.AppendLine()
        foreach ($f in ($M | Group-Object stem | Where-Object { $_.Count -gt 1 } | Sort-Object Count -Descending)) {
            $ruleCount++
            [void]$sb.AppendLine("## $($f.Name)")
            [void]$sb.AppendLine()
            $letter = 65
            foreach ($m in ($f.Group | Sort-Object { [int]$_.words } -Descending)) {
                $star = if ($m.location -eq 'repo') { ' **[IN REPO]**' } else { '' }
                [void]$sb.AppendLine("  **$([char]$letter).**$star ``$($m.path)``")
                [void]$sb.AppendLine("      $($m.words) words | $($m.h2)/$($m.h3) headings | $($m.imgs) images | anchors $($m.anchors_ok) ($($m.anchors_broken) broken) | git=$($m.git_tracked) | $($m.mtime)")
                if ($m.markers) { [void]$sb.AppendLine("      markers: $($m.markers)") }
                [void]$sb.AppendLine()
                $letter++
            }
            $wmin = ($f.Group | Measure-Object words -Minimum).Minimum
            $wmax = ($f.Group | Measure-Object words -Maximum).Maximum
            [void]$sb.AppendLine("Content spread: $($wmax - $wmin) words between best and worst.")
            [void]$sb.AppendLine()
            [void]$sb.AppendLine("RULING: [ ]")
            [void]$sb.AppendLine("REASON:")
            [void]$sb.AppendLine()
            [void]$sb.AppendLine("---")
            [void]$sb.AppendLine()
        }
    }

    if (Test-Path -LiteralPath $imagesCsv) {
        $I = Import-Csv -LiteralPath $imagesCsv
        [void]$sb.AppendLine("# Part 2: Near-duplicate images")
        [void]$sb.AppendLine()
        [void]$sb.AppendLine("Exact duplicates are not listed. They collapse automatically in Phase 1.")
        [void]$sb.AppendLine()
        foreach ($g in ($I | Where-Object { $_.near_group } | Group-Object near_group | Sort-Object Name)) {
            $ruleCount++
            [void]$sb.AppendLine("## $($g.Name)")
            [void]$sb.AppendLine()
            $letter = 65
            foreach ($m in ($g.Group | Sort-Object { [int]$_.width * [int]$_.height } -Descending)) {
                $ex = if ($m.exif_source) { " | metadata: $($m.exif_source)" } else { "" }
                [void]$sb.AppendLine("  **$([char]$letter).** ``$($m.path)``")
                [void]$sb.AppendLine("      [$($m.location)] $($m.width)x$($m.height) | $([math]::Round([int64]$m.bytes / 1KB, 0)) KB$ex")
                $letter++
            }
            [void]$sb.AppendLine()
            [void]$sb.AppendLine("RULING: [ ]")
            [void]$sb.AppendLine()
            [void]$sb.AppendLine("---")
            [void]$sb.AppendLine()
        }
    }

    $sb.ToString() | Set-Content -LiteralPath (Join-Path $OutputDir 'CANONICAL.md') -Encoding UTF8
    Write-Log "  wrote CANONICAL.md ($ruleCount rulings)"
}

# ============================================================
# RUN LOG
# ============================================================

$end = Get-Date
$dur = $end - $script:StartTime
$log = @(
    "# Census Run Log", "",
    "PowerShell: $($PSVersionTable.PSVersion)",
    "Start:      $($script:StartTime.ToString('u'))",
    "End:        $($end.ToString('u'))",
    "Duration:   $([math]::Round($dur.TotalMinutes, 1)) minutes",
    "Output:     $OutputDir",
    "Jobs:       $($Job -join ', ')",
    "Relevance filter: $(if ($NoRelevanceFilter) { 'OFF' } else { 'ON' })",
    "", "## Roots", ""
) + @($Roots | ForEach-Object { "  [$($_.Label)] $($_.Path)" }) + @("", "## Trace", "", '```') + $script:LogLines + @('```')

($log -join "`r`n") | Set-Content -LiteralPath (Join-Path $OutputDir 'RUN_LOG.md') -Encoding UTF8

Write-Host ""
Write-Host "Done in $([math]::Round($dur.TotalMinutes, 1)) minutes. Output in $OutputDir" -ForegroundColor Green
Write-Host ""
