import 'dart:io';
import 'package:flutter/material.dart';
import '../model/eqip_insu.dart';
import '../model/material_setup.dart';
import '../model/field_config.dart';
import 'dynamic_field_builder.dart';

/// Example implementation of EquipmentMaterialCard using dynamic fields
/// This shows how to integrate MaterialSetup with the existing card UI
class DynamicEquipmentCardExample extends StatefulWidget {
  final EquipmentMaterial material;
  final MaterialSetup? materialSetup; // Optional: for dynamic field rendering
  final ValueChanged<EquipmentMaterial> onChanged;
  final VoidCallback onAdd;
  final VoidCallback onDelete;
  final VoidCallback onRemark;

  const DynamicEquipmentCardExample({
    super.key,
    required this.material,
    this.materialSetup,
    required this.onChanged,
    required this.onAdd,
    required this.onDelete,
    required this.onRemark,
  });

  @override
  State<DynamicEquipmentCardExample> createState() =>
      _DynamicEquipmentCardExampleState();
}

class _DynamicEquipmentCardExampleState
    extends State<DynamicEquipmentCardExample> {
  bool _isEditMode = false;
  late EquipmentMaterial _draftMaterial;
  late FieldValues _fieldValues;
  late Map<String, String> _customLabels;

  @override
  void initState() {
    super.initState();
    _draftMaterial = widget.material.copyWith();
    _fieldValues = widget.material.fieldValues ?? FieldValues({});
    _customLabels = Map.from(widget.material.customLabels ?? {});
  }

  @override
  Widget build(BuildContext context) {
    // If MaterialSetup is provided, use dynamic rendering
    if (widget.materialSetup != null) {
      return _buildDynamicCard();
    }

    // Otherwise, fall back to legacy rendering
    return _buildLegacyCard();
  }

  /// Dynamic card using MaterialSetup and FieldConfig
  Widget _buildDynamicCard() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        // Focus first required field
        final firstRequired = widget.materialSetup!.fieldConfig.fields
            .firstWhere((f) => f.required, orElse: () => widget.materialSetup!.fieldConfig.fields.first);
        // Implement focus logic
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 8),

            // Dynamic field builder
            DynamicFieldBuilder(
              materialSetup: widget.materialSetup!,
              fieldValues: _fieldValues,
              onFieldValuesChanged: (newValues) {
                setState(() {
                  _fieldValues = newValues;
                });
                widget.onChanged(
                  widget.material.copyWith(fieldValues: newValues),
                );
              },
              isEditMode: _isEditMode,
              customLabels: _customLabels,
              onCustomLabelsChanged: (newLabels) {
                setState(() {
                  _customLabels = newLabels;
                });
                widget.onChanged(
                  widget.material.copyWith(customLabels: newLabels),
                );
              },
            ),

            const SizedBox(height: 8),

            // Quantity field (always visible)
            _buildQuantityField(),

            const SizedBox(height: 8),

            // Action buttons
            _buildActionRow(),

            // Save/Cancel in edit mode
            if (_isEditMode) ...[
              const SizedBox(height: 8),
              _buildEditActions(),
            ],
          ],
        ),
      ),
    );
  }

  /// Legacy card for backward compatibility
  Widget _buildLegacyCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 8),
          Text(
            'Legacy mode - MaterialSetup not provided',
            style: TextStyle(color: Colors.orange, fontSize: 12),
          ),
          const SizedBox(height: 8),
          _buildQuantityField(),
          const SizedBox(height: 8),
          _buildActionRow(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: _isEditMode
              ? TextFormField(
                  initialValue: _draftMaterial.name,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFD0EAFD),
                    hintText: "Enter Name",
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _draftMaterial = _draftMaterial.copyWith(name: val);
                    });
                  },
                )
              : Text(
                  widget.material.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: widget.onRemark,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFD0EAFD),
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Remark',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityField() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Qty",
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600),
              ),
              SizedBox(
                height: 40,
                child: TextFormField(
                  initialValue: widget.material.qty.toString(),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  onChanged: (val) {
                    final qty = int.tryParse(val) ?? 0;
                    widget.onChanged(widget.material.copyWith(qty: qty));
                  },
                  decoration: InputDecoration(
                    isCollapsed: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide:
                          const BorderSide(color: Colors.blue, width: 2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _actionBtn(Icons.edit, Colors.blue, () {
          setState(() {
            _isEditMode = !_isEditMode;
          });
        }),
        const SizedBox(width: 8),
        _actionBtn(Icons.copy, Colors.green, widget.onAdd),
        const SizedBox(width: 8),
        _actionBtn(Icons.delete_outline, Colors.red, widget.onDelete),
      ],
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      color: color,
      style: IconButton.styleFrom(
        padding: const EdgeInsets.all(6),
        minimumSize: const Size(32, 32),
        side: BorderSide(color: color, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  Widget _buildEditActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              widget.onChanged(_draftMaterial);
              setState(() {
                _isEditMode = false;
              });
            },
            child: const Text("Save"),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _draftMaterial = widget.material.copyWith();
                _isEditMode = false;
              });
            },
            child: const Text("Cancel"),
          ),
        ),
      ],
    );
  }
}

/// Example usage in a DPR screen
class DynamicDPRScreenExample extends StatefulWidget {
  final String siteId;

  const DynamicDPRScreenExample({super.key, required this.siteId});

  @override
  State<DynamicDPRScreenExample> createState() =>
      _DynamicDPRScreenExampleState();
}

class _DynamicDPRScreenExampleState extends State<DynamicDPRScreenExample> {
  List<MaterialSetup> _materialSetups = [];
  List<EquipmentMaterial> _selectedMaterials = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  Future<void> _loadMaterials() async {
    setState(() => _isLoading = true);

    try {
      // Import the sync service
      // final syncService = MaterialSyncService();
      
      // Fetch materials (offline-first)
      // final materials = await syncService.getMaterials(
      //   siteId: widget.siteId,
      //   designation: 'equipment',
      //   preferLocal: true,
      // );

      // For demo purposes, create mock data
      final materials = <MaterialSetup>[];

      setState(() {
        _materialSetups = materials;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading materials: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dynamic DPR - Equipment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMaterials,
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _selectedMaterials.length,
        itemBuilder: (context, index) {
          final material = _selectedMaterials[index];
          
          // Find corresponding MaterialSetup
          final setup = _materialSetups.firstWhere(
            (s) => s.materialCode == material.materialCode,
            orElse: () => _materialSetups.first,
          );

          return DynamicEquipmentCardExample(
            material: material,
            materialSetup: setup,
            onChanged: (updated) {
              setState(() {
                _selectedMaterials[index] = updated;
              });
            },
            onAdd: () {
              setState(() {
                _selectedMaterials.add(material.copyWith(
                  id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
                ));
              });
            },
            onDelete: () {
              setState(() {
                _selectedMaterials.removeAt(index);
              });
            },
            onRemark: () {
              // Show remark dialog
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show material selection dialog
          _showMaterialSelection();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showMaterialSelection() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          itemCount: _materialSetups.length,
          itemBuilder: (context, index) {
            final setup = _materialSetups[index];
            return ListTile(
              title: Text(setup.name),
              subtitle: Text(setup.materialCode),
              onTap: () {
                // Create new material from setup
                final newMaterial = EquipmentMaterial(
                  id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
                  name: setup.name,
                  image: setup.image,
                  uom: setup.uom,
                  materialCode: setup.materialCode,
                  fieldValues: FieldValues({}),
                );

                setState(() {
                  _selectedMaterials.add(newMaterial);
                });

                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }
}
