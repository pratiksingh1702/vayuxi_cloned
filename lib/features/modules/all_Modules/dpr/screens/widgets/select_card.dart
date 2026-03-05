import 'package:flutter/material.dart';

class SelectCard extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const SelectCard({
    super.key,
    required this.icon,
    this.color=Colors.black,
    required this.label,
    required this.onTap,
  });

  // Helper function to capitalize first letter
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;


    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 70,
                width: 70,
                child: Center(
                  child: icon,

                ),
              ),

              const SizedBox(height: 12),

              Text(
                _capitalize(label), // Capitalize first letter here
                textAlign: TextAlign.center,
                style: TextStyle(

                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}