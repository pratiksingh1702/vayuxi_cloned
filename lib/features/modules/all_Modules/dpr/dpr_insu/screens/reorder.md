# Reorder System Implementation Guide
## Target File: `allinsulationmaterial.dart`
## Reference: `AllMaterialsScreen` (mech DPR)

---

## 🔍 What the Reorder System Does (Deep Analysis)

The reorder system in `AllMaterialsScreen` allows users to drag-and-drop material cards to rearrange their display order. It has:

1. **State management** — tracks which category is being reordered, what order the IDs are in, which item is being dragged
2. **Visual feedback** — drag handles, animated lift effect, opacity dimming, index numbers
3. **Optimistic UI** — updates the list immediately, then syncs to persistence layer (Isar), rolls back on failure
4. **Long-press entry** — user can long-press any card to enter reorder mode
5. **Explicit exit** — "Done" button in the header bar
6. **Haptic feedback** — `HapticFeedback.mediumImpact()` on drag start and reorder commit

---

## 📦 Step 1 — Add State Variables

In `_AllInsulationMaterialsScreenState`, add these variables after `_setupsLoaded`:

```dart
// ─── REORDER STATE ───────────────────────────────────────
bool _isReorderMode = false;
String? _reorderCategory;           // 'piping' or 'equipment'
List<int> _reorderMaterialIds = []; // Isar local IDs in display order
List<LocalMaterial> _reorderDisplayMaterials = [];
int? _draggingReorderIndex;
String? _draggingMaterialId;        // serverId or id.toString()
bool _isOrderSyncing = false;
```

**Why:** Each variable serves a precise role:
- `_isReorderMode` gates whether the ReorderableListView is rendered
- `_reorderCategory` scopes reorder to one tab at a time
- `_reorderMaterialIds` is the source of truth for current order (List of Isar int IDs)
- `_reorderDisplayMaterials` is the parallel list of full objects for rendering
- `_draggingReorderIndex` / `_draggingMaterialId` drives the opacity dimming of the item being dragged
- `_isOrderSyncing` shows a "Saving order..." message in the header while persisting

---

## 📦 Step 2 — Add Reorder Helper Methods

Add these methods to the state class. Place them near the other action methods (`_copyMaterial`, `_deleteMaterial`, etc.):

### 2a. Enter Reorder Mode

```dart
void _enterReorderMode(String category, List<LocalMaterial> materials) {
  if (materials.length < 2) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('At least 2 items are needed to reorder'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  setState(() {
    isDeleteMode = false;          // exit delete mode (from DeleteModeMixin)
    selectedIds.clear();           // clear any selection
    _isReorderMode = true;
    _reorderCategory = category;
    // Use local Isar int IDs as the order key
    _reorderMaterialIds = materials.map((m) => m.id).toList();
    _reorderDisplayMaterials = List<LocalMaterial>.from(materials);
    _draggingReorderIndex = null;
    _draggingMaterialId = null;
  });
}
```

**Why:** Guard of `< 2` prevents entering reorder with a single item (nonsensical UX). Clears delete mode because the two modes conflict — selection overlays and drag handles cannot coexist.

### 2b. Exit Reorder Mode

```dart
void _exitReorderMode() {
  // NOTE: called inside setState() by callers, so no setState here
  _isReorderMode = false;
  _reorderCategory = null;
  _reorderMaterialIds = [];
  _reorderDisplayMaterials = [];
  _draggingReorderIndex = null;
  _draggingMaterialId = null;
}
```

**Why:** This is a plain void (no setState) because all callers wrap it: `setState(_exitReorderMode)`. The mech version does the same pattern.

### 2c. Effective Order Resolver

```dart
List<LocalMaterial> _effectiveOrderForCategory(
  String category,
  List<LocalMaterial> materials,
) {
  final isActive = _isReorderMode && _reorderCategory == category;
  if (!isActive) return materials;

  if (_reorderDisplayMaterials.isNotEmpty) {
    return _reorderDisplayMaterials;
  }

  final mapById = {for (final m in materials) m.id: m};
  return _reorderMaterialIds
      .map((id) => mapById[id])
      .where((m) => m != null)
      .cast<LocalMaterial>()
      .toList(growable: false);
}
```

