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
