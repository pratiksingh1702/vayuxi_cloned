# Module Filter & Sort Implementation Guide

This document outlines the architectural approach for implementing a premium, high-fidelity filtering and sorting system in any module list screen. Use this as a reference guide for AI-driven code generation.

## 1. Core Architecture
The system follows a **Filter-then-Sort** pipeline applied to a reactive data stream (Riverpod `AsyncValue`).

### Step A: State Management
Define an enum for sorting options and state variables for filters within the Screen's state class:
```dart
enum ModuleSortOption { nameAsc, nameDesc, dateDesc, dateAsc, valueHighToLow, valueLowToHigh }

// State variables
ModuleSortOption _currentSort = ModuleSortOption.dateDesc; // Default: Latest First
String? _selectedCategory;
double? _minValue;
double? _maxValue;
```

### Step B: The Processing Pipeline
Inside the UI `build` or `data` callback, apply the logic sequentially:
1.  **Filtering**: Start with the full list and chain predicates (Search Query -> Category -> Range).
2.  **Sorting**: Apply a `switch-case` on the sorted list based on the active `enum`.

## 2. UI/UX Standards (Premium Look)

### Filter Entry Point
- **Visual Feedback**: The filter icon should have a notification badge or a background color change when any filter is active.
- **Placement**: Integrated into the search bar row for easy access.

### Bottom Sheet Design
- **Stateful Interaction**: Use `StatefulBuilder` inside `showModalBottomSheet` so users can see changes instantly without closing the sheet.
- **Header**: Include a "Reset All" button and a clear title.
- **Sectioning**: Use bold titles for "Sort By", "Category", and "Range".
- **Chips**: Use `FilterChip` or custom `Container` chips with subtle shadows and border transitions.
- **Inputs**: Range inputs should have clear prefix/suffix icons (e.g., currency symbols).

## 3. Implementation Steps for AI

To replicate this in a new module (e.g., Inventory, Expenses):

1.  **Repository Level**: Update the Isar/Database watcher to default to `sortByTimestampDesc()` to ensure cross-screen consistency (e.g., Attendance list matches Main list).
2.  **Screen Enum**: Create a `ModuleSortOption` specific to the model's fields.
3.  **Filter Widget**: Create a `_buildFilterButton` that tracks `hasActiveFilters`.
4.  **Bottom Sheet Widget**: Create a `_showFilterSortBottomSheet` using the `StatefulBuilder` pattern.
5.  **Data Logic**:
    - Wrap the list processing in a `where` block for filtering.
    - Wrap the resulting list in a `sort` block for the final view.

## 4. Key Logic Example
```dart
var filteredList = allData.where((item) {
  if (_category != null && item.category != _category) return false;
  if (_min != null && item.value < _min!) return false;
  return true;
}).toList();

filteredList.sort((a, b) {
  switch (_currentSort) {
    case ModuleSortOption.dateDesc: return b.updatedAt.compareTo(a.updatedAt);
    // ... other cases
  }
});
```

---
*Note: Always prioritize `updatedAt` or `createdAt` as the default sorting field to show the latest entries first.*
