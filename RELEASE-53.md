# Build 53 — saving a packet, and the amount it opens on

**Date:** 2026-08-22
**Built:** 18:58 BST. **Not installed** — see the bottom of this file.
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

## What was NOT watched, and why

**It is not on his phone.** `xcrun devicectl` reports the device Mirador as
`unavailable` — eight attempts between 18:59 and 19:02 all failed with
`CoreDeviceError 1000`. The pairing is intact (`device info details` answers
fine from cached data) but there is no live connection, which means the phone
is locked, asleep, or off this network. Build 52 installed over the same link
at 18:13, so nothing about the setup has changed.

So: **nothing here has been seen running on a phone.** It is tests and a
verified bundle. The install needs the phone awake and on the network.

## The walkthrough

Written and **not launched**, at
`walkthrough-runs/2026-08-22-build-53-saving-and-amounts/input.json`.
Thirteen steps. Every one says which screen he is standing on, what to tap to
get there, and names things by the words actually printed beside them — the
last walkthrough did none of that and four of its nine steps tested nothing as
a result.
