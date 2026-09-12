# Phase 5: Database Migration — Manual Test Brief

## Prerequisites
- App built and deployed to device: `flutter run -d 00008120-001255D9216B401E --debug`
- If you have existing data from previous sessions, the migration will run automatically on first launch
- If this is a fresh install, you'll start with an empty database (no migration needed)

## Test 1: App Launch & Migration
**Goal:** Verify the app launches and Hive data (if any) is migrated to drift/SQLite.

1. Launch the app
2. **Expected:** App opens to the home/dashboard screen without crashes
3. If you had existing data (foods logged, tracked days), verify it appears
4. **Pass criteria:** App launches, no crash, existing data visible (or empty state if fresh install)

## Test 2: Log a Food Item
**Goal:** Verify food logging works end-to-end through the new drift database.

1. Tap the + button to add a meal (breakfast, lunch, dinner, or snack)
2. Search for a food (e.g. "chicken breast" or "banana")
3. Select a result from the search
4. Set an amount (e.g. 100g) and confirm
5. **Expected:** Food appears in the diary for today's meal slot
6. **Expected:** Dashboard calorie/macro numbers update
7. **Pass criteria:** Food logged, visible in diary, totals update

## Test 3: View Diary / Calendar
**Goal:** Verify tracked day data is read correctly from drift.

1. Navigate to the diary/calendar view
2. Tap on today's date
3. **Expected:** Shows the food you just logged in Test 2
4. If you have historical data from before the migration, tap on a past date
5. **Expected:** Historical data appears correctly
6. **Pass criteria:** Diary shows correct data for today and any historical dates

## Test 4: Delete a Food Entry
**Goal:** Verify deletion works and totals update correctly.

1. In the diary, find the food item you logged in Test 2
2. Delete it (swipe or tap to delete)
3. **Expected:** Item removed from the diary
4. **Expected:** Dashboard calorie/macro totals decrease by the correct amount
5. **Pass criteria:** Item gone, totals recalculated

## Test 5: Log an Activity
**Goal:** Verify activity logging through drift.

1. Go to add an activity
2. Select any physical activity (e.g. "Running")
3. Set a duration (e.g. 30 minutes) and confirm
4. **Expected:** Activity appears in today's view
5. **Expected:** Burned calories number updates
6. **Pass criteria:** Activity logged and visible

## Test 6: Delete an Activity
**Goal:** Verify activity deletion works.

1. Find the activity from Test 5
2. Delete it
3. **Expected:** Activity removed, burned calories adjust
4. **Pass criteria:** Activity gone, totals recalculated

## Test 7: Edit Food Amount
**Goal:** Verify updating an intake amount works.

1. Log a food item (any food, any amount)
2. Tap on the logged item to view details
3. Edit the amount (e.g. change from 100g to 200g)
4. **Expected:** Amount updates, calorie/macro totals adjust proportionally
5. **Pass criteria:** New amount saved, totals correct

## Test 8: Settings Persist
**Goal:** Verify config data is stored and retrieved from drift.

1. Go to Settings
2. Change a setting (e.g. toggle imperial units, change theme)
3. Force-close the app completely
4. Reopen the app
5. Go back to Settings
6. **Expected:** Your setting change persists
7. **Pass criteria:** Setting survived app restart

## Test 9: Export Data
**Goal:** Verify export still produces a valid zip file.

1. Go to Settings > Export Data
2. Export to a file
3. **Expected:** A .zip file is saved
4. **Pass criteria:** File saves without error (import will be tested separately)

## Test 10: Recently Used Foods
**Goal:** Verify the "recent" food list works with drift deduplication.

1. Log the same food 3 times on different days/times (or at least in the same session with different amounts)
2. Start adding a new meal and check the "Recent" tab
3. **Expected:** That food appears only once in recents (deduplicated), most recent first
4. **Pass criteria:** No duplicates in recent list, ordered newest-first

## Overall Pass Criteria
- All 10 tests pass
- No crashes during any operation
- No data appears missing or corrupted after migration
