import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/utlis/widgets/premium_app_bar.dart';
import '../../boq/models/boq_structure_model.dart';
import '../../boq/providers/boq_structure_provider.dart';
import '../providers/dpr_structure_provider.dart';

const _kBrown = Color(0xFF7B3F00);

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
    extends ConsumerState<DprStructureCreateScreen>
    with TickerProviderStateMixin {
  int _step = 0;
  late AnimationController _successCtrl;

  String get _subtitle {
    switch (_step) {
      case 0:
        return 'Step 1: Context & Scope';
      case 1:
        return 'Step 2: reporting progress';
      case 2:
        return 'Step 3: Review & Submit';
      default:
        return '';
    }
  }

  void _handleBack() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      context.pop();
    }
  }

  // Step 1 fields
  BOQStructure? _selectedBOQ;
  DateTime _date = DateTime.now();
  String _remarks = '';
  final _remarkCtrl = TextEditingController();

  // Step 2: qty map {boqItemId: qtyUsed}
  final Map<String, TextEditingController> _qtyControllers = {};
  String _itemSearch = '';

  // BOQ items loaded
  BOQStructure? _boqWithItems;
  bool _loadingItems = false;

  @override
  void initState() {
    super.initState();
    _successCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(boqStructureProvider.notifier).fetchBOQs(widget.siteId);
    });
  }

  @override
  void dispose() {
    _successCtrl.dispose();
    _remarkCtrl.dispose();
    for (final c in _qtyControllers.values) c.dispose();
    super.dispose();
  }

  Future<void> _loadBOQItems(BOQStructure boq) async {
    setState(() { _loadingItems = true; _boqWithItems = null; });
    try {
      final repo = ref.read(boqStructureRepositoryProvider);
      final detail = await repo.getBOQItems(widget.siteId, boq.id);
      for (final it in detail.items) {
        _qtyControllers[it.id] = TextEditingController();
      }
      if (mounted) setState(() { _boqWithItems = detail; _loadingItems = false; });
    } catch (e) {
      if (mounted) setState(() => _loadingItems = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dprState = ref.watch(dprStructureProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: PremiumAppBar(
        title: 'Report Structural Progress',
        onDrawerPressed: () => _handleBack(),
        drawerIcon: Icons.arrow_back_ios_new_rounded,
        subtitle: Text(_subtitle),
      ),
      body: Column(
        children: [
          _StepIndicator(step: _step),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: _buildCurrentStep(cs, dprState),
            ),
          ),
          _buildBottomBar(cs, dprState),
        ],
      ),
    );
  }

  Widget _buildCurrentStep(ColorScheme cs, DPRStructureState dprState) {
    switch (_step) {
      case 0:
        return _buildStep1(cs);
      case 1:
        return _buildStep2(cs);
      case 2:
        return _buildStep3(cs, dprState);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1(ColorScheme cs) {
    final boqState = ref.watch(boqStructureProvider);
    return SingleChildScrollView(
      key: const ValueKey('step1'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepHeader(
            title: 'Context & Scope',
            subtitle: 'Select the BOQ and work date to begin reporting progress.',
          ),
          const SizedBox(height: 28),
          _SectionLabel(label: 'Select Reference BOQ', cs: cs),
          const SizedBox(height: 12),
          if (boqState.isLoading)
            const _LoadingState()
          else if (boqState.boqs.isEmpty)
            _EmptyBOQState(siteId: widget.siteId)
          else
            ...boqState.boqs.map((boq) => _BOQSelectionTile(
                  boq: boq,
                  isSelected: _selectedBOQ?.id == boq.id,
                  onTap: () {
                    setState(() => _selectedBOQ = boq);
                    _loadBOQItems(boq);
                  },
                )),
          const SizedBox(height: 32),
          _SectionLabel(label: 'Work Date', cs: cs),
          const SizedBox(height: 12),
          _DatePickerField(
            date: _date,
            onTap: _selectDate,
          ),
          const SizedBox(height: 24),
          _SectionLabel(label: 'Site Remarks', cs: cs),
          const SizedBox(height: 12),
          _RemarksField(
            controller: _remarkCtrl,
            onChanged: (v) => _remarks = v,
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (_, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: _kBrown),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Widget _buildStep2(ColorScheme cs) {
    if (_loadingItems) return const _LoadingState();

    final items = (_boqWithItems?.items ?? [])
        .where((it) => it.assemblyMark
            .toLowerCase()
            .contains(_itemSearch.toLowerCase()))
        .where((it) => it.remainingQty > 0)
        .toList();

    return Column(
      key: const ValueKey('step2'),
      children: [
        _MaterialSearchHeader(
          onSearch: (v) => setState(() => _itemSearch = v),
          cs: cs,
        ),
        _SelectedItemsChips(
          controllers: _qtyControllers,
          items: _boqWithItems?.items ?? [],
          onRemove: (id) => setState(() => _qtyControllers[id]?.clear()),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final item = items[i];
              _qtyControllers.putIfAbsent(item.id, () => TextEditingController());
              return _ItemEntryRow(
                item: item,
                controller: _qtyControllers[item.id]!,
                onChanged: () => setState(() {}),
              );
            },
          ),
        ),
        _RunningTotalFooter(
          controllers: _qtyControllers,
          items: _boqWithItems?.items ?? [],
        ),
      ],
    );
  }

  Widget _buildStep3(ColorScheme cs, DPRStructureState dprState) {
    final entries = _buildItemEntries();
    final totalWeight = entries.fold<double>(0, (p, c) {
      final item = _boqWithItems?.items.firstWhere((it) => it.id == c['boqItemId']);
      return p + (item?.netWeightPerUnit ?? 0) * (c['qtyUsed'] as double);
    });

    return SingleChildScrollView(
      key: const ValueKey('step3'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepHeader(
            title: 'Review Summary',
            subtitle: 'Verify the details before finalizing the submission.',
          ),
          const SizedBox(height: 28),
          _SummaryCard(
            selectedBOQ: _selectedBOQ,
            date: _date,
            remarks: _remarks,
            itemCount: entries.length,
            totalWeight: totalWeight,
            cs: cs,
          ),
          const SizedBox(height: 32),
          _SectionLabel(label: 'Items Breakdown', cs: cs),
          const SizedBox(height: 12),
          ...entries.map((e) => _ReviewItemTile(
                assemblyMark: e['assemblyMark'] as String,
                qty: e['qtyUsed'] as double,
                cs: cs,
              )),
          if (dprState.error != null) _ErrorMessage(message: dprState.error!),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ColorScheme cs, DPRStructureState dprState) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          if (_step > 0)
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: () => setState(() => _step--),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.onSurface,
                  side: BorderSide(color: cs.outlineVariant),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child: const Icon(Icons.arrow_back_rounded),
              ),
            ),
          if (_step > 0) const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: ElevatedButton(
              onPressed: dprState.isSaving ? null : _handleNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBrown,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 18),
                elevation: 0,
              ),
              child: dprState.isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Text(
                      _step < 2 ? 'Continue' : 'Submit Entry',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: 0.5),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleNext() async {
    if (_step == 0) {
      if (_selectedBOQ == null) {
        _showSnackBar('Please select a reference BOQ', isError: true);
        return;
      }
      setState(() => _step = 1);
    } else if (_step == 1) {
      final entries = _buildItemEntries();
      if (entries.isEmpty) {
        _showSnackBar('No quantities entered for reporting', isError: true);
        return;
      }
      for (final e in entries) {
        final item =
            _boqWithItems?.items.firstWhere((it) => it.id == e['boqItemId']);
        if (item != null && (e['qtyUsed'] as double) > item.remainingQty) {
          _showSnackBar(
              '${item.assemblyMark} quantity exceeds available limit.',
              isError: true);
          return;
        }
      }
      setState(() => _step = 2);
    } else {
      _confirmSubmission();
    }
  }

  Future<void> _confirmSubmission() async {
    final cs = Theme.of(context).colorScheme;
    final entries = _buildItemEntries();
    
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (b) => _SubmissionConfirmSheet(
        itemCount: entries.length,
        cs: cs,
      ),
    );

    if (ok == true && mounted) {
      final success = await ref.read(dprStructureProvider.notifier).createDPR(
            widget.siteId,
            boqId: _selectedBOQ!.id,
            items: entries,
            date: _date,
            remarks: _remarks.isNotEmpty ? _remarks : null,
          );
      if (success && mounted) {
        HapticFeedback.heavyImpact();
        widget.onSuccess?.call();
        Navigator.of(context).pop();
        _showSnackBar('Structural progress recorded successfully!',
            isError: false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  List<Map<String, dynamic>> _buildItemEntries() {
    final entries = <Map<String, dynamic>>[];
    for (final item in (_boqWithItems?.items ?? [])) {
      final ctrl = _qtyControllers[item.id];
      if (ctrl == null) continue;
      final val = double.tryParse(ctrl.text.trim()) ?? 0;
      if (val > 0) {
        entries.add({
          'assemblyMark': item.assemblyMark,
          'qtyUsed': val,
          'boqItemId': item.id,
        });
      }
    }
    return entries;
  }
}

class _StepHeader extends StatelessWidget {
  final String title, subtitle;
  const _StepHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text(subtitle,
            style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int step;
  const _StepIndicator({required this.step});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      decoration: BoxDecoration(
        color: cs.surface,
        border:
            Border(bottom: BorderSide(color: cs.outlineVariant.withOpacity(0.3))),
      ),
      child: Row(
        children: List.generate(3, (i) {
          final active = i <= step;
          final completed = i < step;
          return Expanded(
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active ? _kBrown : cs.surfaceContainerHigh,
                    border: Border.all(
                      color: active ? _kBrown : cs.outlineVariant.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: completed
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 18)
                        : Text('${i + 1}',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: active ? Colors.white : cs.onSurfaceVariant)),
                  ),
                ),
                if (i < 2)
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: completed
                            ? _kBrown
                            : cs.outlineVariant.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _BOQSelectionTile extends StatelessWidget {
  final BOQStructure boq;
  final bool isSelected;
  final VoidCallback onTap;

  const _BOQSelectionTile({
    required this.boq,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? _kBrown.withOpacity(0.04) : cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _kBrown : cs.outlineVariant.withOpacity(0.4),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: _kBrown.withOpacity(0.08), blurRadius: 15)]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? _kBrown : cs.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSelected ? Icons.check_rounded : Icons.table_chart_outlined,
                color: isSelected ? Colors.white : cs.onSurfaceVariant,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(boq.boqName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(
                    '${boq.totalItems} items • ${boq.remainingQuantity.toStringAsFixed(0)} mt remaining',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${boq.progressPercentage.toStringAsFixed(0)}%',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: _kBrown,
                        fontSize: 16)),
                const Text('DONE',
                    style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;
  const _DatePickerField({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_rounded, color: _kBrown),
            const SizedBox(width: 16),
            Text(DateFormat('EEEE, dd MMMM yyyy').format(date),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const Spacer(),
            const Icon(Icons.edit_calendar_rounded, size: 20, color: _kBrown),
          ],
        ),
      ),
    );
  }
}

class _RemarksField extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;
  const _RemarksField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Share any site notes or observations...',
        filled: true,
        fillColor: cs.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _kBrown, width: 2),
        ),
      ),
    );
  }
}

