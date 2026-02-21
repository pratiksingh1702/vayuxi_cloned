import 'package:flutter/material.dart';
import 'package:untitled2/core/utlis/widgets/sidebar.dart';


class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(),
      body: child,
    );
  }
}
