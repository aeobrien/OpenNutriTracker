# Phase 12: Recipes + LLM Recipe Builder — Manual Test Brief

## Prerequisites
- Claude API key configured in Settings
- At least a few food items already logged (so ingredient search has local results)
- A recipe URL from a cooking site (e.g. allrecipes.com, bbcgoodfood.com)

## Test Cases

### TC-1: Bottom Nav — Recipes Tab
1. Launch app → 4 tabs visible: Home, Diary, Recipes, Profile
2. Tap Recipes → recipe list screen with search bar
3. Shows "No recipes yet" placeholder
4. Two FABs visible: small sparkle (LLM) and large + (manual)

### TC-2: Create Recipe Manually
1. Recipes tab → tap + FAB → Recipe Builder opens
2. Enter name: "Test Pasta"
3. Servings: tap + to increase to 2, tap − to decrease to 1.5
4. Tap "Add Ingredient" → ingredient search sheet opens
5. Search "rice" (or any food you've logged before) → results appear
6. Tap a result → selected, grams field shows 100g
7. Change grams to 200 → tap Add
8. Ingredient appears in list with kcal calculated
9. Per-serving nutrition summary updates at bottom
10. Tap "Save Recipe" → snackbar "Recipe saved" → returns to list
11. Recipe visible in list with name and per-serving nutrition

### TC-3: Edit Recipe
1. Recipe list → long-press on "Test Pasta" → options sheet
2. Tap "Edit Recipe" → builder opens with pre-populated data
3. Change name to "Updated Pasta"
4. Remove ingredient (swipe left)
5. Add a new ingredient
6. Save → updates reflected in list

### TC-4: Delete Recipe
1. Recipe list → long-press on recipe → "Delete Recipe"
2. Confirmation dialog appears with "Past diary entries will be preserved"
3. Tap YES → recipe removed from list, snackbar "Recipe deleted"

### TC-5: Favourite Recipe
1. Recipe list → tap star icon on a recipe → turns amber (favourited)
2. Recipe appears in Favourites section at top
3. Tap star again → unfavourited, moves out of Favourites section

### TC-6: Search Recipes
1. Recipe list → type in search bar → filters recipes by name
2. Clear search → all recipes shown again

### TC-7: Log Recipe
1. Recipe list → tap on a recipe → Recipe Log screen
2. Shows recipe name, per-serving nutrition, meal slot selector
3. Serving multiplier: tap ½ → nutrition halves; tap 2 → nutrition doubles
4. Select meal slot (e.g. Dinner)
5. Tap "Log Recipe" → snackbar "Recipe logged" → pops back
6. Go to Home → diary shows recipe entry with cookbook icon, name, and kcal

### TC-8: Recipe in Diary Display
1. After logging a recipe, check home/diary views
2. Recipe entry shows cookbook icon (not food/bolt icon)
3. Name shows recipe name (e.g. "Test Pasta")
4. Kcal badge shows correct computed calories
5. Swipe-to-delete works on recipe diary entries

### TC-9: LLM Text-to-Recipe
1. Recipes tab → tap sparkle FAB → LLM Recipe screen
2. Paste ingredient text, e.g.:
   ```
   2 cups flour
   3 eggs
   1 cup milk
   2 tbsp butter
   1 tsp vanilla extract
   ```
3. Tap "Parse" → "Parsing..." spinner
4. Resolved ingredients appear with match status badges:
   - Green "Matched" = found in local database
   - Red "Not found" = no local match (nutrition will be 0)
5. Edit grams if needed
6. Edit recipe name and servings
7. Per-serving nutrition shown at bottom
8. Tap "Save Recipe" → snackbar → returns to list
9. New recipe visible in list

### TC-10: LLM URL-to-Recipe
1. LLM Recipe screen → paste a recipe URL (e.g. https://www.allrecipes.com/recipe/...)
2. Tap "Parse" → fetches page, sends to Claude, "Parsing..." spinner
3. Ingredients extracted and resolved (same flow as TC-9)
4. Recipe name auto-populated from page
5. Save → recipe in list

### TC-11: LLM — No API Key
1. Clear Claude API key in Settings
2. LLM Recipe screen → paste text → Parse
3. Error: "Claude API key not set"

### TC-12: Recipe Deletion Preserves Diary
1. Log a recipe (TC-7)
2. Verify entry in diary
3. Delete the recipe (TC-4)
4. Check diary → entry still present with recipe name and kcal
5. No crash navigating to diary

### TC-13: Recipe in Recents
1. Log a recipe
2. Home → FAB → Add Food → "Recently" tab
3. Recipe entry appears in recents (deduplicated by recipe)

### TC-14: Schema Migration (Fresh → v5)
1. If testing on device with existing data: launch app
2. No crash — schema v4→v5 migration runs
3. Existing diary entries intact
4. Recipe tab works immediately

### TC-15: Ingredient Search — OFF Fallback
1. In recipe builder → Add Ingredient → search for something NOT in local DB
2. If OFF API available, results from Open Food Facts appear (cloud icon)
3. Select → ingredient added with nutrition from OFF

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
