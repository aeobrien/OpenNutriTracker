# Roadmap

## Next Up

| Task | Milestone | Phase | Status | Effort |
|------|-----------|-------|--------|--------|
| 2.1.1 Allowance breakdown display | 2.1 Dashboard UI | 2: Today Dashboard | In Progress | Deep Focus |
| 7.1.6 Recipes in recents/favourites | 7.1 Recipe System | 7: Recipes | In Progress | Quick Win |
| 8.1.3 Notification settings (per-meal toggles) | 8.1 Notifications & Weekly | 8: Notifications | In Progress | Quick Win |
| 9.1.7 Data export (JSON + CSV) | 9.1 Settings | 9: Settings | In Progress | Deep Focus |

---

## Phase 0: Foundation (Complete)
**Status:** Done
**Definition of Done:** Dev environment set up, codebase audited, roadmap written

Covers original Phases 0-5: dev environment, smoke test, codebase audit, roadmap, strip & clean (Supabase/Sentry removal), database migration (Hive to drift/SQLite).

All deliverables complete.

---

## Phase 1: Core Domain
**Status:** Done
**Definition of Done:** All calculation functions implemented as pure, testable functions with 40+ unit tests. No UI, no database access.

### 1.1 — Calculation Engine
**Status:** Done
**Priority:** High
**Definition of Done:** All core calculation functions pass comprehensive unit tests

| # | Task | Status | Effort | Notes |
|---|------|--------|--------|-------|
| 1.1.1 | Allowance model (base + earned x multiplier) | Done | Deep Focus | `calorie_goal_calc.dart` |
| 1.1.2 | Macro scaling (proportional with per-macro override) | Done | Deep Focus | `macro_calc.dart` |
| 1.1.3 | Day boundary logic (configurable start hour, default 2 AM) | Done | Deep Focus | `day_boundary_calc.dart` |
| 1.1.4 | Meal slot suggestion (time-based, configurable) | Done | Quick Win | `meal_slot_calc.dart` |
| 1.1.5 | Macro/calorie consistency validation (Atwater check) | Done | Deep Focus | `nutrition_validator.dart` |
| 1.1.6 | Recipe nutrition calculation (ingredients + servings) | Done | Deep Focus | `recipe_calc.dart` |
| 1.1.7 | Weekly aggregation | Done | Deep Focus | `weekly_calc.dart` |
| 1.1.8 | DailyStats recomputation | Done | Deep Focus | `recompute_day_usecase.dart` |

40+ unit tests verified.

---

## Phase 2: Today Dashboard + Allowance UI
**Status:** In Progress (~90%) — only 2.1.1 allowance-breakdown completeness audit remains
**Definition of Done:** Today screen shows full allowance breakdown, macro bars, meal-grouped log, loads instantly from cached stats. 10+ widget tests.

### 2.1 — Dashboard UI
**Status:** In Progress
**Priority:** High
**Definition of Done:** Today screen fully redesigned with allowance breakdown and neutral styling

| # | Task | Status | Effort | Notes |
|---|------|--------|--------|-------|
| 2.1.1 | Allowance breakdown display | In Progress | Deep Focus | `dashboard_widget.dart` shows breakdown — needs completeness audit |
| 2.1.2 | Neutral overage display | Done | Quick Win | Verified neutral styling; covered by dashboard widget tests. Completed in phase-blitz integration. |
| 2.1.3 | Weekly context line | Done | Quick Win | |
| 2.1.4 | Macro progress bars | Done | Deep Focus | `MacroNutrimentWidget` |
| 2.1.5 | Meal-grouped log | Done | Deep Focus | `MealGrouping.groupByMeal` + display order; unit + widget tests. Completed in phase-blitz integration. |
| 2.1.6 | Today's date display | Done | Quick Win | |
| 2.1.7 | Calendar dot cleanup | Done | Quick Win | Completed 2026-04-10. Added deleteDayIfEmpty calls to deleteIntakeItem and deleteUserActivityItem. Floating-point tolerance added. |
| 2.1.8 | Home page delete confirmation | Done | Quick Win | Already existed (DeleteDialog on long-press). Drag-down-to-delete replaced by swipe in 3.1.7. |
| 2.1.9 | Instant load from DailyStats | Done | Deep Focus | LoadItemsEvent reads cached DailyStats row as authoritative; falls back to compute only when no row. Completed in phase-blitz integration. |

