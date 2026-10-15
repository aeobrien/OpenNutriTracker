# Phase 11: LLM Label Scan — Manual Test Brief

## Prerequisites
- Claude API key (sk-ant-...) available
- Physical nutrition label to photograph (or a clear photo on another screen)

## Test Cases

### TC-1: API Key Setup
1. Settings → scroll to "Claude API Key" → shows "Not set"
2. Tap → enter API key → Save
3. Tile now shows "Configured"
4. Tap again → Clear → tile shows "Not set"

### TC-2: Scan Label from FAB
1. Home → FAB → "Scan Label" tile visible
2. Tap → LabelScanScreen opens with "Take Photo" button
3. Tap "Take Photo" → camera opens
4. Take photo of nutrition label → "Analyzing label..." spinner
5. Form appears with extracted data (name, brand, kcal, macros)
6. Verify values look reasonable

### TC-3: Validation Badge
1. After successful scan, check validation badge:
   - Green check = "Values look consistent" (< 15% deviation)
   - Amber = "Values may need review" (15-40%) or "Please check these values" (> 40%)
2. Edit kcal to wildly wrong value → badge updates to amber/warning
3. Correct it → badge returns to green

### TC-4: Confidence Indicator
1. Check confidence indicator (high/medium/low) from Claude
2. Sharp label photo → should be "high"
3. Blurry photo → may show "medium" or "low"

### TC-5: Edit and Save
1. Edit product name → changes reflected
2. Select meal slot → verify selection works
3. Set amount (e.g. 50g)
4. Tap "Add" → snackbar "Saved" → returns to home
5. Entry visible in home dashboard with correct kcal

### TC-6: Scanner Fallback
1. Scanner → scan unknown barcode → "Product not found"
2. "Scan label with AI" button visible below "Search"
3. Tap → navigates to LabelScanScreen

### TC-7: No API Key Error
1. Clear API key in Settings
2. FAB → Scan Label → Take Photo → take photo
3. Error: "Claude API key not set" with "Go to Settings" button
4. Tap "Go to Settings" → navigates to Settings

### TC-8: Camera Cancel
1. Scan Label → Take Photo → cancel camera
2. Stays on initial "Take Photo" screen (no crash)

### TC-9: Re-capture
1. After successful scan, tap camera icon in app bar
2. Opens camera again for new photo
3. New extraction replaces previous

## Results

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
