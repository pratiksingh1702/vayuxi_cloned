import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/providers/floorProvider.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/providers/mocProvider.dart';
// import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/all_material.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/dynamic_item_card.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/dynamic_item_card2.dart';
import '../models/dprModel.dart';
import '../providers/dpr.dart';

class AddDescriptionScreen extends ConsumerStatefulWidget {
  final String? workId;
  final String? teamName;
  final String? siteId;
  final String? teamId;

  const AddDescriptionScreen({
    this.workId,
    this.teamName,
    this.siteId,
    this.teamId,
    super.key,
  });

  @override
  ConsumerState<AddDescriptionScreen> createState() => _AddDescriptionScreenState();
}

class _AddDescriptionScreenState extends ConsumerState<AddDescriptionScreen> {
  late String _moc;
  late String _floor;
  late String _size;
  late String _plant;

  bool _pipeFittingOn = false;
  bool _equipmentOn = false;
  bool _editMode = true;
  String _inputValue = '';

  final List<Map<String, dynamic>> _cardInputs = [];
  final List<Map<String, dynamic>> _selectedPipingMaterials = [];
  final List<Map<String, dynamic>> _selectedEquipmentMaterials = [];
  final Set<String> _pendingUpdates = {};

  List<DprModel> _availableMaterials = [];
  bool _isLoadingMaterials = false;
  bool _isSubmitting = false;

  // Cached material lists to avoid recomputation
  List<Map<String, dynamic>>? _cachedPipingMaterials;
  List<Map<String, dynamic>>? _cachedEquipmentMaterials;

