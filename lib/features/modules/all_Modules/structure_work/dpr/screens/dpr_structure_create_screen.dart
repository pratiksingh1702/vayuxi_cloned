import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/utlis/app_toasts.dart';
import '../../../../../../core/utlis/widgets/Button_wrapper.dart';
import '../../../../../../core/utlis/widgets/buttons.dart';
import '../../../../../../core/utlis/widgets/custom.dart';
import '../../../../../../core/utlis/widgets/sidebar.dart';
import '../../dpr_setup/widgets/assembly_card_widget.dart';
import '../../dpr_setup/isar/assembly_card_isar.dart';
import '../providers/dpr_entry_provider.dart';
import '../providers/dpr_structure_provider.dart';
import '../models/dpr_structure_model.dart';
import '../../boq/models/boq_structure_model.dart';
import '../../boq/providers/saved_boq_provider.dart';
import '../../dpr_setup/providers/dpr_setup_providers.dart';
import '../../boq/providers/boq_structure_provider.dart';

class DprStructureCreateScreen extends ConsumerStatefulWidget {
  final String siteId;
  final String siteName;
  final VoidCallback? onSuccess;
  final DPRStructure? initialDpr;

  const DprStructureCreateScreen({
    super.key,
    required this.siteId,
    required this.siteName,
    this.onSuccess,
    this.initialDpr,
  });

  @override
  ConsumerState<DprStructureCreateScreen> createState() =>
      _DprStructureCreateScreenState();
}

