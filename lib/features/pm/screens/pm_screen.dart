import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:untitled2/core/utlis/widgets/premium_app_bar.dart';

import '../models/pm_models.dart';
import '../providers/pm_provider.dart';

const _pmColor = Color(0xFF7B3F00);

enum PmSection {
  setup,
  entry,
  reports;

  String get title {
    switch (this) {
      case PmSection.setup:
        return 'P&M Setup';
      case PmSection.entry:
        return 'P&M Entry';
      case PmSection.reports:
        return 'P&M Reports';
    }
  }
}

class PmScreen extends ConsumerStatefulWidget {
  final String siteId;
  final String siteName;
  final String workType;
  final PmSection section;

  const PmScreen({
    super.key,
    required this.siteId,
    required this.siteName,
    required this.workType,
    required this.section,
  });

  @override
  ConsumerState<PmScreen> createState() => _PmScreenState();
}

class _PmScreenState extends ConsumerState<PmScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pmProvider.notifier).load(widget.siteId);
    });
  }

  Future<void> _pickDate() async {
    final state = ref.read(pmProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: state.selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      await ref.read(pmProvider.notifier).setDate(widget.siteId, picked);
    }
  }

  void _snack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pmProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? cs.surface : cs.surfaceContainerLowest,
      appBar: PremiumAppBar(
        title: widget.section.title,
        subtitle: Text(widget.siteName),
        drawerIcon: Icons.arrow_back_ios_new_rounded,
        onDrawerPressed: () => context.pop(),
        actions: [
          PremiumActionIcon(
            icon: Icons.refresh_rounded,
            onPressed: () => ref.read(pmProvider.notifier).load(widget.siteId),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          if (state.isLoading || state.isSaving)
            LinearProgressIndicator(
              color: _pmColor,
              backgroundColor: _pmColor.withOpacity(0.15),
            ),
          Expanded(
            child: state.error != null && state.categories.isEmpty
                ? _ErrorState(
                    message: state.error!,
                    onRetry: () =>
                        ref.read(pmProvider.notifier).load(widget.siteId),
                  )
                : _buildSection(state),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(PmState state) {
    switch (widget.section) {
      case PmSection.setup:
        return _SetupTab(
          state: state,
          siteId: widget.siteId,
          onSaved: () => _snack('P&M setup saved successfully'),
          onError: (msg) => _snack(msg, isError: true),
        );
      case PmSection.entry:
        return _EntryTab(
          state: state,
          siteId: widget.siteId,
          workType: widget.workType,
          onDateTap: _pickDate,
          onSaved: () {
            HapticFeedback.heavyImpact();
            _snack('P&M entry saved successfully');
          },
          onError: (msg) => _snack(msg, isError: true),
        );
      case PmSection.reports:
        return _ReportsTab(
          state: state,
          onDateTap: _pickDate,
        );
    }
  }
}

class _SetupTab extends ConsumerWidget {
  final PmState state;
  final String siteId;
  final VoidCallback onSaved;
  final ValueChanged<String> onError;

  const _SetupTab({
    required this.state,
    required this.siteId,
    required this.onSaved,
    required this.onError,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading && state.categories.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: _pmColor));
    }
    if (state.categories.isEmpty) {
      return const _EmptyState(title: 'No P&M equipment found');
    }

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'P&M Setup',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            FilledButton.icon(
              onPressed: () => _openEquipmentSheet(context, ref, null),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add'),
              style: FilledButton.styleFrom(backgroundColor: _pmColor),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...state.categories.map(
          (category) => _CategorySection(
            category: category,
            onEdit: (equipment) => _openEquipmentSheet(context, ref, equipment),
            onDelete: (equipment) async {
              if (!equipment.isCustom) {
                onError('Only custom P&M equipment can be deleted');
                return;
              }
              final ok = await ref
                  .read(pmProvider.notifier)
                  .deleteEquipment(siteId, equipment);
              ok
                  ? onSaved()
                  : onError(ref.read(pmProvider).error ?? 'Delete failed');
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openEquipmentSheet(
    BuildContext context,
    WidgetRef ref,
    PmEquipment? equipment,
  ) async {
    final category = equipment == null && state.categories.isNotEmpty
        ? state.categories.first
        : null;
    final name = TextEditingController(text: equipment?.equipmentName ?? '');
    final capacity = TextEditingController(text: equipment?.capacity ?? '');
    final unit = TextEditingController(text: equipment?.unit ?? 'Nos');
    var image = equipment?.image ?? '';
    var categoryKey = equipment?.categoryKey ?? category?.categoryKey ?? '';
    var categoryName = equipment?.categoryName ?? category?.categoryName ?? '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickImage() async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.image,
                allowMultiple: false,
              );
              final file = result?.files.single;
              if (file == null) return;
              final url =
                  await ref.read(pmProvider.notifier).uploadImage(siteId, file);
              if (url.isNotEmpty) setModalState(() => image = url);
            }

            Future<void> save() async {
              if (name.text.trim().isEmpty) {
                onError('Equipment name is required');
                return;
              }
              final ok = await ref.read(pmProvider.notifier).saveEquipment(
                    siteId,
                    equipment: equipment,
                    categoryKey: categoryKey,
                    categoryName: categoryName,
                    equipmentName: name.text.trim(),
                    capacity: capacity.text.trim(),
                    unit: unit.text.trim().isEmpty ? 'Nos' : unit.text.trim(),
                    image: image,
                  );
              if (!context.mounted) return;
              Navigator.of(context).pop();
              ok
                  ? onSaved()
                  : onError(ref.read(pmProvider).error ?? 'Save failed');
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 18,
                bottom: MediaQuery.of(context).viewInsets.bottom + 18,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      equipment == null
                          ? 'Add P&M Equipment'
                          : 'Edit P&M Equipment',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 14),
                    if (equipment == null)
                      DropdownButtonFormField<String>(
                        value: categoryKey.isEmpty ? null : categoryKey,
                        items: state.categories
                            .map((cat) => DropdownMenuItem(
                                  value: cat.categoryKey,
                                  child: Text(cat.categoryName),
                                ))
                            .toList(),
                        onChanged: (value) {
                          final selected = state.categories.firstWhere(
                            (cat) => cat.categoryKey == value,
                            orElse: () => state.categories.first,
                          );
                          setModalState(() {
                            categoryKey = selected.categoryKey;
                            categoryName = selected.categoryName;
                          });
                        },
                        decoration:
                            const InputDecoration(labelText: 'Category'),
                      ),
                    const SizedBox(height: 10),
                    _TextField(controller: name, label: 'Equipment Name'),
                    _TextField(controller: capacity, label: 'Capacity'),
                    _TextField(controller: unit, label: 'Unit'),
                    const SizedBox(height: 10),
                    _ImagePreview(imageUrl: image, height: 130),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: pickImage,
                      icon: const Icon(Icons.image_rounded),
                      label: const Text('Upload Image'),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: state.isSaving ? null : save,
                        style:
                            FilledButton.styleFrom(backgroundColor: _pmColor),
                        child: const Text('Save Equipment'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    name.dispose();
    capacity.dispose();
    unit.dispose();
  }
}

class _EntryTab extends ConsumerStatefulWidget {
  final PmState state;
  final String siteId;
  final String workType;
  final VoidCallback onDateTap;
  final VoidCallback onSaved;
  final ValueChanged<String> onError;

  const _EntryTab({
    required this.state,
    required this.siteId,
    required this.workType,
    required this.onDateTap,
    required this.onSaved,
    required this.onError,
  });

  @override
  ConsumerState<_EntryTab> createState() => _EntryTabState();
}

class _EntryTabState extends ConsumerState<_EntryTab> {
  String? _categoryKey;
  PmEquipment? _equipment;
  final _equipmentNo = TextEditingController();
  final _capacity = TextEditingController();
  final _vendor = TextEditingController();
  final _start = TextEditingController();
  final _end = TextEditingController();
  final _working = TextEditingController();
  final _breakdown = TextEditingController();
  final _idle = TextEditingController();
  final _operator = TextEditingController();
  final _driver = TextEditingController();
  final _fuel = TextEditingController();
  final _quantity = TextEditingController();
  final _unit = TextEditingController();
  final _location = TextEditingController();
  final _activity = TextEditingController();
  final _description = TextEditingController();
  String _ownerType = '';
  String _fuelType = '';
  String _status = 'working';
  bool _maintenanceRequired = false;

  @override
  void dispose() {
    for (final controller in [
      _equipmentNo,
      _capacity,
      _vendor,
      _start,
      _end,
      _working,
      _breakdown,
      _idle,
      _operator,
      _driver,
      _fuel,
      _quantity,
      _unit,
      _location,
      _activity,
      _description,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.state.categories;
    if (widget.state.isLoading && categories.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: _pmColor));
    }
    if (categories.isEmpty) {
      return const _EmptyState(title: 'Configure P&M setup first');
    }

    _categoryKey ??= categories.first.categoryKey;
    final selectedCategory = categories.firstWhere(
      (cat) => cat.categoryKey == _categoryKey,
      orElse: () => categories.first,
    );
    _equipment ??= selectedCategory.equipment.isNotEmpty
        ? selectedCategory.equipment.first
        : null;

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _DateCard(
          title: 'P&M Daily Entry',
          date: widget.state.selectedDate,
          onTap: widget.onDateTap,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: selectedCategory.categoryKey,
          items: categories
              .map((cat) => DropdownMenuItem(
                    value: cat.categoryKey,
                    child: Text(cat.categoryName),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _categoryKey = value;
              final next = categories.firstWhere(
                (cat) => cat.categoryKey == value,
                orElse: () => categories.first,
              );
              _equipment =
                  next.equipment.isNotEmpty ? next.equipment.first : null;
            });
          },
          decoration: const InputDecoration(labelText: 'Category'),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<PmEquipment>(
          value: selectedCategory.equipment.contains(_equipment)
              ? _equipment
              : null,
          items: selectedCategory.equipment
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item.equipmentName),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _equipment = value;
              _capacity.text = value?.capacity ?? '';
              _unit.text = value?.unit ?? '';
            });
          },
          decoration: const InputDecoration(labelText: 'Equipment'),
        ),
        const SizedBox(height: 12),
        if (_equipment != null) _EquipmentMiniCard(equipment: _equipment!),
        const SizedBox(height: 12),
        _TextField(controller: _equipmentNo, label: 'Equipment Number'),
        _TextField(controller: _capacity, label: 'Equipment Capacity'),
        _MenuField(
          label: 'Owner Type',
          value: _ownerType,
          values: const ['', 'company', 'rental'],
          onChanged: (value) => setState(() => _ownerType = value),
        ),
        _TextField(controller: _vendor, label: 'Vendor Name'),
        Row(
          children: [
            Expanded(
                child: _TextField(controller: _start, label: 'Start Time')),
            const SizedBox(width: 10),
            Expanded(child: _TextField(controller: _end, label: 'End Time')),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: _TextField(
                controller: _working,
                label: 'Working Hours',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TextField(
                controller: _breakdown,
                label: 'Breakdown Hours',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        _TextField(
            controller: _idle,
            label: 'Idle Hours',
            keyboardType: TextInputType.number),
        _TextField(controller: _operator, label: 'Operator Name'),
        _TextField(controller: _driver, label: 'Driver Name'),
        _MenuField(
          label: 'Fuel Type',
          value: _fuelType,
          values: const ['', 'diesel', 'petrol', 'electric', 'other'],
          onChanged: (value) => setState(() => _fuelType = value),
        ),
        _TextField(
            controller: _fuel,
            label: 'Fuel Consumed',
            keyboardType: TextInputType.number),
        Row(
          children: [
            Expanded(
              child: _TextField(
                controller: _quantity,
                label: 'Quantity Executed',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: _TextField(controller: _unit, label: 'Unit')),
          ],
        ),
        _TextField(controller: _location, label: 'Location'),
        _TextField(controller: _activity, label: 'Activity Performed'),
        _TextField(
            controller: _description, label: 'Work Description', maxLines: 3),
        _MenuField(
          label: 'Status',
          value: _status,
          values: const ['working', 'idle', 'breakdown', 'maintenance'],
          onChanged: (value) => setState(() => _status = value),
        ),
        SwitchListTile(
          value: _maintenanceRequired,
          onChanged: (value) => setState(() => _maintenanceRequired = value),
          title: const Text('Maintenance Required'),
          activeColor: _pmColor,
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: widget.state.isSaving ? null : _save,
            icon: const Icon(Icons.save_rounded),
            label: const Text('Save P&M Entry'),
            style: FilledButton.styleFrom(backgroundColor: _pmColor),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final equipment = _equipment;
    if (equipment == null) {
      widget.onError('Please select equipment');
      return;
    }
    final ok = await ref.read(pmProvider.notifier).createEntry(
      widget.siteId,
      equipment: equipment,
      workType: widget.workType,
      data: {
        'equipmentNumber': _equipmentNo.text.trim(),
        'equipmentCapacity': _capacity.text.trim(),
        'vendorName': _vendor.text.trim(),
        'ownerType': _ownerType,
        'startTime': _start.text.trim(),
        'endTime': _end.text.trim(),
        'totalWorkingHours': _num(_working.text),
        'breakdownHours': _num(_breakdown.text),
        'idleHours': _num(_idle.text),
        'operatorName': _operator.text.trim(),
        'driverName': _driver.text.trim(),
        'fuelType': _fuelType,
        'fuelConsumed': _num(_fuel.text),
        'quantityExecuted': _num(_quantity.text),
        'unit': _unit.text.trim(),
        'location': _location.text.trim(),
        'activityPerformed': _activity.text.trim(),
        'workDescription': _description.text.trim(),
        'status': _status,
        'maintenanceRequired': _maintenanceRequired,
      },
    );
    ok
        ? widget.onSaved()
        : widget.onError(ref.read(pmProvider).error ?? 'Save failed');
  }

  double _num(String value) => double.tryParse(value.trim()) ?? 0;
}

class _ReportsTab extends StatelessWidget {
  final PmState state;
  final VoidCallback onDateTap;

  const _ReportsTab({required this.state, required this.onDateTap});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _DateCard(
            title: 'P&M Report Date',
            date: state.selectedDate,
            onTap: onDateTap),
        const SizedBox(height: 12),
        GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: 2,
          childAspectRatio: 1.55,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            _SummaryTile(
                label: 'Equipment', value: '${state.summary.totalEquipment}'),
            _SummaryTile(
                label: 'Entries', value: '${state.summary.totalEntries}'),
            _SummaryTile(
                label: 'Working Hrs',
                value: _fmt(state.summary.totalWorkingHours)),
            _SummaryTile(
                label: 'Fuel', value: _fmt(state.summary.totalFuelConsumption)),
          ],
        ),
        const SizedBox(height: 14),
        if (state.entries.isEmpty)
          const _EmptyState(title: 'No entries for selected date')
        else
          ...state.entries.map((entry) => _EntryCard(entry: entry)),
      ],
    );
  }
}

class _CategorySection extends StatelessWidget {
  final PmCategory category;
  final ValueChanged<PmEquipment> onEdit;
  final ValueChanged<PmEquipment> onDelete;

  const _CategorySection({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 8),
          child: Text(
            category.categoryName,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ),
        ...category.equipment.map(
          (equipment) => _EquipmentCard(
            equipment: equipment,
            onEdit: () => onEdit(equipment),
            onDelete: () => onDelete(equipment),
          ),
        ),
      ],
    );
  }
}

