# ModuleScreenV2 — Enhanced UI Replication Guide
> **For AI / Developer use.** This document describes exactly how to replace the visual layer of `ModuleScreenV2` with the new design while keeping every line of business logic, provider, routing, access-control, tour/showcase, shimmer, and state management untouched.

---

## 1. Scope — What Changes vs. What Stays

### ✅ KEEP EXACTLY AS-IS (zero edits)
| Area | Items |
|---|---|
| All providers | `siteProvider`, `siteDropdownValueProvider`, `teamProvider`, `teamDropdownValueProvider`, `accessControlProvider`, `moduleScreenSyncProvider`, `tourControllerProvider`, `tourPersistenceProvider`, `typeProvider`, `languageModuleProvider` |
| All business logic methods | `_checkAccess`, `_storePendingAndShowOverlay`, `_hideOverlay`, `_onUnlocked`, `_maybeStartShowcase` |
| All navigation | `_handleModuleTap`, `_navigateToModule`, `_handleAiAnalysisTap`, `_handleBottomNavTap`, `_handleSwipe` |
| Module data lists | `_dailyEntryModules`, `_setupModules`, `_reportModules`, `_moreModules`, `_currentModules` getter |
| Tour / Showcase wrapping | All `Showcase(key: ...)` wrappers on module icon items and setup bottom nav key — keep exactly |
| Access overlay | `AccessOverlay` widget, `_overlayType`, `_overlayLoading` stack layers |
| Shimmer loading state | `_buildLoadingState()` and `_buildActivityRowShimmer()` — keep as-is |
| `ModuleItem` data class | No changes |
| `initState` / `dispose` | Pulse `AnimationController` kept |
| `didChangeDependencies` | Kept |

### 🎨 REPLACE (visual only)
- `build()` scaffold structure → new layout
- `_buildContextualHeader()` → enhanced version
- `_buildDropdownRow()` + `_buildCustomDropdown()` → enhanced
- `_buildActivityCard()` + `_buildActivityRow()` → enhanced
- `_buildModuleCard()` + `_buildCardTabLabel()` + `_buildIconGrid()` + `_buildModuleIconItem()` → enhanced + attach/detach
- `_buildFloatingNavBar()` → enhanced floating dock
- `_buildMenuButton()`, `_buildQuickSettingsMenu()`, `_buildQuickSettingRow()`, `_buildTabPills()`, `_buildTabPill()`, `_buildAiButton()` → enhanced

---

## 2. New State Variables to Add

Add these to `_ModuleScreenV2State` alongside the existing ones:

```dart
// NEW — module card attach/detach
bool _moduleCardAttached = false;   // true = card is part of floating dock
bool _moduleCardVisible = true;     // false = user collapsed inline card

// NEW — scroll controller for programmatic scrolling
final ScrollController _scrollController = ScrollController();
```

Dispose the scroll controller:
```dart
@override
void dispose() {
  _pulseController.dispose();
  _scrollController.dispose(); // ADD THIS
  super.dispose();
}
```

---

## 3. Layout Architecture

### 3.1 Overall Scaffold
```
Scaffold
  backgroundColor: _pageBackgroundColor
  drawer: CustomDrawer()          ← unchanged
  body: ShowCaseWidget(           ← unchanged wrapper
    builder: (showcaseContext) {
      return GestureDetector(     ← unchanged (closes quick settings)
        child: Stack([
          // Layer 1: Scrollable page content
          SafeArea(child: _buildScrollBody()),

          // Layer 2: Floating dock (nav + optional attached card)
          Positioned(bottom, left, right) → _buildFloatingDock(showcaseContext),

          // Layer 3: Quick settings panel (existing)
          if (_showQuickSettings) Positioned(...) → _buildQuickSettingsMenu(),

          // Layer 4: Access overlay loading spinner (existing — unchanged)
          if (_overlayLoading) Positioned.fill(...),

          // Layer 5: Access overlay widget (existing — unchanged)
          if (!_overlayLoading && _overlayType != null && ...) AccessOverlay(...),
        ])
      );
    }
  )
```

