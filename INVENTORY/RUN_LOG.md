# Census Run Log

PowerShell: 7.6.6
Start:      2026-09-19 18:10:21Z
End:        2026-09-19 18:10:37Z
Duration:   0.3 minutes
Output:     C:\Users\dstor\lse-repo\INVENTORY
Jobs:       Files, Images, References
Relevance filter: ON

## Roots

  [repo] C:\Users\dstor\lse-repo
  [Downloads] C:\Users\dstor\Downloads

## Trace

```
[18:10:21] PowerShell: 7.6.6
[18:10:21] Output:     C:\Users\dstor\lse-repo\INVENTORY
[18:10:21] Root [repo]: C:\Users\dstor\lse-repo
[18:10:21] Root [Downloads]: C:\Users\dstor\Downloads
[18:10:21] Jobs:       Files, Images, References
[18:10:21] Relevance filter: ON
[18:10:21] JOB 1: file census
[18:10:21]   git-tracked files in repo: 255
[18:10:21]   walking [repo] C:\Users\dstor\lse-repo
[18:10:22]     207 kept, 0 dropped as not-LSE, of 363 seen
[18:10:22]   walking [Downloads] C:\Users\dstor\Downloads
[18:10:23]     360 kept, 672 dropped as not-LSE, of 2071 seen
[18:10:23]   wrote files.csv (567 rows) and excluded_by_relevance.csv (672 rows)
[18:10:23]   wrote files_summary.md
[18:10:23] JOB 3: image census
[18:10:23]   images found: 180
[18:10:24]   exact duplicate groups: 2
[18:10:24]   near-duplicate groups: 0
[18:10:24]   wrote images.csv and image_groups.md
[18:10:24] JOB 4: reference reconciliation
[18:10:37]   wrote references.md and references.csv
[18:10:37]   REPO: 170 refs, 0 missing, 0 recoverable elsewhere
```
