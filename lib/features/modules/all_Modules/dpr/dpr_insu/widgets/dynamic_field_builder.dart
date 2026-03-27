import 'dart:io';
import 'package:flutter/material.dart';
import '../model/field_config.dart';
import '../model/material_setup.dart';

class DynamicFieldBuilder extends StatefulWidget {
  final MaterialSetup materialSetup;
  final FieldValues fieldValues;
  final ValueChanged<FieldValues> onFieldValuesChanged;
  final bool isEditMode;
  final Map<String, String>? customLabels;
  final ValueChanged<Map<String, String>>? onCustomLabelsChanged;

  const DynamicFieldBuilder({
    super.key,
    required this.materialSetup,
    required this.fieldValues,
    required this.onFieldValuesChanged,
    this.isEditMode = false,
    this.customLabels,
    this.onCustomLabelsChanged,
  });

  @override
  State<DynamicFieldBuilder> createState() => _DynamicFieldBuilderState();
}

class _DynamicFieldBuilderState extends State<DynamicFieldBuilder> {
  final Map<String, TextEditingController> _valueControllers = {};
  final Map<String, TextEditingController> _labelControllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  
  late FieldValues _localFieldValues;
  late Map<String, String> _localCustomLabels;

  @override
  void initState() {
    super.initState();
    _localFieldValues = FieldValues(Map.from(widget.fieldValues.values));
    _localCustomLabels = Map.from(widget.customLabels ?? {});
    _initControllers();
  }

  void _initControllers() {
    for (final field in widget.materialSetup.fieldConfig.fields) {
      // Value controller
      final value = _localFieldValues[field.key];
      _valueControllers[field.key] = TextEditingController(
        text: value?.toString() ?? '',
      );

      // Label controller (for edit mode)
      final customLabel = _localCustomLabels[field.key] ?? field.label;
      _labelControllers[field.key] = TextEditingController(text: customLabel);

      // Focus node
      _focusNodes[field.key] = FocusNode();
    }
  }

