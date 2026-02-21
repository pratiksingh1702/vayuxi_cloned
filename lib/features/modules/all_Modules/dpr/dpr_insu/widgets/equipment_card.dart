import 'package:flutter/material.dart';
import '../../../../../../core/utlis/widgets/image.dart';
import '../model/eqip_insu.dart';
import 'config/equipment_config.dart';

class EquipmentMaterialCard extends StatefulWidget {
  final EquipmentMaterial material;
  final ValueChanged<EquipmentMaterial> onChanged;
  final VoidCallback onAdd;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRemark;

  const EquipmentMaterialCard({
    super.key,
    required this.material,
    required this.onChanged,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onRemark,
  });

  @override
  State<EquipmentMaterialCard> createState() => _EquipmentMaterialCardState();
}

class _EquipmentMaterialCardState extends State<EquipmentMaterialCard> {
  final Map<EquipmentFieldType, FocusNode> _focusNodes = {
    EquipmentFieldType.qty: FocusNode(),
    EquipmentFieldType.length: FocusNode(),
    EquipmentFieldType.circumference: FocusNode(),
    EquipmentFieldType.circumference1: FocusNode(),
    EquipmentFieldType.circumference2: FocusNode(),
    EquipmentFieldType.circumference3: FocusNode(),
    EquipmentFieldType.zHeight: FocusNode(),
  };
  void _focusMainField(List<EquipmentFieldConfig> fields) {
    // Priority order for focus:
    // length -> qty -> zHeight -> circumference -> others
    final order = [
      EquipmentFieldType.length,
      EquipmentFieldType.qty,
      EquipmentFieldType.zHeight,
      EquipmentFieldType.circumference,
      EquipmentFieldType.circumference1,
      EquipmentFieldType.circumference2,
      EquipmentFieldType.circumference3,
    ];

    for (final type in order) {
      if (fields.any((f) => f.type == type)) {
        _focusNodes[type]!.requestFocus();
        return;
      }
    }
  }


  @override
  void dispose() {
    for (final n in _focusNodes.values) {
      n.dispose();
    }
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final key = _resolveConfigKey(widget.material.name);
    final fields = equipmentFieldConfig[key]!;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => _focusMainField(fields),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF2),

          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            const SizedBox(height: 8),

            Column(
              children: fields.map((field) {
                final imageUrl = widget.material.image.length > field.imageIndex
                    ? widget.material.image[field.imageIndex]
                    : null;

                return _fieldCard(
                  field: field,
                  imageUrl: imageUrl,
                );
              }).toList(),
            ),

            const SizedBox(height: 6),

            // 🔥 ACTION BUTTONS — BOTTOM LEFT
            _actionRow(),
          ],
        ),
      ),
    );
  }
  Widget _actionRow() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {}, // ✅ blocks parent
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _actionBtn(Icons.edit, Colors.blue, widget.onEdit),
          const SizedBox(width: 8),
          _actionBtn(Icons.copy, Colors.green, widget.onAdd),
          const SizedBox(width: 8),
          _actionBtn(Icons.delete, Colors.red, widget.onDelete),
        ],
      ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
  Widget _fieldCard({
    required EquipmentFieldConfig field,
    String? imageUrl,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _focusNodes[field.type]?.requestFocus();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 110,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    field.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (imageUrl != null)
                    buildSmartImage(
                      image: imageUrl,
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: _blueField(field)),
          ],
        ),
      ),
    );
  }


  // --------------------------------------------------
  // HEADER
  // --------------------------------------------------

  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          widget.material.name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
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

  // --------------------------------------------------
  // IMAGE + FIELD MINI CARD (CARD INSIDE CARD)
  // --------------------------------------------------

  Widget _imageFieldCard({
    required String imageUrl,
    required EquipmentFieldConfig field,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          buildSmartImage(
            image: imageUrl,
            height: 90,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 6),
          Text(
            field.label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // FIELD (BLUE DESIGN)
  // --------------------------------------------------

  Widget _blueField(EquipmentFieldConfig config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const SizedBox(height: 6),
        SizedBox(
          height: 36,
          child: TextFormField(
            focusNode: _focusNodes[config.type],
            initialValue: _getValue(config).toString(),
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFD0EAFD),
              suffixText: _unitFor(config.type),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 6,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) {
              final v = double.tryParse(val) ?? 0;
              widget.onChanged(_updateMaterial(config, v));
            },
          ),
        ),
      ],
    );
  }


  // --------------------------------------------------
  // VALUE LOGIC (UNCHANGED)
  // --------------------------------------------------

  double _getValue(EquipmentFieldConfig config) {
    switch (config.type) {
      case EquipmentFieldType.qty:
        return widget.material.qty.toDouble();
      case EquipmentFieldType.length:
        return widget.material.length;
      case EquipmentFieldType.circumference:
        return widget.material.circumference;
      case EquipmentFieldType.circumference1:
        return widget.material.circumference1;
      case EquipmentFieldType.circumference2:
        return widget.material.circumference2;
      case EquipmentFieldType.circumference3:
        return widget.material.circumference3;
      case EquipmentFieldType.zHeight:
        return widget.material.zHeight;
    }
  }

  EquipmentMaterial _updateMaterial(
      EquipmentFieldConfig config,
      double value,
      ) {
    switch (config.type) {
      case EquipmentFieldType.qty:
        return widget.material.copyWith(qty: value.toInt());
      case EquipmentFieldType.length:
        return widget.material.copyWith(length: value);
      case EquipmentFieldType.circumference:
        return widget.material.copyWith(circumference: value);
      case EquipmentFieldType.circumference1:
        return widget.material.copyWith(circumference1: value);
      case EquipmentFieldType.circumference2:
        return widget.material.copyWith(circumference2: value);
      case EquipmentFieldType.circumference3:
        return widget.material.copyWith(circumference3: value);
      case EquipmentFieldType.zHeight:
        return widget.material.copyWith(zHeight: value);
    }
  }

  String _resolveConfigKey(String name) {
    final upper = name.toUpperCase().replaceAll(RegExp(r'\s*\(COPY\)'), '');
    return equipmentFieldConfig.keys.firstWhere(
          (k) => upper.startsWith(k),
      orElse: () => 'DEFAULT',
    );
  }

  String _unitFor(EquipmentFieldType type) {
    return type == EquipmentFieldType.qty ? 'NOS' : 'mm';
  }
}