class _DprStructureCreateScreenState
    extends ConsumerState<DprStructureCreateScreen> {
  DateTime _selectedDate = DateTime(
      DateTime.now().year, DateTime.now().month, DateTime.now().day);
  final TextEditingController _workNameController =
      TextEditingController(text: 'Structure Work');
  List<DPRStructure> _existingDprs = [];
  bool _isLoadingDprs = false;
  String? _selectedDprId;
  String? _selectedBoqId;
  DPRStructure? _latestDpr;
  List<AssemblyCardIsar>? _localSetupCards;

  String? get selectedDprId => _selectedDprId;
  bool get _isUpdate => _selectedDprId != null;

  @override
  void initState() {
    super.initState();

    if (widget.initialDpr != null) {
      _selectedDate = widget.initialDpr!.date ?? _selectedDate;
      _workNameController.text = widget.initialDpr!.dprName;
      _selectedDprId = widget.initialDpr!.id;
      _latestDpr = widget.initialDpr;
      _selectedBoqId = widget.initialDpr!.boqId;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dprEntryProvider.notifier).initialize(widget.siteId);
      ref.read(savedBOQProvider.notifier).fetchAndSync(widget.siteId).then((_) {
        final boqs = ref.read(savedBOQProvider).boqs;
        if (widget.initialDpr != null) {
          setState(() => _selectedBoqId = widget.initialDpr!.boqId);
        } else if (boqs.length == 1) {
          setState(() {
            _selectedBoqId = boqs.first.id;
          });
        }
      });
      _fetchDprsForDate(_selectedDate, preserveInitial: widget.initialDpr != null);
    });
  }

  Future<void> _fetchDprsForDate(DateTime date, {bool preserveInitial = false}) async {
    setState(() => _isLoadingDprs = true);
    final normalizedDate = DateTime(date.year, date.month, date.day);
    try {
      final dprs = await ref
          .read(dprStructureRepositoryProvider)
          .getDPRList(widget.siteId, startDate: normalizedDate, endDate: normalizedDate);
      setState(() {
        _existingDprs = dprs;
        _isLoadingDprs = false;
      });

      if (!preserveInitial) {
        setState(() {
          _selectedDprId = null;
          _latestDpr = null;
          _workNameController.text = 'Structure Work'; 
        });
      }
    } catch (e) {
      setState(() => _isLoadingDprs = false);
      debugPrint('Error fetching DPRs: $e');
    }
  }

  @override
  void dispose() {
    _workNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final structureState = ref.watch(dprStructureProvider);
    final entryState = ref.watch(dprEntryProvider);
    final boqState = ref.watch(savedBOQProvider);
    final setupCards = ref.watch(assemblyCardsProvider(widget.siteId));
    final boqStructureState = ref.watch(boqStructureProvider);

    // Initialize local setup cards from provider (Setup -> Entry reflection)
    // ENFORCE SINGLE CARD: Only take the first one if it exists
    if (_localSetupCards == null && setupCards.isNotEmpty) {
      _localSetupCards = [_cloneCard(setupCards.first)];
    }

    // Sync controller with state if it's empty
    if (_workNameController.text.isEmpty &&
        entryState.selectedWorkName != null) {
      _workNameController.text = entryState.selectedWorkName!;
    }

    return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: cs.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          final title = widget.siteName.isNotEmpty
              ? widget.siteName
              : 'Structure DPR Entry';
          return [
            CustomSliverAppBar(title: title),
          ];
        },
        body: BottomButtonWrapper(
          customButtons: [
            CustomButton(
              button: RoundedButton(
                text: structureState.isSaving ? 'Submitting...' : 'Submit DPR Entry',
                isLoading: structureState.isSaving,
                color: (entryState.activeCards.isEmpty && (_localSetupCards?.isEmpty ?? true))
                    ? cs.surfaceContainerHighest
                    : cs.primary,
                textColor: (entryState.activeCards.isEmpty && (_localSetupCards?.isEmpty ?? true))
                    ? cs.onSurfaceVariant
                    : cs.onPrimary,
                onPressed: ((entryState.activeCards.isEmpty && (_localSetupCards?.isEmpty ?? true)) || structureState.isSaving) ? () {} : _submitDPR,
                isOutlined: false,
              ),
            ),
          ],
          child: Column(
            children: [
              if (entryState.isLoading || _isLoadingDprs)
                LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(6),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            tooltip: 'Select Date',
                            onPressed: _selectDate,
                            icon: const Icon(Icons.calendar_month_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildDateSection(cs),
                      const SizedBox(height: 16),
                      _buildEditableWorkHeader(cs, entryState, boqState),
                      const SizedBox(height: 16),
                      _buildAddEntryRow(cs),
                      const SizedBox(height: 12),
                      _buildCardList(cs, entryState, boqState),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSection(ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded, size: 18, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _selectDate,
            icon:
                Icon(Icons.edit_calendar_rounded, size: 16, color: cs.primary),
            label: Text(
              'Change',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableWorkHeader(
      ColorScheme cs, DprEntryState state, SavedBOQState boqState) {
    final hasBoqs = boqState.boqs.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Entry Name TextField (Prominent)
          TextField(
            controller: _workNameController,
            onChanged: (val) {
              ref.read(dprEntryProvider.notifier).setWorkName(val);
            },
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: 'Enter Entry Name...',
              hintStyle: TextStyle(
                  color: cs.onSurfaceVariant.withOpacity(0.5),
                  fontSize: 15,
                  fontWeight: FontWeight.w500),
              prefixIcon: Icon(Icons.edit_note_rounded, size: 24, color: cs.primary),
              suffixIcon: _existingDprs.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.arrow_drop_down_circle_outlined,
                          color: cs.primary),
                      onPressed: () => _showDprSelector(context),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          Divider(color: cs.outlineVariant.withOpacity(0.3), height: 1),
          const SizedBox(height: 12),

          // 2. Compact Selectors Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (hasBoqs)
                  _buildCompactSelector(
                    cs: cs,
                    icon: Icons.folder_zip_rounded,
                    label: _selectedBoqId != null
                        ? (boqState.boqs
                                .firstWhere((b) => b.id == _selectedBoqId,
                                    orElse: () => boqState.boqs.first)
                                .boqName)
                        : 'Select BOQ',
                    color: cs.primary,
                    onTap: () {
                      _showBoqSelector(context, boqState.boqs);
                    },
                  ),

                if (_selectedDprId != null) ...[
                  const SizedBox(width: 8),
                  _buildCompactSelector(
                    cs: cs,
                    icon: Icons.add_circle_outline_rounded,
                    label: 'New Entry',
                    color: cs.onSurfaceVariant,
                    onTap: () {
                      setState(() {
                        _selectedDprId = null;
                        _latestDpr = null;
                        _workNameController.text = 'Structure Work';
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSelector({
    required ColorScheme cs,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: color),
          ],
        ),
      ),
    );
  }

  void _showBoqSelector(BuildContext context, List<BOQStructure> boqs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Select BOQ File',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: boqs.length,
                itemBuilder: (context, index) {
                  final boq = boqs[index];
                  return ListTile(
                    leading: const Icon(Icons.folder_open_rounded),
                    title: Text(boq.boqName),
                    subtitle: Text(boq.boqNumber),
                    onTap: () {
                      _validateAndSelectBoq(boq);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _validateAndSelectBoq(BOQStructure boq) async {
    final entryState = ref.read(dprEntryProvider);
    final unmatchedItems = <String>[];

    for (final card in entryState.activeCards) {
      final exists = boq.items.any((item) =>
          item.assemblyMark == card.assemblyMark ||
          item.id == card.boqItemId);
      if (!exists && card.assemblyMark.isNotEmpty) {
        unmatchedItems.add(card.assemblyMark);
      }
    }

    if (unmatchedItems.isNotEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unmatched Items'),
          content: Text(
            'The following items are not found in the selected BOQ (${boq.boqName}):\n\n'
            '${unmatchedItems.join(", ")}\n\n'
            'Do you still want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );

      if (proceed != true) return;
    }

    setState(() {
      _selectedBoqId = boq.id;
    });
  }

  void _showDprSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Existing DPRs for this date',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _existingDprs.length,
                itemBuilder: (context, index) {
                  final dpr = _existingDprs[index];
                  return ListTile(
                    leading: const Icon(Icons.history_rounded),
                    title: Text(dpr.dprName),
                    subtitle: Text(dpr.dprNumber),
                    trailing: Text(dpr.status,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    onTap: () {
                      setState(() {
                        _selectedDprId = dpr.id;
                        _latestDpr = dpr;
                        _workNameController.text = dpr.dprName;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAddEntryRow(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Text(
            'Entries',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () {
              ref.read(dprEntryProvider.notifier).addEmptyCard(widget.siteId);
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add'),
            style: OutlinedButton.styleFrom(
              foregroundColor: cs.primary,
              side: BorderSide(color: cs.primary.withOpacity(0.6)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardList(ColorScheme cs, DprEntryState state, SavedBOQState boqState) {
    final displaySetupCards = _localSetupCards ?? [];
    final boqStructureState = ref.watch(boqStructureProvider);
    final existingItems = _latestDpr?.items ?? [];
    
    // Combine setup cards, active (new) cards, and existing items
    final totalItemsCount = displaySetupCards.length + state.activeCards.length + existingItems.length;

    if (totalItemsCount == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 60),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined,
                  size: 48, color: cs.onSurfaceVariant.withOpacity(0.2)),
              const SizedBox(height: 16),
              Text("No entries added yet",
                  style: TextStyle(
                      color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
      itemCount: totalItemsCount,
      itemBuilder: (context, index) {
        // 1. LOCAL SETUP CARDS (Modified locally for this DPR)
        if (index < displaySetupCards.length) {
          final card = displaySetupCards[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  "Setup Card",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: cs.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              AssemblyCardWidget(
                card: card,
                onUpdate: (mark, qty) {
                  setState(() {
                    _syncCardWithBOQ(card, mark, qty, boqStructureState);
                  });
                  // NOTE: WE DO NOT call setup notifier update here (No Vice-Versa reflection)
                },
                onDelete: () {
                   setState(() {
                     _localSetupCards?.removeAt(index);
                   });
                },
              ),
              const Divider(height: 32),
            ],
          );
        }

        // 2. ACTIVE (NEW) CARDS
        final activeIndex = index - displaySetupCards.length;
        if (activeIndex < state.activeCards.length) {
          final card = state.activeCards[activeIndex];
          return AssemblyCardWidget(
            card: card,
            onUpdate: (mark, qty) {
              setState(() {
                _syncCardWithBOQ(card, mark, qty, boqStructureState);
              });
              ref.read(dprEntryProvider.notifier).updateCard(activeIndex, mark, qty);
            },
            onDelete: () {
              ref.read(dprEntryProvider.notifier).removeCard(activeIndex);
            },
          );
        } else {
          // 3. EXISTING ITEMS (Historical)
          final existingItemIndex = index - displaySetupCards.length - state.activeCards.length;
          final item = existingItems[existingItemIndex];
          
          // Look up description from BOQ provider
          String lookedUpDesc = '';
          for (var b in boqState.boqs) {
            final found = b.items.where((i) => i.assemblyMark == item.assemblyMark);
            if (found.isNotEmpty) {
              lookedUpDesc = found.first.typeDescription;
              break;
            }
          }

          final AssemblyCardIsar card = AssemblyCardIsar()
            ..siteId = widget.siteId
            ..boqItemId = item.boqItemId ?? ''
            ..boqId = '' // Default
            ..assemblyMark = item.assemblyMark
            ..description = lookedUpDesc
            ..quantity = item.qtyUsed
            ..availableQty = item.availableQty ?? 0
            ..usedQty = 0
            ..remainingQty = item.remainingQty ?? 0
            ..progressPercentage = 0
            ..createdAt = DateTime.now()
            ..isSynced = true
            ..netWeightPerUnit = item.netWeightPerUnit
            ..totalNetWeight = item.totalNetWeight;

          return AssemblyCardWidget(
            card: card,
            readOnly: false,
            allowMarkEdit: false,
            allowQtyEdit: true,
            onUpdate: (mark, qty) async {
              if (_latestDpr == null) return;
              
              final updatedItems = _latestDpr!.items.map((i) {
                if (i.assemblyMark == mark) {
                  return {
                    'assemblyMark': mark,
                    'qtyUsed': qty,
                    'boqItemId': i.boqItemId,
                  };
                }
                return {
                  'assemblyMark': i.assemblyMark,
                  'qtyUsed': i.qtyUsed,
                  'boqItemId': i.boqItemId,
                };
              }).toList();

              final success = await ref.read(dprStructureProvider.notifier).updateDPR(
                widget.siteId,
                _latestDpr!.id,
                items: updatedItems,
                replaceMode: true,
              );

              if (success) {
                // Refresh list to show updated values
                _fetchDprsForDate(_selectedDate);
              }
            },
            onDelete: () async {
              // Optional: Add delete item from DPR functionality here if needed
            },
          );
        }
      },
    );
  }

  Future<void> _submitDPR() async {
    final entryState = ref.read(dprEntryProvider);
    final setupCards = _localSetupCards ?? [];
    final boqState = ref.read(savedBOQProvider);

    // Collect all items to submit (Setup cards + Active cards)
    final allCards = [...setupCards, ...entryState.activeCards];

    if (allCards.isEmpty) return;

    final invalidMarks = allCards
        .where((c) => c.assemblyMark.trim().isEmpty)
        .toList();
    if (invalidMarks.isNotEmpty) {
      AppToast.error('Please enter an assembly mark for all entries.');
      return;
    }

    final boqId =
        _selectedBoqId ?? _resolveBoqId(allCards, boqState.boqs);
    if (boqId == null) {
      AppToast.error('Please select a BOQ file for this DPR.');
      return;
    }

    final selectedBoq =
        boqState.boqs.where((b) => b.id == boqId).firstOrNull;

    final items = allCards.map((c) {
      String? itemId = c.boqItemId;
      
      // Auto-resolve itemId if missing using the selected BOQ
      if ((itemId == null || itemId.isEmpty) && selectedBoq != null) {
        final matchedItem = selectedBoq.items
            .where((item) => item.assemblyMark == c.assemblyMark)
            .firstOrNull;
        itemId = matchedItem?.id;
      }

      return {
        'assemblyMark': c.assemblyMark,
        'qtyUsed': c.quantity,
        'boqItemId': itemId ?? "",
      };
    }).toList();

    // Final validation: ensure no boqItemId is empty
    if (items.any((item) => (item['boqItemId'] as String).isEmpty)) {
      AppToast.error('Some items could not be matched with the selected BOQ.');
      return;
    }
    final dprName = _workNameController.text.trim();
    
    final bool success;
    if (_isUpdate) {
      success = await ref.read(dprStructureProvider.notifier).updateDPR(
            widget.siteId,
            _selectedDprId!,
            items: items,
            remarks: dprName.isNotEmpty ? dprName : null,
          );
    } else {
      success = await ref.read(dprStructureProvider.notifier).createDPR(
            widget.siteId,
            boqId: boqId,
            items: items,
            dprName: dprName.isNotEmpty ? dprName : null,
            date: _selectedDate,
            remarks: dprName.isNotEmpty ? dprName : null,
          );
    }

    if (success && mounted) {
      HapticFeedback.heavyImpact();
      AppToast.success(_isUpdate ? "DPR Updated Successfully!" : "DPR Submitted Successfully!");
      widget.onSuccess?.call();
      context.pop();
    } else if (mounted) {
      final error = ref.read(dprStructureProvider).error;
      if (error != null && error.isNotEmpty) {
        AppToast.error(error);
      }
    }
  }

  String? _resolveBoqId(List<AssemblyCardIsar> cards, List<BOQStructure> boqs) {
    String? foundBoqId;
    for (final card in cards) {
      final itemId = card.boqItemId.trim();
      if (itemId.isEmpty) {
        AppToast.error('Please select a valid BOQ mark for all entries.');
        return null;
      }
      String? parentId;
      for (final boq in boqs) {
        if (boq.items.any((i) => i.id == itemId)) {
          parentId = boq.id;
          break;
        }
      }

      if (parentId == null || parentId.isEmpty) {
        AppToast.error('BOQ item not found for mark ${card.assemblyMark}.');
        return null;
      }

      if (foundBoqId == null) {
        foundBoqId = parentId;
      } else if (foundBoqId != parentId) {
        AppToast.error('All entries must belong to the same BOQ.');
        return null;
      }
    }
    return foundBoqId;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedDprId = null; // Clear selection on date change
      });
      _fetchDprsForDate(picked);
    }
  }

  void _syncCardWithBOQ(AssemblyCardIsar card, String mark, double qty, BOQStructureState boqState) {
    if (mark.isEmpty) {
      card.assemblyMark = "";
      card.description = "Description";
      card.quantity = qty;
      card.boqItemId = "";
      card.boqId = "";
      card.availableQty = 0;
      card.remainingQty = 0;
      card.netWeightPerUnit = 0;
      card.totalNetWeight = 0;
      card.length = null;
      card.width = null;
      card.height = null;
      card.progressPercentage = 0;
      return;
    }

    // Try to find matching BOQ item
    BOQStructureItem? matchedItem;
    String? matchedBoqId;

    for (var boq in boqState.boqs) {
      for (var item in boq.items) {
        if (item.assemblyMark.toLowerCase() == mark.toLowerCase()) {
          matchedItem = item;
          matchedBoqId = boq.id;
          break;
        }
      }
      if (matchedItem != null) break;
    }

    if (matchedItem != null) {
      // Sync details
      card.boqId = matchedBoqId ?? "";
      card.boqItemId = matchedItem.id;
      card.assemblyMark = matchedItem.assemblyMark;
      card.description = matchedItem.typeDescription;
      card.quantity = qty > 0 ? qty : matchedItem.quantity;
      card.netWeightPerUnit = matchedItem.netWeightPerUnit;
      card.totalNetWeight = (matchedItem.netWeightPerUnit ?? 0) * (qty > 0 ? qty : matchedItem.quantity);
      card.length = matchedItem.length;
      card.width = matchedItem.width;
      card.height = matchedItem.height;
      card.availableQty = qty > 0 ? qty : matchedItem.quantity;
      card.remainingQty = qty > 0 ? qty : matchedItem.quantity;
      card.usedQty = 0;
      card.progressPercentage = 0;
      card.isSynced = false;
    } else {
      // Manual entry mode: Just update Mark and Qty
      card.boqId = "";
      card.boqItemId = "";
      card.description = "Description";
      card.assemblyMark = mark;
      card.quantity = qty;
      card.availableQty = qty;
      card.remainingQty = qty;
      card.usedQty = 0;
      card.netWeightPerUnit = 0;
      card.totalNetWeight = 0;
    }
  }

  AssemblyCardIsar _cloneCard(AssemblyCardIsar card) {
    final clone = AssemblyCardIsar();
    clone.isarId = card.isarId;
    clone.siteId = card.siteId;
    
    // Safely copy late fields with defaults
    try { clone.boqId = card.boqId; } catch (_) { clone.boqId = ""; }
    try { clone.boqItemId = card.boqItemId; } catch (_) { clone.boqItemId = ""; }
    try { clone.assemblyMark = card.assemblyMark; } catch (_) { clone.assemblyMark = ""; }
    try { clone.description = card.description; } catch (_) { clone.description = "Description"; }
    
    clone.quantity = card.quantity;
    clone.availableQty = card.availableQty;
    clone.usedQty = card.usedQty;
    clone.remainingQty = card.remainingQty;
    clone.length = card.length;
    clone.width = card.width;
    clone.height = card.height;
    clone.netWeightPerUnit = card.netWeightPerUnit;
    clone.totalNetWeight = card.totalNetWeight;
    clone.progressPercentage = card.progressPercentage;
    clone.createdAt = card.createdAt;
    clone.isSynced = card.isSynced;
    
    return clone;
  }
}
