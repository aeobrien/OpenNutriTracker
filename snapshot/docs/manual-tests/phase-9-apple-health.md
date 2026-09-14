# Phase 9: Apple Health Integration — Manual Test Brief

## Prerequisites
- iPhone with Apple Health data (active energy burned)
- App freshly installed or config key `hasAskedHealthPermission` not yet set

## Test Cases

### TC-1: First launch — HealthKit permission prompt
1. Launch app (fresh install or cleared config)
2. **Expected:** iOS HealthKit permission prompt appears for Active Energy Burned (read)
3. Grant permission
4. **Expected:** Dashboard shows "Active calories: X kcal" line below base/earned/eaten row
5. **Expected:** Earned value reflects active calories * exercise multiplier (default 0.75)

### TC-2: Permission denied — graceful fallback
1. Launch app (fresh install)
2. Deny HealthKit permission when prompted
3. **Expected:** No "Active calories" line in dashboard
4. **Expected:** Earned calories come from manual activities (or 0 if none)
5. **Expected:** No error dialogs, no nag prompts

### TC-3: Foreground refresh
1. Grant HealthKit permission
2. Note current active calories in dashboard
3. Go for a walk (or wait for Watch/phone to log some active energy)
4. Return to FoodTracker app
5. **Expected:** Active calories update on app resume (may take a moment)

### TC-4: Exercise multiplier changes
1. Go to Settings > Calculations > Exercise multiplier
2. Change from 0.75 to 0.5
3. Return to home
4. **Expected:** Earned calories recalculate (active * 0.5 instead of * 0.75)

### TC-5: Kill and relaunch — cached data
1. Grant HealthKit, note active calories
2. Force-quit the app
3. Relaunch
4. **Expected:** Cached active calories appear while HealthKit refreshes
5. **Expected:** "updated X min ago" shows if cache is stale (> 15 min)

### TC-6: No active energy data
1. At midnight (or cleared health data), launch app
2. **Expected:** Active calories shows 0 or line is hidden
3. **Expected:** Earned = 0, allowance = base only

### TC-7: Schema migration (upgrade from Phase 8)
1. Install Phase 8 build (schema v2)
2. Log some food
3. Install Phase 9 build over it
4. **Expected:** App launches without crash
5. **Expected:** Existing data preserved, new active_calories columns added

## Pass Criteria
- All TC pass without crashes
- No red/error colours used for any calorie display
- Permission only requested once (subsequent launches skip the prompt)
