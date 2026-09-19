#!/usr/bin/env python3
"""
LSE build. Renders each book's HTML to PDF with WeasyPrint.

    python build.py --list              show books, build nothing
    python build.py --book 1            build Book 1
    python build.py                     build all five
    python build.py --book 1 --sweep    compare figure heights
    python build.py --book 1 --raw      no image compression, for comparison
    python build.py --book 1 --jpeg 82  re-encode images as JPEG at quality 82

--jpeg is a last resort. It shrinks photos well and blurs diagram text,
so check a figure page before keeping it.

Output goes to dist/. Writes dist/build_manifest.json.
"""

import argparse
import inspect
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

FONTS_CONF = """<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <dir>C:/Windows/Fonts</dir>
  <dir>{userfonts}</dir>
  <cachedir>{cachedir}</cachedir>
  <match target="pattern">
    <test qual="any" name="family"><string>serif</string></test>
    <edit name="family" mode="prepend" binding="strong"><string>Georgia</string></edit>
  </match>
  <match target="pattern">
    <test qual="any" name="family"><string>sans-serif</string></test>
    <edit name="family" mode="prepend" binding="strong"><string>Segoe UI</string></edit>
  </match>
  <match target="pattern">
    <test qual="any" name="family"><string>monospace</string></test>
    <edit name="family" mode="prepend" binding="strong"><string>Consolas</string></edit>
  </match>
</fontconfig>
"""

BOOK_PATTERN = re.compile(r"LSE_BOOK_(\d)_(.+?)_WORKING\.html$", re.IGNORECASE)


def setup_fontconfig(repo: Path):
    if os.name != "nt":
        return None
    bd = repo / ".build"
    bd.mkdir(exist_ok=True)
    cache = bd / "fontcache"
    cache.mkdir(exist_ok=True)
    userfonts = Path(os.environ.get("LOCALAPPDATA", "")) / "Microsoft" / "Windows" / "Fonts"
    conf = bd / "fonts.conf"
    conf.write_text(
        FONTS_CONF.format(
            userfonts=str(userfonts).replace("\\", "/"),
            cachedir=str(cache).replace("\\", "/"),
        ),
        encoding="utf-8",
    )
    os.environ["FONTCONFIG_FILE"] = str(conf)
    os.environ["FONTCONFIG_PATH"] = str(bd)
    return conf


def find_books(repo: Path):
    books = []
    for p in sorted(repo.glob("LSE_BOOK_*_WORKING.html")):
        m = BOOK_PATTERN.search(p.name)
        if m:
            books.append({
                "number": int(m.group(1)),
                "slug": m.group(2).lower(),
                "path": p,
                "title": m.group(2).replace("_", " ").title(),
            })
    return sorted(books, key=lambda b: b["number"])


def repo_root() -> Path:
    try:
        out = subprocess.run(["git", "rev-parse", "--show-toplevel"],
                             capture_output=True, text=True, check=True)
        return Path(out.stdout.strip())
    except Exception:
        return Path.cwd()


def pdf_kwargs(write_pdf, raw: bool, jpeg: int | None):
    """WeasyPrint has renamed its image-compression options across versions.
    Inspect the signature and pass whatever this build actually supports."""
    if raw:
        return {}, ["none (--raw)"]
    try:
        params = inspect.signature(write_pdf).parameters
    except (TypeError, ValueError):
        return {}, ["could not inspect signature"]

    kw, used = {}, []
    if "optimize_images" in params:
        kw["optimize_images"] = True
        used.append("optimize_images=True")
    if "optimize_size" in params:
        kw["optimize_size"] = ("fonts", "images")
        used.append("optimize_size=('fonts','images')")
    if jpeg is not None and "jpeg_quality" in params:
        kw["jpeg_quality"] = jpeg
        used.append(f"jpeg_quality={jpeg}")
    elif jpeg is not None:
        used.append("jpeg_quality NOT SUPPORTED in this WeasyPrint")
    if not used:
        used.append("none available in this WeasyPrint version")
    return kw, used


