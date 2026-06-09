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

enum _PmSetupMode { chooser, view }

String _pmCategoryIdentity(PmCategory category) => category.categoryName;

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
      ref.read(pmProvider.notifier).load(widget.siteId, widget.workType);
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
      await ref
          .read(pmProvider.notifier)
          .setDate(widget.siteId, widget.workType, picked);
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
            onPressed: () => ref
                .read(pmProvider.notifier)
                .load(widget.siteId, widget.workType),
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
                    onRetry: () => ref
                        .read(pmProvider.notifier)
                        .load(widget.siteId, widget.workType),
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
          workType: widget.workType,
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

class _SetupTab extends ConsumerStatefulWidget {
  final PmState state;
  final String siteId;
  final String workType;
  final VoidCallback onSaved;
  final ValueChanged<String> onError;

  const _SetupTab({
    required this.state,
    required this.siteId,
    required this.workType,
    required this.onSaved,
    required this.onError,
  });

  @override
  ConsumerState<_SetupTab> createState() => _SetupTabState();
}

class _SetupTabState extends ConsumerState<_SetupTab> {
  _PmSetupMode _mode = _PmSetupMode.chooser;
  String? _categoryId;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    if (state.isLoading && state.categories.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: _pmColor));
    }
    if (state.categories.isEmpty) {
      return _SetupChooser(
        onView: null,
        onAdd: null,
        emptyText: 'No P&M categories found',
      );
    }

    if (_mode == _PmSetupMode.chooser) {
      return _SetupChooser(
        onView: () => setState(() => _mode = _PmSetupMode.view),
        onAdd: () => _openEquipmentSheet(null),
      );
    }

    final selectedCategory = _categoryId == null
        ? null
        : state.categories.firstWhere(
            (category) => _pmCategoryIdentity(category) == _categoryId,
            orElse: () => state.categories.first,
          );

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => setState(() {
                if (_categoryId != null) {
                  _categoryId = null;
                } else {
                  _mode = _PmSetupMode.chooser;
                }
              }),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: Text(_categoryId == null ? 'Options' : 'Categories'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _openEquipmentSheet(null),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Work'),
                style: FilledButton.styleFrom(backgroundColor: _pmColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (selectedCategory == null)
          _PmCategoryGrid(
            categories: state.categories,
            onSelected: (category) =>
                setState(() => _categoryId = _pmCategoryIdentity(category)),
          )
        else
          _PmEquipmentList(
            category: selectedCategory,
            onEdit: _openEquipmentSheet,
            onDelete: _deleteEquipment,
          ),
      ],
    );
  }

  Future<void> _openEquipmentSheet(PmEquipment? equipment) async {
    await showPmEquipmentSheet(
      context: context,
      ref: ref,
      state: widget.state,
      siteId: widget.siteId,
      workType: widget.workType,
      equipment: equipment,
      onSaved: widget.onSaved,
      onError: widget.onError,
    );
  }

  Future<void> _deleteEquipment(PmEquipment equipment) async {
    if (!equipment.isCustom) {
      widget.onError('Only custom P&M works can be deleted');
      return;
    }
    final ok = await ref
        .read(pmProvider.notifier)
        .deleteEquipment(widget.siteId, widget.workType, equipment);
    ok
        ? widget.onSaved()
        : widget.onError(ref.read(pmProvider).error ?? 'Delete failed');
  }
}

class _SetupChooser extends StatelessWidget {
  final VoidCallback? onView;
  final VoidCallback? onAdd;
  final String? emptyText;

