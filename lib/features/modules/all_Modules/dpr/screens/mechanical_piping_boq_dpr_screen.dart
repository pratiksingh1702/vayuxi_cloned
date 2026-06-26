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
import 'package:untitled2/features/modules/all_Modules/dpr/models/data/equipment_material_data.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/models/data/piping_material_data.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/providers/dprService.dart';

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
      itemBuilder: (_, index) => _rowCard(rows[index], cs),
    );
  }

  Widget _defaultMaterialState(ColorScheme cs) {
    final materials = [
      ...PipingMaterialsData.materials.map(
        (e) => _DefaultMaterialCard(title: e.materialName, image: e.image),
      ),
      ...EquipmentMaterialsData.materials.map(
        (e) => _DefaultMaterialCard(title: e.materialName, image: e.image),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      children: [
        Text(
          'Default Materials',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Search drawing number or item name to load BOQ cards for DPR entry.',
          style: TextStyle(
            fontSize: 12,
            height: 1.35,
            fontWeight: FontWeight.w600,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: materials.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.08,
          ),
          itemBuilder: (_, index) {
            final material = materials[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: cs.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Center(
                      child: Image.asset(
                        material.image,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.precision_manufacturing_outlined,
                          color: cs.primary,
                          size: 42,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    material.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _rowCard(_PipingBoqRow row, ColorScheme cs) {
    final item = row.item;
    final remaining = item.remainingQuantity > 0
        ? item.remainingQuantity
        : item.totalQuantityCalculated;
    final imagePath = _imageForItem(item);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayDescription,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      row.group.workDescription,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _remarkButton(cs, item.id),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 9,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.precision_manufacturing_outlined,
                      color: cs.primary,
                      size: 52,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 10,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _infoBox(
                            cs,
                            label: 'Drawing No.',
                            value: row.group.drawingNo,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _infoBox(
                            cs,
                            label: 'Size',
                            value: item.displaySize,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _uomBox(cs, item.displayUom),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _qtyController(item.id),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Progress',
                        hintText: '0',
                        filled: true,
                        fillColor: cs.surfaceContainerLowest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _smallStat(
                    cs,
                    'BOQ',
                    '${_fmt(item.totalQuantityCalculated)} ${item.displayUom}',
                  ),
                ),
                Container(width: 1, height: 28, color: cs.outlineVariant),
                Expanded(
                  child: _smallStat(
                    cs,
                    'Balance',
                    '${_fmt(remaining)} ${item.displayUom}',
                  ),
                ),
                if ((item.moc ?? '').trim().isNotEmpty) ...[
                  Container(width: 1, height: 28, color: cs.outlineVariant),
                  Expanded(child: _smallStat(cs, 'MOC', item.moc!)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(
    ColorScheme cs, {
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFCFEAFF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }

  Widget _uomBox(ColorScheme cs, String uom) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'UOM',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            uom,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: cs.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallStat(ColorScheme cs, String label, String value) {
    return Column(
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _remarkButton(ColorScheme cs, String itemId) {
    return InkWell(
      onTap: () => _showRemarkSheet(itemId),
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFC9F7F7),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: cs.outline.withValues(alpha: 0.40)),
        ),
        child: const Text(
          'Remark',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Color(0xFF111827),
          ),
        ),
      ),
    );
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

class _DefaultMaterialCard {
  const _DefaultMaterialCard({
    required this.title,
    required this.image,
  });

  final String title;
  final String image;
}
