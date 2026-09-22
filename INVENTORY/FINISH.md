# Finish the Living Soil Encyclopedia

Every block is final. Paste each where its heading says.

**Today:** steps 1 to 4
**October 3, 2026**, or sooner if Louws replies: steps 5 to 12

**Still waiting on a reply:**

| Image | Waiting on | If no reply |
|---|---|---|
| `B30_025` tomato Fusarium wilt | Frank Louws, NC State | attribution only |
| `B30_081` strawberry black root rot | Frank Louws, NC State | attribution only |

**Resolved:** `B30_080` basil root rot, permission granted by Jan Byrne, MSU,
2026-09-22. `B30_026` replaced today with a Bugwood image, so UMass no longer
matters. `B30_024` (Bacchi) is removed.

---

## 1. Install the scripts and move the new Bugwood downloads

**Paste into PowerShell.**

```powershell
cd C:\Users\dstor\lse-repo
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$dl = "$env:USERPROFILE\Downloads"

function Get-Newest($pattern, $marker) {
    Get-ChildItem $dl -File -Filter $pattern -ErrorAction SilentlyContinue |
      Where-Object { (Get-Content $_.FullName -Raw -EA SilentlyContinue) -match $marker } |
      Sort-Object LastWriteTime -Descending | Select-Object -First 1
}

$s = Get-Newest "Swap-LseBugwood*"    'BW194941'
$f = Get-Newest "Finalize-Lse*"       'Resolved by Bugwood'
$b = Get-Newest "Build-LseFrontBack*" 'Reproduced with attribution'
$m = Get-Newest "FINISH*"             'Install the scripts'

foreach ($x in @(@{f=$s;d='tools\Swap-LseBugwood.ps1'},
                 @{f=$f;d='tools\Finalize-Lse.ps1'},
                 @{f=$b;d='tools\Build-LseFrontBack.ps1'},
                 @{f=$m;d='INVENTORY\FINISH.md'})) {
    if ($x.f) { Copy-Item $x.f.FullName $x.d -Force; Write-Host "OK    $($x.d)" -ForegroundColor Green }
    if (-not $x.f) { Write-Host "MISS  $($x.d)  download it again" -ForegroundColor Red }
}
Get-ChildItem .\tools\*.ps1 | Unblock-File

Get-ChildItem $dl -File |
  Where-Object { $_.Name -match '1402049|1568003|5458611|194941' } |
  Move-Item -Destination "D:\LSE_ARCHIVE\bugwood_194930" -Force
Write-Host "Bugwood 194941 files moved" -ForegroundColor Green
```

If any line says MISS, download that file and run the block again.

---

## 2. Swap in the damping-off image

**Paste into PowerShell.**

```powershell
cd C:\Users\dstor\lse-repo
.\tools\Swap-LseBugwood.ps1
```

`B30_026` should show as ready, with its current alt text, the new alt text,
and the text that sits with it in the book. The other six show as already
swapped. Then:

```powershell
.\tools\Swap-LseBugwood.ps1 -Execute
git add -A
git commit -m "Swap in Bugwood damping-off image, request 194941"
git push
```

---

## 3. Tell UMass you no longer need their photo

**To:** `jdl@umass.edu`
**Cc:** `tsmith@umext.umass.edu`
**Subject:** `Re: Permission request, pepper damping off photo for a free gardening reference`

```
Hi Jason,

Quick follow-up to my earlier email: I found an alternative damping off
photo through the Bugwood image database, so you don't need to do
anything on my request. Thanks for your time, and sorry for the extra
email.

Damon Smith
```

---

## 4. Log today's changes

**Paste into PowerShell.**

