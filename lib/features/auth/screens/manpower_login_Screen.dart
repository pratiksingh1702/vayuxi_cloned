// Create a new file: lib/features/auth/screen/manpower_login_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../provider/auth_provider.dart';

class ManpowerLoginScreen extends ConsumerStatefulWidget {
  const ManpowerLoginScreen({super.key});

  @override
  ConsumerState<ManpowerLoginScreen> createState() => _ManpowerLoginScreenState();
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Manpower Login"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                "Manpower Login",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Enter your employee code and password to login",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 40),

              // Employee Code Field
              const Text(
                "Employee Code*",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: employeeCodeController,
                decoration: InputDecoration(
                  hintText: "mer-mech-00006",
                  hintStyle: TextStyle(color: Colors.grey.shade300),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 20),

              // Password Field
              const Text(
                "Password*",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  hintText: "Enter your password",
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
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

              const SizedBox(height: 30),

              // Login Button
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
                    backgroundColor: const Color(0xFF218AE6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    "Login as Manpower",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Forgot Password Button
              Center(
                child: TextButton(
                  onPressed: () {
                    // TODO: Implement forgot password functionality
                    _showErrorSnackBar("Forgot password functionality coming soon");
                  },
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Switch to User Login
              Center(
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: RichText(
                    text: const TextSpan(
                      text: "Not a manpower? ",
                      style: TextStyle(color: Colors.grey),
                      children: [
                        TextSpan(
                          text: "Login as User",
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
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
    );
  }
}