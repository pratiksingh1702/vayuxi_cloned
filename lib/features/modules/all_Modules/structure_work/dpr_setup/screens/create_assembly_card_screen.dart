import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../core/utlis/widgets/premium_app_bar.dart';
import '../../../site_Details/repository/siteModel.dart';
import '../isar/assembly_card_isar.dart';
import '../providers/card_config.dart';
import '../../boq/models/boq_structure_model.dart';
import '../../boq/providers/boq_structure_provider.dart';

class CreateAssemblyCardScreen extends ConsumerStatefulWidget {
  final SiteModel site;
  final AssemblyCardIsar? card;
  const CreateAssemblyCardScreen({super.key, required this.site, this.card});

  @override
  ConsumerState<CreateAssemblyCardScreen> createState() =>
      _CreateAssemblyCardScreenState();
}

class _CreateAssemblyCardScreenState
    extends ConsumerState<CreateAssemblyCardScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _markController;
  late TextEditingController _descController;
  late TextEditingController _qtyController;
  late TextEditingController _weightController;
  late TextEditingController _lengthController;
  late TextEditingController _widthController;
  late TextEditingController _heightController;

  @override
  void initState() {
    super.initState();
    final initialConfig = widget.card;
    _markController = TextEditingController(text: initialConfig?.assemblyMark);
    _descController = TextEditingController(text: initialConfig?.description);
    _qtyController =
        TextEditingController(text: initialConfig?.quantity.toString());
    _weightController = TextEditingController(
        text: initialConfig?.netWeightPerUnit?.toString());
    _lengthController =
        TextEditingController(text: initialConfig?.length?.toString());
    _widthController =
        TextEditingController(text: initialConfig?.width?.toString());
    _heightController =
        TextEditingController(text: initialConfig?.height?.toString());

    // Ensure BOQs are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(boqStructureProvider.notifier).fetchBOQs(widget.site.id);
    });
  }

  @override
  void dispose() {
    _markController.dispose();
    _descController.dispose();
    _qtyController.dispose();
    _weightController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _onBoqItemPicked(BOQStructureItem item, String boqId, String boqName) {
    ref
        .read(assemblyCardConfigProvider(
            {'siteId': widget.site.id, 'card': widget.card}).notifier)
        .selectBoqItem(item, boqId, boqName);

    // Update local text controllers to reflect new state
    _markController.text = item.assemblyMark;
    _descController.text = item.typeDescription;
    _qtyController.text = item.quantity.toString();
    _weightController.text = item.netWeightPerUnit?.toString() ?? "";
    _lengthController.text = item.length?.toString() ?? "";
    _widthController.text = item.width?.toString() ?? "";
    _heightController.text = item.height?.toString() ?? "";
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(assemblyCardConfigProvider(
        {'siteId': widget.site.id, 'card': widget.card}).notifier);

    // Ensure all controller values are synced back before saving
    notifier.updateMark(_markController.text);
    notifier.updateDescription(_descController.text);
    notifier.updateQuantity(double.tryParse(_qtyController.text) ?? 0);
    notifier.updateWeight(double.tryParse(_weightController.text));
    notifier.updateLength(double.tryParse(_lengthController.text));
    notifier.updateWidth(double.tryParse(_widthController.text));
    notifier.updateHeight(double.tryParse(_heightController.text));

    await notifier.saveCard(widget.card);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final boqState = ref.watch(boqStructureProvider);
    final cardConfig = ref.watch(assemblyCardConfigProvider(
        {'siteId': widget.site.id, 'card': widget.card}));

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: PremiumAppBar(
        title: widget.card == null ? "Create Card" : "Edit Card",
        subtitle: Text(widget.site.siteName),
        actions: [
          PremiumActionIcon(
            icon: Icons.check_rounded,
            onPressed: _save,
            tooltip: "Save",
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          children: [
            _buildSectionTitle("BOQ Reference"),
            const SizedBox(height: 12),
            _buildBoqItemPicker(boqState, cardConfig.boqItemId),
            const SizedBox(height: 32),
            _buildSectionTitle("General Details"),
            const SizedBox(height: 16),
            _buildTextField(
                _descController, "Description", Icons.description_rounded,
                maxLines: 2),
            const SizedBox(height: 16),
            _buildTextField(
                _markController, "Assembly Mark", Icons.tag_rounded),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _buildTextField(
                        _qtyController, "Quantity", Icons.numbers_rounded,
                        isNumber: true)),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildTextField(_weightController, "Weight (kg)",
                        Icons.monitor_weight_rounded,
                        isNumber: true)),
              ],
            ),
            const SizedBox(height: 32),
            _buildSectionTitle("Dimensions (m)"),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _buildTextField(
                        _lengthController, "Length", Icons.straighten_rounded,
                        isNumber: true)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildTextField(
                        _widthController, "Width", Icons.straighten_rounded,
                        isNumber: true)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildTextField(
                        _heightController, "Height", Icons.straighten_rounded,
                        isNumber: true)),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(widget.card == null ? "Make Card" : "Update Card",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
                color: cs.onSurface, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {bool isNumber = false, int maxLines = 1}) {
    final cs = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: cs.primary.withOpacity(0.7)),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: cs.outlineVariant)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.5))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: cs.primary, width: 1.5)),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? cs.surfaceContainerHigh
            : cs.surface,
      ),
      validator: (val) => (val == null || val.isEmpty) ? "Required" : null,
    );
  }

  Widget _buildBoqItemPicker(
      BOQStructureState state, String? selectedBoqItemId) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => _showBoqSelectionDialog(state),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? cs.surfaceContainerHigh : cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(Icons.list_alt_rounded, color: cs.onSurfaceVariant, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedBoqItemId == null
                        ? "Link to BOQ Item"
                        : "Linked to BOQ",
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                        fontSize: 13),
                  ),
                  if (selectedBoqItemId == null)
                    Text("Select a BOQ entry to auto-fill",
                        style: TextStyle(
                            fontSize: 11, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  void _showBoqSelectionDialog(BOQStructureState state) {
    if (state.isLoading) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Loading BOQs...")));
      return;
    }

    if (state.boqs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No BOQs found for this site.")));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text("Select BOQ Item",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            Expanded(
              child: Builder(builder: (context) {
                final allItems = <Map<String, dynamic>>[];
                for (final boq in state.boqs) {
                  for (final item in boq.items) {
                    allItems.add({'boq': boq, 'item': item});
                  }
                }

                if (allItems.isEmpty) {
                  return const Center(
                      child: Text("No items available in BOQs"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: allItems.length,
                  itemBuilder: (context, idx) {
                    final itemData = allItems[idx];
                    final boq = itemData['boq'] as BOQStructure;
                    final item = itemData['item'] as BOQStructureItem;
                    return Card(
                      elevation: 0,
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withOpacity(0.3),
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text(item.assemblyMark,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                        subtitle: Text(
                          "Type: ${item.typeDescription.isNotEmpty ? item.typeDescription : 'No Type Description'}\nQty: ${item.quantity} | Wt: ${item.netWeightPerUnit ?? 0}kg",
                        ),
                        isThreeLine: true,
                        trailing: Icon(Icons.add_circle_rounded,
                            size: 28,
                            color: Theme.of(context).colorScheme.primary),
                        onTap: () {
                          _onBoqItemPicked(item, boq.id, boq.boqName);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
