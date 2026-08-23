# What is waiting on Aidan

> **Build 57 is on your phone, and the panel to open is**
> `~/Dev/FoodTracker/OpenNutriTracker/walkthrough-runs/2026-08-23-build-57-a-plan-tab-and-four-answers/input.json`
> — eighteen steps. Start it from the top. Every earlier panel is dead, including
> the build 56 one; 57 is 56 plus everything you answered this morning.

**Date:** 2026-08-23 13:00 (clock read in the turn it was written)

**Three things.** Seven of the eight items that were here this morning are
answered and built. What is left is one question you have not been asked yet,
one you have been asked and not yet answered, and one piece of tidying that
waits on your verdict.

---

## 1. Whether release 8 is finished

**Unchanged since this morning, and still the one real question.** Release 8's
exit criterion is that this becomes usable: *"Fourteen jars in the fridge, one
shopping line per ingredient, and seven mornings where logging breakfast takes
one tap each."* Its only card, BC-0027, ends with *"Nothing is recorded as
having been made, and nothing is counted afterwards."*

The jars and the shopping line are built and tested. The seven mornings are not
in this release, and not in any other.

**What you have to say.** Which of three it is: the mornings were describing the
logging that already works, so the release is done; or a batch that has been
made should become something loggable in one tap, which is new behaviour and
wants a card; or the exit criterion overreached and should be narrowed.

The difference between the first two is whether you expect to search for the
porridge every morning or tap it. That is a question about your kitchen rather
than about the code. Full working in
`~/Dev/Mantel/ledger/plans/2026-08-23-release-8-what-is-already-built.md`.

**Your own rule now covers the rest of it.** *"If it's not tested and approved
by me, it's not done."* That is written into `~/Dev/Mantel/ledger/PROJECT.md`,
the planning project's roadmap and `~/Dev/FoodTracker/CLAUDE.md`. Nothing in
release 8's code was re-opened on the strength of it: the gap is your approval,
not the build.

## 2. The batch screen — you asked to see it, and now you can

**What it is.** On the kitchen panel, a meal the server had nothing to say about
was drawn with an empty ingredient list, which reads as "this takes nothing to
make". It now says *"Couldn't work out what this one takes."* instead.

**It is on the Mac Mini**, deployed and verified live. You could not see it by
using the panel normally, because the server it talks to cannot currently
produce that answer — so there is a temporary switch. Steps 14 to 18 of the
walkthrough turn it on and walk you into it.

**What you have to say.** Whether that sentence is the right thing to say there.

## 3. The temporary switch comes off once you have ruled

`?batchdemo=1` exists only so you can see the above. It is marked TEMPORARY in
`~/Dev/Mantel/web/plan.js` and comes off the moment you have ruled on item 2.
Nothing else depends on it and it does nothing unless the address carries it.

---

## Answered this morning, and built

Seven answers, all of them now in code, all of them held by tests that were
broken deliberately to check they hold.

1. **"If it's not tested and approved by me, it's not done."** Written into the
   project's own record in three places, and it applies backwards.
2. **The batch screen deployed and made visible.** Above.
3. **"Yes, give them their own menu item on the bottom of the screen."** A Plan
   tab, between Diary and Recipes. It does not put the week back on Home.
4. **"100% of the meal, but prompts you to update it."** A planned meal goes
   down as the whole of it against whoever planned it, with the prompt above
   the plan rather than in place of it. Nobody else is given a nought.
5. **"No default, I do it manually - the learning system is unproven."** Nothing
   in the meal builder arrives ticked. The ordering is still the Mac Mini's,
   because that is a suggestion and not a choice.
6. **"14 days."** Recorded as your decision rather than the panel's habit, and
   held by three tests. It is not a ceiling.
7. **BC-0026's refusal, built.** Half a shared meal will not move onto whoever
   holds the other half, and the refusal offers to delete the entry in case the
   meal was never shared.

## One thing that is not held by a test, said out loud

Both machines check *"is the person you are moving it to holding the other
half"*. In a two-person household that cannot disagree with *"is anybody
holding it"* — the only person you can move a row to is the only person who
can have it. So the precise form of that check is not held by any test, and
manufacturing data the app cannot produce would not hold it either. It stays
because it is the rule the card states. It is written down here rather than
left to be found.

## One card in the planning project still reads as unsettled

BC-0023 says the shopping list should default to *"the whole of the current
week"*. You said fourteen days. The code says fourteen days and says whose
decision it is; the card still carries the old proposal, because changing a
gate-approved card is an amendment you open, not an edit made from a build
session.