---

## Phase 3: Friction Foundations
**Status:** Done — all 3.1.x tasks complete
**Definition of Done:** Logging is fast and frictionless — portion memory, quick increments, favourites, recents, inline editing, draft persistence.

### 3.1 — Fast Logging
**Status:** Done
**Priority:** High
**Definition of Done:** All friction-reduction features working and tested

| # | Task | Status | Effort | Notes |
|---|------|--------|--------|-------|
| 3.1.1 | Portion memory (default to last-used quantity) | Done | Deep Focus | Verified already implemented during phase-blitz audit. |
| 3.1.2 | Quick increment buttons (+10g, +50g, 1/2, 1 serving) | Done | Deep Focus | Completed 2026-04-10. Added 1/2 srv + 1 srv buttons alongside +10/+50 in meal detail and edit dialog. |
| 3.1.3 | Improved defaults (last-used or 1 serving, not 100g) | Done | Quick Win | Verified already implemented during phase-blitz audit. |
| 3.1.4 | Favourites system (star/pin, shown above recents) | Done | Deep Focus | Verified already implemented during phase-blitz audit. |
| 3.1.5 | Improved recents (deduplicated, one-tap re-log) | Done | Deep Focus | Deduplicated, one-tap working |
| 3.1.6 | Inline editing (tap entry to adjust grams) | Done | Deep Focus | Verified already implemented during phase-blitz audit. |
| 3.1.7 | Swipe to delete with undo | Done | Deep Focus | Completed 2026-04-10. Changed from DismissDirection.down to endToStart (swipe left). Undo snackbar already existed. |
| 3.1.8 | Draft state persistence | Done | Deep Focus | `QuickAddDraftRepository` + usecase persist draft across app switches; DI registered. Completed in phase-blitz integration (fastlog). |
| 3.1.9 | Meal slot auto-suggestion | Done | Quick Win | |

---

## Phase 4: Apple Health Integration
**Status:** In Progress (~95%) — only 4.1.7 native background observer (stretch) remains
**Definition of Done:** Active calories read from HealthKit, applied to allowance with configurable multiplier, refreshes on foreground.

### 4.1 — HealthKit Integration
**Status:** In Progress
**Priority:** High
**Definition of Done:** Exercise-adjusted allowance working end to end

| # | Task | Status | Effort | Notes |
|---|------|--------|--------|-------|
| 4.1.1 | Add health plugin + HealthKit entitlement | Done | Deep Focus | |
| 4.1.2 | Permission flow | Done | Deep Focus | Graceful denial handling |
| 4.1.3 | Read active calories | Done | Deep Focus | |
| 4.1.4 | Apply multiplier (default 0.75) | Done | Quick Win | |
| 4.1.5 | Cache in DailyStats | Done | Deep Focus | Active calories cached via `daily_stats_dao`; `getCachedActiveCalories` read on load. Completed in phase-blitz integration (health). |
| 4.1.6 | Foreground refresh | Done | Deep Focus | `didChangeAppLifecycleState` resume fires `RefreshActiveCaloriesEvent`; bloc refresh test covers it. Completed in phase-blitz integration (health). |
| 4.1.7 | Native background observer (stretch) | Todo | Deep Focus | Swift platform channel — not found |
| 4.1.8 | Update Today screen with earned calories | Done | Deep Focus | |

---

## Phase 5: Quick-Add Estimate
**Status:** Done — all 5.1.x tasks complete
**Definition of Done:** Quick-add flow works in <5 seconds, entries count toward daily totals, visually distinct in log.

### 5.1 — Quick-Add Flow
**Status:** Done
**Priority:** Normal
**Definition of Done:** Quick-add accessible in 1 tap from home, full flow working

