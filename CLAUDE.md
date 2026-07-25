# CLAUDE.md — Living Soil Encyclopedia

Save this as `CLAUDE.md` in the repo root. Claude Code reads it automatically at the
start of every session, so these rules apply to every formatting and editing pass
without you restating them.

---

## What this project is

A five-book gardening reference, ~310,000 reader-facing words, currently in working-draft
state after a large automated restructuring. The goal is publish-ready. These are real
manuscripts headed for print and sale — not scratch files.

| File | Words | Scope |
|---|---:|---|
| `LSE_BOOK_1_THE_LIVING_SOIL_WORKING.html` | 60,994 | Soil biology, methodologies, water, infrastructure |
| `LSE_BOOK_2_INPUTS_AND_AMENDMENTS_WORKING.html` | 72,459 | Composts, minerals, inoculants, brews |
| `LSE_BOOK_3_CROPS_AND_GUILDS_WORKING.html` | 74,674 | Crop profiles, companion planting, herbs |
| `LSE_BOOK_4_PLANT_HEALTH_AND_DEFENSE_WORKING.html` | 53,276 | IPM, pests, diseases, biological controls |
| `LSE_BOOK_5_FIELD_COMPANION_WORKING.html` | 48,604 | SOPs, appendices, quick reference |
| `LSE_INTERNAL_PRODUCTION_HOLD.html` | 7,409 | **Not reader-facing.** Held/superseded content. |

---

## Non-negotiable rules

### 1. `verify.py` is the contract

Run it before you start and after every change. If it fails, stop and fix — do not
proceed, do not work around it, do not edit the checker to make a failure go away. If you
believe a check is wrong, say so and wait for a decision.

### 2. Never edit a mirror directly

Thirty blocks of content are duplicated across books by design, tracked in
`LSE_MIRROR_SYNCHRONIZATION_LEDGER.csv`. Fifteen canonical sources live in Book 4 and
fifteen in Book 5; mirrors appear in Books 1, 2, 3, and 4.

Mirrors carry this notice and are marked `class="mirror-entry"`:

> Synchronized mirror — do not edit independently. Canonical text: Book N. Mirror location: Book N, Chapter N.

**Edit the canonical copy, then regenerate the mirror from it.** Editing a mirror puts
two books into silent disagreement — the single most likely way this project breaks
without anyone noticing. If a change affects mirrored content, say so before making it.

### 3. Never invent a citation

There are 125 orphaned `[n]` markers in the manuscript (106 in Book 1, 19 in Book 5).
The reference entries they point to must be recovered from the original `_SOURCE` files
or supplied by the author.

**Do not generate, guess, complete, or "reconstruct" any reference, DOI, author, year,
or journal name.** A fabricated citation in a technical reference is worse than no
citation. Anything that can't be resolved from a real recovered source goes into an
exception report for the author to handle by hand.

### 4. Preserve safety-critical content exactly

Do not reword, condense, soften, or relocate without explicit approval:
- `North Texas Note` blockquotes — region-specific guidance
- `Safety Box` blockquotes — handling and application warnings
- Product-label override language
- Application rates, dilutions, intervals, and re-entry guidance

This book instructs people to mix and apply pesticides and fungicides near edible crops.
Treat every number in that context as load-bearing.

### 5. Parse HTML, never regex it

Use BeautifulSoup. Regex substitution across 300,000 words of nested markup will
silently corrupt structure in ways `verify.py` may not catch. No exceptions.

### 6. Preserve anchor IDs

IDs are the link substrate for cross-book references and TOC page numbering. Don't
rename or drop an `id` unless the task is specifically about IDs. If a section moves,
its ID travels with it and any inbound links get updated in the same commit.

### 7. Nothing leaves the production hold, and nothing gets deleted from it

`LSE_INTERNAL_PRODUCTION_HOLD.html` is the archive of removed and superseded content.
Never delete from it. Never reintroduce content from it into a reader-facing book
without explicit approval.

---

## How to work

**Propose before bulk edits.** Anything touching more than ~10 locations gets described
first — what changes, where, how many instances — and waits for approval. Show a sample
of two or three before applying at scale.

**Script it, don't generate it.** Most remaining work is deterministic: citation
remapping, image auditing, front-matter templating, TOC page numbers, index term
extraction. Write a script, run it, show the output. Reserve model-generated prose for
tasks that are genuinely editorial, and flag clearly when you're doing that.

**One book per commit.** Don't fan a single change across all five books in one commit —
it makes review and revert impractical. Commit messages state what changed and how many
instances.

**Report exceptions, don't resolve them silently.** When a script can't handle a case,
it goes in a report. Never fall back to a guess to keep a run clean. A partial result
with a clear exception list is the correct output.

**Ask when the manuscript contradicts itself.** Two books disagreeing on a rate, an
interval, or an identification is an author decision, not a merge conflict to resolve by
picking one.

---

## Print production constraints

- `lse_five_book_working.css` is shared by all five books. A change affects everything —
  never edit it for a one-book problem.
- TOC classes `toc-part`, `toc-chapter`, and `toc-section` drive `target-counter` page
  numbering. Don't rename or restructure them.
- Rendering target is WeasyPrint. Verify against actual PDF output, not browser preview —
  they diverge on paged-media features.

---

## Publication blockers still open

Context for scoping, not a task list:

- **Image rights.** 169 image references, 83 `◆` markers, none final-cleared.
  `◆ REPL` = must be replaced, `◆ SA` = ShareAlike/copyleft review, `◆ ATTR` =
  attribution chain unresolved.
- **Citations.** 125 orphaned markers.
- **Placeholders.** 63 remaining, including the Product Label/Regulatory and
  Legal/Local/Water appendices.
- **Front matter.** All five books still carry private-edition language
  ("not public/sold publication-ready", marker legends, evidence-status notices).
- **Legal review.** Disclaimer and liability language requires an attorney. Not a task
  for Claude Code — flag and route to the author.

---

## Assumption

This is written as the standing guardrail file for all formatting and editing work in
the repo — the Claude Code equivalent of project instructions. If you instead wanted a
one-shot task prompt for a specific next editing job, say which job and I'll write that
separately; this file would still be worth dropping in either way.
