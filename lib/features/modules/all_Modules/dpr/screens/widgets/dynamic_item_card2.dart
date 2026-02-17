import 'package:flutter/material.dart';

import '../../../../../../core/utlis/widgets/image.dart';
import '../../models/rate_file_models.dart';

class DynamicItemCard2 extends StatefulWidget {
  final String title;
  final String quantity;
  final String ton;
  final String meter; // UOM
  final String floor;
  final String moc;
  final String? size;
  final String image;
  final String? remark;
  final List<DynamicField> fields;
  final Function(String key, String value) onChanged;


  final Function(String) onQtyChanged;
  final Function(String) onMeterChanged;
  final Function(String) onTonChanged;
  final Function(String) onFloorChanged;
  final Function(String) onMocChanged;

  final VoidCallback onRemark;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onCopy;
  final VoidCallback? onAdd;

  final bool isEditable;

  const DynamicItemCard2({
    super.key,
    required this.title,
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
    required this.isEditable,
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


  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(text: widget.quantity);
    _tonCtrl = TextEditingController(text: widget.ton);
    _floorCtrl = TextEditingController(text: widget.floor);
    _mocCtrl = TextEditingController(text: widget.moc);

    _qtyCtrl.addListener(() {
      if (_qtyCtrl.text != widget.quantity) {
        widget.onQtyChanged(_qtyCtrl.text);
      }
    });
    for (final f in widget.fields) {
      _controllers[f.key] =
          TextEditingController(text: f.displayText);
    }


    _tonCtrl.addListener(() {
      if (_tonCtrl.text != widget.ton) {
        widget.onTonChanged(_tonCtrl.text);
      }
    });

    _floorCtrl.addListener(() {
      if (_floorCtrl.text != widget.floor) {
        widget.onFloorChanged(_floorCtrl.text);
      }
    });

    _mocCtrl.addListener(() {
      if (_mocCtrl.text != widget.moc) {
        widget.onMocChanged(_mocCtrl.text);
      }
    });
  }

  @override
  void didUpdateWidget(DynamicItemCard2 oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.quantity != _qtyCtrl.text) _qtyCtrl.text = widget.quantity;
    if (widget.ton != _tonCtrl.text) _tonCtrl.text = widget.ton;
    if (widget.floor != _floorCtrl.text) _floorCtrl.text = widget.floor;
    if (widget.moc != _mocCtrl.text) _mocCtrl.text = widget.moc;
  }
  Widget _buildDynamicFields() {
    final items = widget.fields;
    if (items.isEmpty) return const SizedBox();

    final rows = <Widget>[];

    for (int i = 0; i < items.length; i += 2) {
      rows.add(
        Row(
          children: [
            Expanded(
              child: _updatedblueBox(
                label: items[i].label,
                controller: _controllers.putIfAbsent(
                  items[i].key,
                      () => TextEditingController(),
                ),
                unit: items[i].unit,
                keyName: items[i].key,
              ),
            ),
            const SizedBox(width: 8),
            if (i + 1 < items.length)
              Expanded(
                child: _updatedblueBox(
                  label: items[i + 1].label,
                  controller: _controllers.putIfAbsent(
                    items[i + 1].key,
                        () => TextEditingController(),
                  ),
                  unit: items[i + 1].unit,
                  keyName: items[i + 1].key,
                ),
              )
            else
              const Expanded(child: SizedBox()),
          ],
        ),
      );

      rows.add(const SizedBox(height: 8));
    }

    return Column(children: rows);
  }
  Widget _updatedblueBox({
    required String label,
    required TextEditingController controller,
    required String keyName,
    String unit = '',
  }) {
    final shouldShowHint = label.toLowerCase() == "qty";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            unit.isEmpty ? label : "$label ($unit)",
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
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
              hintText: shouldShowHint ? "Enter quantity" : "",
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
          // HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 260,
                child: Text(
                  widget.title,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,

                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: widget.onRemark,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: 50, // Adjust this value as needed
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD0EAFD),
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.remark?.isNotEmpty == true ? widget.remark! : 'Remark',
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
              )

            ],
          ),

          Row(
            children: [
              // LEFT: IMAGE + ACTIONS
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [

                        buildSmartImage(image: widget.image),

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
                                      side: const BorderSide(color: Colors.blue, width: 1.5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
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
                                      side: const BorderSide(color: Colors.green, width: 1.5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
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
                                      side: const BorderSide(color: Colors.red, width: 1.5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
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

              // RIGHT: INPUTS
              Flexible(
                child: Column(
                  children: [
                    _buildDynamicFields(),

                    const SizedBox(height: 12),
                    _blueBox(
                      'UOM (${widget.meter})',
                      TextEditingController(text: widget.meter),
                      enabled: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
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
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600)),
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
              fillColor:
              widget.isEditable && enabled ? const Color(0xFFD0EAFD) : Colors.grey[300],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(
                  color: Colors.black,
                ),

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
    super.dispose();
  }
}
