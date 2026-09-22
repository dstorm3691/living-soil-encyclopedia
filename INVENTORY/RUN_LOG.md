# Census Run Log

PowerShell: 7.6.6
Start:      2026-09-21 20:33:51Z
End:        2026-09-21 20:34:06Z
Duration:   0.3 minutes
Output:     C:\Users\dstor\lse-repo\INVENTORY
Jobs:       Files, Images, References
Relevance filter: ON

## Roots

  [repo] C:\Users\dstor\lse-repo
  [Downloads] C:\Users\dstor\Downloads

## Trace

```
[20:33:51] PowerShell: 7.6.6
[20:33:51] Output:     C:\Users\dstor\lse-repo\INVENTORY
[20:33:51] Root [repo]: C:\Users\dstor\lse-repo
[20:33:51] Root [Downloads]: C:\Users\dstor\Downloads
[20:33:51] Jobs:       Files, Images, References
[20:33:51] Relevance filter: ON
[20:33:51] JOB 1: file census
[20:33:51]   git-tracked files in repo: 259
[20:33:51]   walking [repo] C:\Users\dstor\lse-repo
[20:33:51]     207 kept, 0 dropped as not-LSE, of 524 seen
[20:33:51]   walking [Downloads] C:\Users\dstor\Downloads
[20:33:52]     363 kept, 673 dropped as not-LSE, of 2075 seen
[20:33:52]   wrote files.csv (570 rows) and excluded_by_relevance.csv (673 rows)
[20:33:52]   wrote files_summary.md
[20:33:52] JOB 3: image census
[20:33:52]   images found: 180
[20:33:53]   exact duplicate groups: 2
[20:33:54]   near-duplicate groups: 0
[20:33:54]   wrote images.csv and image_groups.md
[20:33:54] JOB 4: reference reconciliation
[20:34:06]   wrote references.md and references.csv
[20:34:06]   REPO: 170 refs, 0 missing, 0 recoverable elsewhere
```