class _MaterialSearchHeader extends StatelessWidget {
  final Function(String) onSearch;
  final ColorScheme cs;
  const _MaterialSearchHeader({required this.onSearch, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        color: cs.surface,
        border:
            Border(bottom: BorderSide(color: cs.outlineVariant.withOpacity(0.3))),
      ),
      child: TextField(
        onChanged: onSearch,
        decoration: InputDecoration(
          hintText: 'Search by assembly mark...',
          prefixIcon: const Icon(Icons.search_rounded, color: _kBrown),
          filled: true,
          fillColor: cs.surfaceContainerHigh,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _ItemEntryRow extends StatelessWidget {
  final BOQStructureItem item;
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _ItemEntryRow({
    required this.item,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final val = double.tryParse(controller.text.trim()) ?? 0;
    final isOver = val > item.remainingQty;
    final hasVal = val > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: hasVal ? _kBrown.withOpacity(0.04) : cs.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isOver
              ? Colors.red.withOpacity(0.6)
              : hasVal
                  ? _kBrown.withOpacity(0.6)
                  : cs.outlineVariant.withOpacity(0.4),
          width: hasVal ? 2 : 1,
        ),
        boxShadow: hasVal
            ? [BoxShadow(color: _kBrown.withOpacity(0.06), blurRadius: 12)]
            : [],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.assemblyMark,
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: hasVal ? _kBrown : cs.onSurface)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _Badge(
                      label: 'Available: ${item.remainingQty.toStringAsFixed(0)}',
                      color: cs.onSurfaceVariant.withOpacity(0.12),
                      textColor: cs.onSurfaceVariant,
                    ),
                    if (hasVal) ...[
                      const SizedBox(width: 8),
                      _Badge(
                        label: 'Reporting: $val',
                        color: _kBrown.withOpacity(0.15),
                        textColor: _kBrown,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 90,
            child: TextField(
              controller: controller,
              onChanged: (_) => onChanged(),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: isOver ? Colors.red : (hasVal ? _kBrown : cs.onSurface),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
              ],
              decoration: InputDecoration(
                hintText: '0',
                filled: true,
                fillColor: isOver
                    ? Colors.red.withOpacity(0.1)
                    : hasVal
                        ? _kBrown.withOpacity(0.15)
                        : cs.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color, textColor;
  const _Badge({required this.label, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w800, color: textColor)),
    );
  }
}

class _RunningTotalFooter extends StatelessWidget {
  final Map<String, TextEditingController> controllers;
  final List<BOQStructureItem> items;
  const _RunningTotalFooter({required this.controllers, required this.items});

  @override
  Widget build(BuildContext context) {
    double totalQty = 0;
    for (final item in items) {
      final ctrl = controllers[item.id];
      totalQty += double.tryParse(ctrl?.text.trim() ?? '') ?? 0;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: _kBrown.withOpacity(0.08),
        border:
            Border(top: BorderSide(color: _kBrown.withOpacity(0.2), width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Session Total Reporting:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          Text(totalQty.toStringAsFixed(0),
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w900, color: _kBrown)),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final BOQStructure? selectedBOQ;
  final DateTime date;
  final String remarks;
  final int itemCount;
  final double totalWeight;
  final ColorScheme cs;

  const _SummaryCard({
    required this.selectedBOQ,
    required this.date,
    required this.remarks,
    required this.itemCount,
    required this.totalWeight,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kBrown,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: _kBrown.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10)),
        ],
        image: const DecorationImage(
          image: AssetImage('assets/images/header_bg.webp'),
          fit: BoxFit.cover,
          opacity: 0.1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('DPR Details',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(DateFormat('dd MMM').format(date).toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SummaryRow(
              label: 'Reference BOQ',
              value: selectedBOQ?.boqName ?? '—',
              icon: Icons.table_chart_outlined),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryStat(
                    label: 'Items',
                    value: itemCount.toString(),
                    icon: Icons.inventory_2_outlined),
              ),
              Expanded(
                child: _SummaryStat(
                    label: 'Net Weight',
                    value: '${(totalWeight / 1000).toStringAsFixed(2)} MT',
                    icon: Icons.scale_outlined),
              ),
            ],
          ),
          if (remarks.isNotEmpty) ...[
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(color: Colors.white24, height: 1)),
            Text('Notes',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 10,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(remarks,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _SummaryRow({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white60, size: 16),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800)),
          ],
        ),
      ],
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _SummaryStat({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900)),
          ],
        ),
      ],
    );
  }
}

