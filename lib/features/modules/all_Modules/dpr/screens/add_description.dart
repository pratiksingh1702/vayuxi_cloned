import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/dynamic_item_card.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/dynamic_item_card2.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/material_selection.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/materila_card_wrapper.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/shimmer.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';
import 'package:untitled2/features/modules/all_Modules/team/model/teamModel.dart';
import 'package:untitled2/features/modules/all_Modules/team/provider/teamProvider.dart';
import '../../../../../core/utlis/widgets/buttons.dart';
import '../../../../../core/utlis/widgets/custom.dart';

import 'controllers/add_dpr_controller.dart';
import 'controllers/add_dpr_state.dart';

class AddDescriptionScreen extends ConsumerStatefulWidget {
  const AddDescriptionScreen({super.key});

  @override
  ConsumerState<AddDescriptionScreen> createState() =>
      _AddDescriptionScreenState();
}

class _AddDescriptionScreenState extends ConsumerState<AddDescriptionScreen> {
  late AddDescriptionController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeController();
    });
  }

  void _initializeController() async {
    try {
      await _controller.fetchAvailableMaterials();
      setState(() {});
    } catch (e) {
      _showErrorDialog('Failed to load materials: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final siteId = ref.read(selectedSiteIdProvider)!;
    final teamId = ref.read(selectedTeamIdProvider)!;
    final team = ref.read(selectedTeamProvider)!;

    _controller = ref.watch(addDescriptionControllerProvider((team: team)));

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [CustomSliverAppBar(title: "Add DPR")];
        },
        body: BottomButtonWrapper(
          customButtons: [
            // Create DPR Button
            CustomButton(
              button: _controller.isSubmitting
                  ? RoundedButton(
                      onPressed: () {},
                      text: 'creating...',
                      color: const Color(0xFF1B6DCE),
                      textColor: Colors.white,
                    )
                  : RoundedButton(
                      text: 'Create DPR',
                      color: const Color(0xFF1B6DCE),
                      textColor: Colors.white,
                      onPressed: _handleSubmit,
                      isOutlined: false,
                      width: 120,
                    ),
            ),

          ],
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_controller.isLoadingMaterials)
                          _buildShimmerLoading(),
                        const SizedBox(height: 10),
                        _buildDateSection(),
                        const SizedBox(height: 20),
                        _buildFormSection(),
                        const SizedBox(height: 20),
                        _buildToggleSection(),
                        const SizedBox(height: 20),
                        _buildMaterialsSection(),
                        const SizedBox(height: 20),

                      ],
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

  Widget _buildShimmerLoading() {
    return Column(
      children: List.generate(3, (index) => const MaterialShimmerItem()),
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

  Widget _buildFormSection() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          _buildDprNameSection(),
          const SizedBox(height: 20),
          _buildInputFields(),
        ],
      ),
    );
  }

  Widget _buildDprNameSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 3,
          child: _controller.isEditingName
              ? TextField(
                  controller: TextEditingController(text: _controller.dprName),
                  onChanged: (value) => _controller.dprName = value,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    contentPadding: const EdgeInsets.all(8),
                    hintText: 'Enter DPR Name',
                  ),
                )
              : Text(
                  _controller.dprName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 80,
          child: IconButton(
            onPressed: () {
              if (_controller.isEditingName) {
                if (_controller.dprName.isEmpty) {
                  _showErrorDialog('Please enter DPR name');
                  return;
                }
                setState(() => _controller.isEditingName = false);
              } else {
                setState(() => _controller.isEditingName = true);
              }
            },
            icon: _controller.isEditingName
                ? const Icon(
                    Icons.mode_edit_outline_outlined,
                    color: Colors.blue,
                  )
                : const Icon(Icons.edit, color: Colors.blue),
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
              child: _buildInputField(
                'MOC',
                _controller.moc,
                (value) => setState(() => _controller.moc = value),
                isRequired: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildInputField(
                'Size in Inches',
                _controller.size,
                (value) => setState(() => _controller.size = value),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildInputField(
                'Plant',
                _controller.plant,
                (value) => setState(() => _controller.plant = value),
                isRequired: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildInputField(
                'Location',
                _controller.floor,
                (value) => setState(() => _controller.floor = value),
                isRequired: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInputField(
    String label,
    String value,
    Function(String) onChanged, {
    bool isRequired = false,
  }) {
    return TextField(
      controller: TextEditingController(text: value),
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFD0EAFD),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        contentPadding: const EdgeInsets.all(12),
        hintText: label,
        hintStyle: const TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _buildToggleSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _buildToggleCard('Pipe Fitting', _controller.pipeFittingOn, (
            value,
          ) {
            setState(() => _controller.togglePipeFitting(value));
          }),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildToggleCard('Equipment', _controller.equipmentOn, (
            value,
          ) {
            setState(() => _controller.toggleEquipment(value));
          }),
        ),
      ],
    );
  }

  Widget _buildToggleCard(String title, bool value, Function(bool) onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: value ? const Color(0xFF1B6DCE) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1B6DCE), width: 2),
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
                    alignment: value
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
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
        const Text(
          'Material Usage',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 10),
        if (_controller.pipeFittingOn &&
            _controller.selectedPipingMaterials.isEmpty &&
            _controller.equipmentOn &&
            _controller.selectedEquipmentMaterials.isEmpty)
          _buildAddMaterialButton(
            'Add Materials',
            _showMaterialSelectionDialog,
          ),
        ..._buildPipingMaterials(),
        ..._buildEquipmentMaterials(),
      ],
    );
  }

  List<Widget> _buildPipingMaterials() {
    if (!_controller.pipeFittingOn ||
        _controller.selectedPipingMaterials.isEmpty) {
      return [];
    }

    return _controller.selectedPipingMaterials.map((piping) {
      final input = _controller.cardInputs.firstWhere(
        (input) => input['id'] == piping['id'],
        orElse: () => {},
      );
      final isUpdating = _controller.pendingUpdates.contains(piping['id']);

      return MaterialCardWrapper(
        isUpdating: isUpdating,
        child: DynamicItemCard(
          quantity: 'NOS',
          size: _controller.size,
          length: 'UOM',
          floor: input['floor'] ?? '',
          moc: input['moc'] ?? '',
          image: piping['image'],
          sizeLabel: 'Size (if applicable)',
          lengthLabel: piping['materialName'] ?? 'Piping Material',
          sizePlaceholder: 'inch',
          lengthPlaceholder: piping['uom'] ?? 'Meter',
          onQtyChanged: (val) =>
              _controller.updateCardInput(piping['id'], 'quantity', val),
          onSizeChanged: (val) =>
              _controller.updateCardInput(piping['id'], 'size', val),
          onLengthChanged: (val) =>
              _controller.updateCardInput(piping['id'], 'length', val),
          onFloorChanged: (val) =>
              _controller.updateCardInput(piping['id'], 'floor', val),
          onMocChanged: (val) =>
              _controller.updateCardInput(piping['id'], 'moc', val),
          onDelete: () =>
              setState(() => _controller.deleteMaterial(piping['id'])),
          onRemark: () => _showRemarkDialog(piping['id'], ''),
          onEdit: () => _navigateToEdit(piping['id']),
          onAdd: () => setState(() => _controller.copyMaterial(piping['id'])),
          isEditable: true,
        ),
      );
    }).toList();
  }

  List<Widget> _buildEquipmentMaterials() {
    if (!_controller.equipmentOn ||
        _controller.selectedEquipmentMaterials.isEmpty) {
      return [];
    }

    return _controller.selectedEquipmentMaterials.map((equipment) {
      final input = _controller.cardInputs.firstWhere(
        (input) => input['id'] == equipment['id'],
        orElse: () => {},
      );
      final isUpdating = _controller.pendingUpdates.contains(equipment['id']);

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
          onAdd: () =>
              setState(() => _controller.copyMaterial(equipment['id'])),
          onEdit: () => _navigateToEdit(equipment['id']),
          onMocChanged: (val) =>
              _controller.updateCardInput(equipment['id'], 'moc', val),
          onDelete: () =>
              setState(() => _controller.deleteMaterial(equipment['id'])),
          onRemark: () => _showRemarkDialog(equipment['id'], ''),
          onQtyChanged: (val) =>
              _controller.updateCardInput(equipment['id'], 'quantity', val),
          onFloorChanged: (val) =>
              _controller.updateCardInput(equipment['id'], 'floor', val),
          onTonChanged: (val) =>
              _controller.updateCardInput(equipment['id'], 'ton', val),
          isEditable: true,
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
      ),
    );
  }

  void _showMaterialSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => MaterialSelectionDialog(
        title: 'Select Materials',
        pipingMaterials: _controller.getPipingMaterialsFromAPI(),
        equipmentMaterials: _controller.getEquipmentMaterialsFromAPI(),
        onMaterialsSelected: (selectedMaterials) {
          setState(() {
            for (final material in selectedMaterials) {
              _controller.addMaterial(material);
            }
          });
        },
      ),
    );
  }

  Widget _buildButtonsSection() {
    return Column(
      children: [
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _controller.isSubmitting
                  ? const ElevatedButton(
                      onPressed: null,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('Creating...'),
                        ],
                      ),
                    )
                  : ElevatedButton(
                      onPressed: _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B6DCE),
                      ),
                      child: const Text(
                        'Create DPR',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: _controller.isSubmitting
                    ? null
                    : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    try {
      await _controller.submitDpr();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showErrorDialog(e.toString());
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: SingleChildScrollView(child: Text(message)),
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
    // Implement remark dialog
  }

  void _navigateToEdit(String materialId) {
    // Implement edit navigation
  }
}