class _EquipmentCard extends StatelessWidget {
  final PmEquipment equipment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EquipmentCard({
    required this.equipment,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            _ImagePreview(imageUrl: equipment.image, height: 68, width: 76),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    equipment.equipmentName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [equipment.capacity, equipment.unit]
                        .where((text) => text.trim().isNotEmpty)
                        .join(' • '),
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Edit',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded, size: 20),
            ),
            if (equipment.isCustom)
              IconButton(
                tooltip: 'Delete',
                onPressed: onDelete,
                icon: Icon(Icons.delete_rounded, size: 20, color: cs.error),
              ),
          ],
        ),
      ),
    );
  }
}

class _EquipmentMiniCard extends StatelessWidget {
  final PmEquipment equipment;

  const _EquipmentMiniCard({required this.equipment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _pmColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _pmColor.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          _ImagePreview(imageUrl: equipment.image, height: 58, width: 68),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              equipment.equipmentName,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final PmEntry entry;

  const _EntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ImagePreview(
                imageUrl: entry.equipmentImage, height: 64, width: 72),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.equipmentName,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(entry.categoryName,
                      style:
                          TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _ChipText('${_fmt(entry.totalWorkingHours)} hrs'),
                      _ChipText(
                          '${_fmt(entry.quantityExecuted)} ${entry.unit}'),
                      _ChipText(entry.status),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final String imageUrl;
  final double height;
  final double? width;

  const _ImagePreview({
    required this.imageUrl,
    required this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: width ?? double.infinity,
        height: height,
        color: _pmColor.withOpacity(0.08),
        child: imageUrl.trim().isEmpty
            ? const Icon(Icons.precision_manufacturing_rounded, color: _pmColor)
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const Icon(
                    Icons.precision_manufacturing_rounded,
                    color: _pmColor),
                placeholder: (_, __) => const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
      ),
    );
  }
}

class _DateCard extends StatelessWidget {
  final String title;
  final DateTime date;
  final VoidCallback onTap;

  const _DateCard({
    required this.title,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _pmColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _pmColor.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_rounded, color: _pmColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          TextButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.edit_calendar_rounded, size: 16),
            label: Text(DateFormat('dd MMM yyyy').format(date)),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _ChipText extends StatelessWidget {
  final String text;

  const _ChipText(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: _pmColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class _MenuField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  const _MenuField({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        value: values.contains(value) ? value : values.first,
        items: values
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(item.isEmpty ? 'Select' : item),
                ))
            .toList(),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final int maxLines;

  const _TextField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;

  const _EmptyState({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: _pmColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.precision_manufacturing_rounded,
                  size: 40, color: _pmColor),
            ),
            const SizedBox(height: 14),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

String _fmt(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(2);
}
