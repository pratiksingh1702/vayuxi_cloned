import 'package:flutter/material.dart';

class DynamicItemCard2 extends StatefulWidget {
  final String title;
  final String quantity;
  final String ton;
  final String meter; // UOM
  final String floor;
  final String moc;
  final String? size;
  final String? image;
  final String? remark;

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
    required this.quantity,
    required this.ton,
    required this.meter,
    required this.floor,
    required this.moc,
    this.size,

    this.image,
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

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
                child: Column(
                  children: [
                    if (widget.image != null && widget.image!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Image.asset(
                          widget.image!,
                          height: 100,
                          errorBuilder: (_, __, ___) =>
                          const Icon(Icons.image_not_supported),
                        ),
                      ),

                    if (widget.isEditable &&
                        (widget.onEdit != null ||
                            widget.onCopy != null ||
                            widget.onDelete != null))
                      Row(
                        children: [
                          if (widget.onEdit != null)
                            IconButton(
                              onPressed: widget.onEdit,
                              icon: const Icon(Icons.edit, size: 18),
                              color: Colors.blue,
                            ),
                          if (widget.onCopy != null)
                            IconButton(
                              onPressed: widget.onCopy,
                              icon: const Icon(Icons.copy, size: 18),
                              color: Colors.green,
                            ),
                          if (widget.onDelete != null)
                            IconButton(
                              onPressed: widget.onDelete,
                              icon: const Icon(Icons.delete, size: 18),
                              color: Colors.red,
                            ),
                        ],
                      ),
                  ],
                ),
              ),

              // RIGHT: INPUTS
              Flexible(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _blueBox('Floor', _floorCtrl)),
                        const SizedBox(width: 8),
                        Expanded(child: _blueBox('MOC', _mocCtrl)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _blueBox('Qty', _qtyCtrl)),
                        const SizedBox(width: 8),
                        Expanded(child: _blueBox('Ton', _tonCtrl)),
                      ],
                    ),
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
          height: 23,
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
                borderSide: BorderSide.none,
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
