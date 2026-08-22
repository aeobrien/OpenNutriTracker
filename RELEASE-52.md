# Build 52 — the day's work, on the phone

**Date:** 2026-08-22

Build 51 was build 50's code, built properly, and contained no new work. Build 52
is the first build carrying anything Aidan has not seen.

## What is in it that 51 did not have

- **"One pie" and "one pack" as amounts.** The amount box counted grams, ounces,
  millilitres and servings. It now also offers *"pack (500 g)"* and *"one
  (125 g)"* for a food the house knows a pack weight and a count for, with the
  weight inside the words rather than in a caption elsewhere.
- **Two boxes on the confirmation screen**, for what a whole pack weighs and how
  many are in it, and a line saying what the two come to: *"That makes one of
  them 66.7 g."* The pack weight used to travel from the photograph to the
  household list without ever appearing, so a misread one could not be
  corrected.
- **The starting amount, in the order Aidan settled**: the household's portion of
  that meal, then the amount he had of that food last time, then the packet, then
  a round number. The first step has no source until a meal gets its own screen,
  so on this build the box starts on last time — but a gram figure is now said in
  whatever unit the box is counting in, so 96 g of a 125 g pie opens on **0.8**
  rather than on 96.

## The build-50 trap, checked rather than assumed

Build 50 shipped a piece of native code built for the Simulator and came up as a
white screen. Every framework in this bundle was checked before installing:

- 23 of them report `platform IOS` under `vtool -show-build`, including
  `objective_c.framework` — the one that broke build 50.
- The other 7 are older frameworks that carry `LC_VERSION_MIN_IPHONEOS` instead,
  which `vtool -show-build` says nothing about. Each was checked separately with
  `otool -l` and `lipo -info`: all seven are arm64 iPhoneOS. None is a simulator
  binary.

No hand-signing of any kind was needed. It installed first time.

## What was verified, and how

- **It opens.** Launched on the phone at 18:13:22. Eleven seconds later the Mac
  Mini's log shows the phone registering itself, fetching its settings, fetching
  today's day, fetching the people list and pulling its pending meals — five
  requests, all 200, all from the home screen's own start-up. Build 50 made no
  requests at all, which is what a screen that never drew looks like from the
  server's side.
- **It stays up.** `Runner` was still running afterwards, from the bundle this
  install created.
- **The phone reports build 52.**

## Not verified

Anything that needs a finger on the glass. Nobody has tapped an amount box, a
unit, or a pack field on this build. That is what the walkthrough is for.

## Standing lesson, unchanged

Installed is not opened. A build is not "on his phone" until it has been launched
and seen to talk to the house.