  const _SetupChooser({
    required this.onView,
    required this.onAdd,
    this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: _SetupActionCard(
                icon: Icons.visibility_rounded,
                iconColor: Colors.blue,
                label: 'View',
                onTap: onView,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SetupActionCard(
                icon: Icons.add_circle_outline_rounded,
                iconColor: Colors.green,
                label: 'Add',
                onTap: onAdd,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.45),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? colorScheme.shadow.withOpacity(0.12)
                    : colorScheme.shadow.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            emptyText ??
                'View existing P&M works by category, or add a new work with an optional image.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _SetupActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback? onTap;

  const _SetupActionCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEnabled = onTap != null;
    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 132,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Opacity(
            opacity: isEnabled ? 1 : 0.45,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: iconColor.withOpacity(0.25)),
                  ),
                  child: Icon(icon, color: iconColor, size: 30),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkSelectionPage extends StatefulWidget {
  final List<PmCategory> categories;
  final ValueChanged<PmEquipment> onSelect;

  const _WorkSelectionPage({
    required this.categories,
    required this.onSelect,
  });

  @override
  State<_WorkSelectionPage> createState() => _WorkSelectionPageState();
}

class _WorkSelectionPageState extends State<_WorkSelectionPage> {
  String? _categoryId;

  @override
  Widget build(BuildContext context) {
    final selectedCategory = _categoryId == null
        ? null
        : widget.categories.firstWhere(
            (category) => _pmCategoryIdentity(category) == _categoryId,
            orElse: () => widget.categories.first,
          );

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        if (selectedCategory == null) ...[
          const Text(
            'Select P&M Category',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          _PmCategoryGrid(
            categories: widget.categories,
            onSelected: (category) =>
                setState(() => _categoryId = _pmCategoryIdentity(category)),
          ),
        ] else ...[
          OutlinedButton.icon(
            onPressed: () => setState(() => _categoryId = null),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Categories'),
          ),
          const SizedBox(height: 12),
          _PmEquipmentList(
            category: selectedCategory,
            onTap: widget.onSelect,
          ),
        ],
      ],
    );
  }
}

class _PmCategoryGrid extends StatelessWidget {
  final List<PmCategory> categories;
  final ValueChanged<PmCategory> onSelected;

  const _PmCategoryGrid({
    required this.categories,
    required this.onSelected,
  });

  IconData _iconFor(String value) {
    final key = value.toLowerCase();
    if (key.contains('earth')) return Icons.landscape_rounded;
    if (key.contains('concrete')) return Icons.foundation_rounded;
    if (key.contains('transport')) return Icons.local_shipping_rounded;
    if (key.contains('crane') || key.contains('lifting')) {
      return Icons.precision_manufacturing_rounded;
    }
    if (key.contains('dg') || key.contains('generator')) {
      return Icons.electrical_services_rounded;
    }
    return Icons.construction_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.08,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];
        return InkWell(
          onTap: () => onSelected(category),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_iconFor(category.categoryName),
                    color: _pmColor, size: 30),
                const Spacer(),
                Text(
                  category.categoryName,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${category.equipment.length} equipment',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PmEquipmentList extends StatelessWidget {
  final PmCategory category;
  final ValueChanged<PmEquipment>? onTap;
  final ValueChanged<PmEquipment>? onEdit;
  final ValueChanged<PmEquipment>? onDelete;

  const _PmEquipmentList({
    required this.category,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (category.equipment.isEmpty) {
      return const _EmptyPanel(title: 'No works found in this category');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category.categoryName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        ...category.equipment.map(
          (equipment) => _EquipmentCard(
            equipment: equipment,
            onTap: onTap == null ? null : () => onTap!(equipment),
            onEdit: onEdit == null ? null : () => onEdit!(equipment),
            onDelete: onDelete == null ? null : () => onDelete!(equipment),
          ),
        ),
      ],
    );
  }
}

class _SelectedWorkHeader extends StatelessWidget {
  final PmEquipment equipment;
  final VoidCallback onChange;
  final VoidCallback onEdit;

  const _SelectedWorkHeader({
    required this.equipment,
    required this.onChange,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _pmColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _pmColor.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          _ImagePreview(imageUrl: equipment.image, height: 62, width: 72),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  equipment.equipmentName,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  equipment.categoryName,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit Work',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded, color: _pmColor),
          ),
          TextButton(
            onPressed: onChange,
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
}

Future<void> showPmEquipmentSheet({
  required BuildContext context,
  required WidgetRef ref,
  required PmState state,
  required String siteId,
  required String workType,
  required VoidCallback onSaved,
  required ValueChanged<String> onError,
  PmEquipment? equipment,
}) async {
  final defaultCategory =
      state.categories.isNotEmpty ? state.categories.first : null;
  final name = TextEditingController(text: equipment?.equipmentName ?? '');
  final capacity = TextEditingController(text: equipment?.capacity ?? '');
  final unit = TextEditingController(text: equipment?.unit ?? 'Nos');
  var image = equipment?.image ?? '';
  var categoryKey =
      equipment?.categoryKey ?? defaultCategory?.categoryKey ?? '';
  var categoryName =
      equipment?.categoryName ?? defaultCategory?.categoryName ?? '';
  var categoryId = equipment == null && defaultCategory != null
      ? _pmCategoryIdentity(defaultCategory)
      : '';

  final saved = await showModalBottomSheet<bool>(
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
            if (!sheetContext.mounted) return;
            if (url.isNotEmpty) setModalState(() => image = url);
          }

          Future<void> save() async {
            if (categoryKey.trim().isEmpty || categoryName.trim().isEmpty) {
              onError('Category is required');
              return;
            }
            if (name.text.trim().isEmpty) {
              onError('Work name is required');
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
                  workType: workType,
                  reloadAfterSave: false,
                );
            if (!sheetContext.mounted) return;
            Navigator.of(sheetContext).pop(ok);
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
                    equipment == null ? 'Add P&M Work' : 'Edit P&M Work',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (equipment == null)
                    DropdownButtonFormField<String>(
                      value: categoryId.isEmpty ? null : categoryId,
                      items: state.categories
                          .map((cat) => DropdownMenuItem(
                                value: _pmCategoryIdentity(cat),
                                child: Text(cat.categoryName),
                              ))
                          .toList(),
                      onChanged: (value) {
                        final selected = state.categories.firstWhere(
                          (cat) => _pmCategoryIdentity(cat) == value,
                          orElse: () => state.categories.first,
                        );
                        setModalState(() {
                          categoryId = _pmCategoryIdentity(selected);
                          categoryKey = selected.categoryKey;
                          categoryName = selected.categoryName;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                  const SizedBox(height: 10),
                  _TextField(controller: name, label: 'Work Name'),
                  _TextField(controller: capacity, label: 'Capacity'),
                  _TextField(controller: unit, label: 'Unit'),
                  const SizedBox(height: 10),
                  _ImagePreview(imageUrl: image, height: 150),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: pickImage,
                    icon: const Icon(Icons.image_rounded),
                    label: const Text('Upload / Replace Image'),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: state.isSaving ? null : save,
                      style: FilledButton.styleFrom(backgroundColor: _pmColor),
                      child: const Text('Save Work'),
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

  if (saved == true) {
    await ref.read(pmProvider.notifier).load(siteId, workType);
    onSaved();
  } else if (saved == false) {
    onError(ref.read(pmProvider).error ?? 'Save failed');
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

    final selectedEquipment = _findCurrentEquipment(categories);
    if (selectedEquipment == null) {
      return _WorkSelectionPage(
        categories: categories,
        onSelect: _selectEquipment,
      );
    }
    _equipment = selectedEquipment;

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _DateCard(
          title: 'P&M Daily Entry',
          date: widget.state.selectedDate,
          onTap: widget.onDateTap,
        ),
        const SizedBox(height: 12),
        _SelectedWorkHeader(
          equipment: selectedEquipment,
          onChange: () => setState(() => _equipment = null),
          onEdit: () => _editSelectedWork(selectedEquipment),
        ),
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

  PmEquipment? _findCurrentEquipment(List<PmCategory> categories) {
    final selected = _equipment;
    if (selected == null) return null;
    for (final equipment in _flattenEquipment(categories)) {
      if (equipment.id == selected.id && equipment.source == selected.source) {
        return equipment;
      }
    }
    return null;
  }

  void _selectEquipment(PmEquipment equipment) {
    setState(() {
      _equipment = equipment;
      _capacity.text = equipment.capacity;
      _unit.text = equipment.unit;
    });
  }

  Future<void> _editSelectedWork(PmEquipment equipment) async {
    await showPmEquipmentSheet(
      context: context,
      ref: ref,
      state: widget.state,
      siteId: widget.siteId,
      workType: widget.workType,
      equipment: equipment,
      onSaved: widget.onSaved,
      onError: widget.onError,
    );
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

class _EquipmentCard extends StatelessWidget {
  final PmEquipment equipment;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const _EquipmentCard({
    required this.equipment,
    this.onEdit,
    this.onDelete,
    this.onTap,
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
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
                      equipment.categoryName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [equipment.capacity, equipment.unit]
                          .where((text) => text.trim().isNotEmpty)
                          .join(' • '),
                      style:
                          TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (onEdit != null)
                IconButton(
                  tooltip: 'Edit',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 20),
                ),
              if (equipment.isCustom && onDelete != null)
                IconButton(
                  tooltip: 'Delete',
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_rounded, size: 20, color: cs.error),
                ),
              if (onTap != null)
                const Icon(Icons.chevron_right_rounded, color: _pmColor),
            ],
          ),
        ),
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

class _EmptyPanel extends StatelessWidget {
  final String title;

  const _EmptyPanel({required this.title});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w700,
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

List<PmEquipment> _flattenEquipment(List<PmCategory> categories) {
  return [
    for (final category in categories) ...category.equipment,
  ];
}
