# Phase 14: Settings & Configuration — Manual Test Brief

## Prerequisites
- App deployed to device (Mirador)
- Some diary entries logged (for export testing)
- At least one recipe created (for export testing)
- Apple Health permission previously granted (or ready to grant)

## Test Cases

### TC-1: Exercise Multiplier Tile
1. Settings → "Exercise Multiplier" tile visible (dumbbell icon), after Calculations
2. Tap → dialog opens with description text, large percentage display, and slider
3. Default value should be 75%
4. Drag slider → percentage updates in real time (5% increments)
5. Tap OK → dialog closes

### TC-2: Exercise Multiplier Persists
1. Settings → Exercise Multiplier → set to 50% → OK
2. Leave settings, return → tap Exercise Multiplier again
3. Slider shows 50%
4. Go to Home tab → allowance should reflect the lower multiplier (earned calories reduced)

### TC-3: Exercise Multiplier Cancel
1. Settings → Exercise Multiplier → change to 25% → tap CANCEL
2. Re-open → still shows previous value (50% from TC-2)

### TC-4: Apple Health Tile
1. Settings → "Apple Health" tile visible (heart monitor icon)
2. Subtitle shows either "Active Energy: Connected" or "Not connected"
3. Tap → dialog opens showing status with check/cancel icon

### TC-5: Apple Health — Permission Already Granted
1. If Health is already connected: dialog shows green check + "Active Energy: Connected"
2. No "Request Permission" button shown
3. Tap OK → dialog closes

### TC-6: Apple Health — Request Permission
1. If Health is not connected: dialog shows grey X + "Not connected"
2. "Request Permission" button visible
3. Tap it → iOS Health permission sheet appears
4. Grant permission → dialog updates to show connected status

### TC-7: Day Start Tile
1. Settings → "Day Start" tile visible (moon icon), after Exercise Multiplier
2. Subtitle shows current value (default "2:00 AM")
3. Tap → dialog opens with radio options: 12 AM through 6 AM

### TC-8: Day Start Selection
1. Settings → Day Start → select "4:00 AM" → dialog closes
2. Tile subtitle now shows "4:00 AM"
3. Leave settings, return → subtitle still shows "4:00 AM"

### TC-9: HealthKit Debug Screen Removed
1. Scroll through all settings tiles
2. No "HealthKit Debug" entry exists (replaced by Apple Health tile)

### TC-10: Calculations — Direct Target Field
1. Settings → Calculations → dialog now shows:
   - TDEE equation dropdown (read-only, same as before)
   - "Calculated TDEE: XXXX kcal" text
   - "Daily Target" text field with current target value
   - Adjustment slider (same as before)
2. The target field value = TDEE + goal adjustment + user adjustment

### TC-11: Calculations — Edit Target Directly
1. Settings → Calculations → clear the Daily Target field
2. Type a round number (e.g. 2500)
3. Adjustment slider moves to match: slider = 2500 - TDEE - goal_adj
4. Slider label updates in real time
5. Tap OK → Home tab reflects the new target

### TC-12: Calculations — Slider Syncs Target
1. Settings → Calculations → drag the adjustment slider to +200
2. Daily Target field updates to show TDEE + goal_adj + 200
3. Bidirectional sync works in both directions

### TC-13: Calculations — Macro Mode Toggle
1. Settings → Calculations → below "Macronutrient Distribution:" heading
2. Segmented button: "Percentage" | "Grams"
3. Default is Percentage (existing sliders visible)

### TC-14: Macro Percentage Mode
1. Settings → Calculations → Percentage mode selected
2. Three colour-coded sliders (carbs/protein/fat) work as before
3. Percentages sum to 100%
4. Save → Home shows correct macro targets

### TC-15: Macro Grams Mode
1. Settings → Calculations → tap "Grams" segment
2. Sliders disappear, replaced by 3 text fields (Protein, Carbs, Fat) with "g" suffix
3. Enter values: Protein 150, Carbs 200, Fat 70
4. Tap OK → Home tab shows macro targets as 150g protein, 200g carbs, 70g fat

### TC-16: Macro Grams Mode Persists
1. Leave settings, return → Calculations dialog
2. "Grams" segment is selected
3. Fields show 150, 200, 70 (values from TC-15)

### TC-17: Reset Button Clears Gram Mode
1. Settings → Calculations → in Grams mode → tap Reset
2. Mode switches back to Percentage
3. Sliders return with default percentages (60/15/25)
4. Gram text fields are cleared

### TC-18: Export — Format Toggle
1. Settings → Export/Import → dialog now shows segmented button: "JSON" | "CSV"
2. Default is JSON
3. Both Export and Import buttons visible in JSON mode

### TC-19: Export JSON — Includes Food Items + Recipes
1. Settings → Export/Import → JSON selected → Export
2. File picker appears → save the zip
3. Inspect zip contents (e.g. via Files app or on Mac):
   - `user_activity.json` (existing)
   - `user_intake.json` (existing)
   - `user_tracked_day.json` (existing)
   - `food_items.json` (new)
   - `recipes.json` (new, with nested ingredients)

### TC-20: Export CSV
1. Settings → Export/Import → tap "CSV" segment
2. Import button disappears (CSV is export-only)
3. Tap Export → file picker appears → save
4. Zip contains CSV files: `food_items.csv`, `log_entries.csv`, `daily_stats.csv`, `recipes.csv`, `recipe_ingredients.csv`
5. Open a CSV in a text editor — header row present, comma-separated, values with commas are quoted

### TC-21: Import JSON — Backward Compatible
1. Settings → Export/Import → JSON mode → Import
2. Pick a previously exported zip (from before Phase 14, without food_items/recipes)
3. Import succeeds (no error) — old format still works

### TC-22: Import JSON — Full
1. Export a fresh JSON zip (which includes food_items + recipes)
2. Import that zip on the same device
3. Import succeeds
4. Data intact on Home and Diary screens

### TC-23: Settings Tile Order
1. Verify settings tiles appear in this order:
   - Units
   - Calculations
   - Exercise Multiplier
   - Day Start
   - Apple Health
   - Reminders
   - Theme
   - Export/Import
   - OpenAI API Key
   - Claude API Key
   - Disclaimer
   - Report Error
   - Privacy Settings
   - About

## Results

| TC  | Pass/Fail | Notes |
|-----|-----------|-------|
| 1   |           |       |
| 2   |           |       |
| 3   |           |       |
| 4   |           |       |
| 5   |           |       |
| 6   |           |       |
| 7   |           |       |
| 8   |           |       |
| 9   |           |       |
| 10  |           |       |
| 11  |           |       |
| 12  |           |       |
| 13  |           |       |
| 14  |           |       |
| 15  |           |       |
| 16  |           |       |
| 17  |           |       |
| 18  |           |       |
| 19  |           |       |
| 20  |           |       |
| 21  |           |       |
| 22  |           |       |
| 23  |           |       |