```powershell
cd C:\Users\dstor\lse-repo
@"

## Bugwood Image Request 194941 — APPROVED 2026-09-22

| Image | Bugwood ID | Used | Citation |
|---|---|---|---|
| B30_026 seedling damping off | 1402049 | Yes, replaces UMass photo | R.J. Reynolds Tobacco Company, Bugwood.org |
| (none) Fusarium wilt, whole plant | 1568003 | No. Shows whole-plant wilt; figure needs split stem with vascular browning | Edward Sikora, Auburn University, Bugwood.org |
| (none) basil downy mildew | 5458611 | No. Leaf disease; figure is root rot | Bruce Watt, University of Maine, Bugwood.org |

B30_026 alt text corrected to seedling damping off, Rhizoctonia solani;
the replacement is most likely tobacco, not pepper.

UMass request withdrawn 2026-09-22.

Still pending, kill date 2026-10-03, attribution only if no reply:
B30_025 and B30_081 (Frank Louws, NC State).
"@ | Add-Content LSE_RIGHTS_LEDGER.md -Encoding UTF8
git add -A
git commit -m "Log Bugwood request 194941, withdraw UMass request"
git push
```

---

## 5. Run the finish script (October 3)

MSU already said yes. The only open question is NC State. **Paste one.**

**NC State said yes:**
```powershell
cd C:\Users\dstor\lse-repo
.\tools\Finalize-Lse.ps1 -Approved NCSU,MSU
```

**NC State said no:**
```powershell
cd C:\Users\dstor\lse-repo
.\tools\Finalize-Lse.ps1 -Approved MSU -Declined NCSU
```

**NC State never replied:**
```powershell
cd C:\Users\dstor\lse-repo
.\tools\Finalize-Lse.ps1 -Approved MSU
```

The dry run labels each image **USED BY PERMISSION**, **ATTRIBUTION ONLY**,
or **REMOVE FROM BOOK**. If it reads right, run the same line again with
`-Execute` on the end. That injects the title pages, copyright pages and
credits, and builds all five PDFs.

**If Louws asks for different credit wording:** tell Claude before running.

**If Louws replies after you publish:** run step 5 again with the matching
line, then repeat steps 7, 9 and 10.

---

## 6. Read the five PDFs

**Paste into PowerShell.**

```powershell
cd C:\Users\dstor\lse-repo
Get-ChildItem .\dist\*.pdf | ForEach-Object { Start-Process $_.FullName }
```

In each book check the title page, the copyright page, and the Image Credits
section at the end. In Book 4 check the herbicide, cowpea curculio and damping
off pages, since those images changed.

---

## 7. Commit the finished books

**Paste into PowerShell.**

```powershell
cd C:\Users\dstor\lse-repo
python verify.py
git add -A
git commit -m "v1.0: rights resolved, front matter and credits injected"
git push
```

---

## 8. Archive and clear the old project files

Copies and hash-verifies 2.2 GB of superseded material to `D:\LSE_ARCHIVE`,
then asks you to type `DELETE` before removing the originals.

**Paste into PowerShell.**

```powershell
cd C:\Users\dstor\lse-repo
.\tools\Invoke-LseCensus.ps1 -SourceDir "C:\Users\dstor\OneDrive\Desktop\LSE_FINAL_IMAGE_AND_SPLIT_FIX","C:\Users\dstor\Downloads","C:\Users\dstor\Desktop"
.\tools\Invoke-LseArchive.ps1 -ArchiveRoot "D:\LSE_ARCHIVE" -Execute
.\tools\Invoke-LseArchive.ps1 -ArchiveRoot "D:\LSE_ARCHIVE" -Execute -RemoveSource
```

---

## 9. Update the README and tag the release

**Paste into PowerShell.**

```powershell
cd C:\Users\dstor\lse-repo
$r = Get-Content README.md -Raw
$r = [regex]::Replace($r, '(?s)\*\*Status:\*\*.*?first tagged release\.',
  '**Status:** v1.0 released. Download the five PDFs from the [Releases page](https://github.com/dstorm3691/living-soil-encyclopedia/releases).')
Set-Content README.md -Value $r -Encoding UTF8 -NoNewline
git add README.md
git commit -m "README: v1.0 released"
git tag -a v1.0 -m "The Living Soil Encyclopedia v1.0"
git push
git push origin v1.0
explorer .\dist
```

The last line opens the folder with the five PDFs. Leave it open for step 10.