**Why:** When reorder mode is active for a category, we must render from `_reorderDisplayMaterials` (the locally-reordered list), NOT from the provider stream. If we used the stream, the Riverpod provider would re-sort it and undo the user's drag. The fallback rebuild from `_reorderMaterialIds` handles edge cases where `_reorderDisplayMaterials` is accidentally empty.

### 2d. Handle Reorder (the core drag logic)

```dart
Future<void> _handleMaterialReorder({
  required String category,
  required int oldIndex,
  required int newIndex,
}) async {
  if (!_isReorderMode || _reorderCategory != category) return;

  // Flutter's ReorderableListView passes newIndex AFTER removal,
  // so we must adjust it when moving down.
  if (newIndex > oldIndex) {
    newIndex -= 1;
  }
  if (oldIndex == newIndex) return;
  if (newIndex < 0 || newIndex >= _reorderMaterialIds.length) return;

  HapticFeedback.mediumImpact();

  // Save previous state for rollback
  final previousIds = List<int>.from(_reorderMaterialIds);
  final previousDisplay = List<LocalMaterial>.from(_reorderDisplayMaterials);

  // Apply optimistic reorder
  final updatedIds = List<int>.from(_reorderMaterialIds);
  final updatedDisplay = List<LocalMaterial>.from(_reorderDisplayMaterials);

  final movedId = updatedIds.removeAt(oldIndex);
  updatedIds.insert(newIndex, movedId);

  final movedItem = updatedDisplay.removeAt(oldIndex);
  updatedDisplay.insert(newIndex, movedItem);

  setState(() {
    _reorderMaterialIds = updatedIds;
    _reorderDisplayMaterials = updatedDisplay;
  });

  // Persist to YOUR Isar layer (insulation-specific repo)
  // ⚠️  YOU must wire this to your insulation Isar repo.
  //     See Step 3 for the persistence call.
  final siteId = ref.read(selectedSiteIdProvider);
  if (siteId == null) return;

  try {
    setState(() => _isOrderSyncing = true);

    // 👇 REPLACE THIS with your insulation repo's display-order persistence
    await _persistInsulationDisplayOrder(
      siteId: siteId,
      category: category,
      orderedIds: _reorderMaterialIds,
    );
  } catch (e) {
    // Rollback on failure
    setState(() {
      _reorderMaterialIds = previousIds;
      _reorderDisplayMaterials = previousDisplay;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to persist order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        _isOrderSyncing = false;
        _draggingReorderIndex = null;
        _draggingMaterialId = null;
      });
    }
  }
}
```

**Why `newIndex -= 1` when `newIndex > oldIndex`:** Flutter's `ReorderableListView.onReorder` gives the new index *after* the item is logically removed from the old position. If you drag item 0 to position 3, Flutter says `newIndex = 3` but the real insertion point after removal is 2. This off-by-one correction is mandatory.

---

## 📦 Step 3 — Isar Persistence (Your Own Repo)

> ⚠️ You said you have different Isar folders for insulation. Provide those to the AI. The method below is a placeholder pattern — replace the body with your actual Isar write.

Create or add to your insulation Isar repo:

```dart
// In your insulation LocalMaterialDao or repo:

Future<void> persistDisplayOrderForSubset({
  required String siteId,
  required String designation,  // 'piping' or 'equipment'
  required List<int> orderedIsarIds,  // local Isar int IDs in desired order
}) async {
  // Write displayOrder field to each LocalMaterial in Isar
  // Example pattern (adapt to your schema):
  await isar.writeTxn(() async {
    for (int i = 0; i < orderedIsarIds.length; i++) {
      final m = await isar.localMaterials.get(orderedIsarIds[i]);
      if (m != null) {
        m.displayOrder = i;  // add this field to your Isar model if not present
        await isar.localMaterials.put(m);
      }
    }
  });
}
```

Then in `allinsulationmaterial.dart`, add the helper:

```dart
Future<void> _persistInsulationDisplayOrder({
  required String siteId,
  required String category,
  required List<int> orderedIds,
}) async {
  final dao = LocalMaterialDao(); // your insulation DAO
  await dao.persistDisplayOrderForSubset(
    siteId: siteId,
    designation: category == 'piping'
        ? MaterialDesignation.piping.key
        : MaterialDesignation.equipment.key,
    orderedIsarIds: orderedIds,
  );
}
```

