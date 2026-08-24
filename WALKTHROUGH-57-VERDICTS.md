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

## Step 9 — nothing can be added except by barcode

**Two separate things. One is fixed; the other is not ours and needs a decision
from you.**

### The search error — partly fixed

**Open Food Facts is refusing searches.** I called it from here rather than
guessing: its old search address and its newer one both answer 503 with a page
of HTML saying "Page temporarily unavailable", while its barcode lookup on the
same machine answers normally. That is why the barcode worked and nothing else
did.

**What I fixed:** one failed request was throwing away results that had already
arrived. Your house has twenty-one foods of its own on the Mac Mini, and the
app asks the house first and the internet second — but a failure from the
internet discarded both. So you got an empty error screen while the answer was
already in hand. Searching now keeps whatever the house found and only fails
when neither could answer at all. Removing that one line turns the new test
red.

So from the next build, searching "chicken" will show the household's own
chicken products even while Open Food Facts is down. It will not show anything
new from the internet.

**What needs you.** Open Food Facts has a third address — a separate search
service — which answers correctly right now. Moving to it means reading a
different shape of answer from a different machine, and it changes where the
food in your app comes from. I have not done it, and there is a prior question
underneath it: whether a public database going down should ever be able to
empty your food search, or whether the house's own list plus the barcode
scanner is the thing you actually rely on. **Say which and I will build it.**

### "Recently" showing nothing — probably working as designed, and the design
is probably wrong for you

The recent list is built from your own past entries on the phone, and it
**deliberately skips anything spoken or quick-added**, because those have no
food behind them to add again. Speaking is how you log most things. So for you
that list will usually be empty, and it is not obvious from looking at it that
this is the reason.

I cannot see your phone from here, so I am not claiming this *is* what you hit
— only that it is the most likely explanation and it is a real design problem
either way. **Written down as something to decide, not built.**

---

## Step 7 — two things that were not bugs

You marked this a pass and raised two separate things inside it. One is a
build we are not doing now; the other was three lines of code and is done.

### "I can't select 'two chicken thighs', I can only select 'chicken'" — written down, not built

Your words: *"for the protein choice we need to be able to define what it is -
for chicken, breasts/thighs, for beef, is it mince, steak, etc. This is a
bigger build than what we're doing now, but we should note it down as a future
development."*

Written down as future work in Mantel's roadmap under **Protein sub-types in
the meal builder**. **Not built.**

Why it is genuinely bigger than it looks: today a protein is one piece of text,
and everything downstream keys on that exact text — which foods the app learns
you pair together, what goes on the shopping list, and the meal's own name. So
"chicken thighs" and "chicken breasts" would arrive as two unrelated proteins
that share none of each other's habits, and plain "chicken" buys you nothing
you can actually pick up in a shop. A cut is not a cooking style and it is not
a separate protein either; it needs a place of its own, which means changing
the builder on both the phone and the kitchen panel, the Mac Mini's normaliser,
the meal-naming code in two languages, the shopping lines, and the pairing
keys. That is a week's work sitting behind a dropdown.

### "veg is currently limited to 2, that shouldn't be the case" — done

The cap is gone. A meal now takes as many vegetables as you say it does. The
carbohydrate is still one, which is what the card asked for and what you have
not disputed.

It was enforced in **three** places, not one, and all three are lifted:

1. The phone's meal builder — refused the third tap out loud.
2. The kitchen panel's meal builder — same refusal, its own copy of the rule.
3. **The Mac Mini's own normaliser** — silently kept the first two and dropped
   the rest, writing a warning to a log nobody reads.

The third is the one that mattered. Had I only changed the two screens, a phone
would have happily offered you a third vegetable, the Mini would have thrown it
away on the way in, and the meal would have come back missing an ingredient
with nothing on screen to say so. That is a worse bug than the one you
reported.

**How I know it is fixed rather than think it is.** I put the cap back into the
phone's builder on purpose and ran the tests: two went red, in the two places
that check a third vegetable survives. I put the cap back into the Mini's
normaliser: two more went red there. Restored both, and the full runs are green
— 1015 tests on the phone, 719 on the Mini, 21 on the kitchen panel.

