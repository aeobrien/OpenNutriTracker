# Build 43 — what changed, and what did not

**Date:** 2026-08-21
**Branch:** `household-release-1` · **Head:** `e0d85fa` · **Version on the phone:** 1.0.0 (43)

Build 42 was a big one. This is a small one: it fixes the single thing you found
by using 42, and it clears two rows off your day. Settings will read
**Version 1.0.0 (43)**.

## The one thing that changed

**Undo was not offered on rows you had spoken into your own phone.**

You caught this in the walkthrough: *"This makes no sense. Step 1 was on the
phone — logging an item here would come from the phone, not from the House."*
You were right, and the reason is worth a paragraph because it explains why the
fix is shaped the way it is.

Build 42 decided whether to offer Undo by asking "did this row come from the
house?" But a sentence you speak into your phone also goes to the house and
comes back down the same pipe, in the same shape, as a sentence Emily speaks at
the kitchen panel. From the row alone the two are identical — so your own words
were being treated as somebody else's.

The phone now writes down what it does at the moment it does it, and checks that
record once as each row comes back. Nothing is guessed from where the row
arrived.

**The rule you asked for is kept.** A row that genuinely came from the kitchen
panel still offers no Undo — that was the whole point of the rule, and a fix
that handed Undo to everything would have satisfied the complaint on Monday and
cost you the thing you wanted on Tuesday. Both directions were run before this
build was made: with the old rule your own row loses Undo (your complaint,
reproduced), with Undo given to everything the panel's row wrongly gains one,
and only the rule as written passes both.

## Also done, but not in the build

**The two "Something you said" rows with no calories are off your day.** They
were the two sentences from 16:52 that sat in the phone's outbox while the
address was wrong, went over once you fixed it, and were never worked out
because the phone had already stopped waiting. They were taken off at the house,
through the same route the app uses to remove a row, and your 21 August now
reads back with one row on it (butter, 74). Nothing on the phone was needed for
this and nothing about it needs testing.

## What is not fixed

- **Rows already on your phone will still not offer Undo, even ones you spoke.**
  The phone has no record of what it did before this build, and the honest
  answer to "was this mine?" for an old row is "I don't know" — which withholds
  the offer rather than making it over somebody else's row. So to check this,
  log something new. An old row behaving as before is not a fault.
- ~~**There is one more "Something you said" row, on 20 August.**~~ You said
  clear it, and it is gone, the same way as the other two and checked the same
  way. There are none left on any day.
- **Photographing a packet still has no finish — in this build.** Your words:
  *"there was no success message… Everything went grey and I had to hit back."*
  It has been looked at now, and it turned out to be three separate silences
  rather than one; all three are fixed, but the fixes are in the **next** build,
  not this one. This one behaves exactly as 42 did on that screen. See
  RELEASE-44.
- Everything else in build 42's "What is not fixed" list still stands: batch
  cooking, the shopping list and meal components are untouched; the question
  about backfilling old days is unanswered; the kitchen-tablet steps are
  untested.
- **One thing from that list has come off it.** Build 42 said the two waits
  behind hold-to-delete were unproved — they looked right and I could not watch
  them work. They are proved now, by a check that holds the removal open so the
  screen can be caught in the act of waiting. Nothing in the app changed for
  it; what changed is that I can now say it works rather than that it reads
  correctly. You confirmed both on your phone already, so there is nothing here
  for you to test.
- **The limit from this morning is narrower now, and I should say exactly how
  narrow.** Most of today's work ran against a throwaway Mantel on my own Mac.
  The Undo fix no longer has that limit: I ran the same end-to-end check against
  Mantel *on the Mini* — the same code your phone talks to, reporting the same
  version — on a copy of its database, so nothing of yours was written to. It
  passed there too, and your own day was read back before and after and is
  unchanged. What has still not happened is build 43 itself going down the real
  wire from your phone to the Mini, and that only happens when you use it.
