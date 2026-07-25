#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
generate_baseline.py — capture the content snapshot the harness verifies against.

Writes two files under baseline/:
  * paragraph_hashes.json — an md5 fingerprint of every normalized <p> of 12+ words
    across the six HTML files (table of contents excluded), plus a human-readable
    preview and the source book(s) for each, used to report a lost paragraph.
  * metrics.json — the per-file tracking baseline (words, images, rights markers,
    orphaned citation markers) that verify.py diffs against for drift.

It imports verify.py so the normalization and extraction logic can never drift from
what the checker uses. Run this ONCE against the pristine, tagged baseline; do not
re-run it after edits unless the owner has approved a new baseline.
"""

import os
import sys
import json

import verify  # single source of truth for normalization / extraction


def build_paragraph_snapshot():
    paragraphs = {}
    for fn in verify.FILES:
        soup = verify.load_soup(fn)
        display = verify.DISPLAY[fn]
        for digest, preview, words in verify.iter_paragraph_records(soup):
            rec = paragraphs.get(digest)
            if rec is None:
                paragraphs[digest] = {
                    "preview": preview,
                    "words": words,
                    "files": [display],
                    "occurrences": 1,
                }
            else:
                rec["occurrences"] += 1
                if display not in rec["files"]:
                    rec["files"].append(display)

    total_kept = sum(r["occurrences"] for r in paragraphs.values())
    return {
        "schema": "lse-paragraph-hashes/1",
        "source_tag": "baseline-five-book-v1",
        "algorithm": "md5",
        "min_words": verify.MIN_PARA_WORDS,
        "normalization": ("get_text(' ', strip=True); lowercase; collapse whitespace; "
                          "strip non-alphanumerics (keep single spaces)"),
        "excluded": "section.toc-section and #table-of-contents",
        "unique_paragraphs": len(paragraphs),
        "total_paragraphs_kept": total_kept,
        "paragraphs": paragraphs,
    }


def build_metrics_snapshot():
    files = {}
    for fn in verify.FILES:
        soup = verify.load_soup(fn)
        files[fn] = verify.file_metrics(soup)
    return {
        "schema": "lse-metrics/1",
        "source_tag": "baseline-five-book-v1",
        "files": files,
    }


def main():
    os.makedirs(verify.BASELINE_DIR, exist_ok=True)

    snapshot = build_paragraph_snapshot()
    with open(verify.PARA_HASHES_PATH, "w", encoding="utf-8") as fh:
        json.dump(snapshot, fh, ensure_ascii=False, indent=1)

    metrics = build_metrics_snapshot()
    with open(verify.METRICS_PATH, "w", encoding="utf-8") as fh:
        json.dump(metrics, fh, ensure_ascii=False, indent=1)

    print("Wrote {}".format(os.path.relpath(verify.PARA_HASHES_PATH, verify.BASE_DIR)))
    print("  unique paragraphs : {}".format(snapshot["unique_paragraphs"]))
    print("  total kept (>= {}w): {}".format(verify.MIN_PARA_WORDS, snapshot["total_paragraphs_kept"]))
    print("Wrote {}".format(os.path.relpath(verify.METRICS_PATH, verify.BASE_DIR)))
    for fn in verify.FILES:
        m = metrics["files"][fn]
        print("  {:<32} words={:>6}  images={:>3}  diamonds={:>3}  orphan[n]={:>4}".format(
            verify.DISPLAY[fn], m["words"], m["images"], m["rights_markers"], m["orphan_citations"]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
