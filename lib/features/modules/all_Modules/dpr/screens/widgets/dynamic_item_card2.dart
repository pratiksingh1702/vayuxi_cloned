import 'package:flutter/material.dart';

import '../../../../../../core/utlis/widgets/image.dart';
import '../../models/rate_file_models.dart';


// ─── PATCH 2: Updated DynamicItemCard2 with full edit mode support ─────────────
// Replace the entire DynamicItemCard2 file with the version below.

import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../../../core/utlis/widgets/file_upload.dart';
import '../../../../../../core/utlis/widgets/image.dart';
import '../../models/dprModel.dart';
import '../../models/rate_file_models.dart';

class DynamicItemCard2 extends StatefulWidget {
  final String title;
  final String quantity;
  final String ton;
  final String meter;
  final String floor;
  final String moc;
  final String? size;
  final String image;
  final String? remark;
  final bool isDpr;
  final bool isEditMode;
  final bool isEditable;
  final List<DynamicField> fields;
  final Function(String key, String value) onChanged;
  final Function(MaterialEditResult)? onSave;
  final VoidCallback? onCancel;

  final Function(String) onQtyChanged;
  final Function(String) onMeterChanged;
  final Function(String) onTonChanged;
  final Function(String) onFloorChanged;
  final Function(String) onMocChanged;
  final Function(String)? onUomChanged;

  final VoidCallback onRemark;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onCopy;
  final VoidCallback? onAdd;

  const DynamicItemCard2({
    super.key,
    required this.title,
    this.onUomChanged,
    required this.fields,
    required this.onChanged,
    required this.quantity,
    required this.ton,
    required this.meter,
    required this.floor,
    required this.moc,
    this.size,
    required this.image,
    this.remark,
    this.isDpr = true,
    this.isEditMode = false,
    required this.isEditable,
    this.onSave,
    this.onCancel,
    required this.onMeterChanged,
    required this.onQtyChanged,
    required this.onTonChanged,
    required this.onFloorChanged,
    required this.onMocChanged,
    required this.onRemark,
    this.onEdit,
    this.onDelete,
    this.onCopy,
    this.onAdd,
  });

  @override
  State<DynamicItemCard2> createState() => _DynamicItemCard2State();
}