### 3.2 Scroll Body
```
SingleChildScrollView(controller: _scrollController)
  Column(
    _buildContextualHeader(t)         // 16px top padding
    SizedBox(12)
    _buildDropdownRow()
    SizedBox(10)
    _buildActivityCard()
    SizedBox(10)
    // CONDITIONAL: inline module card (detached state)
    AnimatedSize(
      child: _moduleCardAttached || !_moduleCardVisible
        ? SizedBox.shrink()
        : _buildInlineModuleCard(t)
    )
    SizedBox(10)
    _buildOverviewCard()              // new summary card
    // bottom padding = dock height + 24
    SizedBox(height: _dockSpacerHeight)
  )
```

### 3.3 Floating Dock
```
Column(mainAxisSize: MainAxisSize.min)
  // CONDITIONAL: attached module panel
  AnimatedSize(
    child: _moduleCardAttached
      ? _buildAttachedModulePanel(t)
      : SizedBox.shrink()
  )
  // Always visible: nav bar
  _buildNavBar(showcaseContext, t)
```

---

## 4. Design Tokens

```dart
// Card background
Color _cardBg(bool isDark) => isDark
    ? cs.surfaceContainerHigh
    : Colors.white;

// Page background
Color _pageBg(bool isDark) => isDark
    ? cs.surface
    : cs.surfaceContainerLowest;

// Border color
Color _borderColor(bool isDark) => isDark
    ? cs.outline.withOpacity(0.35)
    : cs.outlineVariant.withOpacity(0.5);

// Standard box shadow (light mode only)
List<BoxShadow> _cardShadow(bool isDark) => isDark ? [] : [
  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: Offset(0,4))
];

// Dock shadow
List<BoxShadow> _dockShadow() => [
  BoxShadow(color: Colors.black.withOpacity(0.13), blurRadius: 32, offset: Offset(0,10))
];
```

---

## 5. Component Specifications

### 5.1 Contextual Header — `_buildContextualHeader()`
```
Padding(20 left/right, 16 top)
Row [
  // Menu button → opens drawer (keep Builder + Scaffold.of pattern)
  Container(44×44, radius:12, bg: surfaceContainerLow, border)
    Icon(Icons.menu_rounded, 22, onSurfaceVariant)

  SizedBox(14)

  // Title block
  Expanded → Column(crossStart) [
    if eyebrow.isNotEmpty:
      Text(eyebrow, 10px, w700, spacing:1.4, color:primary)
    Text(title, 22px, w800, onSurface, height:1.1)
    Text(dateStr, 11px, w400, onSurfaceVariant)
  ]

  // Module count badge
  Container(px:10, py:4, radius:20, bg: primaryContainer.op(0.45))
    Text("N modules", 10px, w600, onPrimaryContainer)
]
```

### 5.2 Dropdown Row — `_buildDropdownRow()` / `_buildCustomDropdown()`
```
Padding(horizontal:20) → Row [
  Expanded → _buildCustomDropdown("SITE")
  SizedBox(10)
  Expanded → _buildCustomDropdown("TEAM")
]

Each dropdown:
Container(height:54, radius:14, bg: surfaceContainerLow, border)
  Stack [
    Positioned(top:6, left:14): Text(label, 10px, w700, spacing:0.6, primary)
    Padding(top:18, left:10, right:4):
      DropdownButtonHideUnderline → DropdownButton<T>(
        // keep all existing provider logic
        isExpanded: true,
        style: TextStyle(fontSize:13, color: onSurface)
      )
  ]
```