def render(html_path: Path, css_files, out_pdf, raw=False, jpeg=None):
    from weasyprint import HTML, CSS
    stylesheets = [CSS(filename=str(c)) for c in css_files]
    doc = HTML(filename=str(html_path)).render(stylesheets=stylesheets)
    pages = len(doc.pages)
    used = []
    if out_pdf is not None:
        kw, used = pdf_kwargs(doc.write_pdf, raw, jpeg)
        try:
            doc.write_pdf(str(out_pdf), **kw)
        except TypeError:
            doc.write_pdf(str(out_pdf))
            used = ["fell back to defaults"]
    return pages, used


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--book", type=int)
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--no-css", action="store_true")
    ap.add_argument("--css", type=str)
    ap.add_argument("--sweep", action="store_true")
    ap.add_argument("--raw", action="store_true", help="skip image compression")
    ap.add_argument("--jpeg", type=int, metavar="Q", help="re-encode images as JPEG at quality Q")
    ap.add_argument("--repo", type=str)
    args = ap.parse_args()

    repo = Path(args.repo).resolve() if args.repo else repo_root().resolve()
    books = find_books(repo)
    if not books:
        print(f"No LSE_BOOK_*_WORKING.html in {repo}")
        return 1

    print(f"\nRepo: {repo}")
    print(f"Found {len(books)} books:\n")
    for b in books:
        print(f"  Book {b['number']}  {b['title']:<30} {b['path'].stat().st_size/1024/1024:5.1f} MB")
    print()
    if args.list:
        return 0

    conf = setup_fontconfig(repo)
    if conf:
        print(f"Fontconfig: {conf}")

    css_files = []
    if not args.no_css:
        cssp = Path(args.css) if args.css else (repo / "print.css")
        if cssp.exists():
            css_files.append(cssp)
            print(f"Stylesheet: {cssp}")
        else:
            print(f"No print.css at {cssp}")
    print()

    try:
        import weasyprint
        print(f"WeasyPrint: {weasyprint.__version__}\n")
    except ImportError:
        print("WeasyPrint not installed. pip install weasyprint")
        return 1

    dist = repo / "dist"
    dist.mkdir(exist_ok=True)
    targets = [b for b in books if args.book is None or b["number"] == args.book]
    if not targets:
        print(f"No book numbered {args.book}")
        return 1

    # ---- sweep ------------------------------------------------------
    if args.sweep:
        if not css_files:
            print("--sweep needs print.css")
            return 1
        b = targets[0]
        base = css_files[0].read_text(encoding="utf-8")
        tmp = repo / ".build" / "sweep.css"
        print(f"Sweeping figure heights on Book {b['number']}: {b['title']}\n")
        print(f"  {'max-height':>12}  {'pages':>6}")
        print(f"  {'-'*12}  {'-'*6}")
        results = []
        for h in ["3.4in", "4.0in", "4.6in", "5.2in", "6.0in", "7.5in"]:
            patched = re.sub(r"--figure-max-height:\s*[^;]+;",
                             f"--figure-max-height: {h};", base, count=1)
            tmp.write_text(patched, encoding="utf-8")
            pages, _ = render(b["path"], [tmp], None)
            results.append((h, pages))
            print(f"  {h:>12}  {pages:>6}")
        best = min(results, key=lambda r: r[1])
        print(f"\n  Fewest pages: {best[0]} at {best[1]}.")
        print(f"  Pick for readability, not minimum. Set it in print.css.\n")
        return 0

    # ---- build ------------------------------------------------------
    manifest = []
    for b in targets:
        out = dist / f"LSE_Book_{b['number']}_{b['slug']}.pdf"
        before = out.stat().st_size if out.exists() else None
        print(f"Building Book {b['number']}: {b['title']}")
        t0 = time.time()
        try:
            pages, used = render(b["path"], css_files, out, raw=args.raw, jpeg=args.jpeg)
            el = time.time() - t0
            size = out.stat().st_size
            mb = size / 1024 / 1024
            print(f"  compression: {', '.join(used)}")
            print(f"  {pages} pages, {mb:.1f} MB, {el:.1f}s")
            if before:
                delta = (size - before) / 1024 / 1024
                pct = 100 * (size - before) / before
                print(f"  vs previous build: {delta:+.1f} MB ({pct:+.0f}%)")
            if mb / max(pages, 1) > 0.25:
                print(f"  NOTE: {mb/pages:.2f} MB per page is heavy. Try Optimize-LseImages.ps1 -Quantize")
            print(f"  {out}\n")
            manifest.append({
                "book": b["number"], "title": b["title"], "source": b["path"].name,
                "pdf": out.name, "pages": pages, "bytes": size,
                "mb_per_page": round(mb / max(pages, 1), 3),
                "compression": used, "seconds": round(el, 1), "ok": True,
            })
        except Exception as e:
            print(f"  FAILED: {e}\n")
            manifest.append({"book": b["number"], "title": b["title"],
                             "source": b["path"].name, "ok": False, "error": str(e)})

    (dist / "build_manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    ok = [m for m in manifest if m.get("ok")]
    bad = [m for m in manifest if not m.get("ok")]
    print("-" * 60)
    print(f"Built {len(ok)} of {len(manifest)}. {sum(m.get('pages',0) for m in ok)} pages, "
          f"{sum(m.get('bytes',0) for m in ok)/1024/1024:.0f} MB total.")
    if bad:
        print("FAILED: " + ", ".join("Book " + str(m["book"]) for m in bad))
    print()
    return 0 if not bad else 1


if __name__ == "__main__":
    sys.exit(main())
