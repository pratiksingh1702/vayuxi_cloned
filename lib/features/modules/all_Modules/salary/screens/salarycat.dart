import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/core/utlis/widgets/buttons.dart';
import 'package:untitled2/core/utlis/widgets/custom_appBar.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  // Mock translation function - replace with your i18n solution
  String t(String key) {
    final translations = {
      'select_category': 'Select Category',
      'download_individual': 'Download Individual',
      'download_site_wise': 'Download Site Wise',
      'download_all': 'Download All',
      'back': 'Back',
    };
    return translations[key] ?? key;
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: "Select category"),
      body: Column(
        children: [
          // Select Module Options
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  SelectModule(
                    icon: Icons.person,
                    label: t('download_individual'),
                    onTap: () => context.push('/salary/individual'),
                  ),
                  const SizedBox(height: 12),
                  SelectModule(
                    icon: Icons.factory_rounded,
                    label: t('download_site_wise'),
                    onTap: () => context.push('/site-list/siteSalary'),
                  ),
                  const SizedBox(height: 12),
                  SelectModule(
                    icon: Icons.check_box,
                    label: t('download_all'),
                    onTap: () => context.push('/salary-Module/work'),
                  ),
                ],
              ),
            ),
          ),
          // Back Button at the very bottom
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child:RoundedButton(text: "Back",
                    color: Colors.white, textColor: Colors.black, onPressed: () => context.pop()),
              ),
            ],
          ),
        ],
      ),
    );
  }

}

// Custom KeyboardAwareScrollView widget
class KeyboardAwareScrollView extends StatelessWidget {
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;
  final List<Widget> children;

  const KeyboardAwareScrollView({
    super.key,
    required this.backgroundColor,
    required this.padding,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: padding,
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: children,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Protected Route Wrapper
class ProtectedRoute extends StatelessWidget {
  final Widget child;

  const ProtectedRoute({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Add your authentication logic here
    return child;
  }
}

// Dynamic Menu Widget
class DynamicMenu extends StatelessWidget {
  final String name;
  final bool hasMenu;

  const DynamicMenu({
    super.key,
    required this.name,
    required this.hasMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (hasMenu)
            const Icon(Icons.menu, size: 20),
        ],
      ),
    );
  }
}

// Select Module Widget
class SelectModule extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const SelectModule({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),

        ),
        child: Row(
          children: [
            Icon(icon, size: 20,color: Colors.blue,),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }
}

// Button Widget with variants
enum ButtonVariant { primary, secondary }

class Button extends StatelessWidget {
  final String label;
  final ButtonVariant variant;
  final VoidCallback onPressed;

  const Button({
    super.key,
    required this.label,
    required this.variant,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isSecondary = variant == ButtonVariant.secondary;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary
              ? Colors.grey[300]
              : Theme.of(context).primaryColor,
          foregroundColor: isSecondary ? Colors.black87 : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}