  @override
  void initState() {
    super.initState();
    _initializeData();
    // Delay initial fetch to let UI build first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAvailableMaterials();
      _printAllMaterialImages();
      setState(() {
        _pipeFittingOn = false;
        _equipmentOn = false;
      });
    });
  }

  void _initializeData() {
    
    _moc = ref.read(selectedMOCProvider)!.name;
    _floor = ref.read(selectedFloorProvider)!.name;
    _size = '';
    _plant = '';
    _inputValue = 'New DPR Entry';
    _pipeFittingOn = false;
    _equipmentOn = false;
  }

  // Helper method to clean image URLs
  String _cleanImageUrl(String url) {
    if (url.isEmpty) return '';
    return url.trim().replaceAll(RegExp(r'%20+$'), '').replaceAll(RegExp(r'\s+$'), '');
  }

  Future<void> _fetchAvailableMaterials() async {
    print("fetccccccccccccchinng");
    if (widget.siteId == null || widget.teamId == null) {
      return;
    }

    // Only fetch if not already loading and materials are empty
    if (_isLoadingMaterials || _availableMaterials.isNotEmpty) return;

    setState(() {
      _isLoadingMaterials = true;
    });

    try {
      await ref.read(dprProvider.notifier).fetchDprWork(
        siteId: widget.siteId!,
        teamId: widget.teamId!,
      );

      final dprState = ref.read(dprProvider);
      if (dprState.data != null && dprState.data is List<DprModel>) {
        setState(() {
          _availableMaterials = dprState.data as List<DprModel>;
          // Clear cache when new data arrives
          _cachedPipingMaterials = null;
          _cachedEquipmentMaterials = null;
        });
      }
      _printAllMaterialImages();
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Failed to load materials: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMaterials = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _getPipingMaterialsFromAPI() {
    // Return cached result if available
    if (_cachedPipingMaterials != null) {
      return _cachedPipingMaterials!;
    }

    final List<Map<String, dynamic>> pipingMaterials = [];
    for (final dpr in _availableMaterials) {
      for (final piping in dpr.piping) {
        pipingMaterials.add({
          'id': piping.id,
          'materialName': piping.materialName,
          'uom': piping.uom,
          'image': _cleanImageUrl(piping.image),
          'category': 'piping',
          'originalData': piping,
        });
      }
    }

    _cachedPipingMaterials = pipingMaterials;
    return pipingMaterials;
  }

  List<Map<String, dynamic>> _getEquipmentMaterialsFromAPI() {
    // Return cached result if available
    if (_cachedEquipmentMaterials != null) {
      return _cachedEquipmentMaterials!;
    }

    final List<Map<String, dynamic>> equipmentMaterials = [];
    for (final dpr in _availableMaterials) {
      for (final equipment in dpr.equipment) {
        equipmentMaterials.add({
          'id': equipment.id,
          'materialName': equipment.materialName,
          'uom': equipment.uom,
          'image': _cleanImageUrl(equipment.image),
          'category': 'equipment',
          'originalData': equipment,
        });
      }
    }

    _cachedEquipmentMaterials = equipmentMaterials;
    return equipmentMaterials;
  }
  void _printAllMaterialImages() {
    print('📸 PRINTING ALL MATERIAL IMAGES:');

    // Print Piping Materials
    print('\n🏗️ PIPING MATERIALS:');
    final pipingMaterials = _getPipingMaterialsFromAPI();
    for (final material in pipingMaterials) {
      final materialName = material['materialName'] ?? 'Unknown Material';
      final imageUrl = material['image'] ?? 'No Image';
      print('   📍 $materialName');
      print('   🖼️  $imageUrl');
      print('   ──────────────────────────');
    }

    // Print Equipment Materials
    print('\n⚙️ EQUIPMENT MATERIALS:');
    final equipmentMaterials = _getEquipmentMaterialsFromAPI();
    for (final material in equipmentMaterials) {
      final materialName = material['materialName'] ?? 'Unknown Material';
      final imageUrl = material['image'] ?? 'No Image';
      print('   📍 $materialName');
      print('   🖼️  $imageUrl');
      print('   ──────────────────────────');
    }

    // Print summary
    print('\n📊 SUMMARY:');
    print('   Total Piping Materials: ${pipingMaterials.length}');
    print('   Total Equipment Materials: ${equipmentMaterials.length}');
    print('   Total Materials: ${pipingMaterials.length + equipmentMaterials.length}');
  }

  void _handleMocChange(String value) => setState(() => _moc = value);
  void _handleSizeChange(String value) => setState(() => _size = value);
  void _handleFloorChange(String value) => setState(() => _floor = value);
  void _handlePlantChange(String value) => setState(() => _plant = value);

  Future<void> _handleSubmitFields() async {
    if (_moc.isEmpty || _floor.isEmpty || _plant.isEmpty || _inputValue.isEmpty) {
      _showErrorDialog('Please fill all required fields');
      return;
    }

    // Add designation validation
    if (!_pipeFittingOn && !_equipmentOn) {
      _showErrorDialog('Please select at least one type (Pipe Fitting or Equipment)');
      return;
    }

    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final newDprData = {
        'dprName': _inputValue,
        'moc': _moc,
        'size': _size,
        'location': _floor,
        'plant': _plant,
        'piping': _selectedPipingMaterials,
        'equipment': _selectedEquipmentMaterials,
        'designation': _getDesignation(),
      };

      print('📤 Submitting DPR Data: $newDprData');

      await ref.read(dprProvider.notifier).postDprWork(
        data: newDprData,
        siteId: widget.siteId!,
        teamId: widget.teamId!,
      );

      if (mounted) {
        Navigator.pop(context, newDprData);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Failed to create DPR: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
  String _getDesignation() {
    final designations = <String>[];
    if (_pipeFittingOn) designations.add('piping');
    if (_equipmentOn) designations.add('equipment');

    // Return as array for API compatibility with React Native version
    if (designations.isEmpty) {
      return "piping"; // Or handle this case appropriately
    }
    return designations.join(',');
  }

  void _updateCardInput(String id, String field, String value) {
    setState(() {
      final index = _cardInputs.indexWhere((input) => input['id'] == id);
      if (index != -1) {
        _cardInputs[index][field] = value;
      }
      _pendingUpdates.add(id);
    });

    // Debounce updates to avoid too many API calls
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _pendingUpdates.contains(id)) {
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

    if (widget.siteId != null) {
      ref.read(dprProvider.notifier).updateMaterialQty(
        data: formData,
        siteId: widget.siteId!,
        materialId: materialId,
      );
    }

    setState(() => _pendingUpdates.remove(materialId));
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: SingleChildScrollView(
          child: Text(message),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showRemarkDialog(String materialId, String currentRemark) {
    showDialog(
      context: context,
      builder: (context) => RemarkDialog(
        initialValue: currentRemark,
        onSave: (remark) => _updateRemark(materialId, remark),
      ),
    );
  }

  void _updateRemark(String materialId, String remark) {
    // Implement remark update logic
  }

  void _copyMaterial(String materialId) {
    final originalMaterial = _cardInputs.firstWhere(
          (input) => input['id'] == materialId,
      orElse: () => {},
    );

    if (originalMaterial.isNotEmpty) {
      final newId = DateTime.now().millisecondsSinceEpoch.toString();
      final copiedMaterial = Map<String, dynamic>.from(originalMaterial)..['id'] = newId;

      setState(() {
        _cardInputs.add(copiedMaterial);

        final isPiping = _selectedPipingMaterials.any((item) => item['id'] == materialId);
        if (isPiping) {
          final copiedPiping = Map<String, dynamic>.from(
              _selectedPipingMaterials.firstWhere((item) => item['id'] == materialId)
          )..['id'] = newId;
          _selectedPipingMaterials.add(copiedPiping);
        } else {
          final copiedEquipment = Map<String, dynamic>.from(
              _selectedEquipmentMaterials.firstWhere((item) => item['id'] == materialId)
          )..['id'] = newId;
          _selectedEquipmentMaterials.add(copiedEquipment);
        }
      });

      if (widget.siteId != null) {
        ref.read(dprProvider.notifier).copyMaterial(
          siteId: widget.siteId!,
          materialId: materialId,
        );
      }
    }
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
              setState(() {
                _cardInputs.removeWhere((input) => input['id'] == materialId);
                _selectedPipingMaterials.removeWhere((item) => item['id'] == materialId);
                _selectedEquipmentMaterials.removeWhere((item) => item['id'] == materialId);
              });
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddMaterialDialog() {
    // From any widget with access to context
   _showPipingMaterialSelection();
   _showEquipmentMaterialSelection();

    // context.navigateToAllMaterials(
    //   siteId: widget.siteId!,
    //   teamId: widget.teamId!,
    //   teamName: 'Your Team Name',
    // );
  }

  void _showPipingMaterialSelection() {
    final pipingMaterials = _getPipingMaterialsFromAPI();

    if (pipingMaterials.isEmpty) {
      _showErrorDialog('No piping materials available');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => MaterialSelectionDialog(
        title: 'Select Piping Materials',
        materials: pipingMaterials,
        onMaterialsSelected: (selectedMaterials) {
          setState(() {
            for (final material in selectedMaterials) {
              if (!_selectedPipingMaterials.any((item) => item['id'] == material['id'])) {
                _selectedPipingMaterials.add(material);
                _cardInputs.add({
                  'id': material['id'],
                  'floor': _floor,
                  'moc': _moc,
                  'quantity': '0',
                  'size': '',
                  'length': '0',
                  'materialName': material['materialName'],
                  'uom': material['uom'],
                  'image': material['image'],
                });
              }
            }
          });
        },
      ),
    );
  }

  void _showEquipmentMaterialSelection() {
    final equipmentMaterials = _getEquipmentMaterialsFromAPI();

    if (equipmentMaterials.isEmpty) {
      _showErrorDialog('No equipment materials available');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => MaterialSelectionDialog(
        title: 'Select Equipment Materials',
        materials: equipmentMaterials,
        onMaterialsSelected: (selectedMaterials) {
          setState(() {
            for (final material in selectedMaterials) {
              if (!_selectedEquipmentMaterials.any((item) => item['id'] == material['id'])) {
                _selectedEquipmentMaterials.add(material);
                _cardInputs.add({
                  'id': material['id'],
                  'floor': _floor,
                  'moc': _moc,
                  'quantity': '0',
                  'size': '',
                  'length': '0',
                  'ton': '0',
                  'materialName': material['materialName'],
                  'uom': material['uom'],
                  'image': material['image'],
                });
              }
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      appBar: CustomAppBar(title: widget.teamName!),
      body: SafeArea(
        child: Column(
          children: [
            // Fixed header
           
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isLoadingMaterials) _buildShimmerLoading(),
                    const SizedBox(height: 10),
                    _buildDateSection(),
                    const SizedBox(height: 20),
                    Container(

                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                      ),
                      padding: EdgeInsets.all(10),
                      child: Column(
                        children: [
                          _buildDprNameSection(),
                          const SizedBox(height: 20),
                          _buildInputFields(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    _buildToggleSection(),
                    const SizedBox(height: 20),
                    _buildMaterialsSection(),
                    const SizedBox(height: 20),
                    _buildButtonsSection(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Column(
      children: List.generate(3, (index) => const MaterialShimmerItem()),
    );
  }

  // Widget _buildHeader() {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black12,
  //           blurRadius: 2,
  //           offset: const Offset(0, 1),
  //         ),
  //       ],
  //     ),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: [
  //         Expanded(
  //           child: Text(
  //             widget.teamName ?? 'New Team',
  //             style: const TextStyle(
  //               fontSize: 18,
  //               fontWeight: FontWeight.bold,
  //             ),
  //             textAlign: TextAlign.center,
  //           ),
  //         ),
  //         _buildRefreshButton(),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildRefreshButton() {
    return _isLoadingMaterials
        ? const SizedBox(
      width: 40,
      height: 40,
      child: CircularProgressIndicator(strokeWidth: 2),
    )
        : IconButton(
      icon: const Icon(Icons.refresh),
      onPressed: _fetchAvailableMaterials,
    );
  }

  Widget _buildDateSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              contentPadding: const EdgeInsets.all(8),
              hintText: 'Enter DPR Name',
            ),
          )
              : Text(
            _inputValue,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 80,
          child:IconButton(
            onPressed: () {
              if (_editMode) {
                if (_inputValue.isEmpty) {
                  _showErrorDialog('Please enter DPR name');
                  return;
                }
                setState(() => _editMode = false);
              } else {
                setState(() => _editMode = true);
              }
            },

            icon: _editMode ? Icon(Icons.mode_edit_outline_outlined, color: Colors.blue) : Icon(Icons.edit, color: Colors.blue),



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
            Expanded(child: _buildInputField('MOC', _moc, _handleMocChange, isRequired: true)),
            const SizedBox(width: 10),
            Expanded(child: _buildInputField('Size in Inches', _size, _handleSizeChange)),
            const SizedBox(width: 10),
            Expanded(child: _buildInputField('Plant', _plant, _handlePlantChange, isRequired: true)),
            const SizedBox(width: 10),
            Expanded(child: _buildInputField('Location', _floor, _handleFloorChange, isRequired: true)),
          ],
        ),

      ],
    );
  }

  Widget _buildInputField(String label, String value, Function(String) onChanged, {bool isRequired = false}) {
    return TextField(
      controller: TextEditingController(text: value),
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white), // White text color for input
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFD0EAFD) ,// Blue background
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none, // Remove default border
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none, // Remove border when enabled
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white, width: 2), // White border when focused
        ),
        contentPadding: const EdgeInsets.all(12),
        hintText: '$label',
        hintStyle: const TextStyle(color: Colors.grey), // White hint text
      ),
    );
  }
  Widget _buildToggleSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _buildToggleCard('Pipe Fitting', _pipeFittingOn, (value) {
            setState(() => _pipeFittingOn = value);
            _handleToggleChange();
          }),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildToggleCard('Equipment', _equipmentOn, (value) {
            setState(() => _equipmentOn = value);
            _handleToggleChange();
          }),
        ),
      ],
    );
  }
  void _handleToggleChange() {
    // If both are false, show error
    if (!_pipeFittingOn && !_equipmentOn) {
      // You can choose to show a message or keep both off
      return;
    }

    // Auto-create materials when toggled on (matching React Native behavior)
    if (_pipeFittingOn && _selectedPipingMaterials.isEmpty) {
      _showAddMaterialDialog();
    }

    if (_equipmentOn && _selectedEquipmentMaterials.isEmpty) {
      _showAddMaterialDialog();
    }
  }

  Widget _buildToggleCard(String title, bool value, Function(bool) onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: value ? const Color(0xFF1B6DCE) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF1B6DCE),
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: value ? Colors.white : const Color(0xFF1B6DCE),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Container(
                  width: 40,
                  height: 24,
                  decoration: BoxDecoration(
                    color: value ? Colors.white : Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: value ? const Color(0xFF1B6DCE) : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Material Usage', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400)),
        const SizedBox(height: 10),
        if (_pipeFittingOn && _selectedPipingMaterials.isEmpty && _equipmentOn && _selectedEquipmentMaterials.isEmpty)
          _buildAddMaterialButton('Add Materials', _showAddMaterialDialog),
        ..._buildPipingMaterials(),
        ..._buildEquipmentMaterials(),
      ],
    );
  }

  List<Widget> _buildPipingMaterials() {
    if (!_pipeFittingOn || _selectedPipingMaterials.isEmpty) return [];

    return _selectedPipingMaterials.map((piping) {
      final input = _cardInputs.firstWhere((input) => input['id'] == piping['id'], orElse: () => {});
      final isUpdating = _pendingUpdates.contains(piping['id']);

      return MaterialCardWrapper(
        isUpdating: isUpdating,
        child: DynamicItemCard(
          quantity: input['quantity'] ?? '0',
          size: input['size'] ?? '',
          length: input['length'] ?? '0',
          floor: input['floor'] ?? '',
          moc: input['moc'] ?? '',
          image: piping['image'],
          sizeLabel: 'Size (if applicable)',
          lengthLabel: piping['materialName'] ?? 'Piping Material',
          sizePlaceholder: 'inch',
          lengthPlaceholder: piping['uom'] ?? 'Meter',
          onQtyChanged: (val) => _updateCardInput(piping['id'], 'quantity', val),
          onSizeChanged: (val) => _updateCardInput(piping['id'], 'size', val),
          onLengthChanged: (val) => _updateCardInput(piping['id'], 'length', val),
          onFloorChanged: (val) => _updateCardInput(piping['id'], 'floor', val),
          onMocChanged: (val) => _updateCardInput(piping['id'], 'moc', val),
          onDelete: () => _deleteMaterial(piping['id']),
          onRemark: () => _showRemarkDialog(piping['id'], ''),
          onEdit: () => _navigateToEdit(piping['id']),
          onAdd: () => _copyMaterial(piping['id']),
        ),
      );
    }).toList();
  }

  List<Widget> _buildEquipmentMaterials() {
    if (!_equipmentOn || _selectedEquipmentMaterials.isEmpty) return [];

    return _selectedEquipmentMaterials.map((equipment) {
      final input = _cardInputs.firstWhere((input) => input['id'] == equipment['id'], orElse: () => {});
      final isUpdating = _pendingUpdates.contains(equipment['id']);

      return MaterialCardWrapper(
        isUpdating: isUpdating,
        child: DynamicItemCard2(
          title: equipment['materialName'] ?? 'Equipment Material',
          quantity: input['quantity'] ?? '0',
          image: equipment['image'],
          moc: input['moc'] ?? '',
          floor: input['floor'] ?? '',
          ton: input['ton'] ?? '0',
          meter: equipment['uom'] ?? 'Unit',
          onAdd: () => _copyMaterial(equipment['id']),
          onEdit: () => _navigateToEdit(equipment['id']),
          onMocChanged: (val) => _updateCardInput(equipment['id'], 'moc', val),
          onDelete: () => _deleteMaterial(equipment['id']),
          onRemark: () => _showRemarkDialog(equipment['id'], ''),
          onQtyChanged: (val) => _updateCardInput(equipment['id'], 'quantity', val),
          onFloorChanged: (val) => _updateCardInput(equipment['id'], 'floor', val),
          onTonChanged: (val) => _updateCardInput(equipment['id'], 'ton', val),
        ),
      );
    }).toList();
  }

  Widget _buildAddMaterialButton(String text, VoidCallback onPressed) {
    return Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B6DCE),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, size: 20),
              const SizedBox(width: 8),
              Text(text),
            ],
          ),
        )
    );
  }

  void _navigateToEdit(String materialId) {
    // Implement edit navigation
  }

  Widget _buildButtonsSection() {
    return Column(
      children: [

        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _isSubmitting
                  ? const ElevatedButton(
                onPressed: null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                    SizedBox(width: 8),
                    Text('Creating...'),
                  ],
                ),
              )
                  : ElevatedButton(
                onPressed: _handleSubmitFields,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B6DCE)),
                child: const Text('Create DPR', style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// FIXED: Optimized Material Selection Dialog with proper layout constraints
class MaterialSelectionDialog extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> materials;
  final Function(List<Map<String, dynamic>>) onMaterialsSelected;

  const MaterialSelectionDialog({
    required this.title,
    required this.materials,
    required this.onMaterialsSelected,
    super.key,
  });

  @override
  State<MaterialSelectionDialog> createState() => _MaterialSelectionDialogState();
}