**Also:** Make sure your `materialsStreamProvider` sorts by `displayOrder` ascending so the persisted order is reflected when reorder mode is exited.

---

## 📦 Step 4 — Update `_buildMaterialsTab`

This is the most structural change. The tab builder needs to:

1. Call `_effectiveOrderForCategory` to get the display list
2. Show a reorder-mode banner in the header
3. Add a reorder icon button in the non-delete header row
4. Render `_buildReorderableList` instead of normal `ListView.builder` when in reorder mode
5. Add `onLongPress` to normal list items to enter reorder mode

Replace your existing `_buildMaterialsTab` with this structure:

```dart
Widget _buildMaterialsTab({
  required String siteId,
  required List<LocalMaterial> materials,
  required IconData icon,
  required Color color,
  required String emptyMessage,
  required String category,
  bool isLoading = false,
}) {
  if (isLoading) {
    return _buildLoadingState(category: category, color: color);
  }

  final isReorderForCategory = _isReorderMode && _reorderCategory == category;
  // ✅ KEY: use effective order, not raw materials
  final displayMaterials = _effectiveOrderForCategory(category, materials);

  if (displayMaterials.isEmpty) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          emptyMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF5A6E89)),
        ),
      ),
    );
  }

  return Column(
    children: [
      // ── HEADER ──────────────────────────────────────────────
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              // Highlight border when reorder is active for this category
              color: isReorderForCategory ? color : const Color(0xFFD8E5FF),
              width: isReorderForCategory ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── REORDER MODE BANNER ──────────────────────────
              if (isReorderForCategory)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.drag_indicator, size: 16, color: color),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _isOrderSyncing
                              ? 'Reorder mode active. Saving order...'
                              : 'Reorder mode active. Drag cards to arrange display order.',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2E4E79),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // ── DONE BUTTON ──────────────────────────
                      _buildHeaderActionButton(
                        label: 'Done',
                        icon: Icons.check,
                        textColor: Colors.white,
                        bgColor: const Color(0xFF2A66CC),
                        onTap: () => setState(_exitReorderMode),
                      ),
                    ],
                  ),
                )

              // ── DELETE MODE HEADER ────────────────────────────
              else if (isDeleteMode)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildHeaderActionButton(
                        label: 'Close',
                        icon: Icons.close,
                        textColor: const Color(0xFF5A6E89),
                        bgColor: const Color(0xFFF1F5FB),
                        onTap: () => setState(() {
                          toggleDeleteMode();
                          selectedIds.clear();
                        }),
                      ),
                      const SizedBox(width: 8),
                      _buildHeaderActionButton(
                        label: selectAllLabel(materials.map((m) => m.id).toList()),
                        icon: Icons.done_all,
                        textColor: const Color(0xFF2B5FAE),
                        bgColor: const Color(0xFFEAF2FF),
                        onTap: () => setState(() {
                          handleSelectAllToggle(materials.map((m) => m.id).toList());
                        }),
                      ),
                      const SizedBox(width: 8),
                      _buildHeaderActionButton(
                        label: 'Delete',
                        icon: Icons.delete_sweep,
                        textColor: Colors.white,
                        bgColor: const Color(0xFFD34747),
                        onTap: selectedIds.isEmpty
                            ? null
                            : () => _deleteSelectedMaterials(materials),
                      ),
                    ],
                  ),
                )

              // ── NORMAL HEADER ─────────────────────────────────
              else
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Total ${category == 'piping' ? 'Piping' : 'Equipment'}: ${displayMaterials.length}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Color(0xFF2E4E79),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // ── REORDER BUTTON ────────────────────────────
                    _buildHeaderIconButton(
                      icon: isReorderForCategory
                          ? Icons.checklist_rtl_rounded
                          : Icons.reorder_rounded,
                      tooltip: isReorderForCategory
                          ? 'Exit Reorder Mode'
                          : 'Reorder Materials',
                      iconColor: isReorderForCategory
                          ? const Color(0xFF2A66CC)
                          : color,
                      onTap: displayMaterials.length < 2
                          ? null
                          : () {
                              if (isReorderForCategory) {
                                setState(_exitReorderMode);
                                return;
                              }
                              _enterReorderMode(category, displayMaterials);
                            },
                    ),
                    const SizedBox(width: 8),

                    _buildHeaderIconButton(
                      icon: Icons.delete_sweep,
                      tooltip: 'Select Items',
                      iconColor: const Color(0xFFD34747),
                      onTap: displayMaterials.isEmpty || _isReorderMode
                          ? null
                          : () => setState(() => toggleDeleteMode()),
                    ),
                    const SizedBox(width: 8),
                    _buildHeaderIconButton(
                      icon: Icons.add_circle,
                      tooltip: 'Add Material',
                      iconColor: color,
                      onTap: () => _addNewMaterial(siteId, category),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),

      // ── LIST AREA ────────────────────────────────────────────
      Expanded(
        child: isReorderForCategory
            ? _buildReorderableList(
                category: category,
                color: color,
                materials: displayMaterials,
              )
            : RefreshIndicator(
                onRefresh: () async => _loadMaterialSetups(siteId),
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
                  itemCount: displayMaterials.length,
                  itemBuilder: (context, index) {
                    final local = displayMaterials[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        // Long-press enters reorder mode
                        onLongPress: isDeleteMode
                            ? null
                            : () => _enterReorderMode(category, displayMaterials),
                        child: category == 'piping'
                            ? _buildPipingCard(local, color)
                            : _buildEquipmentCard(local, color),
                      ),
                    );
                  },
                ),
              ),
      ),
    ],
  );
}
```

