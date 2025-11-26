import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/dynamic_item_card.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/dynamic_item_card2.dart';
import '../models/dprModel.dart';
import '../providers/dpr.dart';

class DprDetailScreen extends ConsumerStatefulWidget {
  final DprModel dpr;
  final String? workId;
  final String? teamName;

  const DprDetailScreen({
    required this.dpr,
    this.workId,
    this.teamName,
    super.key,
  });

  @override
  ConsumerState<DprDetailScreen> createState() => _DprDetailScreenState();
}

class _DprDetailScreenState extends ConsumerState<DprDetailScreen> {
  late String _moc;
  late String _floor;
  late String _size;
  late String _plant;

  late String _originalMoc;
  late String _originalFloor;
  late String _originalSize;
  late String _originalPlant;

  bool _pipeFittingOn = false;
  bool _equipmentOn = false;
  bool _editMode = false;
  String _inputValue = '';

  final List<Map<String, dynamic>> _cardInputs = [];
  final Set<String> _pendingUpdates = {};
  final Set<String> _isUpdating = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final dpr = widget.dpr;

    _moc = dpr.moc;
    _floor = dpr.location;
    _size = dpr.size;
    _plant = dpr.plant;

    _originalMoc = dpr.moc;
    _originalFloor = dpr.location;
    _originalSize = dpr.size;
    _originalPlant = dpr.plant;

    _inputValue = dpr.dprName;

    _pipeFittingOn = dpr.designation.contains('piping');
    _equipmentOn = dpr.designation.contains('equipment');

