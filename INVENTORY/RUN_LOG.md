# Census Run Log

PowerShell: 7.6.6
Start:      2026-09-21 20:12:45Z
End:        2026-09-21 20:13:01Z
Duration:   0.3 minutes
Output:     C:\Users\dstor\lse-repo\INVENTORY
Jobs:       Files, Images, References
Relevance filter: ON

## Roots

  [repo] C:\Users\dstor\lse-repo
  [Downloads] C:\Users\dstor\Downloads

## Trace

```
[20:12:45] PowerShell: 7.6.6
[20:12:45] Output:     C:\Users\dstor\lse-repo\INVENTORY
[20:12:45] Root [repo]: C:\Users\dstor\lse-repo
[20:12:45] Root [Downloads]: C:\Users\dstor\Downloads
[20:12:45] Jobs:       Files, Images, References
[20:12:45] Relevance filter: ON
[20:12:45] JOB 1: file census
[20:12:45]   git-tracked files in repo: 258
[20:12:45]   walking [repo] C:\Users\dstor\lse-repo
[20:12:46]     207 kept, 0 dropped as not-LSE, of 448 seen
[20:12:46]   walking [Downloads] C:\Users\dstor\Downloads
[20:12:46]     362 kept, 673 dropped as not-LSE, of 2074 seen
[20:12:46]   wrote files.csv (569 rows) and excluded_by_relevance.csv (673 rows)
[20:12:46]   wrote files_summary.md
[20:12:46] JOB 3: image census
[20:12:46]   images found: 180
[20:12:48]   exact duplicate groups: 2
[20:12:48]   near-duplicate groups: 0
[20:12:48]   wrote images.csv and image_groups.md
[20:12:48] JOB 4: reference reconciliation
[20:13:01]   wrote references.md and references.csv
[20:13:01]   REPO: 170 refs, 0 missing, 0 recoverable elsewhere
```
