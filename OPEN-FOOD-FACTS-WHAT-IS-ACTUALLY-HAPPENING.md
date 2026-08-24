# What is actually happening when the food search fails

**Date:** 2026-08-24 14:10 (clock read in the turn this was written)

Aidan, on being told Open Food Facts was down: *"If so, it's been down for a
week or so, so this warrants further investigation."*

He was right to push. **They are not down.** Here is what I ran and what came
back.

## What the app asks them

One request, built in `lib/core/utils/off_const.dart` and sent from
`off_data_source.dart`:

```
GET https://world.openfoodfacts.org/cgi/search.pl
      ?search_terms=<what you typed>
      &fields=code,brands,product_name,product_name_en,product_name_de,
              product_name_fr,url,image_url,image_front_thumb_url,
              image_front_url,product_quantity,quantity,serving_quantity,
              serving_size,nutriments
      &json=true
User-Agent: OpenNutriTracker - iOS - Version 1.0.0 (58) - https://github.com/simonoppowa/OpenNutriTracker
```

One attempt. Twenty-second timeout. No retry.

## What comes back

I sent that exact request twenty times in a row at 13:51 today.

| | |
|---|---|
| **200 (worked)** | **6** |
| **503 (refused)** | **14** |

The 503 is not a timeout. It comes back in about a third of a second, with an
HTML page headed *"Page temporarily unavailable — Open Food Facts"*. The app
tries to read that as JSON, fails, and shows you an error.

## It is not us

I checked the four things that would have made it our fault, and it is none of
them:

- **Not the user agent.** The same request with the app's user agent, with no
  custom user agent, and with a browser's user agent all failed identically.
- **Not the `fields` list.** Dropping it entirely still fails. Individual fields
  succeed and fail at random on repeat.
- **Not a retired route.** The route answers — just not reliably.
- **Not rate limiting from our end.** The failures are interleaved with
  successes in a single sequential run, with no pattern.

The same URL returns 503 and then 200 seconds apart with nothing changed. That
is a server failing part of the time, not a request being refused.

## But it is only that one address of theirs

Same twenty-minute window, same user agent:

| Address | Worked |
|---|---|
| `world.openfoodfacts.org/cgi/search.pl` — **what the app uses** | **6 of 20** |
| `world.openfoodfacts.org/api/v2/search` | 8 of 10 |
| `search.openfoodfacts.org/search` — their dedicated search service | **10 of 10** |
| `world.openfoodfacts.org/api/v2/product/<barcode>` — barcode lookups | 5 of 5 |

So barcodes are fine, which matches what he found on Saturday: he got past it
with a barcode. It is specifically the old free-text search address that is
unwell, and they have two newer ones that are not.

## What each option would actually cost

**Retry the same address.** Each attempt fails in a third of a second, so
retrying is nearly free in time. At six-in-twenty, three attempts get you a
result about two times in three and five attempts about five times in six. It
is a patch on somebody else's fault, and if their reliability drops further it
stops working without warning.

**Move to `api/v2/search`.** No good: it ignores `search_terms` entirely. I
asked it for "peanut butter" and it answered with a count of 4,704,608 — the
whole database. It filters by category tags, not by free text. It is not the
same feature.

**Move to `search.openfoodfacts.org`.** It answers every time and the nutrition
figures use the same names the app already reads (`energy-kcal_100g` and so on),
so that part carries over untouched. **But it does not return four things the
current address does**, and one of them matters a lot here:

- `product_quantity` — what a pack weighs
- `serving_quantity` and `serving_size` — what the pack calls a serving
- `quantity` — the pack size as written on the label

Those are exactly what feeds the "one (66.7 g)" and "pack (400 g)" units. Move
to this service as it stands and every food found by searching loses the ability
to be added as *one of them* — the feature built for the pie and the fish cake.
It would still work for anything scanned by barcode, because barcode lookups
would stay where they are.

There may be a way to ask that service for those fields, or to look the pack
sizes up by barcode afterwards for the handful of results shown. I have not
established either, and I am not going to guess at it in a report.

Its index is also not live: the record I looked at was last indexed on
26 October 2024.

## What I recommend, and what needs him

**Do both, in this order.** Retry the current address two or three times before
showing an error — it is a few lines, it costs a second at worst, and it turns
most of today's failures into results without changing where the food comes
from. Then treat the move to their search service as its own piece of work,
starting with whether the pack sizes can be recovered — because losing them
silently would break something he uses.

**What needs him:** whether that is the right order, and whether losing pack
sizes on searched foods is acceptable if the pack-size question turns out to
have no answer. **Neither is built.**
