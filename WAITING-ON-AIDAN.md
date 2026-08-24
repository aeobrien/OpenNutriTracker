# What is waiting on Aidan

> **Nothing to walk right now.** Build 57 is walked and answered; the build-53
> panel you opened by mistake on Saturday is answered too. The next walkthrough
> will not be put in front of you until there is a build worth walking, and you
> will be told plainly what it covers.

**Date:** 2026-08-24 12:31 (clock read in the turn this was written)

Everything you recorded on build 57 is either fixed and proved, or written down
below with the reason it is not being fixed yet. The full step-by-step is in
`WALKTHROUGH-57-VERDICTS.md` alongside this file; this page is only the things
that need you.

---

# Decisions — nothing moves on these until you rule

## 1. The two amendments to your own plan

Both are changes to gate-approved cards, so they are yours to open, not mine to
edit. The findings are written up; the wording is proposed; nothing has changed.

**J-0005's closing sentence flattens three days into one.** You spotted this
yourself: *"buying the ingredients happens before the breakfasts are made. They
are two completely separate steps."* The journey's steps have the order right —
shopping list at step 4, making the jars at step 5 — but its closing sentence
puts the jars, the shopping line and seven mornings in a single breath, and the
roadmap's release-8 gate copied that sentence word for word. I also found the
same flattening in the journey's opening line, which sits them down *"on a
Sunday afternoon, with a stack of mason jars"* while step 4 is still a buying
action. Proposed rewording and the full working:
`~/Dev/Mantel/ledger/plans/2026-08-24-release-8-gate-and-the-J-0005-mismatch.md`.

**BC-0023 still says "the whole of the current week".** You said fourteen days.
The code says fourteen days and records whose decision it was; the card has said
the old thing since Saturday.

## 2. The cook-ahead page — what it should be, before anything changes

Your step-17 question has a written answer at
`~/Dev/Mantel/ledger/plans/2026-08-24-what-the-cook-ahead-page-is-for.md`, and
an addendum where your release-8 paragraph answered it from the other end.

**Where I was wrong.** I said the page does two things — works out what to cook,
and builds the buy list. You said those are two separate steps run together. You
are right, and the code is blunter than either of us was: the number you type
beside a meal is not kept anywhere. Press the button and the shopping lines
survive; the cooking totals do not survive closing the page. Come back on the
Sunday you actually cook and the box says 1 again.

**What I think it should be, and it is your call.** Not two pages — the two
moments share one decision and splitting it would ask the same question twice.
One page that remembers the number, so the sheet still says 7 when you open it
to cook. That needs a small store on the Mac Mini and a rule for when a count
stops being current. It does **not** mean counting jars; BC-0027's decision
against stock counting is untouched.

**Three smaller drifts from the card, also yours:** the card calls it *"Cook
ahead"* and the panel calls it *"Make a batch"*; the card says it opens from a
recipe's own screen too, and the panel offers it only from the plan; the card
says it is for meals planned more than once, and the panel offers it always.

## 3. A food with calories but no protein, fat or carbohydrate

You hit this on Saturday: your own hand-typed fish cakes could not be put on
your day, because the amount screen demanded all four figures and switched off
the Add button and the amount box together.

**It now accepts calories alone** and says on screen that protein, fat and
carbohydrate will count as zero for the day. That sentence is the part worth
arguing with: it means your day's protein figure is short by whatever was really
in the food, and the app cannot know by how much. The alternative is the form
insisting on all four before it will save anything. I took the first because a
food you cannot log at all is worse than a macro figure that says it is
incomplete. **Say if you would rather have the second.**

## 4. Where your food search comes from

Open Food Facts' search has been down since Saturday — that is their machine,
not ours. Barcodes still work. Their separate search service answers correctly
right now and we could move to it, but it is a different machine and a different
shape of answer, and there is a prior question: whether a public database going
down should ever be able to empty your food search, or whether the house's own
list plus the barcode scanner is what you actually rely on. **Say which and I
will build it.**

The app's own share of that fault is fixed: it used to throw away household
results it already had when the internet call failed. It does not any more.

## 5. Two smaller ones

**"Recently" shows nothing.** It is built from your past entries and
deliberately skips anything spoken or quick-added — which is how you log most
things, so for you it will usually be empty. Probably working as designed, and
probably the wrong design for you. Written down, not built.

**One split peanut-butter row on your phone.** A single entry from Saturday's
shared-meal bug is still half-on-your-day. The bug is fixed; this one row is
left as it is. Say if you want it repaired.

---

# Ruled this morning, and now in the code or the plan

1. **Release 8 closes on the app performing the one-tap logging** — *"so we'll go
   with option 2"*. Not on seven mornings happening. The roadmap's release-8 gate
   now says what the software must do and can be checked in a sitting, with your
   approval still on top. **One thing in it needs settling and is flagged there:**
   J-0005's own step 6 says the morning tap is BC-0010, which release 3 already
   built — so on that reading there is nothing new to build and the release
   closes when you check it. My earlier option 2 described a new "log the batch"
   behaviour the journey never asks for. I think the journey's reading is right.
2. **"The sentence works."** *"Couldn't work out what this one takes."* stands,
   and the temporary `?batchdemo=1` switch that let you see it has been removed.
3. **"veg is currently limited to 2, that shouldn't be the case."** The cap is
   gone from all three places it lived — your phone, the kitchen panel, and the
   Mac Mini's own normaliser. The last one mattered most: without it the phone
   would have offered a third vegetable and the Mini would have silently thrown
   it away.
4. **Protein sub-types written down, not built** — *"for chicken,
   breasts/thighs, for beef, is it mince, steak"*. It is in Mantel's roadmap as
   future work, with a note on why it is bigger than a dropdown.
5. **Your standing instruction recorded** — *"we need to make sure that things
   like that aren't making it through unchallenged."* A criterion that does not
   make sense gets challenged where it is found, not built to.

## Fixed since you walked, and proved by breaking the test first

The moving bug (half a shared meal moving off your day), the amount box on a
food with calories only, the caption that stopped mid-word, the plan page
loading empty on first open, the sheet rendering a third of the width, and the
food search discarding household results when the internet failed. Each one has
a test that was deliberately broken to check it holds. Details per step in
`WALKTHROUGH-57-VERDICTS.md`.

## Two things that are written and unproven on a real phone

**Step 13 of the build-53 panel is now walkable.** It checks that the amount box
opens on what you ate last time rather than starting from scratch. It could not
be walked before because the Add button was dead. It has not been walked.

**Nothing here has been on your phone.** The Mac Mini has today's panel changes
and they are verified live on it. The phone changes are committed and tested and
are not on a device.

## One thing that is not held by a test, said out loud

Both machines check *"is the person you are moving it to holding the other
half"*. In a two-person household that cannot disagree with *"is anybody holding
it"* — the only person you can move a row to is the only person who can have it.
So the precise form of that check is not held by any test, and manufacturing
data the app cannot produce would not hold it either. It stays because it is the
rule the card states.