---

## 10. Create the GitHub release

1. Go to `https://github.com/dstorm3691/living-soil-encyclopedia/releases/new`
2. **Choose a tag:** `v1.0`
3. **Release title:**

```
The Living Soil Encyclopedia v1.0
```

4. **Description:**

```
The first complete edition of The Living Soil Encyclopedia: a five-book
regenerative gardening reference written for North Texas, Zone 8b,
Blackland Prairie clay, alkaline pH, and chloraminated municipal water.

Download the five books below.

1. The Living Soil: soil biology, the soil food web, compost
2. Inputs and Amendments: minerals, inoculants, biochar, brews, soil recipes
3. Crops and Guilds: rotation, companion planting, guild design, herbs
4. Plant Health and Defense: IPM, diagnostics, pest and disease identification
5. The Field Companion: calendars, checklists, protocols, reference cards

Free to read and share. The text and the author's own figures are
licensed CC BY-SA 4.0. Third-party photographs are licensed separately
and credited individually in each book; see the copyright page for what
that means if you reuse this work.

Found an error or a misidentified organism? Open an issue.
```

5. Drag the five PDFs from the open `dist` folder into **Attach binaries**
6. Click **Publish release**

---

## 11. Make the repository public

1. Go to `https://github.com/dstorm3691/living-soil-encyclopedia/settings`
2. Scroll to **Danger Zone**
3. **Change repository visibility**, then **Change to public**
4. Type `dstorm3691/living-soil-encyclopedia` to confirm

---

## 12. Thank-you notes

### Clemson

**Reply on your original HGIC thread, or to:** `HGIC@clemson.edu`
**Subject:** `The okra photo is in, and the book is out`

```
Hi Barbara,

Thanks again for letting me use your okra stink bug photo. The book is
finished and free to download here:

https://github.com/dstorm3691/living-soil-encyclopedia

Your photo is in Book 4, credited the way we agreed. There aren't many
clear photos of that damage out there, and it carries that section.

Thanks,
Damon
```

### Arkansas

**Reply-all on your original UADA thread, which includes Jason Pavel, or to:** `tklass@uada.edu`
**Subject:** `Bacterial wilt photo, and the finished book`

```
Hi Taylor and Jason,

Thanks again for the streaming test photo, and Jason, thanks for
sending the original file. It made a real difference in print.

The book is finished and free to download here:

https://github.com/dstorm3691/living-soil-encyclopedia

Sherrie's photo is in Book 4 with the credit wording you gave me. That
test is the one thing a home grower can do without a lab, and the photo
explains it better than I could in words.

Thanks,
Damon
```

### Maryland

**Reply on Ask Extension thread #0210644**
**Subject:** `Thanks, and the finished book`

```
Hi Miri,

Thanks again for tracking down Jerry and Jon on my behalf. The book is
finished and free to download here:

https://github.com/dstorm3691/living-soil-encyclopedia

All six UMD photos are in, credited by page title and the date I pulled
them, the way we talked about. If you could pass my thanks on to Jerry
and Jon as well, I'd appreciate it.

Thanks,
Damon
```

### NC State, only if they said yes

**To:** `fjlouws@ncsu.edu`
**Subject:** `Thank you, and the finished book`

```
Dr. Louws,

Thank you for letting me use the NC State photos. The book is finished
and free to download here:

https://github.com/dstorm3691/living-soil-encyclopedia

The black root rot comparison and Inga Meadows' Fusarium wilt photo are
both in, credited as agreed. If you could pass my thanks to her as well,
I'd appreciate it.

Thanks,
Damon Smith
```

### MSU

**To:** `byrnejm@msu.edu`
**Subject:** `Thank you, and the finished book`

```
Hi Dr. Byrne,

Thanks for letting me use your basil root rot photo. The book is
finished and free to download here:

https://github.com/dstorm3691/living-soil-encyclopedia

It's in Book 1, credited as agreed.

Thanks,
Damon
```

---

When step 12 is sent, the book is published, credited, backed up, and public.
