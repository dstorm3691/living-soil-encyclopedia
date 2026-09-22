# Census Run Log

PowerShell: 7.6.6
Start:      2026-09-21 20:30:39Z
End:        2026-09-21 20:30:55Z
Duration:   0.3 minutes
Output:     C:\Users\dstor\lse-repo\INVENTORY
Jobs:       Files, Images, References
Relevance filter: ON

## Roots

  [repo] C:\Users\dstor\lse-repo
  [Downloads] C:\Users\dstor\Downloads

## Trace

```
[20:30:39] PowerShell: 7.6.6
[20:30:39] Output:     C:\Users\dstor\lse-repo\INVENTORY
[20:30:39] Root [repo]: C:\Users\dstor\lse-repo
[20:30:39] Root [Downloads]: C:\Users\dstor\Downloads
[20:30:39] Jobs:       Files, Images, References
[20:30:39] Relevance filter: ON
[20:30:39] JOB 1: file census
[20:30:40]   git-tracked files in repo: 259
[20:30:40]   walking [repo] C:\Users\dstor\lse-repo
[20:30:40]     206 kept, 0 dropped as not-LSE, of 502 seen
[20:30:40]   walking [Downloads] C:\Users\dstor\Downloads
[20:30:41]     363 kept, 673 dropped as not-LSE, of 2075 seen
[20:30:41]   wrote files.csv (569 rows) and excluded_by_relevance.csv (673 rows)
[20:30:41]   wrote files_summary.md
[20:30:41] JOB 3: image census
[20:30:41]   images found: 179
[20:30:42]   exact duplicate groups: 2
[20:30:42]   near-duplicate groups: 0
[20:30:42]   wrote images.csv and image_groups.md
[20:30:42] JOB 4: reference reconciliation
[20:30:55]   wrote references.md and references.csv
[20:30:55]   REPO: 169 refs, 0 missing, 0 recoverable elsewhere
```
