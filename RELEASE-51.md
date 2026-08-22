# Build 51 — the same fix, in a build that opens

**Date:** 2026-08-22

Build 51 contains no new work. It is build 50's code, built properly.

## What was wrong with build 50

Build 50 installed on the phone and came up as a white screen. Nothing in it
was visible.

The reason, read off the binary inside the installed app rather than reasoned
about: the app shipped a piece of native code built **for the iPhone
Simulator**, not for a phone.

```
$ vtool -show-build build/ios/iphoneos/Runner.app/Frameworks/objective_c.framework/objective_c
 platform IOSSIMULATOR
```

A simulator binary cannot load on a real device. It is not loaded when the app
starts — the Dart runtime opens it the first time something needs it — so the
app launched, the engine came up, and then the first screen died. That is
exactly what a white screen with a live app looks like.

It got there because a failed **simulator** build at 09:28 that morning left its
output in `build/native_assets/ios/`, and the later `flutter build ios --release`
reused it instead of building for the phone.

## The morning's signing fight was a symptom, not the disease

Build 50 refused to install with `Failed to verify code signature … 0xe8008014`,
and it was made to install by stripping the Intel slice out of that framework by
hand and re-signing it. That worked in the sense that the installer stopped
complaining, and it was the wrong fix: the framework was still a simulator
binary underneath, and re-signing it only got a broken thing onto the phone.

Build 51 needed no hand-signing of any kind. It installed first time.

## What was actually done

```
flutter clean
flutter build ios --release
xcrun devicectl device install app --device <phone> build/ios/iphoneos/Runner.app
```

`flutter clean` replaces the `rm -rf build/native_assets …` that RELEASE-50.md
recommends and that this session could not run. That recommendation can be
ignored; use `flutter clean`.

The same check now reads:

```
 platform IOS
```

## What was verified, and how

- **The framework is a device binary.** `vtool -show-build`, above.
- **It installed with no hand-signing.** `devicectl device install`, first try.
- **It opens.** Launched on the phone and watched the Mac Mini's log: the phone
  registered itself, fetched its settings, fetched today's day, and pulled its
  pending meals — all within a second of launch, all from the home screen's own
  start-up. Build 50 made **no** requests at all, which is what a screen that
  never drew looks like from the server's side.
- **Not verified:** anything that needs a finger on the glass. Nobody has tapped
  or held a ghost card on build 51. That is what the walkthrough is for.

## Standing lesson

Installed is not opened. Build 50 was reported as being on the phone, which was
true, and was allowed to stand as though it worked, which was not. From here a
build is not "on his phone" until it has been launched and seen to talk to the
house.
