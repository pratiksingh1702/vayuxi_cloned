import 'package:flutter/material.dart';

class DynamicItemCard extends StatelessWidget {
  final String quantity;
  final String size;
  final String length;
  final String floor;
  final String moc;
  final String? image;
  final String sizeLabel;
  final String lengthLabel;
  final String sizePlaceholder;
  final String lengthPlaceholder;
  final Function(String) onQtyChanged;
  final Function(String) onSizeChanged;
  final Function(String) onLengthChanged;
  final Function(String) onFloorChanged;
  final Function(String) onMocChanged;
  final VoidCallback onDelete;
  final VoidCallback onRemark;
  final VoidCallback onEdit;
  final VoidCallback onAdd;

  const DynamicItemCard({
    required this.quantity,
    required this.size,
    required this.length,
    required this.floor,
    required this.moc,
    this.image,
    required this.sizeLabel,
    required this.lengthLabel,
    required this.sizePlaceholder,
    required this.lengthPlaceholder,
    required this.onQtyChanged,
    required this.onSizeChanged,
    required this.onLengthChanged,
    required this.onFloorChanged,
    required this.onMocChanged,
    required this.onDelete,
    required this.onRemark,
    required this.onEdit,
    required this.onAdd,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(5),
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
                  lengthLabel,
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



                // Remark Button

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
                SizedBox(height: 10,),
                // 2x2 Grid of Blue Input Fields
                Row(
                  children: [
                    Expanded(child: _blueBox("Floor", floor, onFloorChanged)),
                    const SizedBox(width: 8),
                    Expanded(child: _blueBox("Size", size, onSizeChanged)),
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

                // Length Field with Label
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    _blueBox(lengthLabel, length, onLengthChanged),
                  ],
                ),


                // Action Buttons
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

  // ───────── Blue Input Field with White Hint Text
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