# Phase 6: Core Domain — Manual Test Brief

## What Changed

Phase 6 added the "calculation engine" — pure functions that future features will build on. No UI was changed, but existing code paths were modified, so we need to verify nothing broke.

### Modified files (risk of regression):
- **`calorie_goal_calc.dart`** — added `getAllowance()` with exercise multiplier; `getTotalKcalGoal()` now wraps it with multiplier=1.0 (should behave identically to before)
- **`macro_calc.dart`** — added `MacroTargets` class and `getScaledMacroTargets()`; existing `getTotalCarbsGoal/FatsGoal/ProteinsGoal` untouched
- **`get_kcal_goal_usecase.dart`** — now reads `exerciseMultiplier` from config (defaults to 0.75). **This changes calorie goal calculation** — exercise calories will now be credited at 75% instead of 100%
- **`config_entity.dart`** — added `exerciseMultiplier` field (nullable, defaults to null → 0.75 in usecase)
- **`config_repository.dart`** — added `getExerciseMultiplier()` / `setExerciseMultiplier()`; `getConfig()` now reads the multiplier
- **`log_entry_dao.dart`** — added `getByDate()` method (no change to existing methods)

### New files (no regression risk, tested via unit tests):
- `day_boundary_calc.dart`, `meal_slot_calc.dart`, `nutrition_validator.dart`, `recipe_calc.dart`, `weekly_calc.dart`, `recompute_day_usecase.dart`

## Prerequisites
- App built and deployed to device: `flutter run -d 00008120-001255D9216B401E --debug`

## Test 1: App Launch (no crash)
**Goal:** Verify the app still launches after all the changes.

1. Launch the app
2. **Expected:** App opens to the home/dashboard screen without crashes
3. **Pass criteria:** App launches, no crash

## Test 2: Calorie Goal Display
**Goal:** Verify the dashboard still shows a calorie goal. Note: the number may be **lower** than before if you have logged activities, because exercise calories are now credited at 75% instead of 100%.

1. Look at the dashboard calorie circle/display
2. **Expected:** A calorie goal number is shown (not zero, not NaN, not blank)
3. If you remember your previous goal number and have no activities logged, it should be **unchanged**
4. If you have activities logged, the goal may be ~25% lower on the exercise portion
5. **Pass criteria:** Goal is a reasonable number, no errors

## Test 3: Log a Food Item
**Goal:** Verify food logging still works end-to-end.

1. Tap + to add a meal
2. Search for any food (e.g. "apple" or "rice")
3. Select a result, set an amount, confirm
4. **Expected:** Food appears in diary, calorie/macro totals update
5. **Pass criteria:** Logging works, totals are correct

## Test 4: Macro Goals Display
**Goal:** Verify macro goals (carbs, fat, protein) still display correctly.

1. Look at the dashboard macro bars/numbers
2. **Expected:** All three macros show a goal and tracked amount
3. **Expected:** Numbers are reasonable (not zero or negative unless you haven't eaten)
4. **Pass criteria:** Macro display works, no visual errors

## Test 5: Log an Activity
**Goal:** Verify activity logging still works and earned calories update correctly.

1. Add an activity (e.g. "Running", 30 minutes)
2. **Expected:** Activity appears, burned calories shown
3. **Expected:** Calorie goal increases (but by ~75% of the burn, not 100%)
4. For example: if the activity burns 300 kcal, the goal should increase by ~225 kcal
5. **Pass criteria:** Activity logged, goal increases by a reasonable amount

## Test 6: Delete the Food and Activity
**Goal:** Verify deletion still works.

1. Delete the food from Test 3
2. Delete the activity from Test 5
3. **Expected:** Both removed, totals adjust back
4. **Pass criteria:** Deletion works, totals recalculate

## Test 7: Settings Persist
**Goal:** Verify config changes didn't break settings storage.

1. Go to Settings
2. Toggle a setting (e.g. theme or imperial units)
3. Force-close the app
4. Reopen and check Settings
5. **Expected:** Setting persisted
6. **Pass criteria:** Settings survive restart

## Test 8: Delete from Home (long-press modal)
**Goal:** Verify that deleting a food item from the home page now uses the same long-press modal as the diary page (not drag-to-trash).

1. Make sure you have at least one food item logged (from Test 3)
2. On the **home** page, long-press on a food item card
3. **Expected:** A confirmation dialog appears asking if you want to delete
4. Tap OK to confirm
5. **Expected:** Item is removed, totals update, snackbar says "Item deleted"
6. **Not expected:** No red trash bar should appear at the bottom of the screen. The drag-to-trash mechanism has been removed.
7. **Pass criteria:** Long-press shows delete dialog, item deletes correctly, no drag-to-trash UI

## Key Thing to Watch For

The **exercise multiplier change** (Test 5) is the most significant behavioral change. If you've been using the app with activities, your daily calorie goal will now be ~25% lower on the exercise-credited portion. This is the "earned calories" model — it's intentional, but I should have flagged it before implementing. If the new behavior doesn't feel right, we can adjust the default multiplier.

## Overall Pass Criteria
- All 8 tests pass
- No crashes
- Calorie/macro display working
- Exercise credit at ~75% (the new "earned calories" model)
