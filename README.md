# The Living Soil Encyclopedia

A five-book regenerative gardening reference written for North Texas: Zone 8b,
Blackland Prairie clay, alkaline pH, and chloraminated municipal water. 915
pages, 169 figures and photographs, free to read and free to redistribute.

**Status:** final rights closeout in progress. PDFs will be attached to the
first tagged release.

---

## The books

| # | Title | Pages | What it covers |
|---|---|---:|---|
| 1 | The Living Soil | 197 | Soil biology, the soil food web, mycorrhizal relationships, compost |
| 2 | Inputs and Amendments | 191 | Minerals, microbial inoculants, biochar, brews and ferments, soil recipes |
| 3 | Crops and Guilds | 199 | Rotation, companion planting, guild design, herbs, season extension |
| 4 | Plant Health and Defense | 183 | IPM, diagnostics, pest and disease identification, abiotic disorders |
| 5 | The Field Companion | 145 | Calendars, checklists, protocols, and reference cards for the garden |

Books 1 through 4 are the reference. Book 5 is the part you carry outside.

---

## Who it is for

Home growers and small-scale market gardeners working clay soil in a hot,
alkaline, long-season climate. Most regenerative gardening writing assumes the
Pacific Northwest or the Northeast. Very little of it survives contact with
Blackland Prairie clay in August.

The diagnostic chapters are built around a specific problem: distinguishing
abiotic injury from pest and disease damage. Cupped foliage gets blamed on
disease constantly when the actual cause is herbicide drift, cold, or fertiliser
burn. Getting that wrong wastes a season.

---

## A note on evidence

The book covers practices with very different evidence bases, from well
established soil biology to preparations that have never been through controlled
trials.

Where a practice is unregistered and unproven, the text says so in those words.
Claims about compost teas, KNF, JADAM, and biodynamic preparations follow a
consistent pattern: growers report a result, controlled evidence is limited.
That is a deliberate editorial rule enforced across all five books, not a
disclaimer bolted on at the end.

---

## How it was built

The manuscript is authored as semantic HTML and rendered to PDF with WeasyPrint.
One command builds all five books.

```bash
python build.py --list        # show what it found
python build.py --book 1      # build one
python build.py               # build all five
```

Requires Python 3.10+ and WeasyPrint. Output lands in `dist/`, with a build
manifest recording page count, file size, and stylesheet for every book.

### Repository layout

```
LSE_BOOK_[1-5]_*_WORKING.html      the five books, source of truth
assets/                            169 figures and photographs
print.css                          print stylesheet, page geometry and figure sizing
build.py                           build pipeline
verify.py                          content fingerprinting
LSE_MIRROR_SYNCHRONIZATION_LEDGER.csv
LSE_RIGHTS_LEDGER.md               image permissions, authoritative
INVENTORY/                         audit reports
```

### Content verification

A long reference assembled over months across multiple tools has two failure
modes that are easy to miss and expensive to discover late: text drifting
between revisions, and duplicated sections falling out of sync.

`verify.py` fingerprints the document's paragraphs so unintended changes surface
as a diff rather than as a surprise in the finished PDF.

Thirty sections are deliberately mirrored across books, because a grower reading
the pest chapter should not have to flip to the soil chapter for a definition.
Those are tracked in `LSE_MIRROR_SYNCHRONIZATION_LEDGER.csv`. The canonical copy
is edited and the mirror regenerated, never the other way around.

### Reproducibility

Every image the books reference resolves inside the repository. Nothing depends
on a path on the author's machine, an external host, or a link that can rot. A
fresh clone builds the identical set of PDFs.

---

## Images and rights

109 of the 169 figures were created by the author. The remainder are third-party
photographs, and each one is documented.

Photographs fall into three groups:

**Used by permission.** Photographs from Clemson Extension HGIC, the University
of Arkansas Division of Agriculture, and the University of Maryland Extension
Home and Garden Information Center, granted specifically for free
non-commercial educational use. The credit wording for each was agreed with the
rights holder and is reproduced exactly as agreed.

**Open licence.** Creative Commons and public domain photographs, credited to
the photographer with the licence named.

**Author-created.** Diagrams, decision trees, calendars, and reference cards.

`LSE_RIGHTS_LEDGER.md` is the authoritative record. Where a photograph could not
be cleared, it was replaced or removed rather than used on an assumption.

For pest and disease photography, correct species identification was treated as
non-negotiable. A misidentified organism in a diagnostic reference is worse than
a missing photograph, so every organism-identifying image was confirmed before
use.

---

## Licence

Text and author-created figures are released under
[CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/). Share it, adapt
it, build on it, as long as you credit the source and license your contributions
under the same terms.

**This licence covers the text and the author's own figures only.**

Third-party photographs are licensed separately and credited individually. Some
are under licences permitting non-commercial use only. Others appear by
permission granted for this work specifically, and those permissions do not
transfer. If you reuse this work, you are responsible for clearing each
third-party photograph independently or removing it.

This edition is free. It is not sold, carries no advertising, and generates no
revenue. Several permissions depend on that remaining true.

---

## Thanks

To Barbara H. Smith at Clemson Extension HGIC, Taylor Klass and Jason Pavel at
the Arkansas Plant Health Clinic, and Miri at the University of Maryland
Extension Home and Garden Information Center, who tracked down retired
photographers on my behalf rather than pointing me at a policy page.

Extension services are one of the few remaining sources of plant pathology
photography that names the cause rather than just the symptom. That distinction
is the reason several chapters in this book work at all.

---

## Corrections

Found an error, a misidentified organism, or a claim that overstates the
evidence? Open an issue. Diagnostic corrections are especially welcome.
