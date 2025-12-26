// screens/expense/add_expense_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:untitled2/core/utlis/colors/colors.dart';
import 'package:untitled2/core/utlis/widgets/Button_wrapper.dart';
import 'package:untitled2/core/utlis/widgets/buttons.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';
import 'package:untitled2/core/utlis/widgets/image_clipped.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/providers/site_current_provider.dart';

import '../../../../../../core/utlis/widgets/custom.dart';
import '../genericFormScreen.dart';


class AddExpenseScreen extends ConsumerStatefulWidget {


  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  void _showCategoryModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _CategoryModal(
        onCategorySelected: (category) {
          Navigator.pop(context);
          _navigateToExpenseForm(category);
        },
      ),
    );
  }

  void _navigateToExpenseForm(String category) {
    final siteId=ref.read(selectedSiteIdProvider);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpenseFormScreen(
          siteId:siteId!,
          expenseType: category,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            CustomSliverAppBar(title: "Add Expense"),
          ];
        },
        body: BottomButtonWrapper(
          child: SafeArea(
            child: Column(
              children: [
               // Category Selection Grid
                Expanded(
                  child: _CategoryGrid(
                    onCategorySelected: _navigateToExpenseForm,
                  ),
                ),
          
                   
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final Function(String) onCategorySelected;

  const _CategoryGrid({required this.onCategorySelected});

  @override
  Widget build(BuildContext context) {
    final categories = [
      {
        'type': 'material_tools',
        'icon': Icons.build,
        'color': Colors.orange,
      },
      {
        'type': 'travelling',
        'icon': Icons.directions_car,
        'color': Colors.green,
      },
      {
        'type': 'food',
        'icon': Icons.restaurant,
        'color': Colors.red,
      },
      {
        'type': 'accommodation',
        'icon': Icons.hotel,
        'color': Colors.purple,
      },
      {
        'type': 'advance',
        'icon': Icons.attach_money,
        'color': Colors.blue,
      },
      {
        'type': 'Miscllaneous',
        'icon': Icons.miscellaneous_services,
        'color': Colors.blue,
      },
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _CategoryCard(
          categoryType: category['type'] as String,
          icon: category['icon'] as IconData,
          color: category['color'] as Color,
          onTap: onCategorySelected,
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String categoryType;
  final IconData icon;
  final Color color;
  final Function(String) onTap;

  const _CategoryCard({
    required this.categoryType,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => onTap(categoryType),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 30,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatCategoryName(categoryType),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryModal extends StatelessWidget {
  final Function(String) onCategorySelected;

  const _CategoryModal({required this.onCategorySelected});

  @override
  Widget build(BuildContext context) {
    final categories = [
      'material_tools',
      'travelling',
      'food',
      'accommodation',
      'advance',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Select Expense Category",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...categories.map(
                (category) => ListTile(
              leading: Icon(
                _getCategoryIcon(category),
                color: _getCategoryColor(category),
              ),
              title: Text(_formatCategoryName(category)),
              onTap: () => onCategorySelected(category),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'material_tools':
        return Icons.build;
      case 'travelling':
        return Icons.directions_car;
      case 'food':
        return Icons.restaurant;
      case 'accommodation':
        return Icons.hotel;
      case 'advance':
        return Icons.attach_money;
      default:
        return Icons.receipt;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'material_tools':
        return Colors.orange;
      case 'travelling':
        return Colors.green;
      case 'food':
        return Colors.red;
      case 'accommodation':
        return Colors.purple;
      case 'advance':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

String _formatCategoryName(String category) {
  return category.replaceAll('_', ' ').toUpperCase();
}