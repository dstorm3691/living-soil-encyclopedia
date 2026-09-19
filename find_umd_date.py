#!/usr/bin/env python3
"""
Find when the UMD Extension pages were retrieved.

Checks two independent records:
  1. File timestamps on the UMD images, including the pre-conversion
     originals in the archive, which still carry their download dates.
  2. Browser history for visits to extension.umd.edu.

Read-only. Copies browser history databases to a temp file before reading,
so it works with the browser open and never touches the original.

    python find_umd_date.py
    python find_umd_date.py --archive "D:\\LSE_ARCHIVE\\originals"
"""

import argparse
import os
import shutil
import sqlite3
import subprocess
import tempfile
from datetime import datetime, timedelta, timezone
from pathlib import Path

UMD_FILES = ["B30_035", "B30_036", "B30_037", "B30_038", "B30_077", "B30_078"]
DOMAINS = ["umd.edu", "extension.umd.edu", "ask.extension.org"]


def repo_root() -> Path:
    try:
        out = subprocess.run(["git", "rev-parse", "--show-toplevel"],
                             capture_output=True, text=True, check=True)
        return Path(out.stdout.strip())
    except Exception:
        return Path.cwd()


# ----------------------------------------------------------------
# 1. File timestamps
# ----------------------------------------------------------------

def scan_files(roots):
    hits = []
    for root in roots:
        root = Path(root)
        if not root.exists():
            continue
        for p in root.rglob("*"):
            if not p.is_file():
                continue
            if not any(p.name.startswith(tag) for tag in UMD_FILES):
                continue
            st = p.stat()
            hits.append({
                "file": p.name,
                "where": str(root),
                "modified": datetime.fromtimestamp(st.st_mtime),
                "created": datetime.fromtimestamp(st.st_ctime),
            })
    return hits


# ----------------------------------------------------------------
# 2. Browser history
# ----------------------------------------------------------------

def chrome_time(v):
    # microseconds since 1601-01-01
    if not v:
        return None
    try:
        return datetime(1601, 1, 1, tzinfo=timezone.utc) + timedelta(microseconds=v)
    except (OverflowError, OSError):
        return None


def firefox_time(v):
    if not v:
        return None
    try:
        return datetime.fromtimestamp(v / 1_000_000)
    except (OverflowError, OSError, ValueError):
        return None


def browser_dbs():
    la = os.environ.get("LOCALAPPDATA", "")
    ap = os.environ.get("APPDATA", "")
    found = []

    chromium = {
        "Chrome":  Path(la) / "Google" / "Chrome" / "User Data",
        "Edge":    Path(la) / "Microsoft" / "Edge" / "User Data",
        "Brave":   Path(la) / "BraveSoftware" / "Brave-Browser" / "User Data",
        "Vivaldi": Path(la) / "Vivaldi" / "User Data",
        "Opera":   Path(ap) / "Opera Software" / "Opera Stable",
    }
    for name, base in chromium.items():
        if not base.exists():
            continue
        for prof in list(base.glob("Default")) + list(base.glob("Profile *")) + [base]:
            db = prof / "History"
            if db.exists():
                found.append((f"{name} ({prof.name})", db, "chromium"))

    ff = Path(ap) / "Mozilla" / "Firefox" / "Profiles"
    if ff.exists():
        for prof in ff.iterdir():
            db = prof / "places.sqlite"
            if db.exists():
                found.append((f"Firefox ({prof.name})", db, "firefox"))

    return found


def read_history(label, db, kind):
    rows = []
    tmp = Path(tempfile.gettempdir()) / f"hist_{abs(hash(str(db)))}.db"
    try:
        shutil.copy2(db, tmp)
    except Exception as e:
        return rows, f"{label}: could not copy ({e})"

    try:
        con = sqlite3.connect(f"file:{tmp}?immutable=1", uri=True)
        cur = con.cursor()
        like = " OR ".join(["url LIKE ?"] * len(DOMAINS))
        params = [f"%{d}%" for d in DOMAINS]

        if kind == "chromium":
            cur.execute(f"SELECT url, title, last_visit_time FROM urls WHERE {like}", params)
            conv = chrome_time
        else:
            cur.execute(f"SELECT url, title, last_visit_date FROM moz_places WHERE {like}", params)
            conv = firefox_time

        for url, title, t in cur.fetchall():
            when = conv(t)
            if when:
                rows.append({"browser": label, "url": url,
                             "title": title or "", "when": when})
        con.close()
    except Exception as e:
        return rows, f"{label}: {e}"
    finally:
        try:
            tmp.unlink()
        except Exception:
            pass

    return rows, None


