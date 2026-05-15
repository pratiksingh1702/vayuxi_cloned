import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/utlis/widgets/premium_app_bar.dart';
import '../models/structure_pm_entry_model.dart';
import '../providers/structure_pm_provider.dart';
import '../widgets/structure_pm_overview_card.dart';
import '../widgets/structure_pm_unit_selector.dart';
import '../widgets/structure_pm_category_section.dart';

const _kBrown = Color(0xFF7B3F00);

class StructurePmEntryScreen extends ConsumerStatefulWidget {
  final String siteId;
  final String siteName;

  const StructurePmEntryScreen({
    super.key,
    required this.siteId,
    required this.siteName,
  });

  @override
  ConsumerState<StructurePmEntryScreen> createState() =>
      _StructurePmEntryScreenState();
}

class _StructurePmEntryScreenState
    extends ConsumerState<StructurePmEntryScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(structurePmProvider);
      ref
          .read(structurePmProvider.notifier)
          .load(widget.siteId, state.selectedDate);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final state = ref.read(structurePmProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: state.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      ref.read(structurePmProvider.notifier).setDate(picked);
      ref.read(structurePmProvider.notifier).load(widget.siteId, picked);
    }
  }

  Future<void> _save() async {
    final success =
        await ref.read(structurePmProvider.notifier).save(widget.siteId);
    if (!mounted) return;
    if (success) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('P&M entries saved successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      final error = ref.read(structurePmProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to save P&M entries'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(structurePmProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter rows by unit and search
    List<StructurePmResourceRow> displayRows = state.rows;
    if (state.selectedUnitCode != null) {
      displayRows = displayRows
          .where((r) => r.unitCode == state.selectedUnitCode)
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      displayRows = displayRows
          .where((r) =>
              r.resourceName.toLowerCase().contains(_searchQuery) ||
              r.categoryName.toLowerCase().contains(_searchQuery))
          .toList();
    }

    // Group by category
    final Map<String, List<StructurePmResourceRow>> grouped = {};
    for (final row in displayRows) {
      final key =
          row.categoryName.isNotEmpty ? row.categoryName : 'Uncategorized';
      grouped.putIfAbsent(key, () => []).add(row);
    }
    final categories = grouped.keys.toList()..sort();

    return Scaffold(
      backgroundColor: isDark ? cs.surface : cs.surfaceContainerLowest,
      appBar: PremiumAppBar(
        title: 'P&M Entry',
        subtitle: Text(widget.siteName),
        onDrawerPressed: () => context.pop(),
        drawerIcon: Icons.arrow_back_ios_new_rounded,
        actions: [
          PremiumActionIcon(
            icon: Icons.refresh_rounded,
            onPressed: () => ref
                .read(structurePmProvider.notifier)
                .load(widget.siteId, state.selectedDate),
            tooltip: "Refresh",
          ),
        ],
      ),
      body: Column(
        children: [
          // Loading indicator
          if (state.isLoading || state.isSaving)
            LinearProgressIndicator(
              color: _kBrown,
              backgroundColor: _kBrown.withOpacity(0.15),
            ),

          Expanded(
            child: state.isLoading && state.rows.isEmpty
                ? const Center(child: CircularProgressIndicator(color: _kBrown))
                : state.error != null && state.rows.isEmpty
                    ? _buildErrorState(state.error!, cs)
                    : state.rows.isEmpty
                        ? _buildEmptyState(cs)
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header
                                _buildHeader(cs),
                                const SizedBox(height: 14),

                                // Date Section
                                _buildDateSection(state, cs),
                                const SizedBox(height: 14),

                                // Overview Card
                                StructurePmOverviewCard(
                                    summary: state.summary),
                                const SizedBox(height: 14),

                                // Unit Selector
                                StructurePmUnitSelector(
                                  units: state.summary.unitSummary,
                                  selectedUnitCode: state.selectedUnitCode,
                                  onUnitSelected: (code) => ref
                                      .read(structurePmProvider.notifier)
                                      .setSelectedUnit(code),
                                ),
                                const SizedBox(height: 14),

                                // Search Box
                                _buildSearchBox(cs),
                                const SizedBox(height: 10),

                                // Category Sections
                                if (displayRows.isEmpty)
                                  _buildNoMatchState(cs)
                                else
                                  ...categories.map((cat) =>
                                      StructurePmCategorySection(
                                        categoryName: cat,
                                        rows: grouped[cat]!,
                                        onActualQtyChanged: (entry) => ref
                                            .read(
                                                structurePmProvider.notifier)
                                            .updateActualQty(
                                                entry.key, entry.value),
                                        onRemarksChanged: (entry) => ref
                                            .read(
                                                structurePmProvider.notifier)
                                            .updateRemarks(
                                                entry.key, entry.value),
                                      )),

                                const SizedBox(height: 100),
                              ],
                            ),
                          ),
          ),
        ],
      ),
      bottomNavigationBar: state.rows.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: state.isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kBrown,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    child: state.isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Save P&M Entry',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Row(
      children: [
        Icon(Icons.precision_manufacturing_rounded,
            size: 20, color: _kBrown),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Structure P&M Database',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              Text(
                widget.siteName,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateSection(StructurePmState state, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kBrown.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBrown.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_month_rounded, size: 18, color: _kBrown),
          const SizedBox(width: 10),
          Text(
            'P&M Daily Entry',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: _kBrown,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit_calendar_rounded,
                      size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('dd MMM yyyy').format(state.selectedDate),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox(ColorScheme cs) {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: _searchController,
        style: TextStyle(fontSize: 13, color: cs.onSurface),
        decoration: InputDecoration(
          hintText: 'Search resources...',
          hintStyle: TextStyle(
            fontSize: 12,
            color: cs.onSurfaceVariant.withOpacity(0.6),
          ),
          prefixIcon:
              Icon(Icons.search_rounded, size: 20, color: cs.onSurfaceVariant),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      size: 18, color: cs.onSurfaceVariant),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: cs.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _kBrown, width: 1.5),
          ),
          filled: true,
          fillColor: cs.surface,
          isDense: true,
        ),
        onChanged: (val) {
          setState(() => _searchQuery = val.trim().toLowerCase());
        },
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: _kBrown.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.precision_manufacturing_rounded,
                  size: 44, color: _kBrown),
            ),
            const SizedBox(height: 20),
            const Text(
              'No P&M Resources',
              style:
                  TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'No P&M resources found for this site.\nPlease check if the resource master is configured.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoMatchState(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 48, color: cs.onSurfaceVariant.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text(
              'No matches found',
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 52, color: cs.error),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: cs.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => ref
                  .read(structurePmProvider.notifier)
                  .load(widget.siteId,
                      ref.read(structurePmProvider).selectedDate),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBrown,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
