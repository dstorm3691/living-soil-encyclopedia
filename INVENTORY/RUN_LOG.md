# Census Run Log

PowerShell: 7.6.6
Start:      2026-09-19 16:22:47Z
End:        2026-09-19 16:23:05Z
Duration:   0.3 minutes
Output:     C:\Users\dstor\lse-repo\INVENTORY
Jobs:       Files, Images, References
Relevance filter: ON

## Roots

  [repo] C:\Users\dstor\lse-repo
  [Downloads] C:\Users\dstor\Downloads

## Trace

```
[16:22:47] PowerShell: 7.6.6
[16:22:47] Output:     C:\Users\dstor\lse-repo\INVENTORY
[16:22:47] Root [repo]: C:\Users\dstor\lse-repo
[16:22:47] Root [Downloads]: C:\Users\dstor\Downloads
[16:22:47] Jobs:       Files, Images, References
[16:22:47] Relevance filter: ON
[16:22:47] JOB 1: file census
[16:22:47]   git-tracked files in repo: 258
[16:22:47]   walking [repo] C:\Users\dstor\lse-repo
[16:22:49]     242 kept, 0 dropped as not-LSE, of 540 seen
[16:22:49]   walking [Downloads] C:\Users\dstor\Downloads
[16:22:50]     356 kept, 669 dropped as not-LSE, of 2064 seen
[16:22:50]   wrote files.csv (598 rows) and excluded_by_relevance.csv (669 rows)
[16:22:50]   wrote files_summary.md
[16:22:50] JOB 3: image census
[16:22:50]   images found: 204
[16:22:51]   exact duplicate groups: 8
[16:22:52]   near-duplicate groups: 6
[16:22:52]   wrote images.csv and image_groups.md
[16:22:52] JOB 4: reference reconciliation
[16:23:05]   wrote references.md and references.csv
[16:23:05]   REPO: 643 refs, 321 missing, 177 recoverable elsewhere
```
