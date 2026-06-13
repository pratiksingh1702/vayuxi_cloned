// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:untitled2/features/modules/all_Modules/dpr/dpr_insu/model/eqip_insu.dart';
// import 'package:untitled2/features/modules/all_Modules/dpr/dpr_insu/model/material_setup.dart';
// import 'package:untitled2/features/modules/all_Modules/dpr/dpr_insu/model/field_config.dart';
// import 'package:untitled2/features/modules/all_Modules/dpr/dpr_insu/widgets/equipment_card.dart';
// import 'package:untitled2/features/modules/all_Modules/dpr/dpr_insu/model/card_form_State.dart';

// void main() {
//   testWidgets('EquipmentMaterialCard populates PATCH field when work model is supplied', (WidgetTester tester) async {
//     // 1. Setup FieldConfig for PATCH material
//     final fieldConfig = FieldConfig(
//       fields: [
//         const FieldDefinition(
//           key: 'quantity',
//           label: 'Patch',
//           role: 'QUANTITY',
//           type: 'NUMBER',
//           unitType: 'COUNT',
//           dropdown: 'qtyUom',
//           required: true,
//         ),
//       ],
//       unitDropdowns: const UnitDropdowns(qtyUom: ['NOS']),
//       defaults: const FieldDefaults(qtyUom: 'NOS'),
//       ui: const UiConfig(allowRename: false),
//     );

//     final setup = MaterialSetup(
//       id: 'setup_patch',
//       name: 'PATCH',
//       materialCode: 'PATCH',
//       image: ['https://example.com/patch.png'],
//       uom: 'NOS',
//       designation: 'equipment',
//       calculationType: 'standard',
//       fieldConfig: fieldConfig,
//       siteId: 'site1',
//       companyId: 'comp1',
//     );

//     // 2. Simulate the CardFormState built from API fieldValues
//     // In testing.dart, _buildCardStateFromFieldValues would create this:
//     final entries = {
//       'quantity': const FieldEntry(value: 235, unit: 'NOS'),
//     };
//     final cardState = CardFormState(
//       fieldEntries: entries,
//       geometryMode: null,
//       customLabels: const {},
//     );

//     final material = EquipmentMaterial(
//       id: 'm_patch',
//       name: 'PATCH',
//       image: ['https://example.com/patch.png'],
//       uom: 'NOS',
//       materialCode: 'PATCH',
//       cardFormState: cardState,
//       qty: 235,
//     );

//     // 3. Build the widget
//     await tester.pumpWidget(MaterialApp(
//       home: Scaffold(
//         body: EquipmentMaterialCard(
//           material: material,
//           materialSetup: setup,
//           onChanged: (m) {},
//           onAdd: () {},
//           onEdit: () {},
//           onDelete: () {},
//           onRemark: () {},
//         ),
//       ),
//     ));

//     // 4. Verify that the quantity value '235' is rendered in the TextFormField
//     // Because it's a PATCH material, it should be shown as a dynamic field
//     expect(find.text('235'), findsOneWidget);
    
//     // Also verify the label is 'Patch' as per our fix in equipment_card.dart
//     expect(find.text('Patch'), findsOneWidget);
//   });
// }
