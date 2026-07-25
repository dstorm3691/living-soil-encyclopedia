# Phase B — Exception Report

**Status: Phase B completed cleanly. No check failed.** `verify.py` is green on all
hard checks at the final commit (paragraph preservation, duplicate IDs, dead internal
links, cross-book links, mirror sync). This document is the durable record of everything
**held, deferred, or unresolved** in Phase B — written for a reader (the owner) returning
months later with no memory of this session.

Phase B did three things: extracted 98 chapter references from the two SOURCE volumes,
verified each against CrossRef, then (a) stripped 128 orphaned `[n]` citation markers and
(b) added 9 per-chapter *Further Reading* lists built only from references that verified.
The reasoning for "Further Reading instead of rebuilt numbered endnotes" is at the bottom
under **Decisions**.

Artifacts: `references/extracted.json`, `references/verification.json`,
`references/verification_report.md`, `references/marker_removal_log.md`, and the scripts
under `scripts/` (`extract_references.py`, `verify_references_crossref.py`,
`strip_markers.py`, `build_further_reading.py`).

---

## 1. Held for manual confirmation

### Epstein 1997 — *The Science of Composting* (Chapter 9, Ingham / Soil Food Web)
Excluded from Further Reading; needs a human to confirm the work exists.

- CrossRef, queried on the citation, returned **Epstein's *different* 2011 book,
  *Industrial Composting*** (DOI `10.1201/b10726`), not the cited 1997 title.
  Right author, wrong work.
- Held because **"right author, wrong work" is exactly the shape a fabricated entry takes
  when it slips past verification.** A match to his 2011 book tells us nothing about whether
  the 1997 title exists. Confirm against a library catalog or the physical book, then either
  add it to the Chapter 9 list by hand or drop it.
- Entry id: `volume_1-b5-n4`. Verbatim source text:
  `Epstein, E. (1997). The Science of Composting. CRC press.`

### The three `verified_weak` entries
`verified_weak` = reached "verified" only via a **moderate title match (0.45–0.60) plus a
first-author surname match, with no resolved DOI**. The author matcher is load-bearing here,
so these stay visible for scrutiny. All three matched the *correct author's real work*:

| id | chapter | source | CrossRef matched | why weak |
|---|---|---|---|---|
| `volume_1-b4-n13` | Ch 8 Regen/Permaculture | Wardle, D. A. (2002). *Communities and Ecosystems…* | *Communities and Ecosystems* (2013, DOI `10.1515/9781400847297`) | title 0.505, author ✓, year ✗ — his own book, a later DOI edition. **Released** (published). |
| `volume_1-b5-n5` | Ch 9 Ingham | Ryckeboer, J., et al. (2003). *A survey of bacteria and fungi… during composting…* | *Microbiological aspects of biowaste during composting…* (2003, DOI `10.1046/j.1365-2672.2003.01800.x`) | title 0.473, author ✓, **year ✓** — same author, year, topic. **Released** (published). |
| `volume_1-b5-n4` | Ch 9 Ingham | Epstein, E. (1997). *The Science of Composting.* | *Industrial Composting* (2011, DOI `10.1201/b10726`) | title 0.565, author ✓, year ✗ — **different book, same author. HELD** (see above). |

---

## 2. Chapters with markers but NO Further Reading

Markers appeared under 21 headings across Books 1 and 5, but only **9** had a recoverable
"Key References for This Chapter" block in the SOURCE volumes. The rest carried inline `[n]`
markers whose **source reference list never existed in recoverable form** — the earlier
cleanup pass that removed the reference blocks left the markers behind, and for these
chapters there is nothing to recover. Their markers were still stripped (correct); they
simply get no Further Reading list.

Three chapters (Book 1), **18 markers total**, all bacteria/fungi/protozoa/ratio material:

| Chapter | markers | representative marker-bearing subsections |
|---|---:|---|
| **Book 1 Ch 2 — Bacteria: Decomposers and Cyclers** | 5 | Morphology and Function; Nitrogen Fixation: Free-Living vs. Symbiotic; Bacterial Dominance and Weed Pressure |
| **Book 1 Ch 3 — Fungi: Networkers and Translators** | 6 | Hyphal Networks; Fungal Suppression: The Cost of Tillage and Phosphorus; Saprophytic Fungi: The Heavy Decomposers; Soil Structure Engineering: Glomalin and Macroaggregates |
| **Book 1 Ch 5 — The Predator Tier and Successional Ecology** | 7 | Protozoa: Flagellates, Amoebae, and Ciliates; Microarthropods: The Shredders; The Nutrient Loop: Predation and Mineralization; Matching F:B Ratios to Crop Types |

**Also note:** there were **125 single-number markers against only 98 extracted references** —
**27 markers had no matching reference even before removal.** The per-block numbering also
restarts at `[1]` in every chapter, so the same `[3]` means different things in different
chapters. Rebuilding numbered endnotes from this is not reliably possible; that is why the
approach was Further Reading, not reconstructed citations.

---

## 3. Book 5 electroculture chapter — two structural problems (Phase E)

Both belong to **Book 5, Chapter 2: "Electroculture and Plant Electrophysiology"**
(id `h2-chapter-18-electroculture-and-plant-electrophysiology`).

### 3a. Duplicate heading title
Two headings share the title *"What We Know vs. What We Don't Know"*:

