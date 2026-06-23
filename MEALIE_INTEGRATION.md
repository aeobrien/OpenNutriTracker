# Mealie Integration — Wiring Guide

Branch: `feat/mealie-integration`. Built 2026-06-22 (overnight). All code here is
**new and additive** — no existing file was modified, so nothing of yours was
disturbed (your WIP on `phase-blitz/quickadd`, including `.env`, was left alone).

## What's in this branch

New module under `lib/features/recipes/data/`:

| File | What it is |
|------|-----------|
| `dto/mealie/mealie_parse.dart` | `mealieToDouble()` — tolerant string→double (handles "12.5 g", commas, empty, null) |
| `dto/mealie/mealie_nutrition_dto.dart` | Mealie's per-recipe nutrition block (all 11 fields) |
| `dto/mealie/mealie_recipe_dto.dart` | Recipe summary, ingredient, full recipe, and pagination DTOs (camelCase API) |
| `data_source/mealie_data_source.dart` | `MealieDataSource` — Bearer-token client: `fetchRecipes()`, `fetchRecipe(slug)`; typed exceptions |
| `mealie_recipe_mapper.dart` | `MealieRecipeMapper.toRecipeEntity()` — Mealie recipe → `RecipeEntity` |
| `mealie_secure_storage.dart` | Extension on `SecureAppStorageProvider` storing Mealie base URL + token |

Tests (all 15 passing, analyzer clean):
`test/features/recipes/data/mealie/`, `.../data/dto/mealie_recipe_dto_test.dart`,
`.../data/data_source/mealie_data_source_test.dart`.

Run them: `flutter test test/features/recipes/data/mealie test/features/recipes/data/dto/mealie_recipe_dto_test.dart test/features/recipes/data/data_source/mealie_data_source_test.dart`

## Three steps to make it usable

### 1. Register / construct the data source
`locator.dart` had your in-progress changes, so I didn't touch it. `MealieDataSource`
needs the URL + token at construction, so a plain lazy singleton doesn't fit — build
it where you do the import (usecase or bloc):

```dart
final storage = SecureAppStorageProvider();
final url = await storage.getMealieBaseUrl();
final token = await storage.getMealieToken();
if (url == null || token == null) { /* prompt user to configure Mealie */ }
final mealie = MealieDataSource(baseUrl: url!, token: token!);
final page = await mealie.fetchRecipes(search: query);
final recipe = await mealie.fetchRecipe(page.items.first.slug);
final entity = MealieRecipeMapper.toRecipeEntity(recipe);
```

### 2. Persistence — DONE (`createRecipeWithNutrition`)
`RecipeRepository.createRecipe` recomputes per-serving nutrition from *ingredient* macros,
which would **zero out** a Mealie import (recipe-level nutrition, macro-less ingredients).
Fixed: `RecipeRepository.createRecipeWithNutrition({...})` inserts explicit per-serving
fields and **skips** the recompute. Built + tested against in-memory SQLite
(`test/features/recipes/data/mealie/recipe_repository_nutrition_test.dart`). Just call it
with the mapped entity's fields:

```dart
final entity = MealieRecipeMapper.toRecipeEntity(recipe);
await recipeRepository.createRecipeWithNutrition(
  name: entity.name,
  servings: entity.servings,
  kcalPerServing: entity.kcalPerServing,
  proteinPerServing: entity.proteinPerServing,
  carbsPerServing: entity.carbsPerServing,
  fatPerServing: entity.fatPerServing,
  ingredients: entity.ingredients,
);
```

### 3. UI
Add "Import from Mealie" beside the existing recipe-creation options in `features/recipes`:
1. **Settings**: two fields (Mealie URL + API token) → `storage.setMealieBaseUrl` / `setMealieToken`.
2. **Import screen**: `fetchRecipes(search:)` → list → tap → `fetchRecipe(slug)` → `MealieRecipeMapper.toRecipeEntity` → preview → save (Step 2 path).
3. On the preview, offer a **"these numbers are for the whole recipe"** toggle — pass it as `nutritionIsPerServing: false` to the mapper (it divides by servings). Default is per-serving, which matches how Mealie scrapers fill nutrition.

## Why only 4 macros
`RecipeEntity` only has kcal/protein/carbs/fat per serving — there are no fields for
fibre/sugar/sodium, so the mapper drops them. Mealie's nutrition DTO still parses all
11 fields, so if you later add those to `RecipeEntity`, the data's already there
(note: Mealie stores *sodium*, not salt — multiply by 2.5 for salt grams).

## Mealie server — DEPLOYED + VERIFIED (2026-06-23)
- Host: the Mac mini, `http://100.71.40.51:9000` (Tailscale; LAN-reachable; not public).
- Mealie v3.19.2, running under **OrbStack** (the mini's existing docker runtime that
  hosts the media stack — colima turned out unnecessary). Compose file:
  `~/services/mealie/docker-compose.yml` (official image, SQLite, `mealie-data` volume).
- **Admin login + API token: `~/services/mealie/SETUP_NOTES.md` on the mini** (chmod 600).
  Default login is `changeme@example.com` / `MyPassword` — **change it first thing**.
- Verified end-to-end: imported a recipe by URL and read back per-serving nutrition
  (624 kcal / 35P / 58C / 25F, 6 servings) via the token-auth API — exactly the shape
  this module's DTOs + mapper consume. So pointing the app at it should just work.
