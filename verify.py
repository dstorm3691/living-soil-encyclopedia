#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
verify.py — content-preservation harness for the LSE five-book working set.

Runs standalone (`python verify.py`), prints a readable report, and exits
NONZERO if any HARD check fails. It is the contract referenced in CLAUDE.md:
run it before you start and after every change; if it fails, stop and fix.

HARD checks (any failure => nonzero exit, commit blocked by the pre-commit hook):
  1. Paragraph preservation  -- every paragraph fingerprint captured at baseline
                                still exists somewhere in the current set.
                                THIS IS THE MOST IMPORTANT CHECK IN THE FILE.
  2. Duplicate IDs           -- zero duplicate id attributes per file.
  3. Dead internal links     -- every href="#..." resolves to an id in the same file.
  4. Cross-book links        -- every href containing .html resolves to a file in the
                                set, and (if it has a #fragment) to a real id there.
  5. Mirror synchronization  -- each row of the mirror ledger: canonical section text
                                == mirror section text, after the mirror notice is
                                removed.

TRACKING metrics (reported, never fail the build):
  - Word count per file (BeautifulSoup get_text(' ', strip=True) split on whitespace).
    Word-count drift over 1% vs. baseline is flagged as a WARN, not a FAIL.
  - Orphaned citation markers: count of [n] / [n,m] / [n-m] bracket patterns in body text.
  - <img> tag count and rights-marker (diamond) count per file.

Design notes:
  - Parse HTML with BeautifulSoup, never regex the markup (CLAUDE.md rule 5).
    Regex is used only on already-extracted plain text.
  - All paths resolve relative to this file's directory, so the harness works
    regardless of the current working directory (important for the git hook).
  - The normalization and extraction helpers here are the single source of truth;
    generate_baseline.py imports them so the snapshot and the checker can never drift.
"""

import sys
import os
import re
import json
import csv
import hashlib
import collections

# The manuscript uses UTF-8 (em dashes, the diamond rights marker, etc.). Force the
# console to UTF-8 so the report never dies on a Windows codepage encode error.
for _stream in (sys.stdout, sys.stderr):
    try:
        _stream.reconfigure(encoding="utf-8")
    except Exception:
        pass

try:
    from bs4 import BeautifulSoup
except ImportError:
    sys.stderr.write("verify.py requires beautifulsoup4:  pip install beautifulsoup4\n")
    sys.exit(2)


# --------------------------------------------------------------------------- #
# Configuration
# --------------------------------------------------------------------------- #

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
BASELINE_DIR = os.path.join(BASE_DIR, "baseline")
PARA_HASHES_PATH = os.path.join(BASELINE_DIR, "paragraph_hashes.json")
METRICS_PATH = os.path.join(BASELINE_DIR, "metrics.json")

# The six HTML files, in canonical order, paired with the display names the owner
# used in the expected-baseline table.
BOOK_FILES = [
    ("LSE_BOOK_1_THE_LIVING_SOIL_WORKING.html",        "BOOK_1_THE_LIVING_SOIL"),
    ("LSE_BOOK_2_INPUTS_AND_AMENDMENTS_WORKING.html",  "BOOK_2_INPUTS_AND_AMENDMENTS"),
    ("LSE_BOOK_3_CROPS_AND_GUILDS_WORKING.html",       "BOOK_3_CROPS_AND_GUILDS"),
    ("LSE_BOOK_4_PLANT_HEALTH_AND_DEFENSE_WORKING.html","BOOK_4_PLANT_HEALTH_AND_DEFENSE"),
    ("LSE_BOOK_5_FIELD_COMPANION_WORKING.html",        "BOOK_5_FIELD_COMPANION"),
    ("LSE_INTERNAL_PRODUCTION_HOLD.html",              "INTERNAL_PRODUCTION_HOLD"),
]
FILES = [f for f, _ in BOOK_FILES]
FILE_SET = set(FILES)
DISPLAY = dict(BOOK_FILES)

MIRROR_LEDGER = "LSE_MIRROR_SYNCHRONIZATION_LEDGER.csv"

# Mirror ledger stores mirror_book as a number; map it to the actual file.
MIRROR_BOOK_FILE = {
    "1": "LSE_BOOK_1_THE_LIVING_SOIL_WORKING.html",
    "2": "LSE_BOOK_2_INPUTS_AND_AMENDMENTS_WORKING.html",
    "3": "LSE_BOOK_3_CROPS_AND_GUILDS_WORKING.html",
    "4": "LSE_BOOK_4_PLANT_HEALTH_AND_DEFENSE_WORKING.html",
    "5": "LSE_BOOK_5_FIELD_COMPANION_WORKING.html",
}

HEADING_LEVEL = {"h1": 1, "h2": 2, "h3": 3, "h4": 4, "h5": 5, "h6": 6}
MIN_PARA_WORDS = 12
WORD_DRIFT_WARN_PCT = 1.0
RIGHTS_MARKER = "◆"          # ◆
# Orphaned citation markers: single [n] plus comma-lists and ranges ([4,5], [12,13],
# [4-6], en/em-dash variants). A bare [n] metric read 0 while [4,5]-style orphans survived.
ORPHAN_CITATION_RE = re.compile(r"\[\d{1,3}(?:\s*[,–—-]\s*\d{1,3})*\]")


# --------------------------------------------------------------------------- #
# Shared parsing / normalization helpers (single source of truth)
# --------------------------------------------------------------------------- #

def load_soup(filename):
    """Parse one HTML file (name relative to BASE_DIR) into a BeautifulSoup tree."""
    path = os.path.join(BASE_DIR, filename)
    with open(path, encoding="utf-8") as fh:
        return BeautifulSoup(fh.read(), "html.parser")


def normalize_paragraph(text):
    """
    Canonical paragraph fingerprint normalization:
      1. lowercase
      2. collapse whitespace to single spaces (and trim)
      3. strip non-alphanumerics, keeping the word-separating spaces
      4. re-collapse (removing punctuation can leave a double space)
    Deliberately robust to reformatting (whitespace, case, punctuation) but
    sensitive to any change in the actual words.
    """
    t = text.lower()
    t = re.sub(r"\s+", " ", t).strip()
    t = re.sub(r"[^a-z0-9 ]", "", t)
    t = re.sub(r"\s+", " ", t).strip()
    return t


def _is_in_toc(tag):
    """True if the tag lives inside <section class="toc-section"> or #table-of-contents."""
    return tag.find_parent(
        lambda t: (t.name == "section" and t.get("class") and "toc-section" in t.get("class"))
        or t.get("id") == "table-of-contents"
    ) is not None


def iter_paragraph_records(soup):
    """
    Yield (md5_hash, preview, word_count) for every qualifying <p>:
      - not inside the table of contents,
      - at least MIN_PARA_WORDS words,
      - non-empty after normalization.
    `preview` is the first 150 characters of the human-readable paragraph text.
    """
    for p in soup.find_all("p"):
        if _is_in_toc(p):
            continue
        readable = p.get_text(" ", strip=True)
        if len(readable.split()) < MIN_PARA_WORDS:
            continue
        norm = normalize_paragraph(readable)
        if not norm:
            continue
        digest = hashlib.md5(norm.encode("utf-8")).hexdigest()
        yield digest, readable[:150], len(readable.split())


def section_heading_text(soup, element_id):
    """Whitespace-collapsed text of the heading element itself (the id anchor)."""
    el = soup.find(id=element_id)
    if el is None:
        return None
    return re.sub(r"\s+", " ", el.get_text(" ", strip=True)).strip()


def load_mirror_rows():
    """Read the mirror ledger, or return None if it is missing."""
    ledger_path = os.path.join(BASE_DIR, MIRROR_LEDGER)
    if not os.path.exists(ledger_path):
        return None
    with open(ledger_path, encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


def section_body_text(soup, element_id):
    """
    Return the normalized (whitespace-collapsed) text of a section body.

    Section boundaries: start at the element with `element_id`, walk its following
    siblings, and stop at the next heading of the same or higher level. The heading
    element itself is NOT part of the body (canonical and mirror headings differ by an
    LSE-code prefix by design). Any mirror-notice block inside the body is removed, so
    the notice line and its "Canonical text: ... Mirror location: ..." sentence drop out.

    Returns None if `element_id` is not found.
    """
    start = soup.find(id=element_id)
    if start is None:
        return None
    start_level = HEADING_LEVEL.get(start.name, 99)

    fragments = []
    for sib in start.next_siblings:
        name = getattr(sib, "name", None)
        if name in HEADING_LEVEL and HEADING_LEVEL[name] <= start_level:
            break
        if name is None:
            continue  # NavigableString (whitespace between tags)
        fragments.append(str(sib))

    # Re-parse the collected fragment so we can drop mirror notices without mutating
    # the caller's tree, and so a notice nested anywhere inside is handled too.
    body = BeautifulSoup("".join(fragments), "html.parser")
    for notice in body.find_all("div", class_="mirror-notice"):
        notice.decompose()

    return re.sub(r"\s+", " ", body.get_text(" ", strip=True)).strip()


def file_metrics(soup):
    """Tracking metrics for one file."""
    full = soup.get_text(" ", strip=True)
    return {
        "words": len(full.split()),
        "images": len(soup.find_all("img")),
        "rights_markers": full.count(RIGHTS_MARKER),
        "orphan_citations": len(ORPHAN_CITATION_RE.findall(full)),
    }


def id_set(soup):
    return {el["id"] for el in soup.find_all(id=True)}


# --------------------------------------------------------------------------- #
# Report plumbing
# --------------------------------------------------------------------------- #

class Report:
    """Collects check results and tracks whether any HARD check failed."""

    PASS, FAIL, WARN, INFO = "PASS", "FAIL", "WARN", "INFO"
    _MARK = {PASS: "PASS", FAIL: "FAIL", WARN: "WARN", INFO: "INFO"}

    def __init__(self):
        self.failed = False
        self.checks = []   # (title, status, summary, detail_lines)
        self.notes = []    # freeform trailing lines (metrics table etc.)

    def check(self, title, status, summary, details=None):
        if status == self.FAIL:
            self.failed = True
        self.checks.append((title, status, summary, details or []))

    def note(self, line=""):
        self.notes.append(line)

    def render(self):
        out = []
        out.append("=" * 72)
        out.append(" LSE FIVE-BOOK VERIFICATION HARNESS")
        out.append(" baseline tag: baseline-five-book-v1")
        out.append("=" * 72)
        out.append("")
        out.append("HARD CHECKS")
        out.append("-" * 72)
        for title, status, summary, details in self.checks:
            out.append("[{:4}] {:<26} {}".format(self._MARK[status], title, summary))
            for line in details:
                out.append("         " + line)
        out.append("")
        out.extend(self.notes)
        out.append("")
        out.append("=" * 72)
        if self.failed:
            out.append(" RESULT: FAIL  — content check failed; see [FAIL] lines above.")
        else:
            out.append(" RESULT: PASS  — all hard checks passed.")
        out.append("=" * 72)
        return "\n".join(out)


# --------------------------------------------------------------------------- #
# Hard checks
# --------------------------------------------------------------------------- #

def check_paragraph_preservation(report, soups):
    """Every baseline paragraph fingerprint must still exist somewhere in the set."""
    if not os.path.exists(PARA_HASHES_PATH):
        report.check(
            "Paragraph preservation", Report.FAIL,
            "baseline snapshot missing",
            ["expected {}".format(os.path.relpath(PARA_HASHES_PATH, BASE_DIR)),
             "run:  python generate_baseline.py"],
        )
        return

    with open(PARA_HASHES_PATH, encoding="utf-8") as fh:
        snapshot = json.load(fh)
    baseline = snapshot.get("paragraphs", {})

    current = set()
    for fn in FILES:
        for digest, _preview, _words in iter_paragraph_records(soups[fn]):
            current.add(digest)

    missing = [(h, rec) for h, rec in baseline.items() if h not in current]

    if not missing:
        report.check(
            "Paragraph preservation", Report.PASS,
            "{}/{} baseline paragraphs present".format(len(baseline), len(baseline)),
        )
        return

    details = ["{} of {} baseline paragraphs MISSING from the current set:"
               .format(len(missing), len(baseline))]
    for h, rec in missing:
        src = ", ".join(rec.get("files", [])) or "?"
        preview = rec.get("preview", "").replace("\n", " ")
        details.append("- [{}] {}".format(src, h[:12]))
        details.append("    \"{}\"".format(preview[:150]))
    report.check(
        "Paragraph preservation", Report.FAIL,
        "{} paragraph(s) LOST".format(len(missing)),
        details,
    )


def check_duplicate_ids(report, soups):
    offenders = []
    total = 0
    for fn in FILES:
        ids = [el["id"] for el in soups[fn].find_all(id=True)]
        total += len(ids)
        dups = {i: n for i, n in collections.Counter(ids).items() if n > 1}
        for i, n in sorted(dups.items()):
            offenders.append("[{}] id={!r} appears {}x".format(DISPLAY[fn], i, n))
    if offenders:
        report.check("Duplicate IDs", Report.FAIL,
                     "{} duplicate id(s) found".format(len(offenders)), offenders)
    else:
        report.check("Duplicate IDs", Report.PASS,
                     "0 duplicates across {} ids in {} files".format(total, len(FILES)))


def check_dead_internal_links(report, soups, ids):
    offenders = []
    checked = 0
    for fn in FILES:
        for a in soups[fn].find_all(href=True):
            href = a["href"]
            if not href.startswith("#"):
                continue
            frag = href[1:]
            if not frag:
                continue  # bare "#" is a no-op anchor, not a dead link
            checked += 1
            if frag not in ids[fn]:
                offenders.append("[{}] href=\"{}\" -> no matching id".format(DISPLAY[fn], href))
    if offenders:
        report.check("Dead internal links", Report.FAIL,
                     "{} broken of {} checked".format(len(offenders), checked), offenders)
    else:
        report.check("Dead internal links", Report.PASS,
                     "0 broken of {} internal (#...) links".format(checked))


def check_cross_book_links(report, soups, ids):
    offenders = []
    checked = 0
    for fn in FILES:
        for a in soups[fn].find_all(href=True):
            href = a["href"]
            if ".html" not in href.lower():
                continue
            checked += 1
            path, _, frag = href.partition("#")
            base = os.path.basename(path)
            if base not in FILE_SET:
                offenders.append("[{}] href=\"{}\" -> file not in set".format(DISPLAY[fn], href))
            elif frag and frag not in ids[base]:
                offenders.append("[{}] href=\"{}\" -> no id \"{}\" in {}"
                                 .format(DISPLAY[fn], href, frag, base))
    if offenders:
        report.check("Cross-book links", Report.FAIL,
                     "{} broken of {} checked".format(len(offenders), checked), offenders)
    else:
        report.check("Cross-book links", Report.PASS,
                     "0 broken of {} cross-book (.html) links".format(checked))


def _short_diff(canonical, mirror):
    """A compact human-readable description of where two section texts first diverge."""
    import difflib
    sm = difflib.SequenceMatcher(None, canonical, mirror, autojunk=False)
    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag == "equal":
            continue
        ctx = canonical[max(0, i1 - 25):i1]
        return ("first divergence near ...{}| canonical={!r} vs mirror={!r}"
                .format(ctx[-25:], canonical[i1:i2][:60], mirror[j1:j2][:60]))
    return "texts differ in length only"


def check_mirror_sync(report, soups):
    rows = load_mirror_rows()
    if rows is None:
        report.check("Mirror synchronization", Report.FAIL,
                     "ledger missing: {}".format(MIRROR_LEDGER))
        return

    offenders = []
    compared = 0
    for row in rows:
        cfile = row["canonical_file"]
        cid = row["canonical_id"]
        mbook = row["mirror_book"]
        mid = row["mirror_id"]
        mfile = MIRROR_BOOK_FILE.get(mbook)

        if cfile not in soups or mfile not in soups:
            offenders.append("[{} <-> book {}] unknown file (canonical={}, mirror_book={})"
                             .format(cid, mbook, cfile, mbook))
            continue

        canon = section_body_text(soups[cfile], cid)
        mirror = section_body_text(soups[mfile], mid)
        if canon is None:
            offenders.append("canonical id not found: {} in {}".format(cid, cfile))
            continue
        if mirror is None:
            offenders.append("mirror id not found: {} in {}".format(mid, mfile))
            continue

        compared += 1
        if canon != mirror:
            offenders.append(
                "DESYNC canonical={} ({}) vs mirror={} (book {})"
                .format(cid, DISPLAY.get(cfile, cfile), mid, mbook))
            offenders.append("   " + _short_diff(canon, mirror))

    if offenders:
        report.check("Mirror synchronization", Report.FAIL,
                     "{} of {} mirror(s) out of sync".format(
                         sum(1 for o in offenders if o.startswith("DESYNC") or "not found" in o or "unknown" in o),
                         len(rows)),
                     offenders)
    else:
        report.check("Mirror synchronization", Report.PASS,
                     "{}/{} mirrors in sync".format(compared, len(rows)))


# --------------------------------------------------------------------------- #
# Tracking metrics
# --------------------------------------------------------------------------- #

def report_tracking_metrics(report, soups):
    baseline_metrics = None
    if os.path.exists(METRICS_PATH):
        with open(METRICS_PATH, encoding="utf-8") as fh:
            baseline_metrics = json.load(fh).get("files", {})

    report.note("TRACKING METRICS (report only — never fail the build)")
    report.note("-" * 72)
    header = "{:<32}{:>9}{:>8}{:>7}{:>5}{:>10}".format(
        "file", "words", "Δwords", "images", "◆", "orphan[n]")
    report.note(header)

    drift_warnings = []
    for fn in FILES:
        m = file_metrics(soups[fn])
        delta_str = "—"
        if baseline_metrics and fn in baseline_metrics:
            base_w = baseline_metrics[fn]["words"]
            dw = m["words"] - base_w
            pct = (dw / base_w * 100.0) if base_w else 0.0
            delta_str = "{:+d}".format(dw)
            if abs(pct) > WORD_DRIFT_WARN_PCT:
                delta_str += "!"
                drift_warnings.append(
                    "{}: word count drifted {:+d} ({:+.2f}%) vs baseline"
                    .format(DISPLAY[fn], dw, pct))
        report.note("{:<32}{:>9,}{:>8}{:>7}{:>5}{:>10}".format(
            DISPLAY[fn], m["words"], delta_str, m["images"],
            m["rights_markers"], m["orphan_citations"]))

    if drift_warnings:
        report.note("")
        for w in drift_warnings:
            report.note("[WARN] " + w)
    report.note("")
    report.note("(Δwords \"!\" = drift over {:.0f}% vs baseline — flagged, not failed.)"
                .format(WORD_DRIFT_WARN_PCT))


def report_mirror_heading_divergence(report, soups):
    """
    Tracking metric (NEVER a failure): a mirror section and its canonical source can
    carry different heading titles (e.g. the mirror adds an "LSE-NNN —" code prefix, or
    orders the "SOP" token differently). The bodies are in sync — this is purely a
    title-mismatch that surfaces the same section under two names depending on the book.
    It is a Phase E problem (TOC rebuild), not a sync error, so it is reported here and
    does not affect the exit code.
    """
    rows = load_mirror_rows()
    if rows is None:
        return

    divergences = []
    for row in rows:
        cfile = row["canonical_file"]
        mfile = MIRROR_BOOK_FILE.get(row["mirror_book"])
        if cfile not in soups or mfile not in soups:
            continue
        canon = section_heading_text(soups[cfile], row["canonical_id"])
        mirror = section_heading_text(soups[mfile], row["mirror_id"])
        if canon is None or mirror is None:
            continue
        if canon != mirror:
            divergences.append((row["mirror_book"], canon, mirror))

    report.note("")
    report.note("MIRROR HEADING DIVERGENCE (tracking only — Phase E TOC concern, not a sync error)")
    report.note("-" * 72)
    report.note("{} of {} mirror pair(s) show the same section under two different titles:"
                .format(len(divergences), len(rows)))
    for mbook, canon, mirror in divergences:
        report.note("  - canonical: \"{}\"".format(canon))
        report.note("    mirror   : \"{}\"  (book {})".format(mirror, mbook))


def report_asset_resolution(report, soups):
    """
    TRACKING METRIC (report only — NEVER fails the build): for each file, how many <img>
    src values resolve to a file that exists on disk, relative to this file's directory.
    Reads 0/169 before image assets are copied into place and climbs as they land. The
    hard checks above are untouched; this metric never affects the exit code.
    """
    report.note("")
    report.note("ASSET RESOLUTION (tracking only — <img src> that resolve to a file on disk)")
    report.note("-" * 72)
    report.note("{:<32}{:>8}{:>12}".format("file", "img", "resolved"))

    total_imgs = total_res = 0
    unique_expected = set()
    unique_resolved = set()
    for fn in FILES:
        imgs = [i.get("src") for i in soups[fn].find_all("img") if i.get("src")]
        res = 0
        for src in imgs:
            unique_expected.add(src)
            path = os.path.join(BASE_DIR, src.replace("/", os.sep))
            if os.path.isfile(path):
                res += 1
                unique_resolved.add(src)
        total_imgs += len(imgs)
        total_res += res
        report.note("{:<32}{:>8}{:>12}".format(DISPLAY[fn], len(imgs),
                                               "{}/{}".format(res, len(imgs))))
    report.note("-" * 72)
    report.note("{:<32}{:>8}{:>12}".format("TOTAL (tags)", total_imgs,
                                           "{}/{}".format(total_res, total_imgs)))
    report.note("{:<32}{:>8}{:>12}".format("UNIQUE paths", len(unique_expected),
                "{}/{}".format(len(unique_resolved), len(unique_expected))))


# --------------------------------------------------------------------------- #
# Main
# --------------------------------------------------------------------------- #

def main():
    missing_files = [fn for fn in FILES if not os.path.exists(os.path.join(BASE_DIR, fn))]
    if missing_files:
        sys.stderr.write("ERROR: missing manuscript files: {}\n".format(", ".join(missing_files)))
        return 2

    soups = {fn: load_soup(fn) for fn in FILES}
    ids = {fn: id_set(soups[fn]) for fn in FILES}

    report = Report()
    check_paragraph_preservation(report, soups)
    check_duplicate_ids(report, soups)
    check_dead_internal_links(report, soups, ids)
    check_cross_book_links(report, soups, ids)
    check_mirror_sync(report, soups)
    report_tracking_metrics(report, soups)
    report_mirror_heading_divergence(report, soups)
    report_asset_resolution(report, soups)

    print(report.render())
    return 1 if report.failed else 0


if __name__ == "__main__":
    sys.exit(main())
