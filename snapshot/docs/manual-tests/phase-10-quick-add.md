# Phase 10: Quick-Add Estimate — Manual Test Brief

## Prerequisites
- App built and running on device
- At least one existing food log entry (to verify coexistence)

## Test Cases

### TC-1: Bottom sheet shows Quick Add option
1. Tap the FAB (+) on the home screen
2. **Expected:** Bottom sheet shows "Quick Add" tile with bolt icon, between "Add food" and "Activity"
3. **Expected:** Subtitle reads "Just enter calories"

### TC-2: Quick Add screen opens correctly
1. Tap "Quick Add" in the bottom sheet
2. **Expected:** Screen opens with "Quick Add" in the app bar
3. **Expected:** Calories field is auto-focused and keyboard is open (numeric)
4. **Expected:** Meal slot segmented button is pre-selected based on time of day (breakfast/lunch/dinner/snack)

### TC-3: Save with calories only
1. Open Quick Add screen
2. Enter `350` in the calories field
3. Leave macros and label empty
4. Tap Save
5. **Expected:** Snackbar says "Quick add saved"
6. **Expected:** Returns to home screen
7. **Expected:** 350 kcal entry appears in the time-appropriate meal slot
8. **Expected:** Daily total increases by 350

### TC-4: Save with macros and label
1. Open Quick Add screen
2. Enter `500` calories, `30` protein, `60` carbs, `15` fat
3. Enter label: "Leftover pasta"
4. Select "Dinner" meal slot
5. Tap Save
6. **Expected:** Entry appears in Dinner section
7. **Expected:** Card shows bolt icon, "Leftover pasta" as name, "500 kcal" badge
8. **Expected:** No amount/unit line below the name (unlike food entries)

### TC-5: Meal slot selection
1. Open Quick Add screen
2. Note which slot is pre-selected
3. Tap a different slot (e.g. "Snack")
4. Enter `100` calories, Save
5. **Expected:** Entry appears in Snack section, not the originally suggested slot

### TC-6: Validation — empty or zero calories
1. Open Quick Add screen
2. Tap Save without entering anything
3. **Expected:** Validation error on calories field, entry not saved
4. Enter `0`, tap Save
5. **Expected:** Validation error, entry not saved

### TC-7: Quick-add card visual distinction
1. Have both a regular food entry and a quick-add entry in the same meal slot
2. **Expected:** Food entry shows food image (or restaurant icon) + amount/unit text
3. **Expected:** Quick-add entry shows bolt icon, label (or "Quick add" default), no amount/unit text
4. **Expected:** Both show kcal badge in top-left

### TC-8: Swipe-to-delete on quick-add card
1. Find a quick-add card on the home screen
2. Swipe it down to dismiss
3. **Expected:** Card is removed, daily totals decrease accordingly
4. **Expected:** Snackbar with "Undo" appears

### TC-9: Tap on quick-add card (no edit)
1. Tap on a quick-add card
2. **Expected:** Nothing happens (no edit dialog opens)
3. This is intentional — quick-add entries can't be edited via the amount dialog

### TC-10: Long-press on quick-add card (delete)
1. Long-press on a quick-add card
2. **Expected:** Delete confirmation dialog appears
3. Confirm delete
4. **Expected:** Card removed, totals updated

### TC-11: Quick-add entries not in "Recently Added"
1. Add a quick-add entry
2. Tap FAB > "Add food" to open the meal search screen
3. Check the "Recently" tab
4. **Expected:** Quick-add entries do NOT appear in recently added foods

### TC-12: Diary view shows quick-add entries
1. Add a quick-add entry for today
2. Switch to Diary tab
3. Tap today's date
4. **Expected:** Quick-add entry appears in the correct meal slot with bolt icon and label

### TC-13: Persistence across app restart
1. Add a quick-add entry with label "Test persistence" and 275 kcal
2. Force-quit the app
3. Relaunch
4. **Expected:** Entry still appears with correct kcal, label, and meal slot
5. **Expected:** Daily totals include the quick-add calories

### TC-14: Schema migration (upgrade from v3)
1. If testing on a device that had the previous app version installed:
   - Launch the updated app
   - **Expected:** Existing food entries still display correctly
   - **Expected:** Quick-add feature works alongside old entries
   - **Expected:** No data loss

## Result

| TC | Pass/Fail | Notes |
|----|-----------|-------|
| 1  |           |       |
| 2  |           |       |
| 3  |           |       |
| 4  |           |       |
| 5  |           |       |
| 6  |           |       |
| 7  |           |       |
| 8  |           |       |
| 9  |           |       |
| 10 |           |       |
| 11 |           |       |
| 12 |           |       |
| 13 |           |       |
| 14 |           |       |