---

## 📦 Step 5 — Add `_buildReorderableList`

Add this new method after `_buildMaterialsTab`:

```dart
Widget _buildReorderableList({
  required String category,
  required Color color,
  required List<LocalMaterial> materials,
}) {
  // Edge case: exactly 1 item — can't reorder, render plain
  if (materials.length < 2) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
      children: [
        category == 'piping'
            ? _buildPipingCard(materials.first, color)
            : _buildEquipmentCard(materials.first, color),
      ],
    );
  }

  return Theme(
    // Remove the default drag shadow/canvas color that Flutter applies
    data: Theme.of(context).copyWith(
      canvasColor: Colors.transparent,
      shadowColor: Colors.transparent,
    ),
    child: ReorderableListView.builder(
      buildDefaultDragHandles: false,  // ✅ We provide our own drag handles
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),

      onReorderStart: (index) {
        HapticFeedback.mediumImpact();
        // ✅ CRITICAL: read from _reorderDisplayMaterials, NOT from the `materials` param
        // The `materials` param is captured at build time and may be stale.
        if (index < _reorderDisplayMaterials.length) {
          setState(() {
            _draggingReorderIndex = index;
            // Use string representation of the local int ID as the drag key
            _draggingMaterialId = _reorderDisplayMaterials[index].id.toString();
          });
        }
      },

      onReorderEnd: (_) {
        if (!mounted) return;
        setState(() {
          _draggingReorderIndex = null;
          _draggingMaterialId = null;
        });
      },

      // Custom proxy (the floating ghost card while dragging)
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, child) {
            final elevation = Tween<double>(begin: 0, end: 20)
                .animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ))
                .value;
            final scale = Tween<double>(begin: 1.0, end: 1.04)
                .animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ))
                .value;

            return Opacity(
              opacity: 0.98,
              child: Material(
                elevation: elevation,
                color: Colors.transparent,
                shadowColor: color.withOpacity(0.4),
                borderRadius: BorderRadius.circular(14),
                child: Transform(
                  transform: Matrix4.identity()
                    ..translate(0.0, -6.0, 0.0)
                    ..scale(scale),
                  alignment: Alignment.topCenter,
                  child: child,
                ),
              ),
            );
          },
        );
      },

      // ✅ CRITICAL: item count from _reorderDisplayMaterials, not the param
      itemCount: _reorderDisplayMaterials.length,

      onReorder: (oldIndex, newIndex) {
        _handleMaterialReorder(
          category: category,
          oldIndex: oldIndex,
          newIndex: newIndex,
        );
      },

      itemBuilder: (context, index) {
        // ✅ CRITICAL: read from _reorderDisplayMaterials directly
        if (index >= _reorderDisplayMaterials.length) {
          return const SizedBox.shrink(key: ValueKey('empty'));
        }

        final item = _reorderDisplayMaterials[index];
        final isDragging = _draggingMaterialId == item.id.toString();

        return _buildReorderableItem(
          key: ValueKey('reorder_${item.id}'),
          index: index,
          color: color,
          category: category,
          material: item,
          isDragging: isDragging,
        );
      },
    ),
  );
}
```

