import 'package:flutter/material.dart';

class DynamicItemCard2 extends StatelessWidget {
  final String title;
  final String quantity;
  final String? image;
  final String moc;
  final String floor;
  final String ton;
  final String meter;
  final VoidCallback onAdd;
  final VoidCallback onEdit;
  final Function(String) onMocChanged;
  final VoidCallback onDelete;
  final VoidCallback onRemark;
  final Function(String) onQtyChanged;
  final Function(String) onFloorChanged;
  final Function(String) onTonChanged;

  const DynamicItemCard2({
    required this.title,
    required this.quantity,
    this.image,
    required this.moc,
    required this.floor,
    required this.ton,
    required this.meter,
    required this.onAdd,
    required this.onEdit,
    required this.onMocChanged,
    required this.onDelete,
    required this.onRemark,
    required this.onQtyChanged,
    required this.onFloorChanged,
    required this.onTonChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ───────── LEFT COLUMN (50% width) - NAME & IMAGE
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Material Name
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Image
                if (image != null)
                  Image.network(
                    image!,
                    height: 200,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.image, color: Colors.grey),
                      );
                    },
                  ),
              ],
            ),
          ),

          // ───────── RIGHT COLUMN (50% width) - INPUT FIELDS
          Expanded(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: InkWell(
                    onTap: onRemark,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xffd9ecff),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "Remark",
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 2x2 Grid of Blue Input Fields
                Row(
                  children: [
                    Expanded(child: _blueBox("Floor", floor, onFloorChanged)),
                    const SizedBox(width: 8),
                    Expanded(child: _blueBox("Ton", ton, onTonChanged)),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(child: _blueBox("MOC", moc, onMocChanged)),
                    const SizedBox(width: 8),
                    Expanded(child: _blueBox("NOS", quantity, onQtyChanged)),
                  ],
                ),
                const SizedBox(height: 12),

                // Meter Field with Label
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _blueBox("Meter", meter, (val) {}), // Read-only
                  ],
                ),

                // Action Buttons (commented out like in DynamicItemCard)
                // Row(
                //   children: [
                //     Expanded(
                //       child: ElevatedButton.icon(
                //         onPressed: onAdd,
                //         icon: const Icon(Icons.copy, size: 16),
                //         label: const Text("Copy"),
                //         style: ElevatedButton.styleFrom(
                //           backgroundColor: Colors.green,
                //           foregroundColor: Colors.white,
                //           padding: const EdgeInsets.symmetric(vertical: 8),
                //         ),
                //       ),
                //     ),
                //     const SizedBox(width: 8),
                //     Expanded(
                //       child: ElevatedButton.icon(
                //         onPressed: onEdit,
                //         icon: const Icon(Icons.edit, size: 16),
                //         label: const Text("Edit"),
                //         style: ElevatedButton.styleFrom(
                //           backgroundColor: Colors.blue,
                //           foregroundColor: Colors.white,
                //           padding: const EdgeInsets.symmetric(vertical: 8),
                //         ),
                //       ),
                //     ),
                //     const SizedBox(width: 8),
                //     IconButton(
                //       onPressed: onDelete,
                //       icon: const Icon(Icons.delete, color: Colors.red),
                //     ),
                //   ],
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────── Blue Input Field with White Hint Text (exact same as DynamicItemCard)
  Widget _blueBox(String hintText, String value, Function(String) onChanged) {
    return TextField(
      controller: TextEditingController(text: value),
      onChanged: onChanged,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.white, fontSize: 14),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey),
      ),
    );
  }
}