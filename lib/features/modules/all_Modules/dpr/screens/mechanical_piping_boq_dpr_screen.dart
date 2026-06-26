import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:untitled2/core/api/dio.dart';
import 'package:untitled2/core/utlis/app_toasts.dart';
import 'package:untitled2/core/utlis/common_functions.dart';
import 'package:untitled2/core/utlis/widgets/buttons.dart';
import 'package:untitled2/core/utlis/widgets/custom.dart';
import 'package:untitled2/core/utlis/widgets/image_clipped.dart';
import 'package:untitled2/core/utlis/widgets/sidebar.dart';
import 'package:untitled2/features/modules/all_Modules/boq/models/boq_model.dart';
import 'package:untitled2/features/modules/all_Modules/boq/service/boq_service.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/models/data/piping_material_data.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/models/pipingModel.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/models/rate_file_models.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/providers/dprService.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/calculation/expand_wrapper.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/materila_card_wrapper.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/test_dynamic.dart';

class MechanicalPipingBoqDprScreen extends StatefulWidget {
  const MechanicalPipingBoqDprScreen({
    super.key,
    required this.siteId,
    this.teamId,
    this.teamName,
  });

  final String siteId;
  final String? teamId;
  final String? teamName;

  @override
  State<MechanicalPipingBoqDprScreen> createState() =>
      _MechanicalPipingBoqDprScreenState();
}

