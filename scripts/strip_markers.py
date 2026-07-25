#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Phase B / Task 3 — strip orphaned [n] citation markers from Book 1 and Book 5.

BeautifulSoup is used for STRUCTURE (owning headings, sentence context, mirror-safety
analysis); regex is used ONLY for the marker pattern itself, which is the explicit
Task-3 exception to CLAUDE.md rule 5. Removal is applied to the raw file as a targeted
substitution of marker runs (plus their orphaned spaces) — the file is NOT re-serialized,
so only marker sites change and the diff stays minimal and reviewable.

    python scripts/strip_markers.py           # dry-run: analyze + report, no changes
    python scripts/strip_markers.py --apply    # strip markers + write the removal log

Expected: 106 markers in Book 1, 19 in Book 5 (125 total), all values 1-14.
"""
import os
import re
import sys
import csv
import argparse

sys.stdout.reconfigure(encoding="utf-8")
from bs4 import BeautifulSoup, NavigableString

REPO = os.getcwd()
TARGETS = [
    ("LSE_BOOK_1_THE_LIVING_SOIL_WORKING.html", "BOOK_1", 109),  # 106 single + 3 multi
    ("LSE_BOOK_5_FIELD_COMPANION_WORKING.html", "BOOK_5", 19),
]
LEDGER = "LSE_MIRROR_SYNCHRONIZATION_LEDGER.csv"
LOG_PATH = os.path.join(REPO, "references", "marker_removal_log.md")

# A citation marker: a single number OR a comma-list / range of numbers in brackets:
#   [4]  [12]  [4,5]  [12,13]  [4-6]  [4–6]  [4—6]
_MARK = r"\[\d{1,3}(?:[ \t]*[,–—-][ \t]*\d{1,3})*\]"
MARKER_RE = re.compile(_MARK)
# A run of one or more markers, possibly space/tab-separated, with adjacent spaces/tabs.
RUN_RE = re.compile(r"[ \t]*(?:" + _MARK + r"[ \t]*)+")
HEAD = {"h1", "h2", "h3", "h4", "h5", "h6"}
HEADING_LEVEL = {"h1": 1, "h2": 2, "h3": 3, "h4": 4, "h5": 5, "h6": 6}

# After removing a marker run, join the two sides with a single space UNLESS the char
# now adjacent is a no-space context (sentence punctuation / closing bracket / tag-open,
# or an opening bracket on the left), in which case join with nothing.
NO_SPACE_AFTER = set(".,;:!?)]}»”’") | {"<"}
NO_SPACE_BEFORE = set("([{«“‘")


# --------------------------------------------------------------------------- #
# Structure helpers (BeautifulSoup)
# --------------------------------------------------------------------------- #

def owning_heading(node):
    for prev in node.find_all_previous():
        if getattr(prev, "name", None) in HEAD:
            return prev.name, prev.get_text(" ", strip=True), prev.get("id")
    return None, None, None


def in_toc(node):
    return node.find_parent(
        lambda t: (t.name == "section" and t.get("class") and "toc-section" in t.get("class"))
        or t.get("id") == "table-of-contents"
    ) is not None


def block_ancestor(node):
    """Nearest block-level ancestor that bounds a 'sentence' (p, li, td, ...)."""
    for parent in node.parents:
        if parent.name in ("p", "li", "td", "th", "dd", "dt", "blockquote", "figcaption"):
            return parent
    return node.parent


def section_elements(soup, el_id):
    """Elements of the section starting at el_id (following siblings until same/higher heading)."""
    start = soup.find(id=el_id)
    if start is None:
        return []
    lvl = HEADING_LEVEL.get(start.name, 99)
    out = []
    for sib in start.next_siblings:
        name = getattr(sib, "name", None)
        if name in HEADING_LEVEL and HEADING_LEVEL[name] <= lvl:
            break
        if name is not None:
            out.append(sib)
    return out


def ledger_ids_for(fname):
    """Return (mirror_ids, canonical_ids) that live in this file per the ledger."""
    rows = list(csv.DictReader(open(os.path.join(REPO, LEDGER), encoding="utf-8")))
    book_num = {"LSE_BOOK_1_THE_LIVING_SOIL_WORKING.html": "1",
                "LSE_BOOK_5_FIELD_COMPANION_WORKING.html": "5"}[fname]
    mirror_ids = {r["mirror_id"] for r in rows if r["mirror_book"] == book_num}
    canonical_ids = {r["canonical_id"] for r in rows if r["canonical_file"] == fname}
    return mirror_ids, canonical_ids


# --------------------------------------------------------------------------- #
# Marker removal (regex, marker pattern only)
# --------------------------------------------------------------------------- #

def make_cleaner(raw):
    def clean_run(m):
        nxt = raw[m.end()] if m.end() < len(raw) else ""
        prv = raw[m.start() - 1] if m.start() > 0 else ""
        if nxt == "" or nxt in NO_SPACE_AFTER or prv == "" or prv in NO_SPACE_BEFORE:
            return ""
        return " "
    return clean_run


def clean_text_fragment(text):
    """Apply the same marker-run cleanup to a plain-text fragment (for the log 'after')."""
    return RUN_RE.sub(make_cleaner(text), text)


def predicted_lost_paragraphs(soup):
    """Distinct qualifying <p> (12+ words, not TOC) that contain a marker = verify.py's
    expected 'lost' count for this file after stripping."""
    n = 0
    for p in soup.find_all("p"):
        if in_toc(p):
            continue
        txt = p.get_text(" ", strip=True)
        if len(txt.split()) < 12:
            continue
        if MARKER_RE.search(txt):
            n += 1
    return n


def split_sentences(text):
    return re.split(r"(?<=[.!?])\s+", text)


def sentence_with_marker(block_text, approx_marker):
    """Return the sentence in block_text that contains a marker (first match)."""
    for s in split_sentences(block_text):
        if MARKER_RE.search(s):
            return s.strip()
    return block_text.strip()


# --------------------------------------------------------------------------- #
# Analysis
# --------------------------------------------------------------------------- #

def analyze_file(fname):
    soup = BeautifulSoup(open(os.path.join(REPO, fname), encoding="utf-8").read(), "html.parser")
    raw = open(os.path.join(REPO, fname), encoding="utf-8").read()
    mirror_ids, canonical_ids = ledger_ids_for(fname)
    ledger_id_set = mirror_ids | canonical_ids

    # Build the set of elements that belong to any ledger-tracked section in this file.
    mirror_section_elems = set()
    for lid in ledger_id_set:
        for el in section_elements(soup, lid):
            mirror_section_elems.add(id(el))
            for d in getattr(el, "descendants", []):
                mirror_section_elems.add(id(d))

    occurrences = []  # one per marker
    for node in list(soup.strings):
        if not MARKER_RE.search(str(node)):
            continue
        parent_names = {p.name for p in node.parents}
        in_heading = bool(parent_names & HEAD)
        toc = in_toc(node)
        block = block_ancestor(node)
        block_tag = block.name if block else None
        h_name, h_text, h_id = owning_heading(node)
        block_text = block.get_text(" ", strip=True) if block else str(node)
        # membership in a ledger section: is this node (or its block) inside a tracked section?
        in_mirror = id(node) in mirror_section_elems or (block is not None and id(block) in mirror_section_elems)
        for mm in MARKER_RE.finditer(str(node)):
            val = [int(n) for n in re.findall(r"\d{1,3}", mm.group(0))]  # one or more numbers
            nxt = str(node)[mm.end()] if mm.end() < len(str(node)) else "<end-of-node>"
            prv = str(node)[mm.start() - 1] if mm.start() > 0 else "<start-of-node>"
            occurrences.append({
                "file": fname, "short": None, "value": val, "marker": mm.group(0),
                "in_heading": in_heading, "in_toc": toc, "in_mirror_section": in_mirror,
                "heading": h_text, "heading_id": h_id, "block_tag": block_tag,
                "block_id": id(block), "block_text": block_text,
                "prev_char": prv, "next_char": nxt,
            })

    raw_count = len(MARKER_RE.findall(raw))
    return soup, raw, occurrences, raw_count


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true", help="write changes + log (default: dry-run)")
    args = ap.parse_args()

    all_log = []
    grand_total = 0
    recon = []   # (short, markers, by_tag dict, predicted_lost_p)
    print("=" * 70)
    for fname, short, expected in TARGETS:
        soup, raw, occ, raw_count = analyze_file(fname)
        for o in occ:
            o["short"] = short
        distinct_blocks = len({o["block_id"] for o in occ})
        vals = sorted({v for o in occ for v in o["value"]})
        in_toc_n = sum(1 for o in occ if o["in_toc"])
        in_head_n = sum(1 for o in occ if o["in_heading"])
        in_mirror_n = sum(1 for o in occ if o["in_mirror_section"])
        grand_total += len(occ)
        print(f"{short}  ({fname})")
        print(f"  markers (text-node scan): {len(occ)}   expected: {expected}")
        print(f"  markers (raw regex count): {raw_count}   -> match: {len(occ) == raw_count}")
        print(f"  distinct paragraphs touched: {distinct_blocks}")
        print(f"  value range: {vals[0]}-{vals[-1]}  (all in 1-14: {vals[-1] <= 14 and vals[0] >= 1})")
        print(f"  in TOC: {in_toc_n} | in heading: {in_head_n} | in mirror/canonical section: {in_mirror_n}")
        # context pattern distribution
        from collections import Counter
        nxt = Counter(('PUNCT' if o['next_char'] in NO_SPACE_AFTER else
                       'SPACE' if o['next_char'] in ' \t' else
                       'EON' if o['next_char'] == '<end-of-node>' else 'WORD') for o in occ)
        prv = Counter(('SPACE' if o['prev_char'] in ' \t' else
                       'OPEN' if o['prev_char'] in NO_SPACE_BEFORE else
                       'SON' if o['prev_char'] == '<start-of-node>' else 'WORD') for o in occ)
        print(f"  next-char classes: {dict(nxt)}")
        print(f"  prev-char classes: {dict(prv)}")
        by_tag = dict(Counter(o["block_tag"] for o in occ))
        pred = predicted_lost_paragraphs(soup)
        recon.append((short, len(occ), by_tag, pred))
        print(f"  container breakdown: {by_tag}")
        print(f"  predicted verify.py LOST <p> paragraphs: {pred}")
        print("-" * 70)

        if args.apply:
            new_raw = RUN_RE.sub(make_cleaner(raw), raw)
            remaining = len(MARKER_RE.findall(new_raw))
            with open(os.path.join(REPO, fname), "w", encoding="utf-8", newline="") as fh:
                fh.write(new_raw)
            print(f"  APPLIED: {len(occ)} markers removed, {remaining} remaining in {short}")
            for o in occ:
                before = sentence_with_marker(o["block_text"], o["marker"])
                after = re.sub(r"\s+", " ", clean_text_fragment(before)).strip()
                all_log.append({"short": short, "container": o["block_tag"],
                                "heading": o["heading"], "marker": o["marker"],
                                "before": before, "after": after})

    print("=" * 70)
    print(f"GRAND TOTAL markers: {grand_total} (expected 125)")
    total_pred = sum(p for _, _, _, p in recon)
    print(f"PREDICTED verify.py lost <p> paragraphs (N): {total_pred}")

    if args.apply:
        write_log(all_log, recon, total_pred)
        print(f"Wrote {os.path.relpath(LOG_PATH, REPO)} ({len(all_log)} removals)")


ANY_BRACKET = re.compile(r"\[[^\[\]]*\]")


def scan_open_placeholders():
    """Bracket-with-digit tokens that are NOT citation markers — reader-visible
    placeholders left for the front-matter/image phases. Returns {category: [tokens]}."""
    cats = {"image_brief": [], "text_substitute": [], "self_photo": [], "editorial": []}
    for fname, _short, _exp in TARGETS:
        text = BeautifulSoup(open(os.path.join(REPO, fname), encoding="utf-8").read(),
                             "html.parser").get_text(" ", strip=True)
        for tok in ANY_BRACKET.findall(text):
            if not re.search(r"\d", tok) or MARKER_RE.fullmatch(tok):
                continue
            if tok.startswith("[IMAGE "):
                cats["image_brief"].append(tok)
            elif "TEXT-ONLY SUBSTITUTE" in tok:
                cats["text_substitute"].append(tok)
            elif "SELF-PHOTO" in tok:
                cats["self_photo"].append(tok)
            else:
                cats["editorial"].append(tok)
    return cats


def write_log(entries, recon, total_pred):
    lines = ["# Marker removal log — Phase B / Task 3\n",
             "Every orphaned `[n]` citation marker removed from Book 1 and Book 5. For each "
             "removal: the container element, the owning heading, the sentence before, and the "
             "sentence after. Only the marker (and any orphaned space/doubled punctuation) changed.\n"]
    lines.append("## Reconciliation\n")
    lines.append("| File | Markers removed | Containers | Distinct `<p>` lost (= verify.py N) |")
    lines.append("|---|---:|---|---:|")
    for short, n, by_tag, pred in recon:
        containers = ", ".join("{}×{}".format(v, k) for k, v in sorted(by_tag.items()))
        lines.append("| {} | {} | {} | {} |".format(short, n, containers, pred))
    lines.append("| **Total** | **{}** | — | **{}** |".format(
        sum(n for _, n, _, _ in recon), total_pred))
    lines.append("")
    lines.append("`verify.py` fingerprints only `<p>` of 12+ words, so its paragraph-preservation "
                 "FAIL names **{}** paragraphs — the markers in `<li>`/`<td>` are cleaned and logged "
                 "here but are not tracked hashes.\n".format(total_pred))

    # Known open item: reader-visible bracket placeholders left for the front-matter/image phases.
    ph = scan_open_placeholders()
    reader_visible = len(ph["image_brief"]) + len(ph["text_substitute"]) + len(ph["self_photo"])
    lines.append("## Known open item — reader-visible bracket placeholders (front-matter phase)\n")
    lines.append("These are NOT citations and were correctly left untouched by this pass. They are "
                 "logged here so they are not lost track of before the front-matter/image phase.\n")
    lines.append("| Kind | Count |")
    lines.append("|---|---:|")
    lines.append("| `[IMAGE APP-*: …]` image-generation briefs | {} |".format(len(ph["image_brief"])))
    lines.append("| `[TEXT-ONLY SUBSTITUTE — B30_*]` | {} |".format(len(ph["text_substitute"])))
    lines.append("| `[SELF-PHOTO PLACEHOLDER — SP-*]` | {} |".format(len(ph["self_photo"])))
    lines.append("| **Reader-visible total** | **{}** |".format(reader_visible))
    lines.append("")
    lines.append("**Cross-reference:** the {} `TEXT-ONLY SUBSTITUTE` (B30_*) + {} `SELF-PHOTO "
                 "PLACEHOLDER` (SP-*) = **{}** are the SAME 21 empty figure sections the image "
                 "session found — record once, do not double-count later.\n".format(
                     len(ph["text_substitute"]), len(ph["self_photo"]),
                     len(ph["text_substitute"]) + len(ph["self_photo"])))
    if ph["editorial"]:
        lines.append("(Also {} editorial `[… VERIFY … v3]` notes — not reader-visible, tracked "
                     "separately.)\n".format(len(ph["editorial"])))

    cur_file = None
    for e in entries:
        if e["short"] != cur_file:
            cur_file = e["short"]
            lines.append("\n## {}\n".format(cur_file))
        lines.append("### {} — `<{}>` under: {}".format(e["marker"], e["container"], e["heading"]))
        lines.append("- **before:** {}".format(e["before"]))
        lines.append("- **after:** {}".format(e["after"]))
        lines.append("")
    os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)
    with open(LOG_PATH, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines))


if __name__ == "__main__":
    main()