**Why `_reorderDisplayMaterials` instead of `materials` param everywhere:** The `materials` param is captured at widget build time. Once the user drags an item, `_reorderDisplayMaterials` changes but `materials` is still the old closure value. If you read from `materials`, the list length and content will be wrong mid-drag. This is the most common bug when porting this system.

---

## 📦 Step 6 — Add `_buildReorderableItem`

```dart
Widget _buildReorderableItem({
  required Key key,
  required int index,
  required Color color,
  required String category,
  required LocalMaterial material,
  required bool isDragging,
}) {
  return AnimatedContainer(
    key: key,
    duration: const Duration(milliseconds: 220),
    curve: Curves.easeOutCubic,
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      boxShadow: isDragging
          ? [
              BoxShadow(
                color: color.withOpacity(0.25),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ]
          : const [],
    ),
    child: Stack(
      children: [
        // ── CARD (non-interactive during drag) ───────────────
        IgnorePointer(
          ignoring: true,  // Block taps on card while in reorder mode
          child: Opacity(
            opacity: isDragging ? 0.5 : 1.0,  // Dim the source slot while dragging
            child: category == 'piping'
                ? _buildPipingCard(material, color)
                : _buildEquipmentCard(material, color),
          ),
        ),

        // ── DRAG HANDLE (right-side strip) ──────────────────
        Positioned(
          top: 0,
          right: 0,
          bottom: 0,
          child: ReorderableDragStartListener(
            index: index,
            child: Container(
              width: 48,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
                color: color.withOpacity(0.8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.drag_indicator_rounded,
                    color: color.withOpacity(0.8),
                    size: 22,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: color.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
```

**Key details:**
- `IgnorePointer(ignoring: true)` on the card prevents accidental taps on edit/delete/copy buttons while dragging
- `ReorderableDragStartListener` is Flutter's built-in — wrap it around the visual handle area. It reads the `index` to tell `ReorderableListView` which item is being moved
- The right-side strip shows a color-coded drag icon + position number for clarity

---

## 📦 Step 7 — Update `_buildPipingCard` and `_buildEquipmentCard`

The existing card builders wrap content in `Stack` with a selection overlay. You need to also block interactions when reorder mode is active.

In `_buildPipingCard`, add this near the top:

```dart
Widget _buildPipingCard(LocalMaterial local, Color color) {
  final material = _toPiping(local);
  final isSelected = selectedIds.contains(local.id);
  final materialSetup = _findMaterialSetup(local);

  // ✅ ADD: Lock interactions during selection OR reorder
  final isInteractionLocked = isDeleteMode || _isReorderMode;

  return Stack(
    children: [
      Opacity(
        opacity: isDeleteMode && !isSelected ? 0.5 : 1.0,
        child: IgnorePointer(
          ignoring: isDeleteMode,   // keep existing delete-mode block
          child: PipingMaterialCard(
            key: ValueKey('piping_${local.id}_${local.materialDataJson?.hashCode}'),
            material: material,
            materialSetup: materialSetup,
            onChanged: (updated) => _updatePipingMaterial(local, updated),
            onAdd: isInteractionLocked ? null : () => _copyMaterial(local),
            onEdit: isInteractionLocked ? () {} : () {},
            onDelete: isInteractionLocked ? null : () => _deleteMaterial(local),
            onRemark: isInteractionLocked ? () {} : () {},
          ),
        ),
      ),
      if (isDeleteMode) _selectionOverlay(local.id, isSelected),
    ],
  );
}
```

Apply the same `isInteractionLocked` pattern to `_buildEquipmentCard`.