class _DynamicItemCard2State extends State<DynamicItemCard2>
    with AutomaticKeepAliveClientMixin {
  late TextEditingController _qtyCtrl;
  late TextEditingController _tonCtrl;
  late TextEditingController _floorCtrl;
  late TextEditingController _mocCtrl;
  final Map<String, TextEditingController> _controllers = {};
  late TextEditingController _uomCtrl;

  // Edit-mode draft state
  late String draftName;
  late String draftUom;
  late List<DynamicField> draftFields;
  File? draftImageFile;
  String? draftImageUrl;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initDraft();
    _uomCtrl = TextEditingController(text: '');
    _uomCtrl.addListener(() {
      widget.onMeterChanged(_uomCtrl.text);
    });
    _qtyCtrl = TextEditingController(text: widget.quantity);
    _tonCtrl = TextEditingController(text: widget.ton);
    _floorCtrl = TextEditingController(text: widget.floor);
    _mocCtrl = TextEditingController(text: widget.moc);

    for (final f in widget.fields) {
      _controllers[f.key] = TextEditingController(text: f.displayText);
    }

    _qtyCtrl.addListener(() {
      if (_qtyCtrl.text != widget.quantity) widget.onQtyChanged(_qtyCtrl.text);
    });
    _tonCtrl.addListener(() {
      if (_tonCtrl.text != widget.ton) widget.onTonChanged(_tonCtrl.text);
    });
    _floorCtrl.addListener(() {
      if (_floorCtrl.text != widget.floor) widget.onFloorChanged(_floorCtrl.text);
    });
    _mocCtrl.addListener(() {
      if (_mocCtrl.text != widget.moc) widget.onMocChanged(_mocCtrl.text);
    });
  }

  void _initDraft() {
    draftName = widget.title;
    draftUom = widget.meter;
    draftImageUrl = widget.image;
    draftImageFile = null;
    draftFields = widget.fields.map((e) => e.copy()).toList();
  }

  @override
  void didUpdateWidget(DynamicItemCard2 oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reset draft when entering edit mode
    if (widget.isEditMode && !oldWidget.isEditMode) {
      _initDraft();
    }

    if (widget.image != oldWidget.image) {
      draftImageUrl = widget.image;
      draftImageFile = null;
    }

    if (widget.quantity != _qtyCtrl.text) _qtyCtrl.text = widget.quantity;
    if (widget.ton != _tonCtrl.text) _tonCtrl.text = widget.ton;
    if (widget.floor != _floorCtrl.text) _floorCtrl.text = widget.floor;
    if (widget.moc != _mocCtrl.text) _mocCtrl.text = widget.moc;
  }

  // ── Dynamic field rows ──────────────────────────────────────────────────────

  Widget _buildDynamicFields() {
    final items = widget.isEditMode ? draftFields : widget.fields;
    if (items.isEmpty) return const SizedBox();

    final rows = <Widget>[];
    for (int i = 0; i < items.length; i += 2) {
      rows.add(Row(
        children: [
          Expanded(
            child: widget.isEditMode
                ? _editFieldTile(i)
                : _viewFieldTile(items[i]),
          ),
          const SizedBox(width: 8),
          if (i + 1 < items.length)
            Expanded(
              child: widget.isEditMode
                  ? _editFieldTile(i + 1)
                  : _viewFieldTile(items[i + 1]),
            )
          else
            const Expanded(child: SizedBox()),
        ],
      ));
      rows.add(const SizedBox(height: 8));
    }
    return Column(children: rows);
  }

  Widget _viewFieldTile(DynamicField field) {
    final controller = _controllers.putIfAbsent(
      field.key,
          () => TextEditingController(text: field.displayText),
    );
    return _updatedblueBox(
      label: field.label,
      controller: controller,
      unit: field.unit,
      keyName: field.key,
    );
  }

  Widget _editFieldTile(int index) {
    final field = draftFields[index];
    final valueController = _controllers.putIfAbsent(
      field.key,
          () => TextEditingController(text: field.displayText),
    );
    final labelController = TextEditingController(text: field.label);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 22,
          child: TextFormField(
            controller: labelController,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: "Label",
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 2),
              filled: true,
              fillColor: const Color(0xFFD0EAFD),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
            onChanged: (v) {
              setState(() => draftFields[index] = field.copyWith(label: v));
            },
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 23,
          child: TextFormField(
            controller: valueController,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: "Value",
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              filled: true,
              fillColor: const Color(0xFFD0EAFD),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(fontSize: 8),
            onChanged: (v) {
              setState(() => draftFields[index] = field.copyWith(displayText: v));
            },
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () => setState(() => draftFields.removeAt(index)),
            child: const Icon(Icons.delete, size: 14, color: Colors.red),
          ),
        ),
      ],
    );
  }

  // ── Smart image helper ──────────────────────────────────────────────────────

  Widget _buildSmartImage({
    String? imageUrl,
    File? imageFile,
    double height = 120,
  }) {
    if (imageFile != null) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: Image.file(imageFile, fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _imgPlaceholder(height)),
      );
    }
    if (imageUrl == null || imageUrl.isEmpty) return _imgPlaceholder(height);
    final isNet =
        imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
    return SizedBox(
      height: height,
      width: double.infinity,
      child: isNet
          ? Image.network(imageUrl, fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _imgPlaceholder(height))
          : Image.asset(imageUrl, fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _imgPlaceholder(height)),
    );
  }

  Widget _imgPlaceholder(double height) => Container(
    height: height,
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(8),
    ),
    child:
    const Icon(Icons.image_not_supported, color: Colors.grey, size: 32),
  );

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
        ),
      ),
      child: Column(
        children: [
          // ── HEADER ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 260),
                child: widget.isEditMode
                    ? TextFormField(
                  initialValue: draftName,
                  onChanged: (v) => draftName = v,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                )
                    : Text(
                  widget.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: widget.onRemark,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 50),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD0EAFD),
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.remark?.isNotEmpty == true
                            ? widget.remark!
                            : 'Remark',
                        style: const TextStyle(
                            fontSize: 9, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── BODY ──
          Row(
            children: [
              // LEFT: image + actions
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),

                      // Change image button (edit mode only)
                      if (widget.isEditMode)
                        TextButton.icon(
                          onPressed: () async {
                            final helper = ImageUploadHelper(context);
                            final file = await helper.pickAndCropImage(
                              enableCropping: true,
                              cropTitle: "Crop Material Image",
                            );
                            if (file != null) {
                              setState(() {
                                draftImageFile = file;
                                draftImageUrl = null;
                              });
                            }
                          },
                          icon: const Icon(Icons.photo),
                          label: const Text("Change"),
                        ),

                      _buildSmartImage(
                        imageFile: widget.isEditMode ? draftImageFile : null,
                        imageUrl:
                        widget.isEditMode ? draftImageUrl : widget.image,
                      ),

                      // Action buttons
                      if (widget.isEditable &&
                          (widget.onEdit != null ||
                              widget.onCopy != null ||
                              widget.onDelete != null))
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            children: [
                              if (widget.onEdit != null) ...[
                                Expanded(
                                  child: IconButton(
                                    onPressed: widget.onEdit,
                                    icon: const Icon(Icons.edit, size: 18),
                                    color: Colors.blue,
                                    style: IconButton.styleFrom(
                                      padding: const EdgeInsets.all(6),
                                      minimumSize: const Size(0, 32),
                                      side: const BorderSide(
                                          color: Colors.blue, width: 1.5),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(6)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              if (widget.onCopy != null) ...[
                                Expanded(
                                  child: IconButton(
                                    onPressed: widget.onCopy,
                                    icon: const Icon(Icons.copy, size: 18),
                                    color: Colors.green,
                                    style: IconButton.styleFrom(
                                      padding: const EdgeInsets.all(6),
                                      minimumSize: const Size(0, 32),
                                      side: const BorderSide(
                                          color: Colors.green, width: 1.5),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(6)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              if (widget.onDelete != null)
                                Expanded(
                                  child: IconButton(
                                    onPressed: widget.onDelete,
                                    icon: const Icon(Icons.delete, size: 18),
                                    color: Colors.red,
                                    style: IconButton.styleFrom(
                                      padding: const EdgeInsets.all(6),
                                      minimumSize: const Size(0, 32),
                                      side: const BorderSide(
                                          color: Colors.red, width: 1.5),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(6)),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // RIGHT: fields + UOM
              Flexible(
                child: Column(
                  children: [
                    _buildDynamicFields(),

                    // Add field button (edit mode)
                    if (widget.isEditMode)
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            draftFields.add(DynamicField(
                              key: DateTime.now()
                                  .millisecondsSinceEpoch
                                  .toString(),
                              label: "New Field",
                              unit: "",
                              displayText: "",
                            ));
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text("Add Field"),
                      ),

                    const SizedBox(height: 12),

                    // UOM
                    widget.isEditMode
                        ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: TextFormField(
                        initialValue: draftUom,
                        decoration: const InputDecoration(
                            labelText: "UOM",
                            border: OutlineInputBorder()),
                        onChanged: (v) => draftUom = v,
                      ),
                    )
                        : _buildUomField()// 👈 use the stored controller

                  ],
                ),
              ),
            ],
          ),

          // ── SAVE / CANCEL (edit mode only) ──
          if (widget.isEditMode)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onCancel,
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onSave?.call(MaterialEditResult(
                          name: draftName,
                          imageFile: draftImageFile,
                          imageUrl: draftImageUrl,
                          uom: draftUom,
                          fields: draftFields,
                        ));
                      },
                      child: const Text("Save"),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  Widget _buildUomField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'UOM',
          style: TextStyle(
            fontSize: 11, // bigger label
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 40, // bigger height
          child: TextFormField(
            controller: _uomCtrl,
            enabled: widget.isEditable,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12, // bigger text
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white, // ✅ white background
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.black, width: 1.2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.black, width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.blue, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
  Widget _updatedblueBox({
    required String label,
    required TextEditingController controller,
    required String keyName,
    String unit = '',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            unit.isEmpty ? label : "$label ($unit)",
            style: const TextStyle(
                fontSize: 9, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        ),
        SizedBox(
          height: 23,
          child: TextFormField(
            key: ValueKey(keyName),
            controller: controller,
            onChanged: (v) => widget.onChanged(keyName, v),
            textAlign: TextAlign.center,
            enabled: widget.isEditable,
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
              const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              filled: true,
              fillColor: widget.isEditable
                  ? const Color(0xFFD0EAFD)
                  : Colors.grey[300],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(fontSize: 8),
          ),
        ),
      ],
    );
  }

  Widget _blueBox(
      String label,
      TextEditingController controller, {
        bool enabled = true,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        SizedBox(
          height: !enabled ? 60 : 23,
          child: TextFormField(
            controller: controller,
            enabled: widget.isEditable && enabled,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 8),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: widget.isEditable && enabled
                  ? const Color(0xFFD0EAFD)
                  : Colors.grey[300],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: Colors.black),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _tonCtrl.dispose();
    _floorCtrl.dispose();
    _mocCtrl.dispose();
    _uomCtrl.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }
}