class _MaterialSelectionDialogState extends State<MaterialSelectionDialog> {
  final Set<String> _selectedMaterialIds = {};

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                widget.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: widget.materials.isEmpty
                  ? const Center(child: Text('No materials available'))
                  : ListView.builder(
                shrinkWrap: true,
                itemCount: widget.materials.length,
                itemBuilder: (context, index) {
                  final material = widget.materials[index];
                  return MaterialSelectionItem(
                    material: material,
                    isSelected: _selectedMaterialIds.contains(material['id']),
                    onSelectionChanged: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedMaterialIds.add(material['id']);
                        } else {
                          _selectedMaterialIds.remove(material['id']);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final selectedMaterials = widget.materials
                          .where((material) => _selectedMaterialIds.contains(material['id']))
                          .toList();
                      widget.onMaterialsSelected(selectedMaterials);
                      Navigator.pop(context);
                    },
                    child: const Text('Add Selected'),
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

// Optimized Material Selection Item
class MaterialSelectionItem extends StatelessWidget {
  final Map<String, dynamic> material;
  final bool isSelected;
  final Function(bool) onSelectionChanged;

  const MaterialSelectionItem({
    required this.material,
    required this.isSelected,
    required this.onSelectionChanged,
    super.key,
  });

  String _cleanImageUrl(String url) {
    if (url.isEmpty) return '';
    return url.trim().replaceAll(RegExp(r'%20+$'), '').replaceAll(RegExp(r'\s+$'), '');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: CheckboxListTile(
        title: Text(material['materialName'] ?? 'Unknown Material'),
        subtitle: Text('Unit: ${material['uom'] ?? 'N/A'}'),
        secondary: SizedBox(
          width: 40,
          height: 40,
          child: CachedNetworkImage(
            imageUrl: _cleanImageUrl(material['image'] ?? ''),
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.image, size: 20, color: Colors.grey),
            ),
            errorWidget: (context, url, error) => Container(
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.broken_image, size: 20, color: Colors.grey),
            ),
          ),
        ),
        value: isSelected,
        onChanged: (value) => onSelectionChanged(value ?? false),
      ),
    );
  }
}

// Loading wrapper for material cards
class MaterialCardWrapper extends StatelessWidget {
  final bool isUpdating;
  final Widget child;

  const MaterialCardWrapper({
    required this.isUpdating,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isUpdating)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

// Shimmer loading effect
class MaterialShimmerItem extends StatelessWidget {
  const MaterialShimmerItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 100,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
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

// FIXED: Remark Dialog with proper constraints
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
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Remark',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter your remark...',
                    alignLabelWithHint: true,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      widget.onSave(_controller.text);
                      Navigator.pop(context);
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}