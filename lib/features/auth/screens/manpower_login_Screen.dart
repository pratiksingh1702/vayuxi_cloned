// Create a new file: lib/features/auth/screen/manpower_login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../provider/auth_provider.dart';

class ManpowerLoginScreen extends ConsumerStatefulWidget {
  const ManpowerLoginScreen({super.key});

  @override
  ConsumerState<ManpowerLoginScreen> createState() =>
      _ManpowerLoginScreenState();
}

class _ManpowerLoginScreenState extends ConsumerState<ManpowerLoginScreen> {
  final employeeCodeController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool isPasswordVisible = false;

  Future<void> login() async {
    final employeeCode = employeeCodeController.text.trim();
    final password = passwordController.text.trim();

    if (employeeCode.isEmpty) {
      _showErrorSnackBar("Please enter your employee code");
      return;
    }

    if (password.isEmpty) {
      _showErrorSnackBar("Please enter your password");
      return;
    }

    setState(() => isLoading = true);

    try {
      await ref
          .read(authProvider.notifier)
          .manpowerLogin(employeeCode, password);

      final authState = ref.read(authProvider);

      if (authState.isLoggedIn && authState.role == 'manpower') {
        _showSuccessSnackBar("Login successful!");
        // Navigate to manpower dashboard
        context.go('/manpower-dashboard');
      } else {
        _showErrorSnackBar(
          authState.errorMessage ?? "Login failed. Please try again",
        );
      }
    } catch (e) {
      _showErrorSnackBar(
        e.toString().contains('Invalid credentials')
            ? "Invalid employee code or password"
            : "Login failed. Please try again",
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorScheme.tertiary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    employeeCodeController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text("Manpower Login"),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: colorScheme.outlineVariant.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(
                      color:
                          colorScheme.shadow.withOpacity(isDark ? 0.28 : 0.08),
                      blurRadius: 16,
                      spreadRadius: -3,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Manpower Login",
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Enter your employee code and password to continue.",
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Employee Code*",
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: employeeCodeController,
                      decoration: InputDecoration(
                        hintText: "mer-mech-00006",
                        hintStyle:
                            TextStyle(color: colorScheme.onSurfaceVariant),
                        filled: true,
                        fillColor: colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: colorScheme.outlineVariant),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: colorScheme.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: colorScheme.primary, width: 1.5),
                        ),
                        prefixIcon: Icon(Icons.badge_outlined,
                            color: colorScheme.primary),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      "Password*",
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: passwordController,
                      obscureText: !isPasswordVisible,
                      decoration: InputDecoration(
                        hintText: "Enter your password",
                        hintStyle:
                            TextStyle(color: colorScheme.onSurfaceVariant),
                        filled: true,
                        fillColor: colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: colorScheme.outlineVariant),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: colorScheme.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: colorScheme.primary, width: 1.5),
                        ),
                        prefixIcon: Icon(Icons.lock_outline,
                            color: colorScheme.primary),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            setState(() {
                              isPasswordVisible = !isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isLoading ||
                                employeeCodeController.text.isEmpty ||
                                passwordController.text.isEmpty
                            ? null
                            : login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          disabledBackgroundColor:
                              colorScheme.surfaceContainerHighest,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.onPrimary,
                                ),
                              )
                            : Text(
                                "Login as Manpower",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          _showErrorSnackBar(
                              "Forgot password functionality coming soon");
                        },
                        child: Text(
                          "Forgot Password?",
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: TextButton(
                        onPressed: () => context.go('/login'),
                        child: RichText(
                          text: TextSpan(
                            text: "Not a manpower? ",
                            style:
                                TextStyle(color: colorScheme.onSurfaceVariant),
                            children: [
                              TextSpan(
                                text: "Login as User",
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
