# Build 49 — tonight's dinner is already on your day, waiting to be confirmed

**22 August 2026**

## What changed

If the household has a meal planned for today, it now appears on your Home
screen among the food you have already eaten — same size, same shape, sitting in
the same row. The only differences are a thin outline, a slightly faded look, and
the words **Tap to confirm** where the calories would normally be.

Tap it and it becomes a real entry on your day. It counts from that moment.

Press and hold it and you get one other option: **Didn't have it**. That is a
real answer, not a way of dismissing the card. The house records that you skipped
it, and nothing goes on your day.

Either answer makes the card disappear straight away, even if the Mac Mini is
asleep. Your answer sits in the queue and lands when the Mini is next reachable.
Being asked to confirm the same dinner twice would be worse than the card
vanishing a moment early.

## Whose portion

Yours. If the meal is 640 calories a portion and the plan has you down for one
and a half of them, the card says 960 and that is what lands on your day.

Emily's phone shows her own card with her own portion, and answering on your
phone does not answer for her. Her dinner is still hers to confirm.

## If the meal has not been fully worked out

A meal with no calories yet says **Awaiting calories**. A meal where nobody has
set your portion says **Awaiting a portion**. The card is still there and still
tappable — you can confirm you ate something before the house has finished
working out what it was worth.

If you have calorie figures switched off, the card shows no number at all but
still says the meal and still lets you confirm it.

## Why it looks like an entry rather than announcing itself

You asked for this in these words: *"a 'ghost' entry on the home screen of the
phone app which looks just like a regular food entry, but says 'tap to confirm' —
you tap to confirm you ate that thing and it becomes a real entry."*

The app previously had the opposite: a faded row captioned "Planned", under a
heading of its own, deliberately built so a planned meal could never be mistaken
for an eaten one. You looked at that on 20 August and said it read as a second
system inside the first. It has been deleted rather than left sitting beside the
new card — one place a planned meal appears, not two.

The kitchen panel keeps everything it already had. This is in addition, not
instead.

## What was checked by running it

- The whole test suite: 755 tests, all passing.
- The check that Home actually hands its planned meals to the diary list was
  deliberately broken — the argument removed from Home — and the right test
  failed with the right reason before it was put back.
- Build 49 installed on the phone and the version read back off the device.

## What has not been tried on the phone yet

Everything above is proved by tests, not by a dinner. The plan on the Mac Mini
has three planned meals on past dates, so seeing a real ghost card on Home needs
a meal planned for today on the kitchen panel.
