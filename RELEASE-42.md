# Build 42 — what changed, and what did not

**Date:** 2026-08-21
**Branch:** `household-release-1` · **Head:** `7e22651` · **Version on the phone:** 1.0.0 (42)

The copy you had was numbered 41. So was the one before it, and the one before
that — every build of this app has been 1.0.0, which is why nobody could tell
you today which one you were holding. That is fixed in this build: the version
line in Settings now reads **Version 1.0.0 (42)**, and every future build will
say its own number.

## The four you reported

These are the four the walkthrough asks you to check, and they are the reason
this build exists.

1. **Tapping a row did nothing.** Anything spoken, and anything the house sent
   over, arrived as a row with no food behind it, and the tap handler gave up on
   the first line for exactly those rows. It now opens the same box every other
   row opens, in the shape that row actually has. Three things were broken
   underneath it and are fixed with it: the correction was being sent under a
   name the kitchen computer had never heard of, so it answered "no such row"
   and nothing told you; the sentence you had said was fetched and thrown away
   rather than shown to you; and moving a row to Emily put it on her day at the
   house and left it sitting on your phone as well.

2. **The ring kept showing the old number after a correction.** Changing 350 to
   175 sent the change, wrote it to the phone's own store, and then redrew the
   screen without waiting for either — so the redraw won the race and painted
   the figure you had just changed. It now waits.

3. **Holding a row to delete it put its calories straight back.** The same fault
   as (2), on the hold-to-delete path for food and for exercise. Both now wait.

4. **Undo was offered on rows the house had put there.** Taking that offer
   rebuilt the food on your phone and left the row still retired at the house,
   so the two sides disagreed about your day. The offer is now made only for
   rows this phone itself made. Nothing became unremovable — the swipe still
   works on a house row, it just does not offer to reverse it.

## Also in this build, and probably not on your phone

I cannot tell you exactly which build your phone was holding, because they were
all numbered 41. Judging by what you described on Thursday, it was made that
morning — which means all of this came after it. You re-tested most of it with
me on Thursday afternoon, so it is listed for completeness, not for testing.

- Spoken food goes into the meal slots and counts towards the day, instead of
  sitting in a list of its own with the ring ignoring it.
- One list of food on Home, and it is the diary. The second copy of the week and
  the planned-meals list came off the phone at your instruction.
- Where "Trending 82.4kg" came from, and why no number sits under your weight
  until there are enough weigh-ins to draw a line.
- A weight typed on the phone goes to the house now rather than next time.
- A weight typed twice in a day: the second one is the answer.
- Setup is skipped when the house already knows you; a first run with no address
  says so instead of spinning.
- The ways into adding food stop falling off the bottom of the screen.
- The packet row promises the shot the camera actually asks for.

## What is not fixed

**The two waits in (3) are not proved.** I put the fix in, took it back out, and
ran the same checks against the broken build — and they passed anyway. The
timing fell the right way on my machine. So those two paths work; whether the
wait was needed on them I cannot tell you from what I ran. The correction path
in (2) is different: I watched that one show a stale figure before the fix and
the right one after. Proving the other two needs a test that controls the
timing rather than a check that hopes for it, and that does not exist yet.

**Everything today ran against a stand-in kitchen computer on my Mac, not the
Mac Mini.** Your phone talks to the Mac Mini. The Mini is up and running the
right version, and the half of each fix that lives there was already in place —
but this build has never been down the real wire until you do it.

**Batch cooking, the shopping list and meal components — steps 22 to 25 —
stand exactly as you found them.** "There are no amounts" is still true, and
"put it on the shopping list" is still on a page where you doubted it belonged.
That work was stopped, and it stays stopped.

**Your backfill question is still unanswered.** Whether meals logged before
today get counted or stay as they are is your decision and nobody has made it.

**Four of your steps were never tested by anyone, because there was nothing to
test them with.** The week ahead and taking a meal off it (steps 14 and 17)
needed planned meals, and there were none. The barcode scan of something already
in the house list (step 19) came after a step you could not start. And the last
step — the phone and the panel agreeing about the same day — you declined, which
was fair.

**Undo across the house is not implemented, it is withdrawn.** A row the house
put on your day can be removed but not undone. Un-retiring at the house is a
decision about what should happen, not a bug, and it has not been made.

**The kitchen tablet steps are still untested** — it was not available when you
tried, and it has not been picked up since.
