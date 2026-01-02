import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/dynamic_item_card.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/dynamic_item_card2.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import '../../../../../core/utlis/widgets/custom.dart';
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
  bool _globalEditMode = false;
  bool _showPipingMaterials = true;
  bool _showEquipmentMaterials = true;
  String _inputValue = '';

  DateTime _selectedDate = DateTime.now();
  bool _isToday = true;

  final List<Map<String, dynamic>> _cardInputs = [];
  final Set<String> _pendingUpdates = {};
  final Set<String> _isUpdating = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _isToday = _isDateToday(_selectedDate);
  }

  bool _isDateToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
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

  bool get _isEditable => _isToday || _globalEditMode;

  void _toggleGlobalEditMode() {
    setState(() {
      _globalEditMode = !_globalEditMode;
    });

    if (_globalEditMode) {
      _showSnackBar(
        _isToday
            ? "Edit mode enabled - You can now modify today's DPR and change date"
            : "Edit mode enabled - You can now modify DPR for ${_formatDate(_selectedDate)}",
        isError: false,
      );
    } else {
      _showSnackBar("Edit mode disabled", isError: false);
    }
  }

  String _formatDate(DateTime d) => "${d.day}/${d.month}/${d.year}";

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  bool _hasFieldsChanged() {
    return _moc != _originalMoc ||
        _size != _originalSize ||
        _floor != _originalFloor ||
        _plant != _originalPlant ||
        _inputValue != widget.dpr.dprName;
  }

  Future<void> _handleSubmitFields() async {
    if (!_isEditable) {
      _showEditRequiredMessage();
      return;
    }

    if (!_hasFieldsChanged() && _cardInputs.isEmpty) {
      _showSnackBar("No changes to save", isError: true);
      return;
    }

    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final updateData = {
        'dprName': _inputValue,
        'moc': _moc,
        'size': _size,
        'location': _floor,
        'plant': _plant,
      };

      await ref.read(dprProvider.notifier).updateDprWork(
        data: updateData,
        mechanicalId: widget.dpr.id!,
      );

      // Update pending material changes
      for (final materialId in _pendingUpdates) {
        await _performMaterialUpdate(materialId);
      }

      _showSnackBar('DPR updated successfully! ✓');

      if (!_isToday) {
        setState(() {
          _globalEditMode = false;
        });
      }

      // Navigate back after success
      Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar('Failed to save DPR: $e', isError: true);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showEditRequiredMessage() {
    if (_isToday) {
      _showSnackBar("You can edit today's DPR directly", isError: true);
    } else {
      _showSnackBar("Please enable edit mode to make changes", isError: true);
    }
  }

  void _handleToggleChange(bool isPiping, bool newValue) {
    setState(() {
      if (isPiping) {
        _pipeFittingOn = newValue;
        if (!newValue) {
          _showPipingMaterials = false;
        } else {
          if (widget.dpr.piping.isNotEmpty) {
            _showPipingMaterials = true;
          }
        }
      } else {
        _equipmentOn = newValue;
        if (!newValue) {
          _showEquipmentMaterials = false;
        } else {
          if (widget.dpr.equipment.isNotEmpty) {
            _showEquipmentMaterials = true;
          }
        }
      }
    });
  }

  void _toggleMaterialVisibility(bool isPiping) {
    if (isPiping) {
      setState(() {
        _showPipingMaterials = !_showPipingMaterials;
      });
    } else {
      setState(() {
        _showEquipmentMaterials = !_showEquipmentMaterials;
      });
    }
  }

  void _updateCardInput(String id, String field, String value) {
    if (!_isEditable) {
      _showEditRequiredMessage();
      return;
    }

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

  Future<void> _performMaterialUpdate(String materialId) async {
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

    try {
      // Call your API here
      print('Updating material: $formData');
      // Uncomment when you have the actual API call
      // await ref.read(dprProvider.notifier).updateMaterial(formData);
    } catch (e) {
      print('Error updating material: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating.remove(materialId);
          _pendingUpdates.remove(materialId);
        });
      }
    }
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
    _showSnackBar('Remark saved for material');
  }

  void _copyMaterial(String materialId) {
    // Implement copy material logic
    print('Copying material: $materialId');
    _showSnackBar('Material copied');
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
              _showSnackBar('Material deleted');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPipingMaterials = widget.dpr.piping.isNotEmpty;
    final hasEquipmentMaterials = widget.dpr.equipment.isNotEmpty;
    final shouldShowPiping = _pipeFittingOn && _showPipingMaterials && hasPipingMaterials;
    final shouldShowEquipment = _equipmentOn && _showEquipmentMaterials && hasEquipmentMaterials;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [const CustomSliverAppBar(title: "Add DPR")];
        },
        body: Padding(
          padding: const EdgeInsets.only(bottom: 80), // Space for the bottom button
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildEditModeButton(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDateSection(),
                  const SizedBox(height: 16),
                  _buildDprInfoCard(),
                  const SizedBox(height: 16),
                  _buildToggleSection(),
                  const SizedBox(height: 16),

                  // Materials Section
                  Column(
                    children: [
                      // Piping materials toggle card
                      if (_pipeFittingOn && hasPipingMaterials)
                        _buildMaterialToggleCard(
                          'Pipe Fitting Materials',
                          widget.dpr.piping.length,
                          _showPipingMaterials,
                              () => _toggleMaterialVisibility(true),
                        ),

                      // Piping materials list
                      if (shouldShowPiping)
                        ..._buildPipingMaterials(),

                      // Equipment materials toggle card
                      if (_equipmentOn && hasEquipmentMaterials)
                        _buildMaterialToggleCard(
                          'Equipment Materials',
                          widget.dpr.equipment.length,
                          _showEquipmentMaterials,
                              () => _toggleMaterialVisibility(false),
                        ),

                      // Equipment materials list
                      if (shouldShowEquipment)
                        ..._buildEquipmentMaterials(),

                      // Show empty state if no materials but toggles are on
                      if (_pipeFittingOn && !hasPipingMaterials)
                        _buildEmptyMaterialsCard('No piping materials available'),

                      if (_equipmentOn && !hasEquipmentMaterials)
                        _buildEmptyMaterialsCard('No equipment materials available'),
                    ],
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleSubmitFields,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isEditable ? const Color(0xFF1B6DCE) : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Text(
                'Save',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMaterialsCard(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 40,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialToggleCard(
      String title,
      int count,
      bool isExpanded,
      VoidCallback onToggle,
      ) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              isExpanded ? 'Hide' : 'Show',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.blue[100]!],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              SizedBox(width: 8),
              Text(
                'Daily Report',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.blue.shade200,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 6),
                Text(
                  _formatDate(_selectedDate),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditModeButton() {
    return GestureDetector(
      onTap: _toggleGlobalEditMode,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.shade700),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _globalEditMode ? "Editing" : "Edit",
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDprInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          children: [
            _buildDprNameSection(),
            const SizedBox(height: 16),
            _buildInputFields(),
          ],
        ),
      ),
    );
  }

  Widget _buildDprNameSection() {
    return Row(
      children: [
        Expanded(
          child: _editMode
              ? TextField(
            controller: TextEditingController(text: _inputValue),
            onChanged: (value) => _inputValue = value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF1B6DCE), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              hintText: 'Enter DPR Name',
              prefixIcon: const Icon(Icons.edit_document, size: 20),
            ),
          )
              : Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.description, color: Colors.grey[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _inputValue,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: _editMode ? Colors.green[50] : Colors.blue[50],
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            onPressed: () {
              if (_editMode && _inputValue.trim().isEmpty) {
                _showSnackBar('Please enter DPR name', isError: true);
                return;
              }
              setState(() => _editMode = !_editMode);
            },
            icon: Icon(
              _editMode ? Icons.check_circle : Icons.edit_rounded,
              color: _editMode ? Colors.green[700] : Colors.blue[700],
              size: 24,
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
            Expanded(child: _buildCompactInputField('Plant', _plant, _handlePlantChange, Icons.factory)),
            const SizedBox(width: 12),
            Expanded(child: _buildCompactInputField('Location', _floor, _handleFloorChange, Icons.location_on)),
            const SizedBox(width: 12),
            Expanded(child: _buildCompactInputField('MOC', _moc, _handleMocChange, Icons.category)),
            const SizedBox(width: 12),
            Expanded(child: _buildCompactInputField('Size', _size, _handleSizeChange, Icons.straighten)),
          ],
        )
      ],
    );
  }

  Widget _buildCompactInputField(String label, String value, Function(String) onChanged, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700]),
          ),
        ),
        SizedBox(
          height: 44,
          child: TextFormField(
            controller: TextEditingController(text: value),
            onChanged: onChanged,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
              filled: true,
              fillColor: const Color(0xFFE3F2FD),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF1B6DCE), width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildToggleCard(
                'Pipe Fitting',
                Icons.plumbing_rounded,
                _pipeFittingOn,
                false,
                    (value) => _handleToggleChange(true, value),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildToggleCard(
                'Equipment',
                Icons.precision_manufacturing_rounded,
                _equipmentOn,
                false,
                    (value) => _handleToggleChange(false, value),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToggleCard(
      String title,
      IconData ico,
      bool value,
      bool isLoading,
      Function(bool) onChanged,
      ) {
    return GestureDetector(
      onTap: isLoading ? null : () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
        decoration: BoxDecoration(
          gradient: value
              ? const LinearGradient(
            colors: [Color(0xFF1B6DCE), Color(0xFF1565C0)],
          )
              : null,
          color: value ? null : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value ? const Color(0xFF1B6DCE) : Colors.grey[300]!,
            width: value ? 2 : 1.5,
          ),
          boxShadow: value
              ? [
            BoxShadow(
              color: const Color(0xFF1B6DCE).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
              : null,
        ),
        child: Column(
          children: [
            if (isLoading)
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: value ? Colors.white : const Color(0xFF1B6DCE),
                ),
              ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: value ? Colors.white : const Color(0xFF1B6DCE),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPipingMaterials() {
    if (widget.dpr.piping.isEmpty) {
      return [];
    }

    return widget.dpr.piping.asMap().entries.map((entry) {
      final index = entry.key;
      final piping = entry.value;

      final input = _cardInputs.firstWhere(
            (input) => input['id'] == piping.id,
        orElse: () => {},
      );

      return Padding(
        key: ValueKey('piping_${piping.id}_$index'),
        padding: const EdgeInsets.only(bottom: 12),
        child: _MaterialCardWrapper(
          isUpdating: _isUpdating.contains(piping.id),
          child: DynamicItemCard(
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
            isEditable: _isEditable,
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildEquipmentMaterials() {
    if (widget.dpr.equipment.isEmpty) {
      return [];
    }

    return widget.dpr.equipment.asMap().entries.map((entry) {
      final index = entry.key;
      final equipment = entry.value;

      final input = _cardInputs.firstWhere(
            (input) => input['id'] == equipment.id,
        orElse: () => {},
      );

      return Padding(
        key: ValueKey('equipment_${equipment.id}_$index'),
        padding: const EdgeInsets.only(bottom: 12),
        child: _MaterialCardWrapper(
          isUpdating: _isUpdating.contains(equipment.id),
          child: DynamicItemCard2(
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
            isEditable: _isEditable, onMeterChanged: (String p1) {  },
          ),
        ),
      );
    }).toList();
  }

  void _navigateToEdit(String materialId) {
    // Navigate to edit screen
    print('Navigate to edit: $materialId');
    _showSnackBar('Edit functionality coming soon');
  }
}

// Wrapper for material cards with update overlay
class _MaterialCardWrapper extends StatelessWidget {
  final bool isUpdating;
  final Widget child;

  const _MaterialCardWrapper({
    required this.isUpdating,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isUpdating)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Updating...',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Add Remark'),
      content: TextField(
        controller: _controller,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: 'Enter remark...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_controller.text);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B6DCE),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
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