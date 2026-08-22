# What is waiting on Aidan

> **Build 56 is on your phone, and the panel to open is**
> `~/Dev/FoodTracker/OpenNutriTracker/walkthrough-runs/2026-08-23-build-56-corrections-and-the-wrong-food/input.json`
> — thirty steps. Start it from the top. Ignore the build 55 panel: 55 was on
> the phone for half an hour, you never opened it, and 56 is 55 plus one more
> thing.

**Date:** 2026-08-22 22:58, last added to 2026-08-23 00:52 (clocks read in the
turns they were written)

Six things. None of them is being chased and none has been decided for him.
The first two are the ones that change what he can do on his phone; the rest
are smaller and can be answered in a sentence each. The sixth was found later
in the night, while auditing release 7.

---

## 1. There is no door into four of release 6's five pieces

**What it is.** The meal's own screen, building a meal from its parts, the
calorie figure worked out from those parts, and his own share of a meal are all
built, tested and installed on his phone. All four open from the week-ahead
panel, and he took that off the phone on 20 August — "planning is what the
kitchen panel is for, and a second copy of it here was a second thing to keep in
step for no gain". That call has not been reversed.

**Checked, not assumed.** `PlanDaySheet.show` has exactly one caller in the whole
application and it is that panel, which is mounted nowhere. A wiring test fails
if the week quietly comes back.

**What he has to say.** Whether he wants a way into the planning screens on the
phone at all, and if so where it hangs. The shopping list went on Home instead,
which is what its own card asks for; that is not a precedent for the rest.

## 2. The build on his phone has not been watched opening

**What it is.** Build 56 went on at 00:49:45 and the device reports `1.0.0 56`
(read at 00:49:58), but the launch is refused for the same reason builds 54 and
55 were — his phone is on the network, it is locked, and iOS will not open an
app on a locked phone. For build 54 the Mac Mini saw no requests from the phone
in that window either, so the gap was confirmed from both ends rather than
assumed.

Build 55 went on at 00:17:02 and was replaced half an hour later, unopened.
Nothing was lost by that: 56 is 55 plus the food swap.

**What he has to do.** Nothing separate. Step 1 of the morning's walkthrough is
exactly this check.

## 3. What a newly built meal defaults its portions to

BC-0021 proposes one portion each. Not taken: nothing in the builder sets a
portion at all, and whose share is what gets settled on the day the meal is
planned. Leaving it that way is a decision as much as changing it, so it is his.

## 4. Whether a newly built meal arrives pre-filled

BC-0021 proposes starting it on his most frequent combination. Not taken: the
lists are ordered by what this house actually cooks, but nothing arrives already
chosen. A meal that fills itself in is faster and is also easier to accept
without looking.

## 5. How far ahead the shopping list reaches

BC-0023 proposes the current week. The kitchen panel has always done fourteen
days and that is what the house expects, so fourteen is what the phone does too.
Noted in the code beside the number. Changing what a shipped button does is not
something to settle quietly while building a second copy of it.

## 6. Whether moving half a shared meal onto the person who already has the other half should be refused

Found while auditing release 7, after the five above were written.

BC-0026 marks this one **[proposed-default]**, which means the card is proposing
a rule rather than recording a decision. Moving half of a shared dinner onto the
person who already holds the other half would count one dinner twice against one
of them and leave the other with none. The card proposes that the app says
exactly that instead, and offers to delete the entry if the meal was not really
shared.

**What he has to say.** Whether that refusal is the rule. The guard has not been
built and will not be until he confirms it — a rule that refuses something a
person deliberately asked for is not a thing to invent on his behalf.

---

## Which build, and which walkthrough

**Build 54 is on his phone.** The walkthrough to open is
`walkthrough-runs/2026-08-22-build-54-packets-amounts-and-the-list/input.json`.
Written, not launched. It replaces the thirteen-step panel from last night, which
described build 53. Starting from the top loses him nothing: the one step he had
marked was reading the version number, and that number has changed.
