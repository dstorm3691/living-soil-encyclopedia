#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Phase B / Task 1 — extract "Key References for This Chapter" blocks from the two
read-only SOURCE volumes into references/extracted.json.

PARSE ONLY. This never corrects, completes, or enriches an entry; `raw` is the
verbatim citation string and the parsed author/year/title/doi fields are best-effort
conveniences left null when not cleanly determinable. Run from the repo root:

    python scripts/extract_references.py

Expected: 98 entries across 9 blocks. Handles both markup formats found in the
sources: `[n]: # "citation"` (quoted) and `[n] citation <em>journal</em>.` (plain).
"""
import os
import re
import sys
import json

sys.stdout.reconfigure(encoding="utf-8")
from bs4 import BeautifulSoup

REPO = os.getcwd()
SOURCES = [
    ("LSE_VOLUME_1_FOUNDATIONS_SYSTEMS_SOURCE.html", "VOLUME_1"),
    ("LSE_VOLUME_3_CROPS_IPM_DIAGNOSTICS_SOURCE.html", "VOLUME_3"),
]
HEAD = {"h1": 1, "h2": 2, "h3": 3, "h4": 4, "h5": 5, "h6": 6}
DOI_RE = re.compile(r"10\.\d{4,9}/[^\s\"'<>]+")
YEAR_RE = re.compile(r"\((\d{4})[a-z]?\)")


def nearest_chapter(node):
    """Nearest preceding heading of level <= 2 (the owning chapter)."""
    for prev in node.find_all_previous():
        if getattr(prev, "name", None) in HEAD and HEAD[prev.name] <= 2:
            return prev.get_text(" ", strip=True)
    return None


def clean_ws(t):
    t = re.sub(r"\s+", " ", t).strip()
    t = re.sub(r"\s+([.,;:])", r"\1", t)   # tidy spaces left before punctuation by tag flattening
    return t


def parse_fields(text):
    """Best-effort author/year/title/doi. Null when not cleanly determinable."""
    doi_m = DOI_RE.search(text)
    doi = doi_m.group(0).rstrip(".") if doi_m else None

    year_m = YEAR_RE.search(text)
    year = year_m.group(1) if year_m else None

    author = title = None
    if year_m:
        author = clean_ws(text[:year_m.start()]).rstrip(" .,") or None
        after = text[year_m.end():].lstrip(" .")
        if after:
            after = re.sub(r"\[[^\]]*\]\s*$", "", after).strip()  # drop trailing [annotation]
            m = re.match(r"(.+?\.)(\s|$)", after)
            title = clean_ws(m.group(1)).rstrip(".") if m else None
    return author, year, title, doi


def extract_entry(line):
    """`line` is the inner HTML of one entry. Returns (number, format, raw) or (None,...)."""
    num_m = re.match(r"\s*\[(\d+)\]", line)
    if not num_m:
        return None, None, None
    num = int(num_m.group(1))
    rest = line[num_m.end():]
    q = re.match(r'\s*:\s*#\s*"(.*)"\s*$', rest, re.S)   # format 1: : # "..."
    if q:
        fmt, inner_html = "quoted", q.group(1)
    else:
        fmt, inner_html = "plain", rest
    raw = clean_ws(BeautifulSoup(inner_html, "html.parser").get_text(" ", strip=True))
    return num, fmt, raw


def main():
    entries, blocks = [], []
    for fname, vol in SOURCES:
        soup = BeautifulSoup(open(os.path.join(REPO, fname), encoding="utf-8").read(), "html.parser")
        for bi, host in enumerate(soup.find_all(string=re.compile("Key References for This Chapter")), 1):
            p = host.find_parent("p")
            chapter = nearest_chapter(p)
            inner = re.sub(r"^\s*<strong>.*?</strong>", "", p.decode_contents(), count=1, flags=re.S)
            block_entries = []
            for ln in (l for l in inner.split("\n") if l.strip()):
                num, fmt, raw = extract_entry(ln)
                if num is None:
                    continue
                author, year, title, doi = parse_fields(raw)
                block_entries.append({
                    "id": "{}-b{}-n{}".format(vol.lower(), bi, num),
                    "source_file": fname,
                    "source_volume": vol,
                    "owning_chapter": chapter,
                    "original_number": num,
                    "format": fmt,
                    "raw": raw,
                    "author": author,
                    "year": year,
                    "title": title,
                    "doi": doi,
                })
            entries.extend(block_entries)
            blocks.append({"volume": vol, "chapter": chapter, "count": len(block_entries)})

    out = {
        "schema": "lse-extracted-references/1",
        "note": "Parsed verbatim from SOURCE files. No correction/completion/enrichment.",
        "total_entries": len(entries),
        "blocks": blocks,
        "entries": entries,
    }
    os.makedirs(os.path.join(REPO, "references"), exist_ok=True)
    with open(os.path.join(REPO, "references", "extracted.json"), "w", encoding="utf-8") as fh:
        json.dump(out, fh, ensure_ascii=False, indent=1)

    print("TOTAL entries:", len(entries), "across", len(blocks), "blocks")
    for b in blocks:
        print("  {:9} {:3} | {}".format(b["volume"], b["count"], b["chapter"]))


if __name__ == "__main__":
    main()
