# The Living Soil Encyclopedia

A five-book regenerative gardening reference built around soil biology: how the
living system under your feet works, how to feed it, what to grow in it, and how
to protect it. Free to read and free to redistribute.

Many sections close with a North Texas note that applies the topic to hot
summers, alkaline clay, and chloraminated municipal water. Those notes extend
the general material; they are not the premise of it.

**Status:** final rights closeout in progress. PDFs will be attached to the
first tagged release.

---

## The books

| # | Title | What it covers |
|---|---|---|
| 1 | The Living Soil | Soil biology, the soil food web, mycorrhizal relationships, compost |
| 2 | Inputs and Amendments | Minerals, microbial inoculants, biochar, brews and ferments, soil recipes |
| 3 | Crops and Guilds | Rotation, companion planting, guild design, herbs, season extension |
| 4 | Plant Health and Defense | IPM, diagnostics, pest and disease identification, abiotic disorders |
| 5 | The Field Companion | Calendars, checklists, protocols, and reference cards for the garden |

Books 1 through 4 are the reference. Book 5 is the part you carry outside.

---

## Who it is for

Home growers and small-scale market gardeners who want to understand why a
practice works, not just follow it. The books explain the biology first and the
method second, so the reader can adapt a practice to their own soil and climate
instead of copying a recipe written for someone else's.

Growers in hot, alkaline, clay-soil regions get something extra: the North
Texas notes work through what changes when summer heat, high pH, and heavy clay
are the starting conditions.

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

### Content verification

A long reference assembled over months across multiple tools has failure modes
that are easy to introduce and expensive to find late: text silently dropped
during a revision, duplicated sections drifting apart, links decaying into
nothing.

`verify.py` is the contract that guards against those. It runs standalone, exits
nonzero on any failure, and is wired to a pre-commit hook so a broken set cannot
be committed.

Five hard checks:

1. **Paragraph preservation.** Every paragraph fingerprint captured at baseline
   still exists somewhere in the current set. This is the important one. It
   means content cannot quietly disappear during an edit.
2. **Duplicate IDs.** Zero duplicate `id` attributes per file.
3. **Dead internal links.** Every `href="#..."` resolves to an `id` in the same
   file.
4. **Cross-book links.** Every link to another book resolves to a file in the
   set, and to a real `id` if it carries a fragment.
5. **Mirror synchronization.** For each row of the mirror ledger, the canonical
   section text matches the mirror text once the mirror notice is stripped.

It also tracks metrics that warn rather than fail: word-count drift per file
against baseline, orphaned citation markers, and image and rights-marker counts.

Thirty sections are deliberately mirrored across books, because a grower reading
the pest chapter should not have to flip to the soil chapter for a definition.
The canonical copy is edited and the mirror regenerated, never the reverse.
Check 5 is what makes that safe.

HTML is parsed with BeautifulSoup rather than regex. Regex is applied only to
already-extracted plain text.

### Reproducibility

Every image the books reference resolves inside the repository. Nothing depends
on a path on the author's machine, an external host, or a link that can rot. A
fresh clone builds the identical set of PDFs.

---

## Images and rights

Most figures were created by the author. The rest are third-party photographs,
and every one is documented in `LSE_RIGHTS_LEDGER.md`, which is the
authoritative record.

Each book's Image Credits section sorts photographs into four groups:

**Used by permission.** Granted specifically for free non-commercial educational
use by Clemson Extension HGIC, the University of Arkansas Division of
Agriculture, the University of Maryland Extension Home and Garden Information
Center, MSU Plant & Pest Diagnostics, and the Bugwood Image Database at the
University of Georgia. Credit wording is reproduced exactly as agreed with each
holder.

**Reproduced with attribution.** Where a permission request went unanswered by
publication, the photograph is credited to its source in a separate section,
with an offer to remove it on request.

**Open licence.** Creative Commons and public domain photographs, credited to
the photographer with the licence named.

**Author-created.** Diagrams, decision trees, calendars, and reference cards.

Photographs that could not be cleared on any of those terms were replaced or
removed.

For pest and disease photography, correct identification was treated as
non-negotiable. A misidentified organism in a diagnostic reference is worse than
a missing photograph, so replacements were chosen only where the source names
the confirmed cause, not just the symptom.

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
the Arkansas Plant Health Clinic, Miri at the University of Maryland Extension
Home and Garden Information Center, who tracked down retired photographers on my
behalf rather than pointing me at a policy page, and Jan Byrne at MSU Plant &
Pest Diagnostics. And to the Bugwood Center at the University of Georgia, whose
image database made several diagnostic plates possible.

Extension services are one of the few remaining sources of plant pathology
photography that names the cause rather than just the symptom. That distinction
is the reason several chapters in this book work at all.

---

## Corrections

Found an error, a misidentified organism, or a claim that overstates the
evidence? Open an issue. Diagnostic corrections are especially welcome.
