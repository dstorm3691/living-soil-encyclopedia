# Census Run Log

PowerShell: 7.6.6
Start:      2026-09-29 17:25:32Z
End:        2026-09-29 17:25:52Z
Duration:   0.3 minutes
Output:     C:\Users\dstor\lse-repo\INVENTORY
Jobs:       Files, Images, References
Relevance filter: ON

## Roots

  [repo] C:\Users\dstor\lse-repo
  [Downloads] C:\Users\dstor\Downloads

## Trace

```
[17:25:32] PowerShell: 7.6.6
[17:25:32] Output:     C:\Users\dstor\lse-repo\INVENTORY
[17:25:32] Root [repo]: C:\Users\dstor\lse-repo
[17:25:32] Root [Downloads]: C:\Users\dstor\Downloads
[17:25:32] Jobs:       Files, Images, References
[17:25:32] Relevance filter: ON
[17:25:32] JOB 1: file census
[17:25:32]   git-tracked files in repo: 262
[17:25:32]   walking [repo] C:\Users\dstor\lse-repo
[17:25:33]     206 kept, 0 dropped as not-LSE, of 593 seen
[17:25:33]   walking [Downloads] C:\Users\dstor\Downloads
[17:25:37]     370 kept, 676 dropped as not-LSE, of 2086 seen
[17:25:37]   wrote files.csv (576 rows) and excluded_by_relevance.csv (676 rows)
[17:25:37]   wrote files_summary.md
[17:25:37] JOB 3: image census
[17:25:37]   images found: 179
[17:25:39]   exact duplicate groups: 2
[17:25:39]   near-duplicate groups: 0
[17:25:39]   wrote images.csv and image_groups.md
[17:25:39] JOB 4: reference reconciliation
[17:25:52]   wrote references.md and references.csv
[17:25:52]   REPO: 169 refs, 0 missing, 0 recoverable elsewhere
```