**Why:** In reorder mode, the drag handle sits on top of the card. Without `isInteractionLocked`, tapping the card body could open edit overlays mid-drag. Null callbacks tell cards to disable their action buttons.

---

## 📦 Step 8 — Update `_buildBody` / Call Sites

In `_buildMaterialsTab` calls inside `_buildBody`, pass `materials` as the raw list from Isar. The `_effectiveOrderForCategory` call inside `_buildMaterialsTab` will select either the live list or the reorder list:

```dart
// In _buildBody:
_buildMaterialsTab(
  siteId: siteId,
  materials: pipingMaterials,   // ← always pass raw provider list
  icon: Icons.precision_manufacturing,
  color: Colors.blue,
  emptyMessage: 'No piping insulation materials found',
  category: 'piping',
  isLoading: isLoading,
),
_buildMaterialsTab(
  siteId: siteId,
  materials: equipmentMaterials,
  icon: Icons.build,
  color: Colors.green,
  emptyMessage: 'No equipment insulation materials found',
  category: 'equipment',
  isLoading: isLoading,
),
```

---

## 📦 Step 9 — Imports to Add

At the top of `allinsulationmaterial.dart`, ensure these are present:

```dart
import 'package:flutter/services.dart';  // for HapticFeedback
// Your insulation Isar DAO import — provide this path:
// import 'package:untitled2/features/modules/all_Modules/dpr/dpr_insu/isar/...';
```

---

## 📦 Step 10 — Isar Schema Change (if `displayOrder` field is new)

If `LocalMaterial` (insulation version) doesn't have a `displayOrder` field, add it:

```dart
// In your insulation LocalMaterial Isar model:
@Index()
int displayOrder = 0;
```

Then run Isar codegen:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

And update your stream/query to sort by `displayOrder`:
```dart
// In your materialsStreamProvider query:
.filter()
  .siteIdEqualTo(siteId)
  .and()
  .designationEqualTo(designation)
.sortByDisplayOrder()  // ← add this
.watch(fireImmediately: true)
```

---

## ✅ Summary Checklist for the AI

- [ ] Add 6 state variables (Step 1)
- [ ] Add `_enterReorderMode` method (Step 2a)
- [ ] Add `_exitReorderMode` method (Step 2b)  
- [ ] Add `_effectiveOrderForCategory` method (Step 2c)
- [ ] Add `_handleMaterialReorder` method (Step 2d)
- [ ] Add `_persistInsulationDisplayOrder` method wired to insulation Isar repo (Step 3)
- [ ] Rewrite `_buildMaterialsTab` to include reorder banner, reorder button, long-press entry, and conditional list rendering (Step 4)
- [ ] Add `_buildReorderableList` method (Step 5)
- [ ] Add `_buildReorderableItem` method (Step 6)
- [ ] Update `_buildPipingCard` and `_buildEquipmentCard` with `isInteractionLocked` (Step 7)
- [ ] Verify `_buildBody` passes raw provider lists (Step 8)
- [ ] Add `flutter/services.dart` import (Step 9)
- [ ] Add `displayOrder` field to insulation Isar model and update query sort (Step 10) — **only if field doesn't exist yet**
- [ ] Provide your insulation Isar folder so the AI can wire Step 3 correctly

---

## ⚠️ Critical "Do Not" Rules

1. **Never read from the `materials` closure param inside `_buildReorderableList` or its `itemBuilder`.** Always read from `_reorderDisplayMaterials` directly. The closure is stale after first drag.

2. **Never call `setState` inside `_exitReorderMode`.** It is called inside `setState(() => _exitReorderMode())` by callers.

3. **Never use `buildDefaultDragHandles: true`** on `ReorderableListView`. It places handles automatically in wrong positions. Set it `false` and use `ReorderableDragStartListener` manually.

4. **The `newIndex -= 1` correction is not optional.** Flutter always passes the post-removal index. Without this fix, dragging items down will place them one position too low.

5. **Do not enter reorder mode and delete mode simultaneously.** `_enterReorderMode` must call `toggleDeleteMode()` / `selectedIds.clear()` if `isDeleteMode` is true before setting `_isReorderMode = true`.