| # | Task | Status | Effort | Notes |
|---|------|--------|--------|-------|
| 5.1.1 | Quick-add screen (kcal + optional macros + label) | Done | Deep Focus | |
| 5.1.2 | Quick-add log entry (type=quickAdd) | Done | Deep Focus | Verified already implemented during phase-blitz audit; covered by intake repository tests. |
| 5.1.3 | Visual distinction in log | Done | Quick Win | Bolt badge icon on quick-add entries; covered by intake card widget test. Confirmed in phase-blitz integration (quickadd). |
| 5.1.4 | Prominent Quick Add button on home | Done | Quick Win | Quick-add entry point added to `main_screen`. Completed in phase-blitz integration (quickadd). |

---

## Phase 6: LLM Label Capture
**Status:** Done — all 6.1.x tasks complete
**Definition of Done:** Photo of nutrition label extracts structured data via Claude API, saves as reusable food item.

### 6.1 — Claude API + Label Extraction
**Status:** Done
**Priority:** Normal
**Definition of Done:** End-to-end label capture flow working

| # | Task | Status | Effort | Notes |
|---|------|--------|--------|-------|
| 6.1.1 | Claude API client | Done | Deep Focus | User's API key from settings |
| 6.1.2 | Photo capture flow | Done | Deep Focus | Camera + gallery capture wired through `label_scan_screen`/bloc; gallery source test passes. Completed in phase-blitz integration (llmlabel). |
| 6.1.3 | LLM extraction + JSON parsing | Done | Deep Focus | |
| 6.1.4 | Client-side Atwater validation | Done | Deep Focus | |
| 6.1.5 | Confirmation UI (editable form) | Done | Deep Focus | |
| 6.1.6 | Save as FoodItem | Done | Quick Win | Extraction result saved as reusable FoodItem. Completed in phase-blitz integration (llmlabel). |
| 6.1.7 | "Not found" flow integration | Done | Deep Focus | Bloc emits not-found state when a label can't be parsed; covered by bloc test. Completed in phase-blitz integration (llmlabel). |
| 6.1.8 | Offline fallback (queue for processing) | Done | Deep Focus | `PendingLabelScanQueue` queues photos when offline and processes on reconnect; bloc + queue tests pass. Completed in phase-blitz integration (llmlabel). |

---

## Phase 7: Recipes + LLM Recipe Builder
**Status:** In Progress (~85%)
**Definition of Done:** Manual and LLM-assisted recipe creation, one-tap recipe logging, recipes in recents/favourites.

### 7.1 — Recipe System
**Status:** In Progress
**Priority:** Normal
**Definition of Done:** All recipe workflows functional

| # | Task | Status | Effort | Notes |
|---|------|--------|--------|-------|
| 7.1.1 | Manual recipe builder | Done | Deep Focus | |
| 7.1.2 | LLM text-to-recipe | Done | Deep Focus | |
| 7.1.3 | LLM URL-to-recipe | Done | Deep Focus | |
| 7.1.4 | Recipe logging (one-tap, portion adjust) | Done | Deep Focus | |
| 7.1.5 | Recipe management (view, edit, delete) | Done | Deep Focus | Edits don't change past logs |
| 7.1.6 | Recipes in recents/favourites | In Progress | Quick Win | Partial integration |

---

## Phase 8: Notifications + Weekly View
**Status:** In Progress (~80%)
**Definition of Done:** Gentle meal-time reminders, weekly summary view, weekly context on Today screen.

### 8.1 — Notifications & Weekly
**Status:** In Progress
**Priority:** Normal
**Definition of Done:** Notifications and weekly view working

| # | Task | Status | Effort | Notes |
|---|------|--------|--------|-------|
| 8.1.1 | Local notification scheduling (meal-time reminders) | Done | Deep Focus | Warm, non-judgmental language |
| 8.1.2 | Notification deep link | Done | Deep Focus | |
| 8.1.3 | Notification settings (per-meal toggles) | In Progress | Quick Win | Partial |
| 8.1.4 | Weekly summary view (7-day) | In Progress | Deep Focus | Partial |
| 8.1.5 | Weekly context on Today screen | Done | Quick Win | |

---

## Phase 9: Settings & Configuration
**Status:** In Progress (~60%)
**Definition of Done:** All settings accessible and functional, API key stored securely, data export/import working.