### 5.3 Activity Card — `_buildActivityCard()`
```
Margin(horizontal:20)
Container(padding:12, radius:16, bg: surfaceContainerLow, border)
  Column [
    Row [
      Container(6×6, circle, greenAccent.op(0.9))   // live dot
      SizedBox(6)
      Text("Recent Activity", 11px, w700, spacing:0.4, onSurfaceVariant)
      Spacer()
      Container(radius:20, bg:green.op(0.10), border:green.op(0.35))
        Text("● Live", 10px, w700, Colors.green)
    ]
    SizedBox(8)
    _buildActivityRow(receipt icon, "Expense entry added", "2 min ago", isRecent:true)
    SizedBox(6)
    _buildActivityRow(check icon, "Attendance submitted", "Today 9:30 AM", isRecent:false)
  ]

_buildActivityRow():
Row [
  Container(26×26, radius:8, surfaceContainerHigh) → Icon(size:14, onSurfaceVariant)
  SizedBox(8)
  Expanded → Column [
    Text(title, 12px, w600, onSurface)
    Text(time, 10px, w400, onSurfaceVariant)
  ]
  if isRecent: Container(6×6, circle, greenAccent)
]
```

### 5.4 Inline Module Card — `_buildInlineModuleCard()` *(new, detached state)*

This is the module card that lives in the scroll body when `_moduleCardAttached == false`.

```
AnimatedOpacity + AnimatedSlide wrapper (enters from below, exits upward)

Padding(horizontal:16)
Container(
  radius:28, bg: isDark?surfaceContainerLow:white,
  border: _borderColor, shadow: _cardShadow
  padding: fromLTRB(16,14,16,16)
)
  Column(mainAxisSize:min) [
    // TOP BAR: drag hint + tab info + attach button
    Row [
      // Drag pill (visual affordance)
      Expanded → Center →
        Container(36×4, radius:2, bg: onSurface.op(0.12))

      // Attach chip
      GestureDetector(onTap: _attachModuleCard) →
        Container(
          px:10, py:5, radius:20,
          bg: primary.op(0.09),
          border: primary.op(0.2)
        )
          Row [
            Icon(Icons.south_rounded, 11, primary)  // arrow down = dock
            SizedBox(4)
            Text("Attach to nav", 10px, w700, primary)
          ]
    ]

    SizedBox(10)

    // Tab label row (same as original _buildCardTabLabel)
    _buildCardTabLabel(t)   // ← reuse existing method

    SizedBox(14)

    // Icon grid (same as original)
    _buildIconGrid(t)       // ← reuse existing method
  ]
```

**Attach animation:**
```dart
void _attachModuleCard() {
  setState(() {
    _moduleCardAttached = true;
    _moduleCardVisible = false;
  });
  // Slight delay so the inline card collapses before panel expands
  Future.delayed(Duration(milliseconds: 320), () {
    if (mounted) setState(() {}); // trigger dock rebuild
    // Show toast
    _showToast("Module card attached to nav");
  });
  // Scroll to bottom so user sees the dock expand
  Future.delayed(Duration(milliseconds: 150), () {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  });
}
```

### 5.5 Attached Module Panel — `_buildAttachedModulePanel()` *(new, dock top)*

Sits above the nav bar inside the dock column. Connected visually — top corners rounded, bottom corners flat to merge with nav.

```
Container(
  margin: EdgeInsets.fromLTRB(0, 0, 0, 0),  // no gap with nav bar
  decoration: BoxDecoration(
    color: isDark ? surfaceContainerHigh.op(0.96) : white.op(0.97),
    borderRadius: BorderRadius.only(
      topLeft: 28, topRight: 28,
      bottomLeft: 0, bottomRight: 0,
    ),
    border: Border(
      top: BorderSide(color: _borderColor, width: 0.8),
      left: BorderSide(color: _borderColor, width: 0.8),
      right: BorderSide(color: _borderColor, width: 0.8),
    ),
    boxShadow: [ BoxShadow(color: black.op(0.10), blurRadius: 24, offset: Offset(0, -6)) ]
  ),
  padding: EdgeInsets.fromLTRB(16, 10, 16, 14),
)
  Column(mainAxisSize:min) [
    // TOP BAR: drag pill + detach button
    Row [
      SizedBox(width:88)    // balance spacer
      Expanded → Center →
        GestureDetector(onTap: _toggleAttachedPanel) →
          Container(40×4, radius:2, bg: onSurface.op(0.14))   // drag pill

      // Detach chip
      GestureDetector(onTap: _detachModuleCard) →
        Container(
          px:10, py:5, radius:20, width:88,
          bg: primary.op(0.09), border: primary.op(0.2)
        )
          Row [
            Icon(Icons.north_rounded, 11, primary)  // arrow up = detach
            SizedBox(4)
            Text("Detach", 10px, w700, primary)
          ]
    ]

    SizedBox(10)
    _buildCardTabLabel(t)   // ← reuse
    SizedBox(14)
    _buildIconGrid(t)       // ← reuse
  ]
```

