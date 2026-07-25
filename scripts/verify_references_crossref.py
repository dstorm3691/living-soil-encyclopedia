#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Phase B / Task 2 — verify each extracted reference against CrossRef.

Reads references/extracted.json, queries the free CrossRef REST API (polite pool:
real User-Agent with a mailto contact, ~1 req/sec), classifies each entry, and writes:
  * references/verification.json         (structured, machine-readable — drives Task 4)
  * references/verification_report.md     (human-readable, grouped by status)

Classification (NO auto-correction — a mismatch is a finding for the author):
  verified          DOI resolves to the same work (author/year/title agree), OR a
                    bibliographic query returns a closely-matching title.
  mismatch          A record was returned but title/author/year disagree. If a DOI
                    resolves to an UNRELATED paper, this is the fabrication signature
                    and is flagged loudly (fabrication_flag = true).
  not_found         Nothing returned / DOI did not resolve, and it is not a book.
  book_or_unindexed CrossRef indexes journal literature; books & practitioner works
                    (publisher, no journal/DOI) legitimately are not present.

Responses are cached to references/crossref_cache.json so re-runs do not re-hit the API.

    python scripts/verify_references_crossref.py            # verify all
    python scripts/verify_references_crossref.py --limit 5  # smoke-test a few
"""
import os
import re
import sys
import json
import time
import argparse
import difflib
import unicodedata
import urllib.parse
import urllib.request

sys.stdout.reconfigure(encoding="utf-8")

REPO = os.getcwd()
EXTRACTED = os.path.join(REPO, "references", "extracted.json")
CACHE = os.path.join(REPO, "references", "crossref_cache.json")
OUT_JSON = os.path.join(REPO, "references", "verification.json")
OUT_MD = os.path.join(REPO, "references", "verification_report.md")

CONTACT = "d.storm369111@gmail.com"
UA = "LSE-reference-verify/1.0 (mailto:{})".format(CONTACT)
REQUEST_DELAY = 1.1  # seconds between live requests (be polite)

STOPWORDS = set("a an the of in on and or for to with without into from by as at is "
                "vs versus review analysis study effects effect role its their a".split())
PUBLISHER_HINTS = [
    "press", "publishing", "publications", "publisher", "books", "book",
    "design services", "tagari", "chelsea green", "university press", "primer",
    "designer's manual", "designers manual", "manual", "usda", "acres u.s.a", "acres usa",
    # self-published / organizational / practitioner presses that CrossRef does not index
    "jadam", "cho global natural farming", "korean natural farming",
    "bionutrient food association", "advancing eco agriculture",
]
# An explicit "[Practitioner ...]" annotation in the source is a definitive signal that the
# entry is a practitioner/field work, not indexed journal literature.
PRACTITIONER_RE = re.compile(r"\[\s*practitioner", re.I)

# Owner decisions: entries held for hand-confirmation regardless of automated status.
# "Right author, different book" is the exact shape a fabricated entry takes when it
# passes — CrossRef matched Epstein's 2011 *Industrial Composting*, which says nothing
# about whether the cited 1997 *The Science of Composting* exists. Held entries are
# excluded from Further Reading and routed to the exception report.
MANUAL_HOLD = {
    "volume_1-b5-n4": ("CrossRef matched a DIFFERENT book by the same author "
                       "(Epstein 2011, Industrial Composting), not the cited 1997 "
                       "'The Science of Composting'; existence of the 1997 title is unconfirmed."),
}

# A status counts as publishable in Further Reading (Task 4) if it is one of these and
# the entry is not manually held.
PUBLISHABLE_STATUSES = {"verified", "verified_weak", "book_or_unindexed"}


# --------------------------------------------------------------------------- #
# Text similarity helpers
# --------------------------------------------------------------------------- #

def fold(s):
    """Casefold + strip diacritics to ASCII letters (fixes YETGİN vs Yetgin etc.)."""
    decomposed = unicodedata.normalize("NFKD", s or "")
    stripped = "".join(c for c in decomposed if not unicodedata.combining(c))
    return re.sub(r"[^a-z]", "", stripped.casefold())


def norm(t):
    return re.sub(r"\s+", " ", re.sub(r"[^a-z0-9 ]", " ", (t or "").lower())).strip()


def title_ratio(a, b):
    return difflib.SequenceMatcher(None, norm(a), norm(b)).ratio()


def content_tokens(t):
    return {w for w in norm(t).split() if w not in STOPWORDS and len(w) > 2}


def token_overlap(a, b):
    ta, tb = content_tokens(a), content_tokens(b)
    if not ta:
        return 0.0
    return len(ta & tb) / len(ta)


def source_surname(entry):
    a = entry.get("author") or ""
    first = a.split(",")[0].strip()
    return fold(first.split()[0]) if first.split() else ""


def looks_like_book(raw):
    if PRACTITIONER_RE.search(raw):
        return True
    low = raw.lower()
    return any(h in low for h in PUBLISHER_HINTS)


# --------------------------------------------------------------------------- #
# CrossRef access (cached)
# --------------------------------------------------------------------------- #

def load_cache():
    if os.path.exists(CACHE):
        with open(CACHE, encoding="utf-8") as fh:
            return json.load(fh)
    return {}


def save_cache(cache):
    with open(CACHE, "w", encoding="utf-8") as fh:
        json.dump(cache, fh, ensure_ascii=False, indent=1)


def _fetch(url, cache, state):
    if url in cache:
        return cache[url]
    if state["last"] is not None:
        wait = REQUEST_DELAY - (time.time() - state["last"])
        if wait > 0:
            time.sleep(wait)
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "application/json"})
    result = {"ok": False}
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            result = {"ok": True, "status_code": r.status, "body": json.load(r)}
    except urllib.error.HTTPError as e:
        result = {"ok": False, "status_code": e.code, "error": "HTTPError"}
    except Exception as e:  # noqa
        result = {"ok": False, "status_code": None, "error": "{}: {}".format(type(e).__name__, e)}
    state["last"] = time.time()
    cache[url] = result
    return result


def fetch_by_doi(doi, cache, state):
    return _fetch("https://api.crossref.org/works/" + urllib.parse.quote(doi), cache, state)


def fetch_by_biblio(text, cache, state):
    url = "https://api.crossref.org/works?" + urllib.parse.urlencode(
        {"query.bibliographic": text, "rows": 3})
    return _fetch(url, cache, state)


# --------------------------------------------------------------------------- #
# Classification
# --------------------------------------------------------------------------- #

def item_authors(item):
    """Family names (falling back to the last token of a 'name' field)."""
    out = []
    for a in item.get("author", []):
        if a.get("family"):
            out.append(a["family"])
        elif a.get("name"):
            out.append(a["name"].split()[-1])
    return out


def item_summary(item):
    return {
        "doi": item.get("DOI"),
        "title": (item.get("title") or [""])[0],
        "authors": item_authors(item),
        "year": _item_year(item),
        "container": (item.get("container-title") or [""])[0],
        "type": item.get("type"),
    }


def author_match(surname, families):
    return bool(surname) and any(surname == fold(fam) for fam in families)


def _item_year(item):
    for k in ("published-print", "published-online", "issued", "created"):
        parts = (item.get(k) or {}).get("date-parts") or [[None]]
        if parts and parts[0] and parts[0][0]:
            return str(parts[0][0])
    return None


def classify(entry, cache, state):
    raw = entry["raw"]
    surname = source_surname(entry)
    src_year = entry.get("year")
    src_title = entry.get("title") or ""
    result = {
        "id": entry["id"], "owning_chapter": entry["owning_chapter"],
        "source_volume": entry["source_volume"], "raw": raw,
        "source_doi": entry.get("doi"), "source_author": entry.get("author"),
        "source_year": src_year, "source_title": entry.get("title"),
        "status": None, "reason": None, "fabrication_flag": False, "matched": None,
        "title_ratio": None, "author_match": None, "year_match": None, "note": "",
        "held": False, "held_reason": None, "publishable": None,
    }

    # (1) The author's own "[Practitioner ...]" annotation is authoritative: hard-classify
    # as book_or_unindexed with NO CrossRef query at all.
    if PRACTITIONER_RE.search(raw):
        result["status"] = "book_or_unindexed"
        result["reason"] = "practitioner_annotation"
        result["note"] = "Source carries a [Practitioner ...] annotation — not indexed literature."
        return result

    if entry.get("doi"):
        resp = fetch_by_doi(entry["doi"], cache, state)
        if not resp.get("ok"):
            result["status"] = "not_found"
            result["reason"] = "doi_unresolved"
            result["note"] = "DOI did not resolve on CrossRef (HTTP {}).".format(resp.get("status_code"))
            return result
        m = item_summary(resp["body"]["message"])
        result["matched"] = m
        tr = max(title_ratio(src_title, m["title"]), token_overlap(src_title, m["title"])) if src_title else None
        result["title_ratio"] = round(tr, 3) if tr is not None else None
        amatch = author_match(surname, m["authors"])
        ymatch = bool(src_year) and (m["year"] == src_year)
        result["author_match"], result["year_match"] = amatch, ymatch
        # DOI resolved: is it the SAME work? A bare surname hit is NOT decisive on its own
        # (common surnames collide), so require corroboration from year or title.
        same = ((amatch and ymatch) or (tr is not None and tr >= 0.55)
                or (ymatch and tr is not None and tr >= 0.40)
                or (amatch and tr is not None and tr >= 0.40))
        unrelated = (not amatch) and (tr is None or tr < 0.30) and (not ymatch)
        if same:
            result["status"] = "verified"
            result["reason"] = "doi_resolved"
            result["note"] = "DOI resolves; author/title/year consistent."
        elif unrelated:
            result["status"] = "mismatch"
            result["reason"] = "doi_unrelated"
            result["fabrication_flag"] = True
            result["note"] = ("DOI RESOLVES TO AN UNRELATED WORK — fabrication signature. "
                              "Source: {!r} / {}. CrossRef: {!r} / {}."
                              .format(src_title or entry.get("author"), src_year, m["title"], m["year"]))
        else:
            result["status"] = "mismatch"
            result["reason"] = "doi_partial"
            result["note"] = "DOI resolves but author/title/year only partially agree — review."
        return result

    # No DOI: bibliographic query.
    resp = fetch_by_biblio(raw, cache, state)
    if not resp.get("ok"):
        result["status"] = "book_or_unindexed" if looks_like_book(raw) else "not_found"
        result["reason"] = "query_failed"
        result["note"] = "Query failed (HTTP {}).".format(resp.get("status_code"))
        return result
    items = resp["body"]["message"].get("items", [])
    if not items:
        book = looks_like_book(raw)
        result["status"] = "book_or_unindexed" if book else "not_found"
        result["reason"] = "book_no_results" if book else "no_results"
        result["note"] = "No CrossRef results." + (" Book/organizational work." if book else "")
        return result

    best, best_tr = None, -1.0
    for it in items:
        m = item_summary(it)
        tr = max(title_ratio(src_title, m["title"]), token_overlap(src_title, m["title"])) if src_title else 0.0
        if tr > best_tr:
            best, best_tr = m, tr
    result["matched"] = best
    result["title_ratio"] = round(best_tr, 3)
    amatch = author_match(surname, best["authors"])
    ymatch = bool(src_year) and best["year"] == src_year
    result["author_match"] = amatch
    result["year_match"] = ymatch

    # A high title ratio ALONE is not enough: a journal review of a book, or a different
    # edition, can title-match perfectly while being a different work. Require the author
    # or year to also agree. The weak "0.45<=tr<0.60 + author" path relies on the author
    # matcher and is tagged so it can be reviewed separately.
    if best_tr >= 0.60 and (amatch or ymatch):
        result["status"] = "verified"
        result["reason"] = "title_ratio>=0.60"
        result["note"] = "Bibliographic query returned a closely-matching record (title + author/year)."
    elif best_tr >= 0.45 and amatch:
        result["status"] = "verified_weak"
        result["reason"] = "title0.45+author"
        result["note"] = ("Moderate title match corroborated by author only, no resolved DOI — "
                          "author matcher is load-bearing here; kept visible for scrutiny.")
    elif looks_like_book(raw):
        result["status"] = "book_or_unindexed"
        result["reason"] = "book_no_close_match"
        result["note"] = ("Book/organizational work; no same-work journal match "
                          "(any title hit is a review/different work — expected).")
    else:
        result["status"] = "mismatch"
        result["reason"] = "no_close_match"
        result["note"] = "Results returned but none match the source title/author+year closely — review."
    return result


# --------------------------------------------------------------------------- #
# Reporting
# --------------------------------------------------------------------------- #

ORDER = ["mismatch", "not_found", "verified_weak", "verified", "book_or_unindexed"]
LABELS = {
    "verified": "VERIFIED (resolved DOI or high title ratio)",
    "verified_weak": "VERIFIED_WEAK (moderate title + author only, no DOI — stays visible)",
    "mismatch": "MISMATCH (author to resolve)",
    "not_found": "NOT FOUND",
    "book_or_unindexed": "BOOK / NOT INDEXED (expected — not a failure)",
}


def write_report(results):
    fabs = [r for r in results if r["fabrication_flag"]]
    by = {s: [r for r in results if r["status"] == s] for s in ORDER}
    lines = []
    lines.append("# Reference verification against CrossRef\n")
    lines.append("Source: `references/extracted.json` (98 entries, 9 blocks). "
                 "Verified via the CrossRef REST API. **Nothing here has been auto-corrected** — "
                 "a mismatch is a finding for the author to resolve.\n")
    lines.append("## Summary\n")
    lines.append("| Status | Count |")
    lines.append("|---|---:|")
    for s in ORDER:
        lines.append("| {} | {} |".format(LABELS[s], len(by[s])))
    lines.append("| **Total** | **{}** |".format(len(results)))
    lines.append("")

    # How each verified/verified_weak entry earned its status; the weak path is called out.
    verifiedish = [r for r in results if r["status"] in ("verified", "verified_weak")]
    weak = [r for r in results if r["status"] == "verified_weak"]
    path_labels = {
        "doi_resolved": "resolved DOI (author/year/title consistent)",
        "title_ratio>=0.60": "high title ratio (>=0.60) + author/year",
        "title0.45+author": "MODERATE title (0.45–0.60) + author only — verified_weak",
    }
    counts = {}
    for r in verifiedish:
        counts[r["reason"]] = counts.get(r["reason"], 0) + 1
    lines.append("## Verification path breakdown (of the {} verified + verified_weak)\n".format(len(verifiedish)))
    lines.append("| Path | Count |")
    lines.append("|---|---:|")
    for key in ("doi_resolved", "title_ratio>=0.60", "title0.45+author"):
        if key in counts:
            lines.append("| {} | {} |".format(path_labels[key], counts[key]))
    lines.append("")
    lines.append("**verified_weak (moderate title + author only, no DOI — matcher is load-bearing): {}**\n".format(len(weak)))
    if weak:
        for r in weak:
            md = r["matched"] or {}
            held = " — **HELD (excluded from Further Reading)**" if r["held"] else " — released"
            lines.append("- **{}**{} · {}".format(r["id"], held, r["owning_chapter"]))
            lines.append("  - Source: `{}`".format(r["raw"]))
            lines.append("  - CrossRef best: `{}` ({}) DOI `{}` [title_ratio={} author_match={} year_match={}]".format(
                md.get("title"), md.get("year"), md.get("doi"),
                r["title_ratio"], r["author_match"], r["year_match"]))
            lines.append("")
    else:
        lines.append("_None — every verified entry was confirmed by a resolved DOI or a high title ratio._\n")

    # Owner-held entries — routed to the exception report, excluded from Further Reading.
    held = [r for r in results if r["held"]]
    lines.append("## Held for manual confirmation (owner decision) — {}\n".format(len(held)))
    if not held:
        lines.append("_None._\n")
    else:
        lines.append("Excluded from Further Reading and carried into the exception report.\n")
        for r in held:
            md = r["matched"] or {}
            lines.append("- **{}** · {}".format(r["id"], r["owning_chapter"]))
            lines.append("  - Source: `{}`".format(r["raw"]))
            lines.append("  - CrossRef best: `{}` ({}) DOI `{}`".format(md.get("title"), md.get("year"), md.get("doi")))
            lines.append("  - Reason held: {}".format(r["held_reason"]))
            lines.append("")

    lines.append("## ⚠️ Fabrication signature — DOI resolves to an unrelated paper\n")
    if not fabs:
        lines.append("_None detected._ No DOI resolved to a paper unrelated to its citation.\n")
    else:
        lines.append("**{} entr{} whose DOI resolves to a DIFFERENT paper. "
                     "This is the most important finding — review each by hand.**\n"
                     .format(len(fabs), "y" if len(fabs) == 1 else "ies"))
        for r in fabs:
            lines.append("- **{}** ({})".format(r["id"], r["owning_chapter"]))
            lines.append("  - Source: `{}`".format(r["raw"]))
            lines.append("  - Source DOI: `{}`".format(r["source_doi"]))
            lines.append("  - CrossRef record for that DOI: `{}` ({}) — authors {}".format(
                r["matched"]["title"], r["matched"]["year"], r["matched"]["authors"]))
            lines.append("")

    for s in ORDER:
        lines.append("## {} — {}\n".format(LABELS[s], len(by[s])))
        if not by[s]:
            lines.append("_None._\n")
            continue
        for r in by[s]:
            md = r["matched"]
            held_tag = " **[HELD]**" if r["held"] else ""
            lines.append("- **{}**{} · {}".format(r["id"], held_tag, r["owning_chapter"]))
            lines.append("  - Source: `{}`".format(r["raw"]))
            if md:
                bits = "title_ratio={} author_match={} year_match={}".format(
                    r["title_ratio"], r["author_match"], r["year_match"])
                lines.append("  - CrossRef best: `{}` ({}) DOI `{}` [{}]".format(
                    md["title"], md["year"], md["doi"], bits))
            if r["note"]:
                lines.append("  - Note: {}".format(r["note"]))
            lines.append("")
    with open(OUT_MD, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--limit", type=int, default=None, help="verify only the first N entries")
    args = ap.parse_args()

    data = json.load(open(EXTRACTED, encoding="utf-8"))
    entries = data["entries"]
    if args.limit:
        entries = entries[:args.limit]

    cache = load_cache()
    state = {"last": None}
    results = []
    for i, entry in enumerate(entries, 1):
        r = classify(entry, cache, state)
        # Apply owner manual-hold decisions and compute publishability.
        if r["id"] in MANUAL_HOLD:
            r["held"] = True
            r["held_reason"] = MANUAL_HOLD[r["id"]]
        r["publishable"] = (r["status"] in PUBLISHABLE_STATUSES) and not r["held"]
        results.append(r)
        flag = "  <-- FABRICATION FLAG" if r["fabrication_flag"] else ""
        held = "  [HELD]" if r["held"] else ""
        print("[{:2}/{}] {:14} {}{}{}".format(i, len(entries), r["status"], entry["id"], flag, held))
        if i % 10 == 0:
            save_cache(cache)
    save_cache(cache)

    verifiedish = [r for r in results if r["status"] in ("verified", "verified_weak")]
    reason_counts = {}
    for r in verifiedish:
        reason_counts[r["reason"]] = reason_counts.get(r["reason"], 0) + 1
    weak_path = [r["id"] for r in results if r["status"] == "verified_weak"]

    out = {
        "schema": "lse-reference-verification/1",
        "note": "CrossRef verification. No auto-correction. Mismatch = author to resolve.",
        "counts": {s: sum(1 for r in results if r["status"] == s) for s in ORDER},
        "publishable_count": sum(1 for r in results if r["publishable"]),
        "held_ids": [r["id"] for r in results if r["held"]],
        "verified_by_path": reason_counts,
        "verified_weak_ids": weak_path,
        "fabrication_flags": sum(1 for r in results if r["fabrication_flag"]),
        "results": results,
    }
    with open(OUT_JSON, "w", encoding="utf-8") as fh:
        json.dump(out, fh, ensure_ascii=False, indent=1)
    write_report(results)

    print("\n== counts ==", out["counts"], "| fabrication_flags:", out["fabrication_flags"])
    print("== publishable ==", out["publishable_count"], "| held ==", out["held_ids"])
    print("== verified by path ==", reason_counts)
    print("== verified_weak ==", weak_path or "none")


if __name__ == "__main__":
    main()
