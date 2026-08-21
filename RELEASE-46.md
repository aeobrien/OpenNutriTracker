# Build 46 — what changed since the one you tested

**Date:** 2026-08-21
**Branch:** `household-release-1`
**Status:** on your phone. Covers builds 45 and 46 together — 45 is the one you
walked through this evening, 46 is what that walkthrough found.

## Build 45: the two things you raised

> *"When you add something like this, I have no idea how it's choosing which
> meal to add it to."*

It was choosing by the clock. Nothing said so, and nothing asked you. You said
what you wanted instead: *"Yes, let me say it, but if 'breakfast', 'lunch',
'dinner' or 'snack' isn't found in what i've said, ask before adding."*

That is now literally what happens. If you name a meal, that is the meal — and
every food in the one sentence goes to it, because one sentence is one sitting.
If you do not name one, nothing is put on any meal and you are asked. The food
sits on the Mac Mini in your own words until you answer. The check is made
before anything reads the sentence, so being asked costs nothing and a day you
open ten times does not pay ten times over.

> *"If there are more than three items in a meal, I can't view them all - they
> disappear off the right, and I can't scroll because scrolling swipes left as
> if to delete."*

Both of those were the same drag. The row of items scrolls sideways, and each
item also swiped sideways to delete, and the item always won. There was no
setting to change: two things cannot both own the same gesture. You chose to
keep the scrolling, so the sideways swipe is gone.

Deleting is now two things instead: hold an item down, as before, or tap it and
press **DELETE** in the box that opens. The **Undo** offer moved onto both of
those, because the swipe had been the only place it was ever offered — it was
build 43's whole feature and you had never once been shown it.

Undo also got more honest. It used to put a spoken item back as a nameless
zero-calorie row; it now puts back what you actually had.

## Build 46: what your walkthrough of 45 turned up

**"A coffee, snack" added an item called "snack".** Fixed on the Mac Mini the
same evening — the name of a meal is a heading, not a food. This one is already
done and needed no new app.

**"There are only four options, let's make it a modal with four buttons."** Done.
The question now comes with its four answers attached and they arrive as
buttons, in a panel that comes up in front of you. Nothing goes on your day
until it is answered, so a question you scroll past is food that never arrives —
it is worth interrupting for. You can dismiss it without answering; the same
four buttons stay on the page underneath.

Only a question with a short, known set of answers works this way. *"Was that a
small, medium or large mocha?"* still has a box to type in, on the page, where
the keyboard has room.

**"The 'which meal was that' field disappears after I submit, but then reappears
after that, even though I haven't submitted anything new."** Real, and exactly
as you described it. Answering a question makes the app re-read your day, and
re-reading your day is also how an unanswered question gets asked again — so
the question you had just answered was handed straight back and asked a second
time. The app now remembers which items it has already asked you about, and the
day stops handing down a question that has been dealt with.

It forgets when you close the app, on purpose. Asked once this sitting is not
the same as asked once ever, and a question you genuinely never answered has to
come back.

## The step that failed for a reason that was mine

Step 8 asked you to leave a question unanswered, close the app, and open it
again — and the question did not come back.

That was me. I deployed the "snack" fix to the Mac Mini at 22:18:59, which
restarts it, and your step 8 ran from 22:18:27 to 22:19:31. When you reopened
the app it asked the Mac Mini what was still outstanding and got no answer,
because the Mac Mini was in the middle of coming back up. So it had nothing to
show you.

I have not "fixed" anything for it, because I have no evidence anything is
broken — the same path worked twice in the minutes before, and is in your
walkthrough again so we find out properly. What I have changed is my own habit:
not deploying to the Mac Mini while you are in the middle of testing it.

## What is not fixed

- **Undo tells your phone but not the house.** Put an item back and it is on
  your phone again while the Mac Mini still counts it as gone. The house knows
  how to retire an item and has no way to un-retire one. Real gap, not yet
  filled.
- **Your 20 August double-count is still unexplained and still needs you.** The
  same sentence captured twice, seventeen seconds apart, as two genuinely
  different recordings — repeat capture, not the app sending one thing twice.
  About 350 extra calories.
- **Saving a packet still does not offer to put it on your day.** Still your
  call, still unanswered by me.
