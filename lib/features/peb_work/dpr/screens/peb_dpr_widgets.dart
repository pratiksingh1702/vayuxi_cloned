import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PebSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;

  const PebSectionHeader({
    required this.title,
    required this.subtitle,
    this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: colorScheme.onSurface,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PebProgressRow extends StatelessWidget {
  final double progress;
  final int done;
  final int total;

  const PebProgressRow({
    required this.progress,
    required this.done,
    required this.total,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(progress * 100).toInt()}% Complete',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
            Text(
              '$done / $total',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 10,
            value: progress,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
        ),
      ],
    );
  }
}

class PebChecklistSection extends StatelessWidget {
  final String title;
  final Map<String, bool> checks;
  final void Function(String key, bool value) onChanged;

  const PebChecklistSection({
    required this.title,
    required this.checks,
    required this.onChanged,
    super.key,
  });

  double get _progress {
    if (checks.isEmpty) return 0;
    final done = checks.values.where((v) => v).length;
    return done / checks.length;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final done = checks.values.where((v) => v).length;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 16),
                PebProgressRow(
                  progress: _progress,
                  done: done,
                  total: checks.length,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: checks.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
            itemBuilder: (context, index) {
              final key = checks.keys.elementAt(index);
              final value = checks[key]!;
              return InkWell(
                onTap: () => onChanged(key, !value),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Checkbox(
                        value: value,
                        onChanged: (v) => onChanged(key, v ?? false),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          key,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: value ? FontWeight.w600 : FontWeight.w500,
                            color: value ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                            decoration: value ? TextDecoration.lineThrough : null,
                            decorationColor: colorScheme.onSurfaceVariant.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class PebMetaChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;

  const PebMetaChip({
    required this.label,
    required this.value,
    this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
          ],
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class PebQtyEntry {
  final DateTime date;
  final int qty;

  const PebQtyEntry({required this.date, required this.qty});
}

class PebFabricationStepCard extends StatefulWidget {
  final String title;
  final String? imagePath;
  final bool hasDistance;
  final VoidCallback? onCopy;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onRemark;

  const PebFabricationStepCard({
    required this.title,
    this.imagePath,
    this.hasDistance = false,
    this.onCopy,
    this.onEdit,
    this.onDelete,
    this.onRemark,
    super.key,
  });

  @override
  State<PebFabricationStepCard> createState() => _PebFabricationStepCardState();
}

class _PebFabricationStepCardState extends State<PebFabricationStepCard> {
  late TextEditingController _mocController;
  late TextEditingController _qtyController;
  late TextEditingController _distanceController;
  late TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    _mocController = TextEditingController();
    _qtyController = TextEditingController(text: '1');
    _distanceController = TextEditingController();
    _weightController = TextEditingController(text: '500.00');
  }

  @override
  void dispose() {
    _mocController.dispose();
    _qtyController.dispose();
    _distanceController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Widget _blueBox({
    required String label,
    required TextEditingController controller,
    String hintText = "",
    bool isNumber = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    const blueFill = Color(0xFFD0EAFD);
    const darkBlueFill = Color(0xFF1E3A5F);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ),
        SizedBox(
          height: 26,
          child: TextFormField(
            controller: controller,
            textAlign: TextAlign.center,
            keyboardType: isNumber
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: hintText,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              filled: true,
              fillColor: isDark ? darkBlueFill : blueFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide.none,
              ),
              hintStyle: TextStyle(
                fontSize: 9,
                color: cs.onSurface.withOpacity(0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainField({
    required String label,
    required TextEditingController controller,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 48,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
          ),
          child: TextFormField(
            controller: controller,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  String get _getEffectiveImagePath {
    if (widget.imagePath != null && widget.imagePath!.isNotEmpty) {
      return widget.imagePath!;
    }

    final title = widget.title.toLowerCase().trim();
    final words = title.split(RegExp(r'\s+'));
    final cleanTitle = title.replaceAll(' ', '');

    final mappings = {
      'cutting': 'assets/images/Cutting.png',
      'dispatch': 'assets/images/Dispatch.png',
      'fit': 'assets/images/Fit.png',
      'grinding': 'assets/images/Grinding.png',
      'shfiting': 'assets/images/Shfiting.png',
      'unloading': 'assets/images/Unloading.png',
      'welding': 'assets/images/Welding.png',
    };

    // 1. Match full clean title
    if (mappings.containsKey(cleanTitle)) return mappings[cleanTitle]!;

    // 2. First keyword matching (check each word)
    for (var word in words) {
      if (mappings.containsKey(word)) return mappings[word]!;
      
      // Special handle: "Fitup" -> "fit"
      if (word.startsWith('fit')) return mappings['fit']!;
      // Special handle: "Weld" -> "welding"
      if (word.startsWith('weld')) return mappings['welding']!;
      // Special handle: "Shifting" -> "shfiting"
      if (word.startsWith('shift')) return mappings['shfiting']!;
    }

    return 'assets/images/default.png';
  }

  Widget _buildSmartImage(ColorScheme cs) {
    final imagePath = _getEffectiveImagePath;

    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
          onError: (exception, stackTrace) {
            // Fallback if asset missing
          },
        ),
      ),
      child: imagePath == 'assets/images/default.png'
          ? Icon(Icons.image_not_supported,
              color: cs.onSurfaceVariant, size: 32)
          : null,
    );
  }

  Widget _buildActionIcon(IconData icon, Color color, VoidCallback? onPressed) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: widget.onRemark,
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 78,
                      maxWidth: 110,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer.withOpacity(0.7),
                      border: Border.all(color: cs.outline.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Remark',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: cs.onSecondaryContainer,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),

          IntrinsicHeight(
            child: Row(
              children: [
                // LEFT COLUMN: Image & Actions
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        _buildSmartImage(cs),
                        const SizedBox(height: 12),
                        // Action row (Edit, Copy, Delete)
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionIcon(Icons.edit_rounded,
                                  cs.primary, () => widget.onEdit?.call()),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildActionIcon(Icons.copy_rounded,
                                  Colors.green, () => widget.onCopy?.call()),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildActionIcon(
                                  Icons.delete_outline_rounded,
                                  cs.error,
                                  () => widget.onDelete?.call()),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // RIGHT COLUMN: Fields
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _blueBox(
                                label: "MOC",
                                controller: _mocController,
                                hintText: "Enter MOC",
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _blueBox(
                                label: "Qty",
                                controller: _qtyController,
                                isNumber: true,
                              ),
                            ),
                          ],
                        ),
                        if (widget.hasDistance) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Expanded(child: SizedBox()),
                              Expanded(
                                child: _blueBox(
                                  label: "Distance",
                                  controller: _distanceController,
                                  hintText: "mtr",
                                  isNumber: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const Spacer(),
                        _buildMainField(
                          label: "Weight (kg)",
                          controller: _weightController,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

