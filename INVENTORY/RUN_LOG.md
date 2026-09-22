# Census Run Log

PowerShell: 7.6.6
Start:      2026-09-21 20:11:46Z
End:        2026-09-21 20:12:05Z
Duration:   0.3 minutes
Output:     C:\Users\dstor\lse-repo\INVENTORY
Jobs:       Files, Images, References
Relevance filter: ON

## Roots

  [repo] C:\Users\dstor\lse-repo
  [Downloads] C:\Users\dstor\Downloads

## Trace

```
[20:11:46] PowerShell: 7.6.6
[20:11:46] Output:     C:\Users\dstor\lse-repo\INVENTORY
[20:11:46] Root [repo]: C:\Users\dstor\lse-repo
[20:11:46] Root [Downloads]: C:\Users\dstor\Downloads
[20:11:46] Jobs:       Files, Images, References
[20:11:46] Relevance filter: ON
[20:11:46] JOB 1: file census
[20:11:46]   git-tracked files in repo: 258
[20:11:46]   walking [repo] C:\Users\dstor\lse-repo
[20:11:47]     207 kept, 0 dropped as not-LSE, of 436 seen
[20:11:47]   walking [Downloads] C:\Users\dstor\Downloads
[20:11:51]     362 kept, 673 dropped as not-LSE, of 2074 seen
[20:11:51]   wrote files.csv (569 rows) and excluded_by_relevance.csv (673 rows)
[20:11:51]   wrote files_summary.md
[20:11:51] JOB 3: image census
[20:11:51]   images found: 180
[20:11:53]   exact duplicate groups: 2
[20:11:53]   near-duplicate groups: 0
[20:11:53]   wrote images.csv and image_groups.md
[20:11:53] JOB 4: reference reconciliation
[20:12:05]   wrote references.md and references.csv
[20:12:05]   REPO: 170 refs, 0 missing, 0 recoverable elsewhere
```
