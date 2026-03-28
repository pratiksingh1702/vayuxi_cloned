import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/screens/widgets/delete_mode_mixin.dart';

class TestWidget extends StatefulWidget {
  final List<String> items;
  const TestWidget({super.key, required this.items});

  @override
  State<TestWidget> createState() => _TestWidgetState();
}

class _TestWidgetState extends State<TestWidget> with DeleteModeMixin<String> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text(isDeleteMode ? '${selectedIds.length} Selected' : 'Test'),
          actions: [
            if (isDeleteMode)
              TextButton(
                onPressed: () => setState(() => handleSelectAllToggle(widget.items)),
                child: Text(selectAllLabel(widget.items)),
              ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => setState(() => toggleDeleteMode()),
            ),
          ],
        ),
        body: ListView.builder(
          itemCount: widget.items.length,
          itemBuilder: (context, index) {
            final item = widget.items[index];
            final isItemHighlight = isSelected(item);
            return Stack(
              children: [
                Opacity(
                  opacity: isDeleteMode && !isItemHighlight ? 0.5 : 1.0,
                  child: ListTile(
                    title: Text(item),
                    onTap: isDeleteMode ? null : () {},
                  ),
                ),
                if (isDeleteMode)
                  Positioned.fill(
                    child: GestureDetector(
                      key: Key('selection_$item'),
                      onTap: () => setState(() => toggleSelection(item)),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        color: Colors.black.withOpacity(0.05),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: isItemHighlight ? const Icon(Icons.check, color: Colors.red) : null,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

void main() {
  group('DeleteModeMixin Tests', () {
    testWidgets('Entering delete mode shows selection UI', (WidgetTester tester) async {
      final items = ['Item 1', 'Item 2', 'Item 3'];
      await tester.pumpWidget(TestWidget(items: items));

      expect(find.text('Test'), findsOneWidget);
      expect(find.text('Select All'), findsNothing);

      // Enter delete mode
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pump();

      expect(find.text('0 Selected'), findsOneWidget);
      expect(find.text('Select All'), findsOneWidget);
    });

    testWidgets('Tapping item in delete mode toggles selection', (WidgetTester tester) async {
      final items = ['Item 1', 'Item 2'];
      await tester.pumpWidget(TestWidget(items: items));

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pump();

      // Tap first item
      await tester.tap(find.byKey(const Key('selection_Item 1')));
      await tester.pump();

      expect(find.text('1 Selected'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);

      // Tap again to deselect
      await tester.tap(find.byKey(const Key('selection_Item 1')));
      await tester.pump();

      expect(find.text('0 Selected'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('Select All / Deselect All behavior', (WidgetTester tester) async {
      final items = ['Item 1', 'Item 2', 'Item 3'];
      await tester.pumpWidget(TestWidget(items: items));

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pump();

      // Select All
      await tester.tap(find.text('Select All'));
      await tester.pump();

      expect(find.text('3 Selected'), findsOneWidget);
      expect(find.text('Deselect All'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsNWidgets(3));

      // Deselect All
      await tester.tap(find.text('Deselect All'));
      await tester.pump();

      expect(find.text('0 Selected'), findsOneWidget);
      expect(find.text('Select All'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('Opacity drops for unselected items in delete mode', (WidgetTester tester) async {
      final items = ['Item 1', 'Item 2'];
      await tester.pumpWidget(TestWidget(items: items));

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pump();

      // Select Item 1
      await tester.tap(find.byKey(const Key('selection_Item 1')));
      await tester.pump();

      final opacityItem1 = tester.widget<Opacity>(
        find.ancestor(of: find.text('Item 1'), matching: find.byType(Opacity)),
      );
      final opacityItem2 = tester.widget<Opacity>(
        find.ancestor(of: find.text('Item 2'), matching: find.byType(Opacity)),
      );

      expect(opacityItem1.opacity, 1.0);
      expect(opacityItem2.opacity, 0.5);
    });
  });
}
