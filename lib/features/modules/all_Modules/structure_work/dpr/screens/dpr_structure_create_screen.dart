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
import '../../boq/models/boq_structure_model.dart';
import '../../boq/providers/saved_boq_provider.dart';

class DprStructureCreateScreen extends ConsumerStatefulWidget {
  final String siteId;
  final String siteName;
  final VoidCallback? onSuccess;

  const DprStructureCreateScreen({
    super.key,
    required this.siteId,
    required this.siteName,
    this.onSuccess,
  });

  @override
  ConsumerState<DprStructureCreateScreen> createState() =>
      _DprStructureCreateScreenState();
}

class _DprStructureCreateScreenState
    extends ConsumerState<DprStructureCreateScreen> {
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _workNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dprEntryProvider.notifier).initialize(widget.siteId);
      ref.read(savedBOQProvider.notifier).fetchAndSync(widget.siteId);
    });
  }

  @override
  void dispose() {
    _workNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final entryState = ref.watch(dprEntryProvider);

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
                text: 'Submit DPR Entry',
                color: entryState.activeCards.isEmpty
                    ? cs.surfaceContainerHighest
                    : cs.primary,
                textColor: entryState.activeCards.isEmpty
                    ? cs.onSurfaceVariant
                    : cs.onPrimary,
                onPressed: entryState.activeCards.isEmpty ? () {} : _submitDPR,
                isOutlined: false,
              ),
            ),
          ],
          child: Column(
            children: [
              if (entryState.isLoading)
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
                      _buildEditableWorkHeader(cs, entryState),
                      const SizedBox(height: 16),
                      _buildAddEntryRow(cs),
                      const SizedBox(height: 12),
                      _buildCardList(cs, entryState),
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

  Widget _buildEditableWorkHeader(ColorScheme cs, DprEntryState state) {
    final boqState = ref.watch(savedBOQProvider);
    final hasNames =
        state.availableWorkNames.isNotEmpty || boqState.boqs.isNotEmpty;
    final names = {
      ...state.availableWorkNames,
      ...boqState.boqs.map((e) => e.boqName)
    }.toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.55)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasNames) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
              child: Text(
                'BOQ File',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: 6),
            PopupMenuButton<String>(
              onSelected: (val) {
                _workNameController.text = val;
                ref
                    .read(dprEntryProvider.notifier)
                    .loadCardsForWork(widget.siteId, val);
              },
              itemBuilder: (context) {
                return names
                    .map(
                        (name) => PopupMenuItem(value: name, child: Text(name)))
                    .toList();
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: cs.primary.withOpacity(0.5),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.folder_open_rounded,
                        size: 18, color: cs.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _workNameController.text.isNotEmpty
                            ? _workNameController.text
                            : 'Select BOQ file',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
                        ),
                      ),
                    ),
                    Icon(Icons.expand_more_rounded, color: cs.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: TextField(
              controller: _workNameController,
              onChanged: (val) {
                ref.read(dprEntryProvider.notifier).setWorkName(val);
              },
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: cs.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: cs.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: cs.primary, width: 2),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                hintText: 'Enter Entry Name',
                hintStyle: TextStyle(color: cs.onSurfaceVariant),
                prefixIcon: Icon(Icons.insights, size: 20, color: cs.primary),
                filled: true,
                fillColor: cs.surface,
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
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

  Widget _buildCardList(ColorScheme cs, DprEntryState state) {
    if (state.activeCards.isEmpty) {
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
      itemCount: state.activeCards.length,
      itemBuilder: (context, index) {
        final card = state.activeCards[index];
        return AssemblyCardWidget(
          card: card,
          onUpdate: (mark, qty) {
            ref.read(dprEntryProvider.notifier).updateCard(index, mark, qty);
          },
          onDelete: () {
            ref.read(dprEntryProvider.notifier).removeCard(index);
          },
        );
      },
    );
  }

  Future<void> _submitDPR() async {
    final entryState = ref.read(dprEntryProvider);
    if (entryState.activeCards.isEmpty) return;

    final invalidMarks = entryState.activeCards
        .where((c) => c.assemblyMark.trim().isEmpty)
        .toList();
    if (invalidMarks.isNotEmpty) {
      AppToast.error('Please enter an assembly mark for all entries.');
      return;
    }

    final boqState = ref.read(savedBOQProvider);
    final boqId = _resolveBoqId(entryState.activeCards, boqState.boqs);
    if (boqId == null) return;

    final items = entryState.activeCards
        .map((c) => {
              'assemblyMark': c.assemblyMark,
              'qtyUsed': c.quantity,
              'boqItemId': c.boqItemId,
            })
        .toList();
    final remarks = _workNameController.text.trim();
    final success = await ref.read(dprStructureProvider.notifier).createDPR(
          widget.siteId,
          boqId: boqId,
          items: items,
          date: _selectedDate,
          remarks: remarks.isNotEmpty ? remarks : null,
        );

    if (success && mounted) {
      HapticFeedback.heavyImpact();
      AppToast.success("DPR Submitted Successfully!");
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
    if (picked != null) setState(() => _selectedDate = picked);
  }
}
