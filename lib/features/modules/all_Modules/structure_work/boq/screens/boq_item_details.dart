import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/utlis/app_toasts.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/buttons.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/core/utlis/widgets/fields/custom_textField.dart';
import 'package:untitled2/features/modules/all_Modules/structure_work/boq/models/boq_structure_model.dart';
import 'package:untitled2/core/utlis/widgets/sidebar.dart';

class BoqItemDetailsScreen extends StatefulWidget {
  final String siteId;
  final String siteName;
  final BOQStructureItem? item;

  const BoqItemDetailsScreen({
    super.key,
    required this.siteId,
    required this.siteName,
    this.item,
  });

  @override
  State<BoqItemDetailsScreen> createState() => _BoqItemDetailsScreenState();
}

class _BoqItemDetailsScreenState extends State<BoqItemDetailsScreen> {
  final TextEditingController markController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController qtyController = TextEditingController();
  final TextEditingController lengthController = TextEditingController();
  final TextEditingController widthController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      markController.text = widget.item!.assemblyMark;
      descController.text = widget.item!.typeDescription;
      qtyController.text = widget.item!.quantity.toString();
      if (widget.item!.length != null) lengthController.text = widget.item!.length.toString();
      if (widget.item!.width != null) widthController.text = widget.item!.width.toString();
      if (widget.item!.height != null) heightController.text = widget.item!.height.toString();
      if (widget.item!.netWeightPerUnit != null) weightController.text = widget.item!.netWeightPerUnit.toString();
    }
  }

  @override
  void dispose() {
    markController.dispose();
    descController.dispose();
    qtyController.dispose();
    lengthController.dispose();
    widthController.dispose();
    heightController.dispose();
    weightController.dispose();
    super.dispose();
  }

  void _saveItem() {
    if (markController.text.isEmpty || descController.text.isEmpty || qtyController.text.isEmpty) {
      AppToast.error("Please fill all required fields");
      return;
    }
    
    // Simulate saving
    setState(() => isLoading = true);
    
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => isLoading = false);
        // Display toast explaining backend limitation
        AppToast.error("Backend support for manual BOQ item creation/editing is currently unavailable.");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEdit = widget.item != null;

    return Scaffold(
      drawer: const CustomDrawer(),
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: CustomAppBar(
        title: isEdit ? "Edit BOQ Item" : "Add BOQ Item",
      ),
      body: BottomButtonWrapper(
        customButtons: [
          CustomButton(
            button: RoundedButton(
              text: isLoading ? "Saving..." : "Save Item",
              color: colorScheme.primary,
              textColor: colorScheme.onPrimary,
              onPressed: _saveItem,
            ),
          ),
        ],
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Identification Section
              _buildSectionHeader("Identification", Icons.badge_outlined, colorScheme),
              const SizedBox(height: 12),
              CustomTextField(
                label: "Assembly Mark / No.",
                controller: markController,
                isRequired: true,
                hint: "e.g., C1",
              ),
              CustomTextField(
                label: "Type Description",
                controller: descController,
                isRequired: true,
                hint: "e.g., Column",
                maxLines: 2,
              ),

              const SizedBox(height: 24),
              // Quantity & Weight Section
              _buildSectionHeader("Measurements", Icons.straighten_rounded, colorScheme),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: "Quantity",
                      controller: qtyController,
                      isRequired: true,
                      keyboardType: TextInputType.number,
                      hint: "e.g., 100",
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: "Unit Weight (kg)",
                      controller: weightController,
                      isRequired: false,
                      keyboardType: TextInputType.number,
                      hint: "e.g., 150",
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              // Dimensions
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: "Length (m)",
                      controller: lengthController,
                      isRequired: false,
                      keyboardType: TextInputType.number,
                      hint: "Optional",
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: "Width (m)",
                      controller: widthController,
                      isRequired: false,
                      keyboardType: TextInputType.number,
                      hint: "Optional",
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: "Height (m)",
                      controller: heightController,
                      isRequired: false,
                      keyboardType: TextInputType.number,
                      hint: "Optional",
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
