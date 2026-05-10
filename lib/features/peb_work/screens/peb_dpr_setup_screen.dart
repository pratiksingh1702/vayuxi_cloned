import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/utlis/app_toasts.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/buttons.dart';
import 'package:untitled2/core/utlis/widgets/custom.dart';
import 'package:untitled2/core/utlis/widgets/sidebar.dart';
import '../models/peb_dpr_model.dart';
import '../service/peb_work_service.dart';

class PebDprSetupScreen extends ConsumerStatefulWidget {
  final String siteId;
  final String workType;

  const PebDprSetupScreen({
    super.key,
    required this.siteId,
    required this.workType,
  });

  @override
  ConsumerState<PebDprSetupScreen> createState() => _PebDprSetupScreenState();
}

class _PebDprSetupScreenState extends ConsumerState<PebDprSetupScreen> {
  final _service = PebWorkService();
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _setupNameController;
  late TextEditingController _sectionController;
  List<PebSetupItem> _items = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _setupNameController = TextEditingController(text: '${widget.workType.toUpperCase()} Setup');
    _sectionController = TextEditingController();
    _fetchExistingSetups();
  }

  Future<void> _fetchExistingSetups() async {
    setState(() => _isLoading = true);
    try {
      final setups = await _service.getDprSetups(widget.siteId, workType: widget.workType);
      if (setups.isNotEmpty) {
        final latest = setups.first;
        _setupNameController.text = latest.setupName;
        _sectionController.text = latest.section;
        _items = List.from(latest.items);
      }
    } catch (e) {
      debugPrint('Error fetching setups: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addItem() {
    setState(() {
      _items.add(PebSetupItem(
        itemCode: '',
        itemName: '',
        description: '',
        unit: 'nos',
        targetQuantity: 0,
        uom: 'nos',
      ));
    });
  }

  Future<void> _saveSetup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      AppToast.error('Please add at least one item');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final setup = PebDprSetup(
        workType: widget.workType,
        setupName: _setupNameController.text.trim(),
        section: _sectionController.text.trim(),
        items: _items,
      );
      await _service.createDprSetup(widget.siteId, setup);
      AppToast.success('Setup saved successfully');
      if (mounted) context.pop();
    } catch (e) {
      AppToast.error('Failed to save setup');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _setupNameController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: isDark ? cs.surface : cs.surfaceContainerLowest,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            CustomSliverAppBar(title: "${widget.workType.toUpperCase()} Setup"),
          ];
        },
        body: BottomButtonWrapper(
          customButtons: [
            CustomButton(
              button: RoundedButton(
                text: _isLoading ? "Saving..." : "Save Configuration",
                onPressed: _isLoading ? () {} : _saveSetup,
                color: cs.primary,
                textColor: cs.onPrimary,
              ),
            ),
          ],
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(cs, isDark),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Configure Items",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text("Add Item"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._items.asMap().entries.map((entry) => _buildItemCard(entry.key, entry.value, cs, isDark)),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(ColorScheme cs, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainer : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          _buildTextField("Setup Name", _setupNameController, Icons.settings_suggest, cs),
          const SizedBox(height: 16),
          _buildTextField("Section / Plant", _sectionController, Icons.factory_outlined, cs),
        ],
      ),
    );
  }

  Widget _buildItemCard(int index, PebSetupItem item, ColorScheme cs, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: cs.primary.withOpacity(0.1),
                child: Text("${index + 1}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cs.primary)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: item.itemName,
                  decoration: const InputDecoration(
                    hintText: "Item Name",
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  onChanged: (val) => _items[index] = _items[index].copyWithItemName(val),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                onPressed: () => setState(() => _items.removeAt(index)),
              ),
            ],
          ),
          const Divider(),
          Row(
            children: [
              Expanded(
                child: _buildItemField("Code", item.itemCode, (val) => _items[index] = _items[index].copyWithItemCode(val), cs),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildItemField("Target Qty", item.targetQuantity.toString(), (val) => _items[index] = _items[index].copyWithTargetQty(double.tryParse(val) ?? 0), cs, keyboardType: TextInputType.number),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildItemField("UOM", item.uom, (val) => _items[index] = _items[index].copyWithUom(val), cs),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, ColorScheme cs) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: (val) => val == null || val.isEmpty ? "Required" : null,
    );
  }

  Widget _buildItemField(String label, String value, Function(String) onChanged, ColorScheme cs, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: value,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }
}

extension PebSetupItemExtension on PebSetupItem {
  PebSetupItem copyWithItemName(String val) => PebSetupItem(itemCode: itemCode, itemName: val, description: description, unit: unit, targetQuantity: targetQuantity, uom: uom, moc: moc, floor: floor, size: size, thickness: thickness, remarks: remarks, images: images);
  PebSetupItem copyWithItemCode(String val) => PebSetupItem(itemCode: val, itemName: itemName, description: description, unit: unit, targetQuantity: targetQuantity, uom: uom, moc: moc, floor: floor, size: size, thickness: thickness, remarks: remarks, images: images);
  PebSetupItem copyWithTargetQty(double val) => PebSetupItem(itemCode: itemCode, itemName: itemName, description: description, unit: unit, targetQuantity: val, uom: uom, moc: moc, floor: floor, size: size, thickness: thickness, remarks: remarks, images: images);
  PebSetupItem copyWithUom(String val) => PebSetupItem(itemCode: itemCode, itemName: itemName, description: description, unit: unit, targetQuantity: targetQuantity, uom: val, moc: moc, floor: floor, size: size, thickness: thickness, remarks: remarks, images: images);
}