**Detach animation:**
```dart
void _detachModuleCard() {
  setState(() {
    _moduleCardAttached = false;
  });
  Future.delayed(Duration(milliseconds: 100), () {
    if (mounted) setState(() { _moduleCardVisible = true; });
    _showToast("Module card moved to page");
    // Scroll so inline card is visible
    Future.delayed(Duration(milliseconds: 200), () {
      _scrollController.animateTo(
        0,
        duration: Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
  });
}
```

### 5.6 Floating Dock Nav Bar — `_buildNavBar()` / replaces `_buildFloatingNavBar()`

The nav bar is the bottom part of the dock. Its border-radius changes based on whether the attached panel is showing above it.

```dart
AnimatedContainer(
  duration: Duration(milliseconds: 400),
  curve: Curves.easeOutCubic,
  height: 62,
  decoration: BoxDecoration(
    color: isDark
        ? cs.surfaceContainerHigh.withOpacity(0.88)
        : Colors.white.withOpacity(0.93),
    borderRadius: BorderRadius.only(
      topLeft:    Radius.circular(_moduleCardAttached ? 0 : 30),
      topRight:   Radius.circular(_moduleCardAttached ? 0 : 30),
      bottomLeft: Radius.circular(30),
      bottomRight:Radius.circular(30),
    ),
    border: Border(
      // when attached, no top border (seamless join with panel)
      top:    _moduleCardAttached
                ? BorderSide.none
                : BorderSide(color: cs.outlineVariant.withOpacity(0.2), width: 0.8),
      left:   BorderSide(color: cs.outlineVariant.withOpacity(0.2), width: 0.8),
      right:  BorderSide(color: cs.outlineVariant.withOpacity(0.2), width: 0.8),
      bottom: BorderSide(color: cs.outlineVariant.withOpacity(0.2), width: 0.8),
    ),
    boxShadow: _dockShadow(),
  ),
  child: ClipRRect(
    borderRadius: /* same as above */,
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row [
          _buildMenuButton(),            // unchanged
          SizedBox(8),
          Expanded(child: _buildTabPills(showcaseContext)),  // unchanged
          SizedBox(8),
          _buildAiButton(),              // unchanged (pulse animation kept)
        ]
      )
    )
  )
)
```

**AI button tap behaviour change:**
```dart
// In _buildAiButton onTap, replace _handleAiAnalysisTap with:
onTap: _overlayType != null ? null : () {
  if (!_moduleCardAttached) {
    _attachModuleCard();
  } else {
    _handleAiAnalysisTap(); // original behaviour when already attached
  }
},
```
> **Note:** Keep `_handleAiAnalysisTap` method itself unchanged — it still navigates to `/analysis`. Only the button routing logic changes as above.

### 5.7 Dock Wrapper — `_buildFloatingDock()`

```dart
Widget _buildFloatingDock(BuildContext showcaseContext) {
  return Positioned(
    bottom: 16 + MediaQuery.of(context).padding.bottom,
    left: 12,
    right: 12,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Attached panel — slides in/out with AnimatedSize
        AnimatedSize(
          duration: Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          child: _moduleCardAttached
              ? _buildAttachedModulePanel(t)
              : SizedBox.shrink(),
        ),
        // Nav bar — always visible
        _buildNavBar(showcaseContext, t),
      ],
    ),
  );
}
```

