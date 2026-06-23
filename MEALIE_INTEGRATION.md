# Mealie Integration — Wiring Guide

Branch: `feat/mealie-integration`. All code here is **additive** — the only existing
file touched is `recipe_repository.dart` (two new methods appended, nothing changed).
Your WIP on `phase-blitz/quickadd` (settings work, `.env`, etc.) was left alone.

## The model: one-way mirror (decided 2026-06-23)

**Mealie is the single source of truth for recipes** — it's the shared cookbook
(your partner uses Mealie too, without tracking food). **FoodTracker keeps a one-way,
read-only mirror**, synced down so recipes are loggable offline. FoodTracker never
writes recipes back to Mealie.

Consequence: FoodTracker's own recipe authoring (the manual builder **and** the
Phase-12 LLM URL/text importer) becomes redundant and should be **retired/hidden** —
recipe authoring lives only in Mealie. Logging a recipe to today's diary still works
exactly as before; it just logs from the mirrored list.

## What's built (all tested, analyzer clean — 20 tests)

| File | What it is |
|------|-----------|
| `dto/mealie/mealie_parse.dart` | `mealieToDouble()` — tolerant string→double ("12.5 g", commas, empty, null) |
| `dto/mealie/mealie_nutrition_dto.dart` | Mealie's per-recipe nutrition block (11 fields) |
| `dto/mealie/mealie_recipe_dto.dart` | Recipe summary, ingredient, full recipe, pagination DTOs (camelCase) |
| `data_source/mealie_data_source.dart` | `MealieDataSource` — Bearer-token client: `fetchRecipes()`, `fetchRecipe(slug)` |
| `mealie_recipe_mapper.dart` | `MealieRecipeMapper.toRecipeEntity()` — Mealie recipe → `RecipeEntity` |
| `mealie_sync_service.dart` | **`MealieSyncService.syncAllRecipes()`** — the one-way pull engine |
| `mealie_secure_storage.dart` | Extension storing Mealie base URL + token (beside the Claude key) |
| `recipe_repository.dart` (+2 methods) | `createRecipeWithNutrition(...)`, `upsertMirroredRecipe(RecipeEntity)` — nutrition-preserving, no recompute |

Run the tests: `flutter test test/features/recipes/data/mealie test/features/recipes/data/dto/mealie_recipe_dto_test.dart test/features/recipes/data/data_source/mealie_data_source_test.dart`

**The whole sync engine works end-to-end**: given a configured URL + token, one call
mirrors every Mealie recipe into the local store, updating in place and isolating
per-recipe failures:

```dart
final storage = SecureAppStorageProvider();
final url = await storage.getMealieBaseUrl();
final token = await storage.getMealieToken();
final ds = MealieDataSource(baseUrl: url!, token: token!);
final result = await MealieSyncService(ds, recipeRepository).syncAllRecipes();
// result.synced / result.failed / result.total
```

## What's left (needs you — touches your WIP or needs UX/decisions)

1. **Settings UI** — two fields (Mealie URL + API token) → `storage.setMealieBaseUrl` /
   `setMealieToken`, and a "Sync now" button calling `syncAllRecipes()`. This lives in
   `settings_screen.dart` / `settings_bloc.dart`, which are in your Phase-14 WIP — so it's
   yours to place, or hand me the nod once that lands.
2. **Register the pieces** in `locator.dart` (also your WIP) and decide when sync runs
   (on app start? pull-to-refresh on the recipe list? a timer?).
3. **Retire FoodTracker's recipe authoring** — hide/remove the manual recipe builder and
   the LLM importer, since Mealie owns authoring now.
4. **The per-serving toggle** (optional) — Mealie nutrition is per-serving by convention;
   `syncAllRecipes(nutritionIsPerServing: false)` divides by servings if a library is
   entered whole-recipe.

## Deliberately deferred (not silently dropped)

- **Deletion pruning**: a recipe deleted in Mealie is not yet removed from the local
  mirror. Needs either a stored set of previously-synced slugs or a `source`/`mealieSlug`
  column (a drift schema change + migration). Left out to avoid a schema change inside
  your live WIP tree.
- **Incremental sync**: every run re-fetches all recipes rather than only changed ones.
  Fine for a modest library; optimise later via Mealie's `updatedAt`.
- **Migrating existing local FoodTracker recipes** up into Mealie (one-time), if you have
  real ones rather than test data.

## Why only 4 macros
`RecipeEntity` only has kcal/protein/carbs/fat per serving — no fields for fibre/sugar/
sodium, so the mapper drops them. The nutrition DTO still parses all 11, so if you add
those fields later the data's already there (note: Mealie stores *sodium*, not salt —
×2.5 for salt grams).

## Mealie server — DEPLOYED + VERIFIED (2026-06-23)
- Host: the Mac mini, `http://100.71.40.51:9000` (Tailscale; LAN-reachable; not public).
- Mealie v3.19.2, running under **OrbStack** (the mini's existing docker runtime).
  Compose: `~/services/mealie/docker-compose.yml` (official image, SQLite, `mealie-data` volume).
- **Admin login + API token: `~/services/mealie/SETUP_NOTES.md` on the mini** (chmod 600).
  Default login `changeme@example.com` / `MyPassword` — **change it first thing**.
- Verified end-to-end: URL-imported a recipe and read back per-serving nutrition
  (624 kcal / 35P / 58C / 25F, 6 servings) via the token API.
