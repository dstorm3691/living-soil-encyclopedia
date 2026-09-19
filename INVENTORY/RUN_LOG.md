# Census Run Log

PowerShell: 7.6.6
Start:      2026-09-19 18:17:47Z
End:        2026-09-19 18:18:02Z
Duration:   0.3 minutes
Output:     C:\Users\dstor\lse-repo\INVENTORY
Jobs:       Files, Images, References
Relevance filter: ON

## Roots

  [repo] C:\Users\dstor\lse-repo
  [Downloads] C:\Users\dstor\Downloads

## Trace

```
[18:17:47] PowerShell: 7.6.6
[18:17:47] Output:     C:\Users\dstor\lse-repo\INVENTORY
[18:17:47] Root [repo]: C:\Users\dstor\lse-repo
[18:17:47] Root [Downloads]: C:\Users\dstor\Downloads
[18:17:47] Jobs:       Files, Images, References
[18:17:47] Relevance filter: ON
[18:17:47] JOB 1: file census
[18:17:47]   git-tracked files in repo: 255
[18:17:47]   walking [repo] C:\Users\dstor\lse-repo
[18:17:48]     207 kept, 0 dropped as not-LSE, of 389 seen
[18:17:48]   walking [Downloads] C:\Users\dstor\Downloads
[18:17:48]     360 kept, 673 dropped as not-LSE, of 2072 seen
[18:17:48]   wrote files.csv (567 rows) and excluded_by_relevance.csv (673 rows)
[18:17:48]   wrote files_summary.md
[18:17:48] JOB 3: image census
[18:17:48]   images found: 180
[18:17:50]   exact duplicate groups: 2
[18:17:50]   near-duplicate groups: 0
[18:17:50]   wrote images.csv and image_groups.md
[18:17:50] JOB 4: reference reconciliation
[18:18:02]   wrote references.md and references.csv
[18:18:02]   REPO: 170 refs, 0 missing, 0 recoverable elsewhere
```