### 5.8 Overview / Summary Card — `_buildOverviewCard()` *(new)*

This replaces the multiple separate content cards. One compact card with 4 data rows.

```
Margin(horizontal:20)
Container(padding:12, radius:16, bg: surfaceContainerLow, border)
  Column [
    Row [
      Icon(Icons.bar_chart_rounded, 13, onSurfaceVariant)
      SizedBox(6)
      Text("Overview", 11px, w700, onSurfaceVariant)
    ]
    SizedBox(8)

    _buildOverviewRow(building icon, "Site Summary",      "3 active · 2 pending", badge:"Active",  badgeColor:primary)
    _buildOverviewRow(payment icon,  "Today's Totals",    "₹12,400 · 24/30",      badge:"24/30",   badgeColor:green)
    _buildOverviewRow(doc icon,      "Pending Approvals", "3 DPR awaiting review", badge:"3 Pending",badgeColor:orange)
    _buildOverviewRow(chart icon,    "Weekly Progress",   "78% completion",        badge:"78%",     badgeColor:green, last:true)
  ]

_buildOverviewRow(icon, title, subtitle, badge, badgeColor, {last:false}):
Row [
  Container(26×26, radius:8, surfaceContainerHigh) → Icon(icon, 13, onSurfaceVariant)
  SizedBox(8)
  Expanded → Column [
    Text(title, 12px, w600, onSurface)
    Text(subtitle, 10px, w400, onSurfaceVariant)
  ]
  Container(radius:10, px:7, py:2, bg:badgeColor.op(0.12))
    Text(badge, 9px, w700, badgeColor.darken)
]
if !last: Padding(top:6, bottom:6): Divider(height:1, op:0.08)  // subtle separator
```

---

## 6. Animation Specifications

### 6.1 Inline Card Enter/Exit
```dart
// Wrap _buildInlineModuleCard in:
AnimatedOpacity(
  duration: Duration(milliseconds: 350),
  opacity: _moduleCardVisible ? 1.0 : 0.0,
  child: AnimatedSlide(
    duration: Duration(milliseconds: 420),
    offset: _moduleCardVisible ? Offset.zero : Offset(0, 0.15),
    curve: Curves.easeOutCubic,
    child: /* card */,
  ),
)
```

### 6.2 Attached Panel Enter
- `AnimatedSize` on the Column wrapping the panel handles height change smoothly
- Duration: `450ms`, curve: `Curves.easeOutCubic`
- The nav bar `AnimatedContainer` handles the border-radius morph simultaneously

### 6.3 Tab Switching (existing + enhanced)
Keep `AnimatedPositioned` / `AnimatedContainer` for the pill slider — already in codebase.

### 6.4 Bottom Spacer
```dart
double get _dockSpacerHeight {
  // Nav bar: 62 + bottom padding + 16 (margin) + 24 (extra)
  double base = 62 + 16 + 24;
  if (_moduleCardAttached) {
    // Approximate attached panel height based on module count
    int rows = (_currentModules.where((m)=>!m.isEmpty).length / 4).ceil();
    base += 58 + (rows * 78.0) + 30; // header + grid rows + padding
  }
  return base;
}
```

Use this in the scroll body:
```dart
AnimatedContainer(
  duration: Duration(milliseconds: 450),
  curve: Curves.easeOutCubic,
  height: _dockSpacerHeight,
)
```

---

## 7. Toast Notification

Add a simple toast overlay inside the Stack (above access overlay):

```dart
// State
String _toastMessage = '';
bool _toastVisible = false;
Timer? _toastTimer;

void _showToast(String msg) {
  setState(() { _toastMessage = msg; _toastVisible = true; });
  _toastTimer?.cancel();
  _toastTimer = Timer(Duration(seconds: 2), () {
    if (mounted) setState(() => _toastVisible = false);
  });
}

// Widget (add to Stack in build)
AnimatedPositioned(
  duration: Duration(milliseconds: 300),
  curve: Curves.easeOutBack,
  top: _toastVisible ? 20 : -50,
  left: 0, right: 0,
  child: Center(
    child: AnimatedOpacity(
      duration: Duration(milliseconds: 220),
      opacity: _toastVisible ? 1.0 : 0.0,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.80),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(_toastMessage,
          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    ),
  ),
)
```