class _SubmissionConfirmSheet extends StatelessWidget {
  final int itemCount;
  final ColorScheme cs;

  const _SubmissionConfirmSheet({required this.itemCount, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 40)
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: cs.outlineVariant, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _kBrown.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_upload_outlined,
                color: _kBrown, size: 48),
          ),
          const SizedBox(height: 24),
          const Text('Confirm Submission',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Text(
            'You are about to report structural progress for $itemCount items. This will update the BOQ remaining quantities.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 15, color: cs.onSurfaceVariant, height: 1.5),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Review Again',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kBrown,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Confirm & Submit',
                      style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final ColorScheme cs;
  const _SectionLabel({required this.label, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
              color: _kBrown, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.3)),
      ],
    );
  }
}

class _ReviewItemTile extends StatelessWidget {
  final String assemblyMark;
  final double qty;
  final ColorScheme cs;

  const _ReviewItemTile({
    required this.assemblyMark,
    required this.qty,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 6, color: _kBrown),
          const SizedBox(width: 12),
          Expanded(
            child: Text(assemblyMark,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          ),
          Text(qty.toStringAsFixed(0),
              style: const TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 16, color: _kBrown)),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(color: _kBrown),
      ),
    );
  }
}

class _EmptyBOQState extends StatelessWidget {
  final String siteId;
  const _EmptyBOQState({required this.siteId});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.table_rows_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No BOQs Available',
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Ensure structural BOQs are uploaded for this site.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  final String message;
  const _ErrorMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.errorContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.error.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: cs.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message,
                style: TextStyle(
                    color: cs.error, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _SelectedItemsChips extends StatelessWidget {
  final Map<String, TextEditingController> controllers;
  final List<BOQStructureItem> items;
  final Function(String) onRemove;

  const _SelectedItemsChips({
    required this.controllers,
    required this.items,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final selected = <_ChipData>[];
    for (final item in items) {
      final val = double.tryParse(controllers[item.id]?.text ?? '') ?? 0;
      if (val > 0) {
        selected.add(_ChipData(item.id, item.assemblyMark, val));
      }
    }

    if (selected.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: selected.length,
        itemBuilder: (ctx, i) {
          final data = selected[i];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Chip(
              backgroundColor: _kBrown,
              label: Text('${data.mark}: ${data.qty.toStringAsFixed(0)}'),
              labelStyle: const TextStyle(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
              deleteIcon:
                  const Icon(Icons.close_rounded, size: 14, color: Colors.white70),
              onDeleted: () => onRemove(data.id),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: BorderSide.none,
              elevation: 2,
            ),
          );
        },
      ),
    );
  }
}

class _ChipData {
  final String id, mark;
  final double qty;
  _ChipData(this.id, this.mark, this.qty);
}