  @override
  void dispose() {
    for (final controller in _valueControllers.values) {
      controller.dispose();
    }
    for (final controller in _labelControllers.values) {
      controller.dispose();
    }
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  bool _isFieldVisible(FieldDefinition field) {
    if (field.visibleWhen == null) return true;

    // Check geometry mode visibility
    if (field.visibleWhen!.geometryMode != null) {
      final currentMode = _localFieldValues['geometryMode'];
      return currentMode == field.visibleWhen!.geometryMode;
    }

    return true;
  }

  Widget _buildField(FieldDefinition field) {
    if (!_isFieldVisible(field)) {
      return const SizedBox.shrink();
    }

    final customLabel = _localCustomLabels[field.key] ?? field.label;
    final hasDropdown = field.dropdown != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          _buildLabel(field, customLabel),
          const SizedBox(height: 6),

          // Input field with optional dropdown
          Row(
            children: [
              Expanded(
                child: _buildInputField(field),
              ),
              if (hasDropdown && !widget.isEditMode) ...[
                const SizedBox(width: 8),
                _buildUnitDropdown(field),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(FieldDefinition field, String customLabel) {
    if (widget.isEditMode && widget.materialSetup.fieldConfig.ui.allowRename) {
      return SizedBox(
        height: 28,
        child: TextFormField(
          controller: _labelControllers[field.key],
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: const Color(0xFFD0EAFD),
            hintText: "Enter Label",
            hintStyle: const TextStyle(fontSize: 11, color: Colors.black54),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (val) {
            _localCustomLabels[field.key] = val;
            widget.onCustomLabelsChanged?.call(_localCustomLabels);
          },
        ),
      );
    }

    return Text(
      customLabel,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildInputField(FieldDefinition field) {
    if (widget.isEditMode) {
      // In edit mode, show current value as read-only
      final value = _localFieldValues[field.key];
      return Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          value?.toString() ?? '0',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
      );
    }

    return TextFormField(
      controller: _valueControllers[field.key],
      focusNode: _focusNodes[field.key],
      keyboardType: field.type == 'NUMBER'
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFD0EAFD),
        hintText: field.required ? 'Required' : 'Optional',
        hintStyle: const TextStyle(fontSize: 11, color: Colors.black38),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
      ),
      validator: field.required
          ? (value) => (value?.isEmpty ?? true) ? 'Required' : null
          : null,
      onChanged: (val) {
        if (field.type == 'NUMBER') {
          final numValue = num.tryParse(val);
          if (numValue != null) {
            _localFieldValues[field.key] = numValue;
            widget.onFieldValuesChanged(_localFieldValues);
          }
        } else {
          _localFieldValues[field.key] = val;
          widget.onFieldValuesChanged(_localFieldValues);
        }
      },
    );
  }

  Widget _buildUnitDropdown(FieldDefinition field) {
    final dropdownKey = field.dropdown!;
    final unitDropdowns = widget.materialSetup.fieldConfig.unitDropdowns.toJson();
    final options = unitDropdowns[dropdownKey] as List?;

    if (options == null || options.isEmpty) {
      return const SizedBox.shrink();
    }

    final unitKey = '${field.key}Uom';
    final currentUnit = _localFieldValues[unitKey]?.toString() ??
        widget.materialSetup.fieldConfig.defaults.toJson()[dropdownKey]?.toString() ??
        options.first.toString();

    return Container(
      width: 80,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentUnit,
          isExpanded: true,
          isDense: true,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          items: options.map((opt) {
            return DropdownMenuItem<String>(
              value: opt.toString(),
              child: Text(opt.toString()),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _localFieldValues[unitKey] = value;
                widget.onFieldValuesChanged(_localFieldValues);
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildGeometryModeSwitch() {
    final geometryField = widget.materialSetup.fieldConfig.fields.firstWhere(
      (f) => f.key == 'geometryMode',
      orElse: () => FieldDefinition(
        key: '',
        label: '',
        role: '',
        type: '',
        required: false,
      ),
    );

    if (geometryField.key.isEmpty) return const SizedBox.shrink();

    final currentMode = _localFieldValues['geometryMode']?.toString() ?? 'DIAMETER';
    final options = widget.materialSetup.fieldConfig.unitDropdowns.geometryMode ?? [];

    if (options.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: options.map((mode) {
          final isSelected = currentMode == mode;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton(
                onPressed: widget.isEditMode
                    ? null
                    : () {
                        setState(() {
                          _localFieldValues['geometryMode'] = mode;
                          widget.onFieldValuesChanged(_localFieldValues);
                        });
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected ? Colors.blue : Colors.grey.shade200,
                  foregroundColor: isSelected ? Colors.white : Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  mode,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasGeometrySwitch = widget.materialSetup.fieldConfig.ui.allowGeometrySwitch;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Geometry mode switch (for SHELL material)
        if (hasGeometrySwitch) _buildGeometryModeSwitch(),

        // Dynamic fields
        ...widget.materialSetup.fieldConfig.fields
            .where((f) => f.key != 'geometryMode')
            .map(_buildField)
            .toList(),
      ],
    );
  }
}

/// Helper widget for rendering a single dynamic field in a compact card style
class DynamicFieldCard extends StatelessWidget {
  final FieldDefinition field;
  final dynamic value;
  final String? unit;
  final ValueChanged<dynamic>? onChanged;
  final bool isEditMode;
  final String? imageUrl;
  final File? imageFile;
  final VoidCallback? onImageChange;

  const DynamicFieldCard({
    super.key,
    required this.field,
    this.value,
    this.unit,
    this.onChanged,
    this.isEditMode = false,
    this.imageUrl,
    this.imageFile,
    this.onImageChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Image section (if provided)
          if (imageUrl != null || imageFile != null)
            SizedBox(
              width: 120,
              child: Column(
                children: [
                  if (isEditMode && onImageChange != null)
                    TextButton.icon(
                      onPressed: onImageChange,
                      icon: const Icon(Icons.photo, size: 14),
                      label: const Text("Change", style: TextStyle(fontSize: 12)),
                    ),
                  _buildImage(),
                  const SizedBox(height: 6),
                  Text(
                    field.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

          if (imageUrl != null || imageFile != null) const SizedBox(width: 8),

          // Value section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (unit != null)
                  Text(
                    unit!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (unit != null) const SizedBox(height: 6),
                TextFormField(
                  initialValue: value?.toString() ?? '',
                  enabled: !isEditMode,
                  textAlign: TextAlign.center,
                  keyboardType: field.type == 'NUMBER'
                      ? const TextInputType.numberWithOptions(decimal: true)
                      : TextInputType.text,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: isEditMode ? Colors.grey.shade100 : const Color(0xFFD0EAFD),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (imageFile != null) {
      return Image.file(imageFile!, height: 80, fit: BoxFit.contain);
    }
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      if (imageUrl!.startsWith('http')) {
        return Image.network(imageUrl!, height: 80, fit: BoxFit.contain);
      }
      return Image.file(File(imageUrl!), height: 80, fit: BoxFit.contain);
    }
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 32),
    );
  }
}