    _transformMaterialData();
  }

  void _transformMaterialData() {
    _cardInputs.clear();

    // Process piping items
    for (final item in widget.dpr.piping) {
      final baseData = {
        'id': item.id,
        'floor': item.location ?? '',
        'moc': item.moc ?? '',
        'quantity': item.qty.toString() ?? '0',
        'size': item.size.toString() ?? item.diameter?.toString() ?? '',
        'length': item.length.toString() ?? '0',
      };
      _cardInputs.add(baseData);
    }

    // Process equipment items
    for (final item in widget.dpr.equipment) {
      final baseData = {
        'id': item.id,
        'floor': item.location ?? '',
        'moc': item.moc ?? '',
        'quantity': item.qty.toString() ?? '0',
        'size': item.size?.toString() ?? item.diameter?.toString() ?? '',
        'length': item.length?.toString() ?? '0',
        'ton': item.weight?.toString() ?? '0',
      };
      _cardInputs.add(baseData);
    }
  }
  void _handleMocChange(String value) {
    setState(() {
      _moc = value;
    });
  }

  void _handleSizeChange(String value) {
    setState(() {
      _size = value;
    });
  }

  void _handleFloorChange(String value) {
    setState(() {
      _floor = value;
    });
  }

  void _handlePlantChange(String value) {
    setState(() {
      _plant = value;
    });
  }

  bool _hasFieldsChanged() {
    return _moc != _originalMoc ||
        _size != _originalSize ||
        _floor != _originalFloor ||
        _plant != _originalPlant;
  }

  void _handleSubmitFields() {
    if (!_hasFieldsChanged()) return;

    final updateData = {
      'moc': _moc,
      'size': _size,
      'location': _floor,
      'plant': _plant,
    };

    ref.read(dprProvider.notifier).updateDprWork(
      data: updateData,
      mechanicalId: widget.dpr.id!,
    );

    // Navigate back
    Navigator.pop(context);
  }

  void _updateCardInput(String id, String field, String value) {
    setState(() {
      _isUpdating.add(id);

      final index = _cardInputs.indexWhere((input) => input['id'] == id);
      if (index != -1) {
        _cardInputs[index][field] = value;
      }

      _pendingUpdates.add(id);
    });

    // Simulate debounced API call
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _performMaterialUpdate(id);
      }
    });
  }

  void _performMaterialUpdate(String materialId) {
    final input = _cardInputs.firstWhere(
          (input) => input['id'] == materialId,
      orElse: () => {},
    );

    if (input.isEmpty) return;

    final formData = {
      '_id': materialId,
      'moc': input['moc'] ?? '',
      'qty': input['quantity'] ?? '0',
      'size': input['size'] ?? '',
      'location': input['floor'] ?? '',
      'length': input['length'] ?? '0',
      if (input.containsKey('ton')) 'weight': input['ton'] ?? '0',
    };

    // Call your API here
    print('Updating material: $formData');

    setState(() {
      _isUpdating.remove(materialId);
      _pendingUpdates.remove(materialId);
    });
  }

  void _showRemarkDialog(String materialId, String currentRemark) {
    showDialog(
      context: context,
      builder: (context) => RemarkDialog(
        initialValue: currentRemark,
        onSave: (remark) {
          _updateRemark(materialId, remark);
        },
      ),
    );
  }

  void _updateRemark(String materialId, String remark) {
    // Implement remark update logic
    print('Updating remark for $materialId: $remark');
  }

  void _copyMaterial(String materialId) {
    // Implement copy material logic
    print('Copying material: $materialId');
  }

  void _deleteMaterial(String materialId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this material?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement delete logic
              print('Deleting material: $materialId');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dprState = ref.watch(dprProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFCFE8FA),
      body: SafeArea(
        child: SingleChildScrollView( // 🔹 Wrap everything to make whole screen scrollable
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 10),
                _buildDateSection(),
                const SizedBox(height: 20),
                _buildDprNameSection(),
                const SizedBox(height: 20),
                _buildInputFields(),
                const SizedBox(height: 20),
                _buildToggleSection(),
                const SizedBox(height: 20),

                // 🧩 Fix: Remove Expanded and make list inside shrink-wrapped container
                _buildMaterialsSection(),
                const SizedBox(height: 20),

                _buildButtonsSection(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              widget.teamName!,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Icon(Icons.menu), // Menu icon
        ],
      ),
    );
  }

  Widget _buildDateSection() {
    return Column(
      children: [
        const Text(
          'Daily Report',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
        ),
        Text(
          DateFormat('EEE, MMM d, yyyy').format(DateTime.now()),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
        ),
      ],
    );
  }

  Widget _buildDprNameSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 3,
          child: _editMode
              ? TextField(
            controller: TextEditingController(text: _inputValue),
            onChanged: (value) => _inputValue = value,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              contentPadding: const EdgeInsets.all(8),
            ),
          )
              : Text(
            _inputValue,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 80,
          child: ElevatedButton(
            onPressed: () {
              if (_editMode) {
                ref.read(dprProvider.notifier).updateDprWork(
                  data: {
                    'dprName': _inputValue,
                    'moc': _moc,
                    'size': _size,
                    'location': _floor,
                    'plant': _plant,
                  },
                  mechanicalId: widget.dpr.id!,
                );
                setState(() {
                  _editMode = false;
                });
              } else {
                setState(() {
                  _editMode = true;
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007BFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(vertical: 6),
            ),
            child: Text(
              _editMode ? 'Save' : 'Edit',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInputField('MOC', _moc, _handleMocChange),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildInputField('Size in Inches', _size, _handleSizeChange),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildInputField('Plant', _plant, _handlePlantChange),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildInputField('Location', _floor, _handleFloorChange),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInputField(String label, String value, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: TextEditingController(text: value),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleSection() {
    return Row(
      children: [
        Expanded(
          child: _buildToggleCard('Pipe Fitting', _pipeFittingOn, (value) {
            setState(() {
              _pipeFittingOn = value;
            });
          }),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildToggleCard('Equipment', _equipmentOn, (value) {
            setState(() {
              _equipmentOn = value;
            });
          }),
        ),
      ],
    );
  }

  Widget _buildToggleCard(String title, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1B6DCE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Material Usage',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 10),
        ListView(
          physics: const NeverScrollableScrollPhysics(), // prevent nested scrolls
          shrinkWrap: true, // 🔹 allow it to fit inside SingleChildScrollView
          children: [
            if (_pipeFittingOn) ..._buildPipingMaterials(),
            if (_equipmentOn) ..._buildEquipmentMaterials(),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildPipingMaterials() {
    if (widget.dpr.piping.isEmpty) {
      return [
        const Center(
          child: Text(
            'No data available',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      ];
    }

    return widget.dpr.piping.map((piping) {
      final input = _cardInputs.firstWhere(
            (input) => input['id'] == piping.id,
        orElse: () => {},
      );

      return DynamicItemCard(
        quantity: input['quantity'] ?? '0',
        size: input['size'] ?? '',
        length: input['length'] ?? '0',
        floor: input['floor'] ?? '',
        moc: input['moc'] ?? '',
        image: piping.image,
        sizeLabel: 'Size (if applicable)',
        lengthLabel: piping.materialName,
        sizePlaceholder: 'inch',
        lengthPlaceholder: piping.uom,
        onQtyChanged: (val) => _updateCardInput(piping.id, 'quantity', val),
        onSizeChanged: (val) => _updateCardInput(piping.id, 'size', val),
        onLengthChanged: (val) => _updateCardInput(piping.id, 'length', val),
        onFloorChanged: (val) => _updateCardInput(piping.id, 'floor', val),
        onMocChanged: (val) => _updateCardInput(piping.id, 'moc', val),
        onDelete: () => _deleteMaterial(piping.id),
        onRemark: () => _showRemarkDialog(piping.id, piping.remarks ?? ''),
        onEdit: () => _navigateToEdit(piping.id),
        onAdd: () => _copyMaterial(piping.id),
      );
    }).toList();
  }

  List<Widget> _buildEquipmentMaterials() {
    if (widget.dpr.equipment.isEmpty) {
      return [
        const Center(
          child: Text(
            'No data available',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      ];
    }

    return widget.dpr.equipment.map((equipment) {
      final input = _cardInputs.firstWhere(
            (input) => input['id'] == equipment.id,
        orElse: () => {},
      );

      return DynamicItemCard2(
        title: equipment.materialName,
        quantity: input['quantity'] ?? '0',
        image: equipment.image,
        moc: input['moc'] ?? '',
        floor: input['floor'] ?? '',
        ton: input['ton'] ?? '0',
        meter: equipment.uom,
        onAdd: () => _copyMaterial(equipment.id),
        onEdit: () => _navigateToEdit(equipment.id),
        onMocChanged: (val) => _updateCardInput(equipment.id, 'moc', val),
        onDelete: () => _deleteMaterial(equipment.id),
        onRemark: () => _showRemarkDialog(equipment.id, equipment.remarks ?? ''),
        onQtyChanged: (val) => _updateCardInput(equipment.id, 'quantity', val),
        onFloorChanged: (val) => _updateCardInput(equipment.id, 'floor', val),
        onTonChanged: (val) => _updateCardInput(equipment.id, 'ton', val),
      );
    }).toList();
  }

  void _navigateToEdit(String materialId) {
    // Navigate to edit screen
    print('Navigate to edit: $materialId');
  }

  Widget _buildButtonsSection() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            // Navigate to add product/service
          },
          child: const Text('Add Product/Service'),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _handleSubmitFields,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B6DCE),
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Remark Dialog
class RemarkDialog extends StatefulWidget {
  final String initialValue;
  final Function(String) onSave;

  const RemarkDialog({
    required this.initialValue,
    required this.onSave,
    super.key,
  });

  @override
  State<RemarkDialog> createState() => _RemarkDialogState();
}

class _RemarkDialogState extends State<RemarkDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Remark'),
      content: TextField(
        controller: _controller,
        maxLines: 3,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: 'Enter your remark...',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_controller.text);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}