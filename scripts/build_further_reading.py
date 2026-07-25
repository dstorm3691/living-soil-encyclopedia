#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Phase B / Task 4 — build per-chapter Further Reading sections.

For each of the 9 owning chapters, insert (at the end of its content-matched anchor
section, immediately before the next heading of equal-or-higher level) a block:

    <p><strong>Further Reading:</strong></p>
    <ul><li>…verbatim citation…</li>…</ul>

- Anchors were matched on CONTENT (paragraph-hash overlap), not title string.
- Entries: publishable only (verified / verified_weak / book_or_unindexed, minus
  owner-held), deduplicated, ordered alphabetically by author, numbering dropped.
- The <p><strong> label mirrors the removed "Key References for This Chapter:" blocks,
  nests correctly under any anchor depth, and adds nothing to the TOC.

    python scripts/build_further_reading.py --samples   # 3 samples + rendered preview
    python scripts/build_further_reading.py --apply      # insert all 9 (minimal-diff)
"""
import os
import re
import sys
import csv
import json
import html
import argparse
import unicodedata

sys.stdout.reconfigure(encoding="utf-8")
REPO = os.getcwd()
sys.path.insert(0, REPO)  # verify.py lives at the repo root
import verify  # for load_soup / DISPLAY / FILES
VERIF = os.path.join(REPO, "references", "verification.json")
HEAD = {"h1": 1, "h2": 2, "h3": 3, "h4": 4, "h5": 5, "h6": 6}

BOOK1 = "LSE_BOOK_1_THE_LIVING_SOIL_WORKING.html"
BOOK5 = "LSE_BOOK_5_FIELD_COMPANION_WORKING.html"

# owning_chapter prefix -> (file, anchor element id).  Matched on content (see recon).
# NOTE (electroculture): the SOURCE "Section 5 — Closing Summary" references map by
# content into Book 5's Chapter 2. That chapter's section order is scrambled (a
# duplicate "What We Know" h4 sits mid-Section-2, and the real "Section 5 — Closing
# Summary" h3 is followed by yet more sections), so per owner decision the list is
# anchored at the CHAPTER and placed at the chapter's end. Heading order flagged for Phase E.
ANCHORS = [
    ("Chapter 1.",  BOOK1, "h2-chapter-1-from-salts-to-symbiosis-why-living-soil-outperforms-liquid-feeding"),
    ("Chapter 2.",  BOOK1, "h2-chapter-2-the-soil-food-web-a-functional-map"),
    ("Chapter 6.",  BOOK1, "h2-chapter-6-mycorrhizal-symbiosis-and-plant-immune-function"),
    ("Chapter 8.",  BOOK1, "h2-chapter-8-regenerative-and-permaculture-foundations"),
    ("Chapter 9.",  BOOK1, "h2-chapter-9-the-soil-food-web-dr-elaine-ingham"),
    ("Chapter 10.", BOOK1, "h2-chapter-10-coots-mix-clackamas-coot"),
    ("Chapter 11.", BOOK1, "h2-chapter-11-bionutrient-farming-john-kempf-dan-kittredge"),
    ("Chapter 12.", BOOK1, "h2-chapter-12-survey-of-knf-jadam-and-biodynamics"),
    ("Section 5",   BOOK5, "h2-chapter-18-electroculture-and-plant-electrophysiology"),
]

# Owner-approved field completion from the authenticating CrossRef record (the DOI
# resolved with matching author + year). This is the ONE entry where a field was filled;
# recorded in the exception report.
FIELD_FILLS = {
    "volume_1-b1-n1": {
        "title": "Influence of synthetic fertilizers and pesticides on soil health and soil microbiology",
    },
}


def fold(s):
    d = unicodedata.normalize("NFKD", s or "")
    return re.sub(r"[^a-z]", "", "".join(c for c in d if not unicodedata.combining(c)).casefold())


def sort_key(entry):
    """Alphabetical by first-author surname (folded), then by full raw."""
    a = entry.get("source_author") or entry["raw"]
    surname = a.split(",")[0].strip().split()[0] if a.split(",")[0].strip().split() else a
    return (fold(surname), fold(entry["raw"]))


def dedup_key(raw):
    raw = re.sub(r"\[[^\]]*\]\s*$", "", raw)   # drop trailing [annotation]
    return re.sub(r"\s+", " ", re.sub(r"[^a-z0-9 ]", " ", raw.lower())).strip()


def work_key(entry):
    """Identify the same work across chapters (author surname + year + title stem)."""
    a = (entry.get("source_author") or "").split(",")[0].strip().split()
    surname = a[0] if a else ""
    stem = (entry.get("source_title") or entry["raw"])[:40]
    return (fold(surname), entry.get("source_year"), fold(stem))


def normalize_doi(raw, doi):
    """Normalize a DOI reference to the single 'https://doi.org/<doi>' form (fix 3)."""
    if not doi:
        return raw
    pat = r"(?:https?://(?:dx\.)?doi\.org/|DOI:\s*)" + re.escape(doi) + r"\.?"
    return re.sub(pat, "https://doi.org/" + doi, raw, flags=re.I)


def rendered_raw(entry):
    """Apply owner-approved field fill (Tripathi) then DOI normalization to the raw."""
    raw = entry["raw"]
    fill = FIELD_FILLS.get(entry["id"])
    if fill and fill.get("title"):
        raw = re.sub(r"(\(\d{4}\)\.)\s*", r"\1 " + fill["title"] + ". ", raw, count=1)
    return normalize_doi(raw, entry.get("source_doi"))


def load_publishable():
    data = json.load(open(VERIF, encoding="utf-8"))
    return [r for r in data["results"] if r.get("publishable")]


def build_canonical(pub):
    """Fix 4: one canonical (fullest) rendering per work — prefer a DOI, then longer text.
    Returns (canon_by_key, unified_report)."""
    best = {}
    for e in pub:
        k = work_key(e)
        rr = rendered_raw(e)
        score = (1 if e.get("source_doi") else 0, len(rr))
        cur = best.get(k)
        if cur is None or score > cur[0]:
            best[k] = (score, rr, e)
    canon = {k: v[1] for k, v in best.items()}
    # report works that appeared in >1 chapter with >1 distinct rendering
    unified = []
    by_key = {}
    for e in pub:
        by_key.setdefault(work_key(e), []).append(e)
    for k, rows in by_key.items():
        chapters = {r["owning_chapter"] for r in rows}
        renders = {rendered_raw(r) for r in rows}
        if len(chapters) > 1 and len(renders) > 1:
            src = best[k][2]
            unified.append({"work": "{} {}".format(k[0], k[1]), "canonical": canon[k],
                            "from_chapter": src["owning_chapter"],
                            "chapters": sorted(chapters)})
    return canon, unified


def publishable_by_chapter():
    pub = load_publishable()
    canon, _unified = build_canonical(pub)
    groups = {}
    for e in pub:
        groups.setdefault(e["owning_chapter"], []).append((e, canon[work_key(e)]))
    out = {}
    for ch, items in groups.items():
        seen = {}
        for e, rr in items:
            seen.setdefault(dedup_key(rr), (e, rr))
        rows = sorted(seen.values(), key=lambda er: sort_key(er[0]))
        out[ch] = [rr for _e, rr in rows]
    return out


def anchor_for(owning_chapter):
    for prefix, fname, aid in ANCHORS:
        if owning_chapter.startswith(prefix):
            return fname, aid
    return None, None


def build_block_html(raws, indent=""):
    """The exact HTML to insert (verbatim citations, escaped, no numbering)."""
    lines = [indent + "<p><strong>Further Reading:</strong></p>", indent + "<ul>"]
    for raw in raws:
        lines.append("{}<li>{}</li>".format(indent, html.escape(raw, quote=False)))
    lines.append(indent + "</ul>")
    return "\n".join(lines)


def next_boundary(soup, anchor_id):
    """The heading element (equal-or-higher level) that ends the anchor's section,
    or None if the section runs to the end of its container."""
    start = soup.find(id=anchor_id)
    lvl = HEAD.get(start.name, 99)
    for sib in start.next_siblings:
        if getattr(sib, "name", None) in HEAD and HEAD[sib.name] <= lvl:
            return start, sib
    return start, None


# --------------------------------------------------------------------------- #
# Samples + rendered preview
# --------------------------------------------------------------------------- #

SAMPLE_CHAPTERS = [
    "Chapter 1.",   # h3 anchor
    "Chapter 6.",   # h2 anchor
    "Section 5",    # h4 anchor
]


def render_samples(by_chapter):
    # Report the applied transforms (fixes 2 and 4) up front.
    pub = load_publishable()
    _canon, unified = build_canonical(pub)
    print("TRANSFORMS APPLIED")
    print("  Fix 2 — field fill: {} (title from resolved CrossRef record)".format(
        ", ".join(FIELD_FILLS.keys())))
    print("  Fix 4 — unified same-work-different-detail (fuller rendering used in all):")
    for u in unified:
        print("     {} -> canonical from {} (appears in {})".format(
            u["work"], u["from_chapter"][:14], "; ".join(c[:14] for c in u["chapters"])))
    print()

    css = open(os.path.join(REPO, "lse_five_book_working.css"), encoding="utf-8").read()
    preview_sections = []
    for ch, raws in by_chapter.items():
        prefix = next((p for p in SAMPLE_CHAPTERS if ch.startswith(p)), None)
        if not prefix:
            continue
        fname, aid = anchor_for(ch)
        soup = verify.load_soup(fname)
        start, boundary = next_boundary(soup, aid)
        block = build_block_html(raws)
        # Console output
        print("=" * 74)
        print("ANCHOR: {} <{}> id={}".format(verify.DISPLAY[fname], start.name, aid))
        print("  heading: {!r}".format(start.get_text(" ", strip=True)))
        print("  insert BEFORE: {}".format(
            "<{}> {!r}".format(boundary.name, boundary.get_text(" ", strip=True)[:50])
            if boundary is not None else "[end of container]"))
        print("  entries: {}".format(len(raws)))
        print("-" * 74)
        print(block)
        print()
        # Build a rendered preview: anchor heading + its section + FR block + boundary heading.
        # Cap long sections (e.g. the whole electroculture chapter) to keep the preview small.
        section = []
        for sib in start.next_siblings:
            if sib is boundary:
                break
            if getattr(sib, "name", None) is not None:
                section.append(str(sib))
        if len(section) > 12:
            section = (section[:3] +
                       ["<p style='color:#b00'>[… {} elements omitted …]</p>".format(len(section) - 9)] +
                       section[-6:])
        ctx = [str(start)] + section + [block]
        if boundary is not None:
            ctx.append(str(boundary))
        preview_sections.append(
            "<div style='margin:2em 0;padding:1em;border:2px dashed #999'>"
            "<p style='color:#999;font-size:9pt'>PREVIEW — {} · anchor &lt;{}&gt;</p>{}</div>"
            .format(verify.DISPLAY[fname], start.name, "\n".join(ctx)))

    preview = ("<!DOCTYPE html><html><head><meta charset='utf-8'><style>\n" + css +
               "\n</style></head><body class='book-body'>\n" +
               "\n".join(preview_sections) + "\n</body></html>")
    out = os.path.join(REPO, "references", "further_reading_preview.html")
    with open(out, "w", encoding="utf-8") as fh:
        fh.write(preview)
    print("Wrote rendered preview: {}".format(os.path.relpath(out, REPO)))


def apply_all(by_chapter):
    """Minimal-diff insertion: place each FR block in the raw file immediately before
    its boundary heading's opening tag (located by the boundary's unique id)."""
    per_file = {}
    for ch, raws in by_chapter.items():
        fname, aid = anchor_for(ch)
        if not fname:
            continue
        soup = verify.load_soup(fname)
        start, boundary = next_boundary(soup, aid)
        if boundary is None or not boundary.get("id"):
            raise SystemExit("No id-bearing boundary heading for anchor {} ({})".format(aid, ch))
        per_file.setdefault(fname, []).append((ch, boundary.name, boundary["id"], raws))

    total = 0
    for fname, items in per_file.items():
        raw = open(os.path.join(REPO, fname), encoding="utf-8").read()
        for ch, bname, bid, raws in items:
            block = build_block_html(raws) + "\n"
            m = re.search(r"<" + bname + r"\b[^>]*id=\"" + re.escape(bid) + r"\"", raw)
            if not m:
                raise SystemExit("Boundary tag not found in raw: {} {}".format(bname, bid))
            raw = raw[:m.start()] + block + raw[m.start():]
            total += 1
            print("  inserted {} refs into {} before <{}> id={}".format(
                len(raws), verify.DISPLAY[fname], bname, bid))
        with open(os.path.join(REPO, fname), "w", encoding="utf-8", newline="") as fh:
            fh.write(raw)
    print("Applied {} Further Reading sections.".format(total))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--samples", action="store_true")
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()

    by_chapter = publishable_by_chapter()
    if args.apply:
        apply_all(by_chapter)
    else:
        render_samples(by_chapter)


if __name__ == "__main__":
    main()