### 9.1 — Settings
**Status:** In Progress
**Priority:** Normal
**Definition of Done:** All configuration options working

| # | Task | Status | Effort | Notes |
|---|------|--------|--------|-------|
| 9.1.1 | Calorie target setting | In Progress | Quick Win | Partial implementation |
| 9.1.2 | Macro target setting | In Progress | Deep Focus | Partial implementation |
| 9.1.3 | Exercise multiplier | Done | Quick Win | |
| 9.1.4 | Day boundary | Done | Quick Win | |
| 9.1.5 | Claude API key (secure storage) | Done | Deep Focus | `flutter_secure_storage` |
| 9.1.6 | HealthKit permissions status | Done | Quick Win | `HealthDebugScreen` |
| 9.1.7 | Data export (JSON + CSV) | In Progress | Deep Focus | Partial |
| 9.1.8 | Data import from JSON | In Progress | Deep Focus | Partial |
| 9.1.9 | Theme (light/dark/system) | Done | Quick Win | |
| 9.1.10 | Units (metric/imperial) | Todo | Quick Win | Not found in codebase |

---

## Phase 10: Polish + UX Audit
**Status:** Todo (~5%)
**Definition of Done:** Vision statement fully met, timing targets hit, no shame language, all edge cases handled.

### 10.1 — UX Audit
**Status:** Todo
**Priority:** Normal
**Definition of Done:** Comprehensive audit document, all issues resolved

| # | Task | Status | Effort | Notes |
|---|------|--------|--------|-------|
| 10.1.1 | Vision statement audit | Todo | Administrative | Walk through every principle |
| 10.1.2 | Timing tests (<10s barcode, <60s LLM, <5s quick-add) | Todo | Administrative | |
| 10.1.3 | Shame-language audit | Todo | Administrative | |
| 10.1.4 | ADHD-friendliness audit | Todo | Administrative | |
| 10.1.5 | Edge cases | Todo | Deep Focus | Partial edge case coverage in tests |
| 10.1.6 | Performance audit | Todo | Deep Focus | |
| 10.1.7 | Retroactive logging verification | Todo | Administrative | |

---

## Dependencies

| Item | Depends On | Status |
|------|-----------|--------|
| Phase 1 (Core Domain) | Phase 0 (Foundation) | Met |
| Phase 2 (Today Dashboard) | Phase 1 (Core Domain) | Met |
| Phase 3 (Friction) | Phase 2 (Today Dashboard) | Met (Phase 2 partial but unblocking) |
| Phase 4 (Apple Health) | Phase 2 (Today Dashboard) | Met (Phase 2 partial but unblocking) |
| Phase 5 (Quick-Add) | Phase 0 (Foundation) | Met |
| Phase 6 (LLM Label) | Phase 5 (Quick-Add) | Met (Phase 5 partial but unblocking) |
| Phase 7 (Recipes) | Phase 6 (LLM Label) | Met (Phase 6 partial but unblocking) |
| Phase 8 (Notifications) | Phase 2 (Today Dashboard) | Met (Phase 2 partial but unblocking) |
| Phase 9 (Settings) | Phases 4, 5, 6, 8 | Met (all partial but unblocking) |
| Phase 10 (Polish) | All previous | Unmet |

---

## Reference

### Status Values
| Status | Meaning |
|--------|---------|
| Todo | Not yet started |
| In Progress | Actively being worked on |
| Blocked: [reason] | Cannot proceed — reason is one of: poorly-defined, too-large, missing-info, missing-resource, decision-required |
| Waiting | User's part done, waiting on external input |
| Done | Complete |
| Dropped | Deliberately abandoned |

### Effort Types
| Type | Description |
|------|-------------|
| Deep Focus | Sustained concentration, problem-solving, design work |
| Creative | Open-ended, generative, exploratory |
| Administrative | Organising, documenting, updating, filing |
| Communication | Discussions, reviews, feedback |
| Physical | Hands-on work, building, soldering |
| Quick Win | Small, low-effort, momentum-building |

### Priority
High / Normal / Low — milestones only. Tasks inherit from their milestone unless overridden.