# ----------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--archive", default=r"D:\LSE_ARCHIVE\originals")
    ap.add_argument("--repo", default=None)
    args = ap.parse_args()

    repo = Path(args.repo) if args.repo else repo_root()

    print()
    print("=" * 70)
    print(" WHEN WERE THE UMD PAGES RETRIEVED?")
    print("=" * 70)

    # --- files ---
    print("\n1. UMD IMAGE FILE TIMESTAMPS")
    print("-" * 70)
    roots = [repo / "assets", Path(args.archive)]
    hits = scan_files(roots)

    if not hits:
        print("  No UMD image files found.")
        print(f"  Looked in: {', '.join(str(r) for r in roots)}")
    else:
        archive_hits = [h for h in hits if "ARCHIVE" in h["where"].upper()]
        if archive_hits:
            print("  Pre-conversion originals (these carry the download date):\n")
            for h in sorted(archive_hits, key=lambda x: x["modified"]):
                print(f"    {h['modified']:%Y-%m-%d %H:%M}   {h['file'][:60]}")
        other = [h for h in hits if "ARCHIVE" not in h["where"].upper()]
        if other:
            print("\n  Current working copies (modified by the format conversion):\n")
            for h in sorted(other, key=lambda x: x["modified"]):
                print(f"    {h['modified']:%Y-%m-%d %H:%M}   {h['file'][:60]}")

        source = archive_hits or hits
        dates = sorted({h["modified"].date() for h in source})
        print(f"\n  Distinct dates: {', '.join(str(d) for d in dates)}")
        if dates:
            print(f"  Earliest: {dates[0]}   Latest: {dates[-1]}")

    # --- browser ---
    print("\n2. BROWSER HISTORY, UMD AND ASK EXTENSION")
    print("-" * 70)
    dbs = browser_dbs()
    if not dbs:
        print("  No browser history databases found.")
    all_rows, problems = [], []
    for label, db, kind in dbs:
        rows, err = read_history(label, db, kind)
        if err:
            problems.append(err)
        all_rows.extend(rows)

    if all_rows:
        print()
        for r in sorted(all_rows, key=lambda x: x["when"]):
            t = r["when"].strftime("%Y-%m-%d %H:%M")
            print(f"    {t}  [{r['browser']}]")
            print(f"       {r['url'][:100]}")
            if r["title"]:
                print(f"       {r['title'][:100]}")
        hist_dates = sorted({r["when"].date() for r in all_rows})
        print(f"\n  Distinct visit dates: {', '.join(str(d) for d in hist_dates)}")
    else:
        print("  No UMD or Ask Extension visits in history.")
        print("  Browser history is often trimmed after 90 days, so this may")
        print("  simply be too old.")

    for p in problems:
        print(f"  note: {p}")

    # --- conclusion ---
    print("\n" + "=" * 70)
    print(" SUGGESTION")
    print("=" * 70)

    candidates = []
    if hits:
        src = [h for h in hits if "ARCHIVE" in h["where"].upper()] or hits
        candidates += [h["modified"].date() for h in src]
    if all_rows:
        candidates += [r["when"].date() for r in all_rows]

    if candidates:
        best = max(set(candidates), key=candidates.count)
        print(f"\n  Most likely retrieval date: {best}")
        print(f"  Format for the credits:     retrieved {best:%B %-d, %Y}"
              .replace("%-d", str(best.day)))
        print("\n  Cross-check against your Ask Extension thread #0210644.")
        print("  If they disagree, use the email date. It is the firmer record.")
    else:
        print("\n  Nothing found automatically.")
        print("  Fall back to the date on your Ask Extension thread #0210644,")
        print("  which is when UMD confirmed the permissions.")
    print()


if __name__ == "__main__":
    main()