- an **`<h4>`** mid-Section-2, id **`h3-what-we-know-vs-what-we-dont-know`**
- the real **`<h3>` "Section 5: What We Know vs. What We Don't Know — Closing Summary"**,
  id **`h2-section-5-what-we-know-vs-what-we-dont-know-closing-summary`**, later in the chapter

Title-matching grabbed the `<h4>` (wrong); paragraph-content matching points to the `<h3>`
Section 5. The duplicate title should be disambiguated in Phase E.

### 3b. Scrambled section order (template appended after the narrative)
"Section 5 — Closing Summary" is **not** the last section. It is followed by *Interactions
and Pairings*, *When to Avoid It*, *How to Check Your Results*, *Related Topics*, two `LSE-`
encyclopedia entries (LSE-129, LSE-130), and two practitioner notes. It looks like an
encyclopedia-entry template was appended after the narrative chapter ended.

**Because of this, the electroculture Further Reading list is anchored at the CHAPTER END
(before "Chapter 3: Paramagnetism in Soils"), not at its content-correct home in Section 5.**
Other chapters may carry the same template-append pattern — **worth a scan in Phase E, not
now.**

---

## 4. Deferred to later phases

- **63 reader-visible bracket placeholders** (front-matter / image phase), all non-citation
  brackets that `MARKER_RE` correctly left untouched:
  - 42 × `[IMAGE APP-*: …]` image-generation briefs
  - 11 × `[TEXT-ONLY SUBSTITUTE — B30_*]`
  - 10 × `[SELF-PHOTO PLACEHOLDER — SP-*]`
  - The **11 + 10 = 21** (B30_* + SP-*) are the **same 21 empty figure sections the image
    session found** — record once, **do not double-count** later. Full list in
    `references/marker_removal_log.md` (Known open item section).
- **Mirror heading divergence (4 pairs)** — the same mirrored SOP appears under two titles
  (the mirror adds an `LSE-NNN —` prefix, or orders the "SOP" token differently). Already a
  report-only tracking metric in `verify.py`; restate here as a **Phase E TOC concern**, not
  a sync error (the section *bodies* are in sync, 30/30).

---

## 5. Harness blind spots — read this before trusting "green"

`verify.py` fingerprints **only `<p>` elements of 12+ words** for its paragraph-preservation
check. It does **not** track:

- **`<li>` and `<td>` content.** 45 of the 128 stripped markers lived in list items and
  table cells — those edits did not move a tracked hash.
- **The Further Reading blocks just added.** The `<p><strong>Further Reading:</strong></p>`
  label is under 12 words, and the `<li>` reference items are not tracked at all.

**Consequence, stated plainly: deleting all nine Further Reading blocks — or any list item or
table cell — would pass every hard check silently.** Green is NOT proof of preservation for
structured content (lists, tables, the reference blocks). Closing this gap (extending the
fingerprint to `<li>`/`<td>`, or hashing the Further Reading blocks) is **Phase E work.**
Until then, treat structured content as unprotected and review it by eye after any pass.

---

## 6. Decisions made, and why

- **Field completion (the one exception to "never fill a field").** Tripathi 2020
  (`volume_1-b1-n1`) had author + DOI but no title in the source. Its DOI resolved with
  matching author and year, so the title was filled **from the authenticating CrossRef
  record** — *"Influence of synthetic fertilizers and pesticides on soil health and soil
  microbiology."* This is completion from the authenticating source, not enrichment, and it
  is the **only** entry where a field was filled.
- **Cross-chapter works unified to the fuller rendering.** Neumann 2007, Pieterse 2014, and
  Cameron 2013 appeared in more than one chapter, with a DOI in one and not the other; the
  DOI-bearing rendering is used in every chapter. (Roy-Bolduc 2011 was expected to differ but
  had **no DOI in either** Ch 1 or Ch 6 — identical, nothing to unify.)
- **DOI prefixes normalized** to a single `https://doi.org/` form across all nine lists
  (formatting only).
- **Why Further Reading, not rebuilt numbered endnotes.** Per-block numbering restarts at
  `[1]`, so the same `[3]` means different works in different chapters; 125 markers against 98
  references; 27 markers with no matching reference at all. Mapping a citation to the wrong
  claim is worse than no citation. Further Reading is honest about what the sources support.
- **Subsection-level placement.** During restructuring, most SOURCE chapters became `<h3>`
  subsections of fewer Book-1 chapters (five methodology topics now live under "Chapter 6:
  Schools of Practice"). Attaching at chapter level would merge distinct topics' references
  (e.g. permaculture with KNF/JADAM); subsection level keeps each list topic-accurate.
- **`<p><strong>Further Reading:</strong></p>` instead of `<h3>`.** Seven anchors are already
  `<h3>`; an `<h3>` label would be a sibling that structurally ends the subsection and would
  add nine "Further Reading" entries to the TOC. The `<p><strong>` pattern mirrors the removed
  "Key References for This Chapter:" blocks, nests under any anchor depth, and adds nothing to
  the TOC.
- **Anchors matched on content, not title.** Chapters were renamed and renumbered during
  restructuring (the movement ledger's source IDs no longer match the current headings), so
  anchors were located by paragraph-hash overlap between each SOURCE chapter and the 5-book
  set. Only the mycorrhizal chapter matched the movement ledger directly.
- **Electroculture anchored at chapter end** — see §3b.
