# Why the simulator cannot run this app, and what would fix it

**Date:** 2026-08-24

Since some time between 20 and 24 August, this app cannot be built for the iOS
simulator on this Mac. It could on 20 August — the weight-correction fix was
watched running there against a real Mantel. Three builds today failed
identically, the third after a full clean and a fresh pod install:

```
Parse Issue (Xcode): Module 'mobile_scanner' not found
ios/Runner/GeneratedPluginRegistrant.m:65:8
```

**This matters beyond one fix.** It is the only way to watch anything happen
without putting a build on Aidan's phone — and putting a build on his phone is
what emptied his food diary this morning. Until it is sorted, "watched running,
not just tested" costs him his diary.

## The cause

The barcode scanner package we depend on, `mobile_scanner ^6.0.2`, is built on
Google's ML Kit. ML Kit ships no arm64 build for the simulator, so the package's
own build settings exclude arm64 there:

```ruby
# ~/.pub-cache/hosted/pub.dev/mobile_scanner-6.0.11/ios/mobile_scanner.podspec
'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386 armv7 arm64',
# TODO: add back arm64 (and armv7?) when switching to the Vision API.
```

An Apple Silicon Mac's simulator **is** arm64, and it is the only architecture
it has. So every architecture is excluded, nothing is built, and the module the
app tries to import does not exist. This is not a stale build directory and no
amount of cleaning touches it.

It builds for a real phone because the device exclusion is a different line and
only drops armv7.

## What would fix it

**`mobile_scanner` 7.x, which is what that TODO was waiting for.** Version 7
replaced ML Kit with Apple's own Vision framework, and its build settings now
exclude only i386:

```ruby
# github.com/juliansteenbakker/mobile_scanner, darwin/mobile_scanner.podspec
'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
```

Latest is 7.4.0. Flutter 3.29 or newer is required and this machine has 3.41.2.

**What the upgrade would cost us.** Version 7 lists four breaking changes and
**none of them touches anything this app uses**. Our entire use of the package is
one screen, `scanner_screen.dart`: `MobileScannerController()`, `torchState`,
`toggleTorch()`, `switchCamera()`, and `MobileScanner(controller:, onDetect:)`
reading `capture.barcodes`, `rawValue` and `BarcodeType.product`. The four
breaks are to `errorBuilder`, `placeholderBuilder`, the `MobileScannerErrorBuilder`
typedef, a removed `EncryptionType.none`, and the initial camera-facing value —
we use none of them.

## Why it has not been done

**It cannot be proved without his phone.** A simulator has no camera, so
upgrading the barcode scanner and then testing it on the simulator proves
nothing about the thing that changed. It needs a real scan of a real packet,
which is a walkthrough step on his phone — and every route to his phone
currently reinstalls the app.

So it is a decision, not a task: **upgrade the scanner to get the simulator back,
accepting that the scanner itself then needs one walkthrough step on his phone to
prove it still works.** The alternative is to leave it, and go on proving phone
changes only by test.

## The circularity worth naming

Getting the simulator back requires his phone once. Not getting it back requires
his phone every time.
