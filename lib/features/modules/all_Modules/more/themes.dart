import 'package:flutter/material.dart';
import 'package:untitled2/core/utlis/widgets/image_clipped.dart';

class ThemeSettingsPage extends StatefulWidget {
  const ThemeSettingsPage({super.key});

  @override
  State<ThemeSettingsPage> createState() => _ThemeSettingsPageState();
}

class _ThemeSettingsPageState extends State<ThemeSettingsPage> {
  bool isDark = false;
  Color accentColor = Colors.blue;

  final List<Color> accentOptions = [
    Colors.blue,
    Colors.purple,
    Colors.red,
    Colors.orange,
    Colors.green,
    Colors.teal,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text("Theme Settings"),
        elevation: 0,
      ),
      body: CornerClippedScreenSimple(
        color: Colors.white70,
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Appearance",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),

              // Light / Dark Mode Switch
              _buildThemeSwitcher(),

              const SizedBox(height: 30),

              const Text(
                "Accent Color",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),

              _buildAccentColors(),

              const SizedBox(height: 35),

              const Text(
                "Preview",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),

              _buildPreviewCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSwitcher() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),

        color: Colors.blue,
      ),
      child: Row(
        children: [
          const Icon(Icons.light_mode_outlined,color: Colors.white,),
          const SizedBox(width: 15),
          const Expanded(
            child: Text(
              "Dark Mode",

              style: TextStyle(fontSize: 16,color: Colors.white),
            ),
          ),
          Switch(
            value: isDark,
            onChanged: (v) {
              setState(() => isDark = v);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccentColors() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: accentOptions.map((color) {
        final selected = accentColor == color;

        return GestureDetector(
          onTap: () => setState(() => accentColor = color),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: selected ? 52 : 46,
            height: selected ? 52 : 46,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: selected
                  ? Border.all(color: Colors.black, width: 3)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.6),
                  blurRadius: selected ? 14 : 8,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPreviewCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isDark ? "Dark Mode" : "Light Mode",
            style: TextStyle(
              fontSize: 20,
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Accent Color Preview",
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            height: 8,
            width: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}
