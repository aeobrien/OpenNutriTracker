# Phase 8: Friction Foundations — Manual Test Brief

## Pre-conditions
- App built and running on device
- At least one food item previously logged (for testing portion memory)

## Test Cases

### 8.1 Portion Memory
1. Log "Rice" at 200g via meal detail screen
2. Navigate away, then search for "Rice" again in Recently tab
3. Tap to open meal detail
4. **Expected:** Quantity field defaults to "200" (not "100")

### 8.2 Increment Buttons (Meal Detail)
1. Open any food in meal detail screen
2. Observe chip buttons below quantity field: +10g, +50g, +100g
3. Set quantity to "50", tap "+100g"
4. **Expected:** Quantity updates to "150"
5. Switch unit to "serving" (if available)
6. **Expected:** Chips change to "+0.5 srv", "+1 srv"

### 8.3 Improved Defaults
1. Open a food that has never been logged before
2. **Expected:** Defaults to 100g (metric) or 1 (imperial/serving)
3. Open a food that was last logged at 250g
4. **Expected:** Defaults to 250g

### 8.4 Favourites
1. Open any food in meal detail screen
2. Tap the star icon in the app bar
3. **Expected:** Star fills in
4. Go to Recently tab
5. **Expected:** Food appears in "Favourites" section at top
6. Tap the star icon on the meal card in Recently tab
7. **Expected:** Food removed from Favourites section
8. On any meal item card in Recently tab, tap star to favourite
9. **Expected:** Star fills, item appears in Favourites section on reload

### 8.5 One-Tap Re-log
1. Log a food at a specific amount (e.g., 150g)
2. Go to Recently tab
3. **Expected:** Card shows "last: 150g" subtitle
4. Tap the filled circle "+" icon (quick-add)
5. **Expected:** Food logged immediately at 150g, snackbar shown, returns to home

### 8.6 Inline Editing (Edit Dialog)
1. On home page, tap a logged food item
2. **Expected:** Edit dialog opens with current amount pre-selected
3. Observe increment chips: +10g, +50g, +100g
4. Tap "+50g"
5. **Expected:** Amount increases by 50, kcal estimate updates live
6. Tap OK
7. **Expected:** Item updated

### 8.7 Swipe to Delete
1. On home page, in any meal slot, swipe a food card downward
2. **Expected:** Card dismissed with neutral background and trash icon
3. **Expected:** "Item deleted" snackbar with "Undo" action appears
4. Tap "Undo"
5. **Expected:** Food item restored to the meal slot
6. Swipe another card down, do NOT tap undo
7. **Expected:** Item remains deleted after snackbar disappears

### 8.9 Meal Slot Auto-Suggestion
1. If navigating to add meal without specifying type (future: generic "+" button), the meal type should auto-select based on time of day:
   - 6-10: Breakfast
   - 10-14: Lunch
   - 17-21: Dinner
   - Other: Snack
2. Currently all navigation paths specify a meal type, so this is a safety net. Verify no crashes when meal type is provided.

## Pass Criteria
- All test cases pass
- No crashes during any interaction
- Snackbars appear and disappear correctly
- Favourite state persists across app restarts
