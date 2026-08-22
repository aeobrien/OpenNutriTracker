# Build 56 — the wrong food altogether

**Date:** 2026-08-23 (installed 00:49:45 BST, confirmed on the device at
00:49:58, both clocks read in the turn they were written)

Build 55 was on the phone for just over half an hour, unopened, and this
replaces it. Everything in build 55 is in build 56; one thing has been added.
The build 55 note stands as the record of what went on at 00:17 — read this
one for what is on the phone now.

## What is new since 55

**A row can be told it was the wrong food altogether.** Not the wrong amount of
the right food — the wrong food. Open the box that asks how much, and under the
amount there is now the food's name with "Change the food" beside it. That
opens the food list you already use, titled "Choose what it really was", and a
tap there hands the food straight back to the box instead of going on to ask
how much: the amount, the meal and whose day are already filled in on the box
that opened it, and asking again would log a second row on top of the
correction.

The amount is kept and every figure is worked out again from the new food. The
calories on screen move before anything is saved, which is the only way to tell
whether the food picked out of a list of similar names is the one that was
meant.

The Mac Mini is told the new name and the new figures, and told the row is no
longer the household food it was linked to. Unlinking is the only true thing
this phone can say about a food list it has never seen — it cannot name a
replacement in the house's own numbering.

## Two things the break-the-guards pass found, not the reading

**A recipe row was offered the swap.** It takes the same shape of box as a food
row — it has an amount and a unit — but its amount counts servings of a recipe,
and unlike a food row it shows the figures written down rather than working
them out. The swap would have read "two servings of shepherd's pie" as two
grams of bread and written that down as the truth. It is refused at the
repository now and not offered on the box, because an offer that can only end
in a refusal is worse than no offer.

**Nothing drove the food list's own card.** A source-level check can see that
handing the food back is written into it; it cannot see whether the
going-on-anyway underneath it still runs, which is one missing `return` away
from logging a second row on top of the correction. It is driven for real now,
both ways round.

Both are recorded because the pass found them, not because they were foreseen.
Two other breaks proved nothing on the first attempt: one because for a food
row the phone works its figures out live and never reads the ones written down,
which sent the search to the recipe row above; one because no test drove the
card at all, which is the second finding.

## Known limit

After a swap, putting an older version back restores the name and the figures
but not the house's link to its own food list, because a restore forwards only
label, amount, calories and owner. It affects no number anybody can see. It is
written down here rather than left to be found.

## What is left in release 7

Nothing that does not need Aidan. The one thing that does is BC-0026's proposed
default about halves of a shared meal — it is on the waiting list with the
rest.

Release 6's four planning pieces are still on the phone with no way to tap into
them, because they open from the week-ahead panel he took off on 20 August.
Unchanged since build 54, and still his call.

## Watched, not reasoned

The phone was on the network and locked. `devicectl device info apps` reports
`1.0.0 56` on the device. **It has not been watched opening** — every launch
attempt comes back "the device was not, or could not be, unlocked", which is
iOS refusing to open an app on a locked phone. Same wall as builds 54 and 55.
Step 1 of the walkthrough is that check, which is where it belongs.

## Tests

FoodTracker 988 passing (959 at build 55). Mantel 701 (697 at build 55; the
four new ones are the house accepting a row being unlinked from its food, and
refusing a food nobody here has).

## The walkthrough

`walkthrough-runs/2026-08-23-build-56-corrections-and-the-wrong-food/input.json`

Thirty steps: the twenty-eight written for build 55, with the version number in
step 1 corrected, plus two for the swap. The build 55 panel was never opened,
so nothing is lost by starting here.
