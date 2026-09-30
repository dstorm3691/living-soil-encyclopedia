<#
.SYNOPSIS
  Counts production text that reached the built PDFs. Every column should be 0.

.EXAMPLE
  .\tools\Test-LsePdfLeaks.ps1
#>
param([string]$Repo = (Split-Path $PSScriptRoot -Parent))

$gs = Get-ChildItem 'C:\Program Files\gs\*\bin\gswin64c.exe' -EA SilentlyContinue |
      Sort-Object FullName -Descending | Select-Object -First 1 -ExpandProperty FullName
if (-not $gs) { Write-Host "Ghostscript not found." -ForegroundColor Red; exit 1 }

$checks = [ordered]@{
    'anchors'  = 'provisional anchor'
    'mirror'   = 'Synchronized mirror'
    'figIDs'   = 'Figure (LSE_|B30_|UC-|UCI_)'
    'briefs'   = 'Field photo brief'
    'IMAGE'    = '\[IMAGE'
    'placement'= 'Placement:'
    'TODO'     = '\bTODO\b'
    'diamond'  = '◆'
}

$rows = foreach ($pdf in (Get-ChildItem (Join-Path $Repo 'dist') -Filter 'LSE_Book_*.pdf' | Sort-Object Name)) {
    $txt = (& $gs -q -dNOPAUSE -dBATCH -sDEVICE=txtwrite -o - $pdf.FullName) -join "`n"
    $o = [ordered]@{ Book = $pdf.BaseName -replace '^LSE_Book_(\d).*', 'Book $1' }
    foreach ($k in $checks.Keys) { $o[$k] = ([regex]::Matches($txt, $checks[$k])).Count }
    [pscustomobject]$o
}
$rows | Format-Table -AutoSize

$bad = 0
foreach ($r in $rows) { foreach ($k in $checks.Keys) { $bad += $r.$k } }
if ($bad) { Write-Host "LEAKS: $bad" -ForegroundColor Red; exit 1 }
Write-Host "Clean: no production text in the PDFs." -ForegroundColor Green