Don't forget to cancel the timer in `dispose()`.

---

## 8. Shimmer Loading State

**Keep `_buildLoadingState()` exactly as-is.** The only enhancement: add a shimmer placeholder for the bottom dock:

```dart
// At the very end of the shimmer Column, before the SizedBox(80):
Padding(
  padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
  child: ShimmerImage(height: 62, width: double.infinity, borderRadius: 30),
),
```

---

## 9. Tour / Showcase Constraints

The `Showcase` wrappers must remain **exactly** where they are. The only positional change is that `_buildTabPill` for index `1` (Setup) now lives inside `_buildTabPills()` which is called from `_buildNavBar()` inside `_buildFloatingDock()`. The `showcaseContext` is still passed all the way through from the `ShowCaseWidget.builder` — ensure this parameter threading is preserved.

```
ShowCaseWidget.builder(showcaseContext)
  → _buildFloatingDock(showcaseContext)
    → _buildNavBar(showcaseContext, t)
      → _buildTabPills(showcaseContext)    ← Showcase wrapping lives here
```

---

## 10. Complete State Variable Summary

```dart
// EXISTING — keep unchanged
late int _currentIndex;
late AnimationController _pulseController;
late Animation<double> _pulseAnimation;
final Map<String, bool> _pressedMap = {};
bool _showQuickSettings = false;
bool _dummyToggle1 = true;
bool _dummyToggle2 = false;
AccessState? _overlayType;
bool _overlayLoading = false;
bool _checkInProgress = false;
VoidCallback? _pendingAction;
bool _tourChecked = false;
bool _tourStartPending = false;
TourCheckpoint? _checkpoint;
BuildContext? _showcaseContext;

// NEW — add these
bool _moduleCardAttached = false;
bool _moduleCardVisible = true;
final ScrollController _scrollController = ScrollController();
String _toastMessage = '';
bool _toastVisible = false;
Timer? _toastTimer;
```

---

## 11. Import Additions

```dart
import 'dart:async';  // for Timer (toast)
// All other imports remain unchanged
```

---

## 12. Method Rename Map

| Old method name | New method name | Notes |
|---|---|---|
| `_buildFloatingNavBar` | `_buildFloatingDock` | Now wraps both panel + nav |
| — | `_buildNavBar` | Extracted from above, nav bar only |
| `_buildModuleCard` | `_buildInlineModuleCard` | Detached / scroll body card |
| — | `_buildAttachedModulePanel` | New: docked above nav |
| — | `_buildOverviewCard` | New: replaces content cards |
| — | `_attachModuleCard` | New: attach action |
| — | `_detachModuleCard` | New: detach action |
| — | `_showToast` | New: toast helper |

All other method names stay the same.

---

## 13. Quick Checklist Before Shipping

- [ ] `_checkAccess` and all access gate logic compiles and works
- [ ] `_maybeStartShowcase` is called in `ShowCaseWidget.builder`
- [ ] All `TourRegistry.*` keys still reference the correct widgets
- [ ] `SiteRegistry.siteModuleCardKey` still wraps the Site Details icon item
- [ ] `_buildLoadingState` is still returned for loading/error states of `languageModuleProvider`
- [ ] `Scaffold.drawer = CustomDrawer()` still present
- [ ] `_scrollController` is passed to `SingleChildScrollView`
- [ ] `_dockSpacerHeight` prevents content hiding behind dock
- [ ] Toast timer cancelled in `dispose()`
- [ ] All `ref.watch` / `ref.read` calls unchanged
- [ ] No `context.push` or `context.go` calls added or removed