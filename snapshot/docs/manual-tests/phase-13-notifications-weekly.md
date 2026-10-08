# Phase 13: Notifications + Weekly View — Manual Test Brief

## Prerequisites
- App deployed to device (Mirador)
- Some diary entries logged across multiple days this week
- Notification permissions not yet granted (fresh state ideal, but not required)

## Test Cases

### TC-1: Reminders Tile in Settings
1. Settings → "Reminders" tile visible (bell icon), positioned before Theme
2. Tap → Notification Settings dialog opens
3. Four meal slots shown: Breakfast, Lunch, Dinner, Snack
4. All toggles off by default

### TC-2: Enable a Reminder
1. Settings → Reminders → toggle Breakfast ON
2. iOS notification permission prompt appears (first time only) → Allow
3. Time shown below label (default 9:00 AM), underlined in primary colour
4. Close dialog → re-open → Breakfast still ON at 9:00 AM (persisted)

### TC-3: Change Reminder Time
1. Settings → Reminders → Breakfast is ON
2. Tap the time text (e.g. "9:00 AM") → time picker opens
3. Set to 2 minutes from now → confirm
4. New time shown in dialog
5. Wait 2 minutes → notification fires: "Good morning — want to log breakfast?"
6. No title shown — just the body text

### TC-4: Notification Deep Link
1. When notification fires (TC-3), tap it
2. App opens to Add Meal screen with Breakfast pre-selected
3. Can search and add food normally

### TC-5: Disable a Reminder
1. Settings → Reminders → toggle Breakfast OFF
2. Close dialog
3. Previously scheduled notification should not fire
4. Re-open dialog → Breakfast is OFF

### TC-6: Multiple Reminders
1. Enable Lunch (1:00 PM) and Dinner (7:00 PM)
2. Close dialog → re-open → both still enabled with correct times
3. Each fires independently at its scheduled time
4. Body text matches slot:
   - Lunch: "Lunchtime — want to log something?"
   - Dinner: "Dinner time — what did you have?"

### TC-7: Reminders Survive App Restart
1. Enable Snack reminder at a time ~3 min from now
2. Kill app completely (swipe away from app switcher)
3. Wait for scheduled time → notification fires
4. Relaunch app → Settings → Reminders → Snack still ON

### TC-8: Diary — Week/Month Toggle
1. Diary tab → segmented button visible at top: "Week" | "Month"
2. Default is Month (existing calendar view)
3. Tap "Week" → calendar shrinks to week strip
4. Below the week strip: weekly summary card appears

### TC-9: Weekly Summary Card — Layout
1. Diary → Week view → summary card shows:
   - Date range header (e.g. "Feb 23 – Mar 1")
   - Column headers: eaten, Target, Net
   - 7 day rows (Mon–Sun) with day abbreviation
   - Today's row in bold
   - Untracked days show "—" dashes
   - Totals row at bottom (bold)
   - Macros section: protein, carbs, fat (actual/target in grams)

### TC-10: Weekly Summary — Correct Numbers
1. Diary → Week view
2. Cross-check a tracked day's kcal with Month view (tap same day)
3. Net = intake − target (positive shows "+", negative shows "−")
4. Totals = sum of all tracked days
5. Macro totals match sum of individual days

### TC-11: Week View — Day Selection
1. Diary → Week view → tap a different day in the week strip
2. Weekly summary card updates to show that week's data
3. Navigate weeks by swiping the week strip left/right

### TC-12: Switch Back to Month
1. Diary → Week view → tap "Month"
2. Full calendar returns
3. Day detail (DayInfoWidget) loads for the selected date
4. No stale weekly summary visible

### TC-13: Snack Reminder Body Text
1. Enable Snack reminder at a time ~2 min from now
2. Notification fires: "Snack check-in — anything to log?"
3. Tap → Add Meal screen with Snack pre-selected

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
