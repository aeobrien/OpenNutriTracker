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
- **There is one more "Something you said" row, on 20 August.** You said to
  clear the two on today, so that is what I cleared. Say the word and it goes
  the same way.
- **Photographing a packet still has no finish.** Your words: *"there was no
  success message… Everything went grey and I had to hit back."* Recorded, not
  chased — nobody has looked at it yet.
- Everything in build 42's "What is not fixed" list still stands, unchanged:
  batch cooking, the shopping list and meal components are untouched; the
  question about backfilling old days is unanswered; the kitchen-tablet steps
  are untested.
- **The limit from this morning still applies to the app work.** Everything I
  drove today ran against a throwaway Mantel on my own Mac, not the Mini. The
  one exception is the two cleared rows, which were done on the Mini itself and
  read back from it.
