# Rights Blockers: Decisions and Drafts

Five blockers. Four are NC State and resolve as one conversation. One is MSU.

---

## Decision 1: ShareAlike

**This is yours to make and it unblocks the most.**

Several images carry a ShareAlike license (CC-BY-SA in various versions, plus one CC-BY-SA-GFDL, plus the two CC-BY-NC-SA NC State images). ShareAlike says derivative works must carry the same license.

The question is whether your book is a **collection** or a **derivative**.

| Reading | What it means | Consequence |
|---|---|---|
| **Collection** | The images sit alongside your text without being modified or merged into it | SA applies to each image only. Your text stays under whatever license you choose |
| **Derivative** | The book as a whole is built from the images | SA reaches your entire text. The whole book must be CC-BY-SA |

The usual position in publishing is collection, and it's the one most reference books rely on. It is arguable, not settled. What makes it safer in your case: you are not cropping, recoloring, compositing, or otherwise altering these images. They appear whole, with attribution, next to text that stands on its own.

**If you rule "collection":** the two CC-BY-NC-SA NC State REJECTs stop being blockers, since NonCommercial is satisfied by free distribution and ShareAlike stays contained to the images. Record the ruling in `LSE_RIGHTS_LEDGER.md` so it's traceable.

**If you rule "derivative" or you don't want the argument:** release your own text under CC-BY-SA 4.0 too. This costs you nothing under a free non-commercial model, ends the question permanently, and reads as a deliberate choice rather than an oversight.

I'd take the second option. You are giving the book away anyway. Licensing your text CC-BY-SA removes an entire category of argument, and on a portfolio piece "I thought about the license and picked one" looks better than "I relied on an interpretation."

Either way, decide before you flip the repo public.

---

## Decision 2: Email NC State

One email, four images. Reply on your existing July thread rather than starting fresh, so it threads with the original request.

**Before sending:** confirm the current contact. Your original went unanswered, which may mean it landed with someone who left or who didn't consider it theirs. Inga Meadows is credited on the Fusarium image and Frank Louws on the strawberry figure. Both are worth trying directly if the general address stays quiet.

```
Subject: Re: permission request, black root rot photo (and three more)

Hi,

I wrote back in July asking about one photo from the Black Root Rot of
Strawberry page and never heard back. No problem, I know these requests
are easy to miss. I'm following up, and while I'm at it I found three
more NC State Extension photos I'd like to ask about, so it's probably
easier to handle them together.

The four:

1. Figure SS-1 from Black Root Rot of Strawberry, the side by side of a
   healthy root system and one affected by black root rot. Credited to
   Leonor Leandro, Gloria Abad and Frank J. Louws.

2. The tomato Fusarium wilt photo showing vascular browning in a split
   stem. Credited to Inga Meadows.

3. Flumioxazin drift damage on tomato, the fruit necrosis photo.

4. Flumioxazin drift damage on tomato, the foliage and stem necrosis
   photo.

The project is a five book living soil gardening reference I've been
working on. It's free. Not sold, no advertising, no revenue. It's going
up online as a free PDF and a free web version.

I'd credit each one however you prefer. My default would be:

"Photo: [photographer], NC State Extension. Used by permission."

That would go under the image and again in the book's credits section.
If you'd rather I use different wording, I'll use exactly what you give
me.

If any of these belong to the photographers personally rather than to
Extension, just point me their way and I'll write to them directly.

And if the answer is no on any of them, that's completely fine. Just let
me know and I'll pull them.

Thanks for your time,
Damon Smith
```

---

## Decision 3: Email MSU

**You can't send this yet.** The filename says MSU but doesn't name a photographer or a source page. Find the original publication first. Search MSU Extension for basil Rhizoctonia root rot and match the image.

Once you have the photographer name and page title, fill the two brackets.

```
Subject: Permission request, basil root rot photo for a free gardening reference

Hello,

I'd like to ask permission to use one photograph from MSU Extension.

The image: basil with Rhizoctonia root rot, showing the darkened roots.
It appears in [page title].

The project is a five book living soil gardening reference. It's free.
Not sold, no advertising, no revenue. It's going up online as a free PDF
and a free web version.

Why this one specifically: root rot on basil is one of the easiest things
for a home grower to misread as a watering problem, and a clear photo of
the roots themselves does more than any description I could write.

How I'd credit it:

"Photo: [photographer], Michigan State University Extension. Used by
permission."

That would appear under the image and again in the book's credits
section. If MSU prefers different wording I'll use exactly what you
specify.

If the photographer holds the rights personally rather than MSU, I'd
appreciate a pointer to them.

Thanks for your time,
Damon Smith
```

---

## Fallback: what happens if nobody replies

Set a date. Two weeks is reasonable for a follow-up on an existing thread and a fresh request. Put it in `STATE.md`.

If a date passes with no answer, you have three options per image:

**Replace.** Look for an equivalent under CC-BY, CC0, or a US government public domain license. USDA, ARS, and Bugwood carry a lot of plant pathology imagery and much of it is cleanly licensed. This is the best outcome where it works.

**Drop the image, keep the content.** Rewrite the caption into a description and remove the figure. For diagnostic images this hurts, since the picture is the point, but it is not fatal.

**Drop the section.** Only if the section cannot stand without the image.

What you do not do is publish and hope. You have four institutional threads that went well because you asked properly. That is worth more than four photographs.

---

## Checklist

- [ ] Rule on ShareAlike, record it in `LSE_RIGHTS_LEDGER.md`
- [ ] Send the NC State follow-up on the existing thread
- [ ] Find the MSU source page and photographer, then send
- [ ] Set a reply deadline in `STATE.md`
- [ ] Re-run `Get-LseRights.ps1` after each resolution
- [ ] Rename files as status changes, so the filenames stop being stale
- [ ] Work the 23 "check" items in `rights_blockers.md`
