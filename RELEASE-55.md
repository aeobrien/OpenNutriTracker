# Build 55 — fixing something that was logged wrong

**Date:** 2026-08-23 (installed 00:17:02 BST, clock read in the same turn)

Release 7, journey J-0008. Four things, three of which the release-7 audit
found missing on 22 August and one of which — the entry's history — nothing
existed for at all.

## What is in it

**Every row keeps what it used to say.** Correct something, remove it, or put
it back, and the Mac Mini writes down what the row said just before. Open the
row again and there is a short list under the amount headed "What this used to
say", with a way back to each version. Putting one back is not a second way of
writing to a row — it is the ordinary correction, replayed with the older
figures, and which fields it may carry is worked out on the Mini and sent with
each version, so the phone never keeps its own copy of that list.

Restoring puts back the amount, the name, the calories and whose day it is. It
deliberately leaves the meal of the day and the date where they are now.

**A meal logged under the wrong part of the day can be moved.** The edit box
asks which meal, and sends one only when it differs from the meal the row
arrived with. The Mac Mini has accepted a corrected meal since the day it
accepted a correction at all; this is the control that was missing, not the
ability. Before this, a lunch logged under dinner could only be removed and
logged again, which loses when it was eaten and who entered it.

**Deleting something the phone has not sent yet takes it off the queue.**
Before, a delete with no signal queued a removal behind the creation, and the
phone spent the trip home telling the house about a row and then telling it to
forget the row. Two things it will not do: it will not cancel while the queue
is actually draining, because that can leave a row standing on somebody's day
with nothing able to remove it; and undoing puts the creation back rather than
asking the house about a row the house never heard of.

**A row can be removed by voice.** Delete and Edit are now actions on the row
in VoiceOver's actions rotor, doing exactly what tapping and holding do. A long
hold is not a gesture somebody navigating this way can make, so until now a row
could be read out and not removed.

## What is not in it

Changing the food behind a row — swapping the food itself rather than its
amount — is the last item in release 7 that does not need Aidan, and it is not
started. It means reopening the food picker from inside the edit box, which is
a different shape of correction from everything above.

The one thing in release 7 that does need him is BC-0026's proposed default
about halves of a shared meal. It is on the waiting list with the rest.

Release 6's four planning pieces are still on the phone with no way to tap
into them, because they open from the week-ahead panel he took off on
20 August. Unchanged from build 54, and still his call.

## Watched, not reasoned

The phone was on the network and locked. The install went over it and
`devicectl device info apps` reports `1.0.0 55` on the device. **It has not
been watched opening** — every launch attempt comes back "the device was not,
or could not be, unlocked", which is iOS refusing to open an app on a locked
phone, the same wall as build 54. Step 1 of the walkthrough is that check,
which is where it belongs.

## Tests

FoodTracker 959 passing (940 at build 54). Mantel 697 (692 at build 54; five
of tonight's are on the Mac Mini side, saying out loud that a corrected meal
of the day is accepted rather than leaving that as a fact about a tuple).

Each guard was broken deliberately and watched go red on a different test:
fourteen breaks across the three pieces. Three of them proved nothing on the
first attempt and were rewritten until they did, which is recorded in the
commit messages rather than smoothed over.

## The walkthrough

`walkthrough-runs/2026-08-23-build-55-corrections-and-what-a-row-used-to-say/input.json`

Twenty-eight steps. It replaces last night's twenty-two-step panel rather than
adding to it: the same twenty-two steps with the version number corrected, plus
six for release 7. Starting from the top costs nothing already done — the only
step marked on the older panel was reading the version, and that has changed
again.
