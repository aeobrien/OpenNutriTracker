# Phase 7: Today Dashboard + Allowance UI — Manual Test Brief

## What Changed

The home dashboard has been redesigned with a new layout:
- **Date row** — "Today" left, "Fri 21 Feb" right (subdued)
- **Calorie circle** — same gauge, but now shows "over target" (neutral) instead of clamping to 0 when over
- **Allowance breakdown** — row of three columns: base / +earned / eaten (replaces the old "supplied"/"burned" flanking columns)
- **Weekly context line** — "This week: X kcal under/over target" (if data available)
- **Horizontal macro bars** — carbs, fat, protein as linear progress bars (replaces the small circular gauges)
- **Calendar dot cleanup** — deleting all food for a day now removes the calendar dot

### Modified files:
- `dashboard_widget.dart` — full layout rewrite
- `macro_nutriments_widget.dart` — circular → linear bars
- `home_state.dart` — added `totalKcalBase`, `totalKcalEarned`, `weeklyRemaining`
- `home_bloc.dart` — computes base, earned, weekly; calls `deleteDayIfEmpty` on delete
- `home_page.dart` — passes new fields to dashboard
- `daily_stats_dao.dart` — added `deleteByDate()`
- `tracked_day_repository.dart` — added `deleteDayIfEmpty()`
- `add_tracked_day_usecase.dart` — added `deleteDayIfEmpty()`
- `locator.dart` — added `GetTrackedDayUsecase` to HomeBloc

## Prerequisites
- App built and deployed to device: `flutter run -d 00008120-001255D9216B401E --debug`

## Test 1: Dashboard Layout — Date Visible
1. Open the app
2. **Expected:** At the top of the dashboard card, "Today" appears on the left, and the current date (e.g. "Sat 21 Feb") on the right, in a subdued/grey style
3. **Pass criteria:** Date row visible, correct date

## Test 2: Calorie Circle — Under Target
1. With no food logged (or partial food), look at the calorie circle
2. **Expected:** Shows a number and "kcal left" below it
3. **Expected:** The gauge fills proportionally
4. **Pass criteria:** "kcal left" shown, number is positive

## Test 3: Calorie Circle — Over Target
1. Log enough food to exceed your daily calorie goal
2. **Expected:** The circle shows the overage amount and "over target" (not "kcal left")
3. **Expected:** The text is neutral colour (same as the rest of the UI) — no red/error styling
4. **Pass criteria:** "over target" shown with neutral styling, correct overage number

## Test 4: Allowance Breakdown Row
1. Look below the calorie circle
2. **Expected:** Three columns: a number with "base" below, a "+X" number with "earned" below, and a number with "eaten" below
3. **Expected:** base = your TDEE + goal adjustment (no exercise). earned = exercise credit (0 if no activity). eaten = total food logged.
4. **Expected:** base + earned should roughly equal the daily total shown in the circle
5. **Pass criteria:** All three values visible and reasonable

## Test 5: Earned Calories Appear After Activity
1. Log an activity (e.g. "Running", 30 minutes)
2. **Expected:** The "earned" number increases from 0 to some value
3. **Expected:** The "kcal left" in the circle also increases
4. **Pass criteria:** Earned column updates when activity is logged

## Test 6: Weekly Context Line
1. With at least one day of tracking this week, look below the allowance breakdown
2. **Expected:** A line like "This week: X kcal under target" or "This week: X kcal over target" in subdued text
3. **Expected:** If no tracked days exist this week, the line should not appear
4. **Pass criteria:** Weekly line shows with correct direction (under/over)

## Test 7: Horizontal Macro Bars
1. Look at the bottom of the dashboard card
2. **Expected:** Three horizontal progress bars stacked vertically for carbs, fat, protein
3. **Expected:** Each bar has: label on left, coloured bar in center, "X/Y g" text on right
4. **Expected:** Bars fill proportionally to intake vs goal
5. **Expected:** No red/error colours even when over goal (bar fills to 100% and stops)
6. **Pass criteria:** Three horizontal bars, correct labels and numbers

## Test 8: Calendar Dot Cleanup
1. Go to the diary page and find a day with a calendar dot
2. Delete all food items and activities for that day
3. Go back to the diary calendar view
4. **Expected:** The calendar dot for that day has disappeared
5. **Pass criteria:** Empty days have no calendar dot

## Test 9: Old "Supplied"/"Burned" Removed
1. Look at the dashboard
2. **Expected:** The old up-arrow/down-arrow columns flanking the calorie circle ("supplied"/"burned") are gone
3. **Expected:** Replaced by the allowance breakdown row (base/earned/eaten) below the circle
4. **Pass criteria:** No "supplied" or "burned" labels visible on the dashboard

## Overall Pass Criteria
- All 9 tests pass
- No crashes
- Dashboard feels clean and informative
- No red/error/shame styling anywhere
- Weekly context line is helpful (or invisible if no data)
