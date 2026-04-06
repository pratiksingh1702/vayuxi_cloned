import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/dpr_insu/model/piping_insu.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/dpr_insu/model/material_setup.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/dpr_insu/model/field_config.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/dpr_insu/widgets/piping_card.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/dpr_insu/model/card_form_State.dart';

void main() {
  testWidgets('PipingMaterialCard renders updated size from widget update', (WidgetTester tester) async {
    // Setup initial data
    final fieldConfig = FieldConfig(
      fields: [
        FieldDefinition(key: 'size', label: 'Size', role: 'SIZE', type: 'NUMBER', dropdown: 'sizeUom', required: true),
        FieldDefinition(key: 'qty', label: 'Qty', role: 'QTY', type: 'NUMBER', required: true),
      ],
      unitDropdowns: const UnitDropdowns(sizeUom: ['inch', 'mm']),
      defaults: const FieldDefaults(sizeUom: 'inch'),
      ui: const UiConfig(allowRename: false),
    );

    final setup = MaterialSetup(
      id: '1',
      name: 'Piping',
      materialCode: 'P001',
      image: [],
      uom: 'm',
      designation: 'piping',
      calculationType: 'standard',
      fieldConfig: fieldConfig,
      siteId: 'site1',
      companyId: 'comp1',
    );

    final initialCardState = CardFormState.buildInitial(fieldConfig: fieldConfig);
    
    final material = PipingMaterial(
      id: 'm1',
      name: 'Test Pipe',
      image: [],
      uom: 'm',
      materialCode: 'P001',
      cardFormState: initialCardState,
      size: '10',
      sizeUom: 'inch',
    );

    // Build the widget with initial material
    PipingMaterial? updatedMaterial;
    
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PipingMaterialCard(
          material: material,
          materialSetup: setup,
          onChanged: (m) => updatedMaterial = m,
          onAdd: () {},
          onEdit: () {},
          onDelete: () {},
          onRemark: () {},
        ),
      ),
    ));

    // Initially should show nothing or empty if value is null in cardState
    // But cardState.buildInitial sets it to null
    expect(find.text('10'), findsNothing); 

    // Now update the material with a size in cardFormState
    final updatedCardState = initialCardState.updateValue('size', '25').updateUnit('size', 'mm');
    final materialWithNewSize = material.copyWith(
      size: '25',
      sizeUom: 'mm',
      cardFormState: updatedCardState,
    );

    // Re-pump widget with new material
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PipingMaterialCard(
          material: materialWithNewSize,
          materialSetup: setup,
          onChanged: (m) => updatedMaterial = m,
          onAdd: () {},
          onEdit: () {},
          onDelete: () {},
          onRemark: () {},
        ),
      ),
    ));

    // Verify that the new size is rendered in the TextFormField
    expect(find.text('25'), findsOneWidget);
    expect(find.text('Size (mm)'), findsOneWidget);
  });
}
