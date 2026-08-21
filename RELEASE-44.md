# Build 44 — what changed, and what did not

**Date:** 2026-08-21
**Branch:** `household-release-1`
**Status:** built here, not on your phone. Build 43 goes on first.

Everything in here was found by using build 42 — three of the four are things
you reported yourself, in your own words, and the fourth turned up while I was
looking at the third.

## The screen after you photograph a packet

Your note at the end of the build-42 walkthrough:

> *"I added peanut butter through that route and it did work but I only know
> that because afterwards I exited and then went and added it from the barcode…
> there was no success message. It didn't ask me if I wanted to log that food or
> anything. It literally just stopped. Everything went grey and I had to hit back
> to get back to the main menu so there's no success path for that."*

I ran that path rather than reading it, and the first thing worth telling you is
the reassuring half: **the food really was saved.** Nothing was going wrong
behind the screen. The screen simply never said anything.

It turned out to be three separate silences, not one.

**1. A save that worked said nothing.** I drove the whole flow and then asked the
screen what a person could read on it afterwards. The answer was one word — the
button you started from. The form closed, the packet screen closed, and you were
back on Home with no more information than before you pressed Save. Now a line
comes up naming the food, and saying where it went: it is in the household food
list, and that is not the same place as your day. That last part is deliberate —
your *"It didn't ask me if I wanted to log that food"* is a fair complaint, and
the honest answer is that saving a packet and eating it are two different acts.
The line now says so instead of leaving you to work it out.

The confirmation went into the form itself rather than into the photograph flow,
because that form is the one place a food is ever saved — and the other two ways
into it, typing a packet in by hand and looking one up online, were exactly as
silent as the photograph route. One change, three routes.

**2. "Everything went grey" was a wait with nothing on it.** While the Mac Mini
reads your three photographs, every button on the screen is disabled — which is
correct, and on its own is indistinguishable from the app having died. It now
says it is reading, and shows it.

**3. It could genuinely stop.** The screen knew how to talk about two kinds of
failure. Anything else — a photograph no longer on disk, a reply it could not
make sense of — escaped both, and left the screen with every control dead and
nothing on it to explain why. I confirmed this by running it: the buttons come
back unpressable, and Back is the only way out. Exactly what you hit. Now it says
something went wrong, keeps your photographs, and gives the buttons back so you
can try again or type the numbers in.

## Rows that said "Something you said" for ever

Two things you reported are the same fault:

> *"Just says 'working out what that was' for ages, then stops. No food appears,
> eaten counter does not increase."*

and the three rows that sat on your days with no calories against them.

It has nothing to do with understanding sentences. **A sentence is asked about
once**, in the moment you say it. If that single attempt does not land — the Mac
Mini asleep, the address wrong, the phone put down mid-answer — nothing ever
asked again, and the row stayed exactly as it was for good.

There was a retry written for precisely this. It had never been called from
anywhere in the app. Its own note says it runs "when the day is read", and the
screen that read the day was the second tab — the one you had me remove. The
only moment it could have happened went out with it, and nobody noticed, because
a retry that never runs and a retry that has not run yet look identical from
where you are standing.

It now runs when the app opens and the phone is talking to the house anyway. If
the house cannot be reached it stays quiet and the rows wait for next time,
which is what they were doing regardless.

## A word that was doing damage

Twice now you have had to tell me that the machine I kept naming does not
exist. There is the Mac Mini, there is the kitchen tablet, and there is your
phone. I had invented a fourth and used it in a release note and in walkthrough
steps.

It is worse than jargon. Jargon is at least a hard word for a real thing; this
was a plausible name for a machine that is not there, so it read as correct
while sending you to the wrong room to look for a fault. It is out of everything
you have not already been shown, and a check now fails if it comes back — which
it did, on the first draft of this very page, which is how I know the check
works.

The walkthroughs you have already run still contain it. I left those alone on
purpose — a finished run is the record of what you were actually shown, and
tidying it up afterwards would be rewriting history in my own favour.

## What is not fixed

- **A packet saved while the Mac Mini is out of reach cannot be searched for
  until the phone gets home.** It is queued and it will go up, but the search
  asks the house, and the house has not heard of it yet. So the confirmation's
  advice — search for it when you want it on a day — is true eventually rather
  than immediately. Worth knowing if you ever photograph a packet in a shop.
- **Saving a packet still does not offer to put it on your day.** Your words
  again: *"It didn't ask me if I wanted to log that food."* That is a real gap
  and it is a design question rather than a bug, so I have not invented an answer
  to it. The app already has a way to find a food and eat it; whether the packet
  screen should hand you straight into that is your call.
- **Your 20 August double-count is still unexplained and still needs you.** The
  same sentence was captured twice, seventeen seconds apart, as two genuinely
  different recordings — so it is repeat capture, not the app sending one thing
  twice. About 350 extra calories. Nothing has been changed about it.
- Everything else in build 43's list still stands.