class _MechanicalPipingBoqDprScreenState
    extends State<MechanicalPipingBoqDprScreen> {
  final _boqApi = BoqApiService(DioClient.dio);
  final _searchController = TextEditingController();
  final Map<String, TextEditingController> _qtyControllers = {};
  final Map<String, TextEditingController> _remarkControllers = {};
  final Map<String, PipingItem> _defaultMaterials = {
    for (final material in PipingMaterialsData.materials) material.id: material,
  };

  List<BoqDetail> _boqs = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _query = '';
  DateTime _entryDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
    _loadBoqs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (final controller in _qtyControllers.values) {
      controller.dispose();
    }
    for (final controller in _remarkControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadBoqs() async {
    setState(() => _isLoading = true);
    try {
      final boqs = await _boqApi.getMechanicalPipingBoqs(siteId: widget.siteId);
      if (!mounted) return;
      setState(() => _boqs = boqs);
    } catch (e) {
      if (!mounted) return;
      AppToast.error('Unable to load piping BOQ: ${extractBackendError(e)}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<_PipingBoqRow> get _allRows {
    final rows = <_PipingBoqRow>[];
    for (final boq in _boqs) {
      for (final group in boq.mechanicalGroups) {
        for (final item in group.items) {
          rows.add(_PipingBoqRow(boq: boq, group: group, item: item));
        }
      }
    }
    return rows;
  }

  List<_PipingBoqRow> get _visibleRows {
    if (_query.isEmpty) return const [];
    return _allRows.where((row) {
      final haystack = [
        row.group.workDescription,
        row.group.drawingNo,
        row.item.displayDescription,
        row.item.itemType ?? '',
        row.item.itemSize ?? '',
        row.item.sourceHeader ?? '',
        row.item.moc ?? '',
        row.item.size.toString(),
        row.item.sch ?? '',
        row.item.spec ?? '',
      ].join(' ').toLowerCase();
      return haystack.contains(_query);
    }).toList();
  }

  TextEditingController _qtyController(String itemId) {
    return _qtyControllers.putIfAbsent(itemId, () => TextEditingController());
  }

  TextEditingController _remarkController(String itemId) {
    return _remarkControllers.putIfAbsent(
        itemId, () => TextEditingController());
  }

  double _valueFor(String itemId) {
    return double.tryParse(_qtyController(itemId).text.trim()) ?? 0;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _entryDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _entryDate = picked);
  }

  Future<void> _submit() async {
    final selectedRows =
        _allRows.where((row) => _valueFor(row.item.id) > 0).toList();
    if (selectedRows.isEmpty) {
      AppToast.error('Enter progress for at least one BOQ item.');
      return;
    }

    for (final row in selectedRows) {
      final actual = _valueFor(row.item.id);
      final remaining = row.item.remainingQuantity > 0
          ? row.item.remainingQuantity
          : row.item.totalQuantityCalculated;
      if (actual > remaining) {
        AppToast.error(
          '${row.item.displayDescription} exceeds remaining ${_fmt(remaining)} ${row.item.displayUom}.',
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);
    try {
      final payload = {
        'dprName': 'Mechanical Piping DPR',
        if ((widget.teamId ?? '').trim().isNotEmpty) 'teamId': widget.teamId,
        'date': _entryDate.toIso8601String(),
        'updatedDate': DateTime.now().toIso8601String(),
        'designation': ['piping'],
        'piping': selectedRows.map((row) {
          final actual = _valueFor(row.item.id);
          final isPipe = row.item.isPipeItem;
          return {
            'materialName': row.item.displayDescription,
            'rawMaterialName': row.item.displayDescription,
            'normalizedMaterialName': row.item.displayDescription.toLowerCase(),
            'uom': row.item.displayUom,
            'qty': isPipe ? 1 : actual,
            if (isPipe) 'length': actual,
            'actualQty': actual,
            if (isPipe) 'pipeMtr': actual,
            'plannedQty': row.item.totalQuantityCalculated,
            'boqId': row.boq.id,
            'boqItemId': row.item.id,
            'lineItemId': row.item.id,
            'drawingNo': row.group.drawingNo,
            'workDescription': row.group.workDescription,
            'itemType': row.item.itemType,
            'itemSize': row.item.displaySize,
            'boqGroupKey': row.item.boqGroupKey,
            'boqItemKey': row.item.boqItemKey,
            'sourceRowNo': row.item.sourceRowNo,
            'sourceColumnNo': row.item.sourceColumnNo,
            'sourceHeader': row.item.sourceHeader,
            'moc': row.item.moc,
            'size': row.item.size,
            'calculationCategory': 'A',
            'designation': ['piping'],
            'remarks': _remarkController(row.item.id).text.trim(),
          };
        }).toList(),
      };

      await DprApi.postMechanicalBoqDprEntry(
        data: payload,
        siteId: widget.siteId,
      );
      if (!mounted) return;
      AppToast.success('Mechanical DPR entry saved');
      for (final controller in _qtyControllers.values) {
        controller.clear();
      }
      for (final controller in _remarkControllers.values) {
        controller.clear();
      }
      await _loadBoqs();
    } catch (e) {
      if (!mounted) return;
      AppToast.error(extractBackendError(e));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      drawer: const CustomDrawer(),
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          const CustomSliverAppBar(title: 'Mechanical Piping DPR'),
        ],
        body: CornerClippedScreenSimple(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: cs.primary))
              : Column(
                  children: [
                    _header(cs),
                    Expanded(child: _list(cs)),
                    _bottomBar(cs),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _header(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search drawing no, item, size',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 18, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd MMM').format(_entryDate),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
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

  Widget _list(ColorScheme cs) {
    final rows = _visibleRows;
    if (_query.isEmpty) return _defaultMaterialState(cs);

    if (rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No BOQ item found for this search.',
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: rows.length,
      itemBuilder: (_, index) {
        final row = rows[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _pipingCard(
            material: _boqRowAsPipingItem(row),
            quantity: _qtyController(row.item.id).text,
            isEditable: true,
            categoryId: row.item.calculationCategory ?? 'A',
            onQuantityChanged: (value) =>
                _qtyController(row.item.id).text = value,
            onLengthChanged: (value) =>
                _qtyController(row.item.id).text = value,
            onDynamicChanged: (key, value) {
              if (key.toLowerCase() == 'qty') {
                _qtyController(row.item.id).text = value;
              }
            },
            onRemark: () => _showRemarkSheet(row.item.id),
            onEdit: () => _showCardActionMessage(),
            onCopy: () => _showCardActionMessage(),
            onDelete: () => _clearBoqInput(row.item.id),
          ),
        );
      },
    );
  }

  Widget _defaultMaterialState(ColorScheme cs) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      children: [
        ..._defaultMaterials.values.map(
          (material) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _pipingCard(
              material: material,
              quantity: '',
              isEditable: true,
              categoryId: material.calculationCategory,
              onQuantityChanged: (_) {},
              onLengthChanged: (_) {},
              onDynamicChanged: (key, value) =>
                  _updateDefaultMaterialField(material.id, key, value),
              onRemark: () => _showRemarkSheet('default_${material.id}'),
              onEdit: () => _showCardActionMessage(),
              onCopy: () => _copyDefaultMaterial(material),
              onDelete: () => _deleteDefaultMaterial(material.id),
            ),
          ),
        ),
      ],
    );
  }

  Widget _pipingCard({
    required PipingItem material,
    required String quantity,
    required bool isEditable,
    required String categoryId,
    required ValueChanged<String> onQuantityChanged,
    required ValueChanged<String> onLengthChanged,
    required void Function(String key, String value) onDynamicChanged,
    required VoidCallback onRemark,
    required VoidCallback onEdit,
    required VoidCallback onCopy,
    required VoidCallback onDelete,
  }) {
    return MaterialCardWrapper(
      isUpdating: false,
      child: ExpandableMaterialCard(
        categoryId: categoryId,
        isEditMode: false,
        child: testDynamicItemCard(
          image: material.image,
          isEditMode: false,
          lengthLabel: material.materialName,
          lengthPlaceholder: material.uom,
          fields: _sameDprFields(material, quantity),
          onChanged: onDynamicChanged,
          quantity: quantity,
          remark: material.remarks,
          size: material.size,
          length: quantity,
          floor: material.floor,
          moc: material.moc,
          sizeLabel: '',
          sizePlaceholder: '',
          onQtyChanged: onQuantityChanged,
          onSizeChanged: (_) {},
          onLengthChanged: onLengthChanged,
          onFloorChanged: (_) {},
          onMocChanged: (_) {},
          onCopy: onCopy,
          onAdd: onCopy,
          onDelete: onDelete,
          onEdit: onEdit,
          onRemark: onRemark,
          isEditable: isEditable,
        ),
      ),
    );
  }

  PipingItem _boqRowAsPipingItem(_PipingBoqRow row) {
    final item = row.item;
    final remaining = item.remainingQuantity > 0
        ? item.remainingQuantity
        : item.totalQuantityCalculated;
    return PipingItem(
      id: item.id,
      lineItemId: item.id,
      rawMaterialName: item.displayDescription,
      normalizedMaterialName: item.displayDescription.toLowerCase(),
      materialName: item.displayDescription,
      image: _imageForItem(item),
      qty: item.isPipeItem ? 1 : _valueFor(item.id),
      uom: item.displayUom,
      length: _valueFor(item.id),
      rmt: 0,
      diameter: 0,
      weight: 0,
      power: 0,
      floor: row.group.drawingNo,
      elevation: '',
      actualRate: 0,
      rate: 0,
      moc: item.moc ?? '',
      size: item.displaySize,
      location: '',
      plant: '',
      designation: const ['piping'],
      calculationCategory: item.calculationCategory ?? 'A',
      dynamicFields: [
        DynamicField(
          key: 'boq',
          label: 'BOQ',
          value: _fmt(item.totalQuantityCalculated),
          displayText: _fmt(item.totalQuantityCalculated),
          unit: item.displayUom,
        ),
        DynamicField(
          key: 'balance',
          label: 'Balance',
          value: _fmt(remaining),
          displayText: _fmt(remaining),
          unit: item.displayUom,
        ),
        DynamicField(
          key: 'moc',
          label: 'MOC',
          value: item.moc ?? '',
          displayText: item.moc ?? '',
          unit: '',
        ),
        DynamicField(
          key: 'workDescription',
          label: 'Work',
          value: row.group.workDescription,
          displayText: row.group.workDescription,
          unit: '',
        ),
      ],
      remarks: _remarkController(item.id).text,
    );
  }

  List<DynamicField> _sameDprFields(PipingItem material, String quantity) {
    return [
      DynamicField(
        key: 'qty',
        label: 'Qty',
        value: quantity,
        displayText: quantity,
        unit: '',
      ),
      DynamicField(
        key: 'size',
        label: 'Size',
        value: material.size,
        displayText: material.size,
        unit: '',
      ),
      DynamicField(
        key: 'floor',
        label: 'Floor',
        value: material.floor,
        displayText: material.floor,
        unit: '',
      ),
      DynamicField(
        key: 'moc',
        label: 'MOC',
        value: material.moc,
        displayText: material.moc,
        unit: '',
      ),
      ...material.dynamicFields.where((field) {
        final key = field.key.toLowerCase();
        return key != 'qty' && key != 'size' && key != 'floor' && key != 'moc';
      }),
    ];
  }

  void _showCardActionMessage() {
    AppToast.info('Use the same DPR Entry card controls for this material.');
  }

  void _clearBoqInput(String itemId) {
    _qtyController(itemId).clear();
    setState(() {});
  }

  void _updateDefaultMaterialField(
      String materialId, String key, String value) {
    final material = _defaultMaterials[materialId];
    if (material == null) return;

    final normalizedKey = key.toLowerCase();
    if (normalizedKey == 'qty') return;
    if (normalizedKey == 'size') {
      setState(() {
        _defaultMaterials[materialId] = material.copyWith(size: value);
      });
      return;
    }
    if (normalizedKey == 'floor') {
      setState(() {
        _defaultMaterials[materialId] = material.copyWith(floor: value);
      });
      return;
    }
    if (normalizedKey == 'moc') {
      setState(() {
        _defaultMaterials[materialId] = material.copyWith(moc: value);
      });
      return;
    }

    final updated = material.dynamicFields.map((field) {
      if (field.key.toLowerCase() == normalizedKey) {
        return field.copyWith(value: value, displayText: value);
      }
      return field;
    }).toList();

    setState(() {
      _defaultMaterials[materialId] = material.copyWith(dynamicFields: updated);
    });
  }

  void _copyDefaultMaterial(PipingItem material) {
    final copy = material.copyWith(
      id: '${material.id}_${DateTime.now().millisecondsSinceEpoch}',
      materialName: material.materialName,
    );
    setState(() => _defaultMaterials[copy.id] = copy);
  }

  void _deleteDefaultMaterial(String materialId) {
    setState(() => _defaultMaterials.remove(materialId));
  }

  Future<void> _showRemarkSheet(String itemId) async {
    final controller =
        TextEditingController(text: _remarkController(itemId).text);
    final value = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Remark',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Add optional note',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, controller.text),
                  child: const Text('Save Remark'),
                ),
              ),
            ],
          ),
        );
      },
    );
    controller.dispose();
    if (value != null) {
      _remarkController(itemId).text = value.trim();
      setState(() {});
    }
  }

  Widget _bottomBar(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: RoundedButton(
              text: 'Back',
              color: cs.surfaceContainerHigh,
              textColor: cs.onSurface,
              onPressed: () {
                if (_isSubmitting) return;
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RoundedButton(
              text: _isSubmitting ? 'Saving...' : 'Submit DPR',
              color: cs.primary,
              textColor: cs.onPrimary,
              onPressed: () {
                if (_isSubmitting) return;
                _submit();
              },
            ),
          ),
        ],
      ),
    );
  }

  String _imageForItem(MechanicalBoqItem item) {
    final text = [
      item.itemType ?? '',
      item.displayDescription,
      item.sourceHeader ?? '',
    ].join(' ').toLowerCase();
    if (text.contains('reducer')) {
      return 'assets/images/piping/reducer_joints_fitting.webp';
    }
    if (text.contains('tee')) {
      return 'assets/images/piping/tee_joints_fitting.webp';
    }
    if (text.contains('elbow')) {
      return 'assets/images/piping/elbow_90_joint_fitting.webp';
    }
    if (text.contains('flange') || text.contains('gasket')) {
      return 'assets/images/piping/flange_joints_fitting.webp';
    }
    if (text.contains('valve')) {
      return 'assets/images/piping/valve_fitting.webp';
    }
    if (text.contains('blind')) {
      return 'assets/images/piping/blind_fabrication_and_fitting.webp';
    }
    if (text.contains('support')) {
      return 'assets/images/piping/support_fabrication_and_erection.webp';
    }
    if (text.contains('coupling')) {
      return 'assets/images/piping/joints_welding_fitting.webp';
    }
    return 'assets/images/piping/pipe_erection_fittings.webp';
  }

  String _fmt(num value) {
    if (value % 1 == 0) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }
}

class _PipingBoqRow {
  const _PipingBoqRow({
    required this.boq,
    required this.group,
    required this.item,
  });

  final BoqDetail boq;
  final MechanicalBoqGroup group;
  final MechanicalBoqItem item;
}
