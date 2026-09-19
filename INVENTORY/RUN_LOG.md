# Census Run Log

PowerShell: 7.6.6
Start:      2026-09-19 15:10:10Z
End:        2026-09-19 15:11:30Z
Duration:   1.3 minutes
Output:     C:\Users\dstor\lse-repo\INVENTORY
Jobs:       All
Relevance filter: ON

## Roots

  [repo] C:\Users\dstor\lse-repo
  [LSE_FINAL_IMAGE_AND_SPLIT_FIX] C:\Users\dstor\OneDrive\Desktop\LSE_FINAL_IMAGE_AND_SPLIT_FIX
  [Downloads] C:\Users\dstor\Downloads
  [Desktop] C:\Users\dstor\Desktop

## Trace

```
[15:10:10] PowerShell: 7.6.6
[15:10:10] Output:     C:\Users\dstor\lse-repo\INVENTORY
[15:10:10] Root [repo]: C:\Users\dstor\lse-repo
[15:10:10] Root [LSE_FINAL_IMAGE_AND_SPLIT_FIX]: C:\Users\dstor\OneDrive\Desktop\LSE_FINAL_IMAGE_AND_SPLIT_FIX
[15:10:10] Root [Downloads]: C:\Users\dstor\Downloads
[15:10:10] Root [Desktop]: C:\Users\dstor\Desktop
[15:10:10] Jobs:       All
[15:10:10] Relevance filter: ON
[15:10:10] JOB 1: file census
[15:10:10]   git-tracked files in repo: 34
[15:10:10]   walking [repo] C:\Users\dstor\lse-repo
[15:10:11]     203 kept, 0 dropped as not-LSE, of 245 seen
[15:10:11]   walking [LSE_FINAL_IMAGE_AND_SPLIT_FIX] C:\Users\dstor\OneDrive\Desktop\LSE_FINAL_IMAGE_AND_SPLIT_FIX
[15:10:23]     1065 kept, 0 dropped as not-LSE, of 1472 seen
[15:10:23]   walking [Downloads] C:\Users\dstor\Downloads
[15:10:24]     349 kept, 668 dropped as not-LSE, of 2056 seen
[15:10:24]   walking [Desktop] C:\Users\dstor\Desktop
[15:10:25]     15 kept, 62 dropped as not-LSE, of 110 seen
[15:10:25]   wrote files.csv (1632 rows) and excluded_by_relevance.csv (730 rows)
[15:10:25]   wrote files_summary.md
[15:10:25] JOB 2: manuscript fingerprinting
[15:10:25]   candidates: 161
[15:10:38]   wrote manuscripts.md and manuscripts.csv (161 candidates, 28 contested)
[15:10:38] JOB 3: image census
[15:10:38]   images found: 908
[15:10:59]   exact duplicate groups: 271
[15:11:01]   near-duplicate groups: 10
[15:11:01]   wrote images.csv and image_groups.md
[15:11:01] JOB 4: reference reconciliation
[15:11:24]   wrote references.md and references.csv
[15:11:24]   REPO: 322 refs, 0 missing, 0 recoverable elsewhere
[15:11:24] JOB 5: rights scan
[15:11:30]   wrote rights_gap.md (247 files with rights keywords)
[15:11:30] JOB 6: canonical draft
[15:11:30]   wrote CANONICAL.md (38 rulings)
```
