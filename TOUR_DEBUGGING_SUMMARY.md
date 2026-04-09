# Tour System Debugging Summary - Buddy & Showcase Visibility Issue

## Issue Description
**Problem**: Buddy overlay and showcase highlighting are not appearing together on `/site` route
- **Buddy**: Animated card visible in global overlay (bottom-right)
- **Showcase**: Highlighting effect on specific UI elements
- **Expected**: Both should appear when Site tour starts and user is on `/site`
- **Actual**: Neither appears, or they appear separately/at wrong times

---

## Root Cause Analysis

The main issue is that the tour might be **starting at step 1 instead of step 0**, causing:
- Step 0 has route `/site` (where user currently is)
- Step 1 has route `/site-entry-select` (different page)
- **Route mismatch** prevents buddy from rendering
- **Step index mismatch** breaks the entire tour flow

### Why This Causes the Problem
```
GlobalTourOverlay.showBuddy = (
  tourState.status == TourStatus.running          // ✓ Should be true
  && step != null                                  // ✓ Should be true  
  && onSameRoute                                   // ✗ FALSE if step=1 but currentRoute=/site
)
```

If `onSameRoute` is false, buddy stays hidden regardless of other conditions.

---

## Comprehensive Logging Added

To debug this issue, extensive logging has been added to trace the complete flow:

### 1. **TourController.startModule()** 
Logs which step index is being loaded:
```
🔍 TourController.startModule: module=site, savedIndex=0, resumeIndex=0, totalSteps=4
▶️ TourController: started module=site step=0 step_id=site_tap_add route=/site
```

If you see `step=1` here on first run, the persistence is returning 1 (bug).

### 2. **TourController Reset Methods**
Logs each stage of reset process:
```
🔄 TourController: RESET MODULE site - clearing module-specific state
🔄 TourController: after resetModule, stepIndex=0
🔄 TourController: after saveModuleStepIndex(0), stepIndex=0
🔄 TourController: now calling startModule
```

If any of these shows wrong value, persistence writes aren't working.

### 3. **SiteSelectCardGrid PostFrameCallback** (view_add_site.dart)
Logs each decision point:
```
🎬 [SiteSelectCardGrid] PostFrame: siteDone=false, savedIndex=0, alreadyRunningSite=false
🎬 [SiteSelectCardGrid] FRESH START: savedIndex=0 → calling startModule
🎬 [SiteSelectCardGrid] After settle, calling syncToRoute
🎬 [SiteSelectCardGrid] After syncToRoute: step=site_tap_add, isRunning=true
🎬 [SiteSelectCardGrid] STARTING SHOWCASE with key=GlobalKey#12345
```

Helps identify which startup path is taken and if showcase actually triggers.

### 4. **GlobalTourOverlay Build Logic**
Logs buddy visibility calculation:
```
🌐 [GlobalTourOverlay] Build: status=running, stepId=site_tap_add, stepRoute=/site, currentRoute=/site, onSameRoute=true, showBuddy=true

⚠️ [GlobalTourOverlay] MISMATCH: tour running at step=site_tap_import route=/site-entry-select but app is at route=/site
```

If you see MISMATCH warning, it means tour is on wrong step for current route.

---

## How to Debug

### Step 1: Trigger the Tour
1. Launch app
2. Complete auth flow  
3. Navigate to Site module
4. Land on `/site` route (SiteSelectCardGrid screen)
5. This should auto-start the Site tour

### Step 2: Capture Logs
Open debug console/logcat and look for messages starting with:
- `🔍` (tour controller init)
- `▶️` (tour start)
- `🔄` (tour reset)
- `🎬` (site screen callback)
- `🌐` (global overlay)
- `⚠️` (warnings)

### Step 3: Match Steps to Timeline
Expected sequence:
```
1. 🎬 PostFrame: siteDone=false, savedIndex=0, alreadyRunningSite=false
2. 🎬 FRESH START branch
3. 🔍 startModule called
4. ▶️ started module=site step=0 step_id=site_tap_add route=/site
5. 🎬 After syncToRoute: step=site_tap_add, isRunning=true
6. 🎬 STARTING SHOWCASE
7. 🌐 Build: ...showBuddy=true
```

### Step 4: Identify Missing/Wrong Steps
- **Missing step 1 or 2**: Startup path not taken (unexpected state)
- **Step 4 shows `step=1`**: Persistence bug or reset not working
- **Step 7 shows `onSameRoute=false`**: Route comparison logic issue
- **Step 7 shows `showBuddy=false`**: Some condition failed

---

## Key Files Modified

### 1. `lib/features/tour/domain/tour_controller.dart`
- **Change**: Added detailed logging to `startModule()` and reset methods
- **Why**: To trace exact step index being loaded and persistence state

### 2. `lib/features/modules/all_Modules/site_Details/screens/view_add_site.dart`
- **Change**: Added comprehensive logging to postFrameCallback with branching info
- **Why**: To track which startup path is executed and showcase triggering

### 3. `lib/features/tour/screen/global_tour_overlay.dart`
- **Change**: Added route mismatch detection and detailed visibility logging
- **Why**: To identify when buddy render conditions fail

---

## Potential Issues & Solutions

### Issue 1: Tour Starts at Step 1
**Symptoms**: `▶️ started module=site step=1`
**Likely Cause**: Persistence returning saved value from previous run
**Solution**: Check `TourPersistence.getModuleStepIndex()` - ensure it returns 0 for fresh module

### Issue 2: ShowCase Doesn't Trigger  
**Symptoms**: Logs show `STARTING SHOWCASE` but highlight doesn't appear
**Likely Cause**: ShowCaseWidget context or key mismatch
**Solution**: Verify `SiteRegistry.addSiteCardKey` is correctly placed in UI tree

### Issue 3: Buddy Doesn't Show Despite Correct Step
**Symptoms**: `showBuddy=false` with `onSameRoute=true`
**Likely Cause**: One other condition failed (status != running or step == null)
**Solution**: Check `tourState.status` and `step` values in logs

### Issue 4: Route Comparison Fails
**Symptoms**: `⚠️ MISMATCH: ...onSameRoute=false`
**Likely Cause**: Route string format mismatch (e.g., `/site` vs `site`)
**Solution**: Check `_route Matches()` function in global_tour_overlay.dart

---

## Next Steps

1. **Run app with logging enabled**
2. **Capture full debug output when landing on `/site`**
3. **Check logs against expected timeline**
4. **Identify first divergence from expected flow**
5. **Implement targeted fix for that specific issue**

---

## Architecture Reminder

```
PostFrameCallback in view_add_site.dart
  ├─ Read persistence (siteDone, savedIndex)
  ├─ Determine startup path
  ├─ Call ctrl.startModule() or reset
  ├─ Wait 60ms for settlement
  ├─ Call syncToRoute()
  └─ Call sc.startShowCase()
       │
       └─→ GlobalTourOverlay watches tourControllerProvider
           ├─ Read tourState (status, stepIndex)
           ├─ Calculate onSameRoute
           ├─ Set showBuddy = running && step != null && onSameRoute
           └─ Render Buddy if showBuddy=true
```

Both paths need to succeed for buddy+showcase to appear together.
