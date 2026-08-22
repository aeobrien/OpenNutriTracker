# Build 53 — saving a packet, and the amount it opens on

**Date:** 2026-08-22
**Built:** 18:58 BST. **Installed 20:02:52, launched 20:03:04, watched opening.**
**Branch:** `household-release-1`. Nothing pushed; `main` untouched.

## What is in it

Three things, all from Aidan's walkthrough of build 52 at 18:20–18:26, which
failed at step 5.

1. **The offer to put a saved food on today is a question, not a strip.** It
   was a bar along the bottom of the screen with a button on it, and it took
   itself away after ten seconds. It is now a box in the middle of the screen
   with two answers — "Not now" and "Put it on today" — and it waits.
2. **The form closes whichever way he answers.** The hand-typed route never
   closed it at all, so he was left sitting on the boxes he had just filled and
   read that as the save having failed. The amount screen now opens over the
   screen he started from rather than on top of a finished form.
3. **A food the house counts in items can carry what he had last time.** The
   pack weight and the count come off the household's list; how much somebody
   last ate is in this phone's own log; nothing joined them. So for exactly the
   foods that count in items, the amount box could never reach the second step
   of the order he settled that afternoon.

Commits: `843deba`, `750c392`, `1cd47ef`, and the version bump.

## What was watched

- **Whole suite 821 passing**, and each fix broken on its own fails a different
  test: the form left open, the offer never taken up, the offer taken up
  whatever he answers, the question left with one answer, the last-amount
  lookup never made, and the join dropping the pack numbers on its way through.
- **The route is now driven by a test.** It was lifted out of `main.dart`'s
  routes map for that reason — a route written inline in that map cannot be
  reached by a test, which is why this was wrong for weeks.
- **Every framework in the bundle is a phone build.** 23 report `platform IOS`
  under `vtool -show-build`; the other 7 are older binaries that carry
  `LC_VERSION_MIN_IPHONEOS` instead and report nothing there, so each was
  checked separately — all seven are `arm64` with that load command present. No
  simulator binaries. This is the check that build 50 failed.
- `build/ios/iphoneos/Runner.app/Runner` sha256 begins `f380ac0ded06d573`.

## Installed and watched opening

Installed at 20:02:52 and launched at 20:03:04. The phone reported eleven
requests to the Mac Mini one second later, all answered 200 — register-device,
the day, settings, people, and the pending queue — which is the same evidence
build 52 was accepted on. `devicectl device info apps` reports
`com.aeobrien.foodtracker  1.0.0  53` on the device, so the thing that opened
is this build and not the one before it.

The earlier failure was the phone being asleep and off the network, nothing
more: the same command succeeded first time once it was awake.

## What is still NOT watched

**That saving a food actually offers to put it on today, and that saying yes
brings up the amount screen.** Aidan has said the offer did not appear at all
last time, and the diagnosis explains why — it was a bottom strip that wiped
itself after ten seconds, so he never got to say yes. An explanation is not a
check.

It cannot be checked from here: it needs somebody's hands on the phone. Steps 5
and 7 of the walkthrough are exactly that check. The signature to look for on
the Mac Mini is a `GET /household/foods?q=…` — the lookup that only runs when
the offer is taken up, and the request that was absent from the log at 18:21
and 18:25 on build 52.

## The walkthrough

Written and **not launched**, at
`walkthrough-runs/2026-08-22-build-53-saving-and-amounts/input.json`.
Thirteen steps. Every one says which screen he is standing on, what to tap to
get there, and names things by the words actually printed beside them — the
last walkthrough did none of that and four of its nine steps tested nothing as
a result.
