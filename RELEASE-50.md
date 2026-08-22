# Build 50 — a confirmed dinner lands under Dinner

**What changed:** one thing. When you tap tonight's planned meal to say you ate
it, the entry now appears under **Dinner**, not under whichever meal the clock
happened to suggest.

**Why it was wrong.** The plan only knows *what* is for dinner and *when* —
"chicken katsu, Saturday". It does not record that it is the evening meal. So
when you confirmed it, nothing told the Mac Mini which meal of the day it was,
and the Mac Mini fell back to the time on the clock. You tapped at a quarter to
one, so it filed it under Lunch.

The card itself was always in the right place, because the phone draws planned
meals in the dinner strip. Build 50 makes the phone say so when it sends the
answer.

**Still to do, and known:** the ghost card's text is cramped — the meal's name
and "Awaiting calories" sit on top of each other. That is a layout fix, left for
later on purpose.

---

## Before you build 51 — read this

Build 50 would not install on the phone at first. iOS rejected the whole app:
"the executable contains an invalid signature". The offending piece was one
bundled framework, `Frameworks/objective_c.framework`.

**The cause, checked rather than guessed.** That framework is a "native assets"
artefact, and Flutter caches it at `build/native_assets/ios/`. The cached copy
was built at 09:28 on 22 August — during a failed attempt to build for the
simulator — so it is a fat binary carrying both a simulator slice (x86_64) and a
device slice (arm64), and it is only ad-hoc signed. The release build at 13:17
copied that cached file straight into the app without rebuilding or re-signing
it. The two files are byte-for-byte identical (sha256
`c2aeeb5d…85c8bf6c`) and carry the same 09:28 timestamp. Build 49, made before
the simulator attempt, installed without trouble.

**What got build 50 onto the phone.** Stripping the simulator slice from the
copy inside the app and re-signing that one framework with the same identity as
the app:

    FW=build/ios/iphoneos/Runner.app/Frameworks/objective_c.framework
    lipo -remove x86_64 "$FW/objective_c" -output "$FW/objective_c"
    codesign --force --sign "Apple Development: Aidan O'Brien (RP3UX78A8H)" \
             --timestamp=none "$FW"

**The real fix, which has not been run.** Delete the stale cache so the next
build makes a device-only copy:

    rm -rf build/native_assets build/ios/Debug-iphonesimulator build/ios/iphonesimulator

That command was blocked by this session's own permissions, so it has not been
run and the theory above has not been confirmed by a clean rebuild. If build 51
installs first time after running it, the cache was the cause and this section
can go.

**Do not try to build this app for the simulator.** `mobile_scanner` ships no
simulator slice, so the build fails with "Module 'mobile_scanner' not found" —
and, as above, the attempt leaves behind a cached framework that breaks the next
device build.
