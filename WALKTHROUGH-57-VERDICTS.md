# Build 57's walkthrough: what happened to each thing you found

**Date:** 2026-08-24

You walked eighteen steps on the morning of 24 August: twelve passed, six
failed, and several of the passes carried a complaint. This is one line of
where each of those stands. It is added to as each is worked, so anything not
listed here yet has not been reached.

---

## Step 17 — what the "make a batch" page is for

**Answered in writing, no code changed.** The full answer is at
`~/Dev/Mantel/ledger/plans/2026-08-24-what-the-cook-ahead-page-is-for.md`.

The short of it: it is the second thing you guessed — cooking several of
something in advance — and it looked like the first because you opened it with
one of each meal on the week, where multiplying an ingredient list by one gives
back the list you already had. Put 5 in the box beside a meal and the top half
of the screen becomes the thing it is for.

Three ways the built page has drifted from its card, none of them behaviour:
its card calls the button "Cook ahead" and the screen a prep sheet; its card
also opens it from a recipe's own screen and by voice; and its card offers it
only for meals the plan asks for more than once, which is exactly the case you
were not in. **The name is the one worth changing and it is your call.** I have
not changed it.

## Steps 10, 11 and 12 — "it moved it off my day"

**Fixed and proved.** The refusal was there and no screen in the app could
reach it. It read `if (ledger == null) return null`, and that argument is
supplied only by tests — so the guard passed six tests and let every real
person through. It now finds its own ledger, and the new test builds the dialog
the way the app builds it, with no ledger handed in. Breaking the fix back
turns that one test red and leaves the other six green: the original failure,
exactly.

**Two things worth your knowing, from reading the live server while checking.**

The Mac Mini's half of this worked, and worked on the day. Its log carries the
refusal seven times from 10:42:52, and the peanut butter is still against your
name there. So the phone moved a row the house never moved.

That leaves one entry where the two machines disagree: it left your day on the
phone at 10:42 and the Mini still holds it against you. The phone's queue gave
up after eight tries. **I have not touched your diary to repair it** — a
session writing to your food record to tidy up after itself is not something I
will do without you saying so. Say the word and I will, or delete and re-log it
yourself, whichever you prefer.

## Step 4 — adding a meal opens a page instead of adding it

**The step was wrong. The app is right.** So I have fixed the expectation, and
this is the record of it.

What the app does: when the meal you tap has no calorie figure, it puts the
meal on the day and then opens that meal's own screen. Both of your meals —
chicken katsu and the beef stir-fry — have no figure. I checked on the Mini
rather than assuming: their nutrition column is empty, because a meal built
from parts is a name and four component names until somebody says which of the
house's foods stands for the beansprouts and how much goes in. That is what its
own screen asks, and it is the only place it can be said.

So landing there is deliberate: the alternative is a meal sitting on your plan
with no figure and nothing telling you why, which you would have to go and find
out. The step's author — me — wrote "the meal appears on the day" without
allowing for it, and then you tapped the only two meals in the house, both of
which take that route.

**One thing I have deliberately not changed, for you to rule on.** The jump
happens silently. You were moved to a screen and the app never said why. The
rest of this build says what it just did in a sentence — "Put down as all
yours", "Couldn't work out what this one takes" — and this one does not. A line
on arrival saying *this meal has no figure yet; say what it is made of and it
will get one* would make it self-explanatory. That is a change to a screen you
did not ask for, so it is your call, and the instruction I was working to said
to fix the expectation instead of the app. I did that.

**The thing step 4 was actually testing was not seen.** It was the line "Put
down as all yours. Open it to change whose share it is." Step 5 passed, so the
behaviour underneath it is right — the whole meal was against your name and
Emily's share was not set. Whether you saw the sentence is not recorded either
way.

## Step 14 — the kitchen panel loads with nothing between the menus

**Fixed and proved by loading it.** Not caused by the `?batchdemo=1` on the
address; it happens on any cold load whose remembered tab is Recipes or Plan,
and has done for as long as those two tabs have existed.

The panel's main script boots and draws the remembered tab before the two files
that know how to draw Recipes and Plan have loaded — they are the last two
script tags on the page. So it drew nothing, and the refresh that follows
deliberately leaves those two tabs alone because they fetch their own. Tapping
another tab and coming back draws again, by which time the files are there,
which is exactly the workaround you found.

It now draws a second time once every script on the page has run.

Proved by running a throwaway copy of the panel on a spare port with an empty
database, seeding the remembered tab to Recipes, and loading it in a headless
browser: before the fix the list was empty and the "nothing here" line was
blank; after it, the recipes section's own line appears. The default tab still
draws its own list. **It needs deploying to the Mini before you will see it.**

## Step 13 — a removed meal stays on the plan

**Not a separate fault. It is steps 10-12 seen from the other end, and it is
already fixed** — no further change was needed.

The meal you removed did come off; you said so. What stayed was the crunchy
peanut butter, and that is a logged food, not a planned meal. The Plan tab
draws each day straight from the Mac Mini, and Home and Diary draw from the
phone's own copy. The move at step 10 took the row off the phone and the Mini
refused it, so the two now disagree — the Plan tab is showing you the truthful
one.

I asked the Mini rather than reasoning about it. Its answer for your week:

    2026-08-24 | entries: [('Crunchy Peanut Butter', 1)] | planned: []

Person 1 is you. So the plan was right and your diary was wrong, which is the
opposite of how it looked. With the move refused in front of you, this cannot
happen again; the one row already split stays split until somebody puts it
right, as above.

## Step 3 — the day's sheet renders as a small box at the bottom

**Fixed and measured.** A bottom sheet hands its contents loose room, so a
column of short text shrinks to fit its longest line rather than filling the
screen. On a day with nothing on it the longest line is the date, so the sheet
became a small box in the corner. A day with a meal on it was always fine,
because a meal's row takes whatever width it is given — which is why nobody had
seen this until you opened an empty day.

Measured on a phone-sized screen in a test rather than guessed at: 290 points
wide out of 390 before, the full 390 after. Setting it back to a fixed narrow
width turns both new tests red.

**Two corrections to the step, not to the app.** The sheet has one button, not
two: 'Build one from its parts' lives inside the meal picker one tap further
in, which is what you found yourself in your update. And nothing was being cut
off the bottom — the box was simply small. The step was written as though both
buttons were on the sheet, and I have not moved the second one there; where it
sits now is where somebody arrives when the meal they wanted was not in the
list.