---

# The build-53 panel — the one you walked by mistake on Saturday

You walked a superseded panel at 10:32 this morning. That was not your error and
the findings in it were not wasted: four of the thirteen steps recorded
something real, and I checked every one of them against the build you are
holding now before touching anything.

## The two greyed-out boxes were one bug, and it is fixed

You reported them as two things, at steps 11 and 12:

> *"I'm not sure why the 'quantity' window is greyed out though, I can't define
> the quantity manually, but only using the buttons."*

> *"I can't add it, the 'add' button is greyed out and a red message says
> 'product missing required kcal or macronutrients information'."*

They came from the same line of code. The amount screen refused any food that
did not have **all four** of calories, protein, fat and carbohydrate, and it
switched off the amount box and the Add button together.

You had typed those fish cakes in yourself. The form asked you for a name,
calories per 100g, what the pack weighs and how many are in it — the four boxes
the walkthrough named — and it never asked you for protein, fat or
carbohydrate. So the app took a food in through its own front door and then
refused to let you use it, using a sentence about three things it had never
mentioned.

**What it does now.** Calories are still required: a food with none would sit on
your day looking like food and adding nothing, and your total would be wrong
with nothing on screen saying so. Protein, fat and carbohydrate are not
required. A food that has calories and nothing else goes on the day, and the
screen says underneath:

> Calories only — nothing is recorded here for protein, fat or carbohydrate, so
> this will count as zero towards those for the day.

**That sentence is the part worth arguing with, so I am putting it in front of
you rather than burying it.** Accepting the food means your day's protein figure
is short by whatever was actually in it, and the app cannot know by how much.
The alternative is what you hit on Saturday — the food is unusable until
somebody types three more numbers off the packet. I have taken the first because
this house tracks calories and the macros are secondary, and because a food you
cannot log at all is a worse outcome than a macro figure that says so. **If you
would rather the form insisted on all four up front, say so and I will move it
there instead.**

**How I know it is fixed rather than think it is.** There is now a test that
builds the real amount screen with your fish cakes on it and presses on the
buttons. Put the old rule back and two tests go red, including the one driving
the actual screen. That distinction matters this weekend: the refusal I built
for the shared-meal move passed six tests while being unreachable in the running
app, because every test handed it something the app never hands it. This one is
driven through the same widget the app builds.

## The caption that stopped mid-word — fixed

At step 8 you said the figures were right and added:

> *"The 'one of them' text is cut off. It reads 'one of them, worked out from
> what a pac…'"*

That line is the only thing on the screen saying where your number came from, so
half of it is no use. It was attached to the amount box as its helper text,
which pinned it to half the sheet's width and capped it at two lines. It now
sits under the whole row, full width, uncapped.

The one you hit was not the worst case — three of the six explanations are
longer, and the longest ("A starting figure — nobody has said what a portion of
this is") would have lost more. The test uses that one.

## The "+10g / +50g" step — the app was right and the step was wrong

At step 10 you marked a fail and said:

> *"They do say +0.5 and +1, but they never said '+10g' or '+50g'."*

The buttons were doing exactly the right thing. The step told you they "used to
say +10g and +50g", meaning before that build — and you had never seen that
version, so there was nothing for you to recognise. That is a badly written
step, not a defect.

For the record of what the buttons do: **+10g and +50g still exist**, and appear
when the unit is a weight. When the unit counts things — one, a pack, a serving
— you get +0.5 and +1 instead, which is what you saw and what you should see.
Nothing changed here.

## Step 13 is now walkable and has not been walked

> *"Can't do this as it didn't add last time."*

That step is the one that checks the amount box opens on what you ate last time
rather than starting from scratch. It was untestable because the Add button was
dead. The Add button now works, so the step can be walked — **but I have not
walked it and cannot, and until somebody does, that fix is written and unproven
on a real phone.**
