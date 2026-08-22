# Build 54 — release 6, and the one piece of it you can reach

**Date:** 2026-08-22
**Built:** 22:25 BST. **Installed 22:27:24. NOT watched opening — see below.**
**Branch:** `household-release-1`. Nothing pushed; `main` untouched.

## The line to read first

**Build 54 is on your phone.** The walkthrough to open in the morning is
`walkthrough-runs/2026-08-22-build-54-packets-amounts-and-the-list/input.json`.
It is written and **not launched**. It replaces the thirteen-step panel you
started last night — do not go back to that one, it was written against build
53. Starting again from the top costs you only the step you had marked, which
was reading the version number, and that number has changed anyway.

## What is in it

All five pieces of release 6, as the plan defines them.

1. **A planned meal has a screen of its own**, which says what it is made of and
   names the gaps rather than hiding them.
2. **The phone asks the Mac Mini what a meal is made of**, instead of keeping a
   second idea of it.
3. **Your own share of a meal is what the amount box opens on** — the first rung
   of the order settled on 22 August, ahead of what you had last time and ahead
   of the packet.
4. **A meal can be built out of its parts on the phone** — protein, how it is
   cooked, up to two vegetables, one carbohydrate — with the lists made of what
   this house has actually cooked rather than a catalogue.
5. **The shopping list**, read and ticked in a shop with no signal.

Commits, in order: `6b196e2`, `b156c1c`, `7ead85b`, `05c9482`, `8404d2a`,
`1061dc9`, `407f000`, and on the Mac Mini `5fd191d`, `c4556d5`, `2eac67b`,
`013cd84`, `92298a8`.

## Four of the five have no way in on your phone

This is the thing to decide, and it is yours to decide, not mine.

Pieces 1 to 4 all open from the week-ahead panel. You took that off the phone on
20 August — "planning is what the kitchen panel is for, and a second copy of it
here was a second thing to keep in step for no gain". That call stands and
nothing in this build reverses it. The consequence is that four of release 6's
five pieces are built, tested and installed on your phone with nothing you can
tap to reach them.

Checked rather than assumed: `PlanDaySheet.show` is called from exactly one
place in the whole app, and that place is the week-ahead panel, which is mounted
nowhere. A wiring test fails if the week quietly comes back.

The shopping list is the exception, and deliberately so: it is read standing in
a supermarket, which is the one place a phone beats a panel in a kitchen. Its
way in is on Home, which is what the card's own surface list asks for.

## What was watched, and how

**On the Mac Mini, against the live machine after deploying:**

- Both new read routes answer with this household's real data. Asked what goes
  with roast chicken, the live server came back with brussels sprouts, green
  beans, parsnips, peas and roasted carrots, and roast potatoes, mashed potatoes
  and stuffing to go under it.
- All four shopping routes were driven end to end on the live server: a line
  added, read back through the phone's own route, ticked, **ticked a second time
  to prove a repeated tick leaves it ticked rather than flipping it**, and
  removed. The list finished empty, as it started.
- Building a meal was driven on the live server too, and it returned the meal in
  the shape the phone's picker reads.

**Two rows that check wrote to the live database were taken back out**, because
they were not things anybody in the house did: the meal itself, and one pairing
row that had started telling the house roast potatoes are a vegetable to have
with roast chicken. Both removed and the result read back — the roast chicken
vegetable list is again brussels sprouts, green beans, parsnips, peas and
roasted carrots.

**On the phone:**

- Every framework in the bundle is a phone build. 23 report `platform IOS` under
  `vtool -show-build`; the other 7 are older binaries carrying
  `LC_VERSION_MIN_IPHONEOS` instead, all `arm64` with that load command present.
  No simulator slices. This is the check build 50 failed.
- It installed with no hand-signing, second attempt — the first timed out while
  the phone was still waking.
- `devicectl device info apps` reports `com.aeobrien.foodtracker 1.0.0 54` on
  the device.
- `build/ios/iphoneos/Runner.app/Runner` sha256 begins `753c165e2f051d66`.

## What was NOT watched, and why

**It has not been watched opening.** Build 53 was, at 20:03:04, and the way that
was proved was the Mac Mini's log filling with the phone's own start-up requests
one second later. That could not be repeated here: every launch attempt between
22:27 and 22:46 was refused with *"the device was not, or could not be,
unlocked"*. The phone is on the network — the install itself went over it — it
is simply locked, and iOS will not open an app on a locked phone.

The Mac Mini's log confirms the negative rather than leaving it as a guess:
between the install and 22:47 the only requests it received came from this Mac,
none from the phone. So the honest statement is that build 54 is installed and
reported by the device, and nobody has yet seen it draw a screen.

Step 1 of the morning's walkthrough is exactly that check.

## The three choices raised and not made

Each was raised in one line when it was reached, and passed rather than settled,
because each is yours:

- **What a newly built meal defaults its portions to.** BC-0021 proposes one
  portion each. Not taken — nothing here sets a portion at all; whose share is
  what is settled on the day the meal is planned.
- **Whether a newly built meal arrives pre-filled with your most frequent
  combination.** BC-0021 proposes it. Not taken — the lists are ordered by habit,
  but nothing arrives already chosen.
- **What date range the shopping list covers.** BC-0023 proposes the current week;
  the panel has always done fourteen days and the house expects that. Left at
  fourteen, noted in the code beside the number.

## One small thing noticed, not fixed

Nothing stops the same thing being chosen as both a vegetable and the
carbohydrate, and when that happens the meal names it twice. It cannot happen
from the offered lists, which never overlap; it can happen through the "something
else" box. Left alone rather than changed quietly.
