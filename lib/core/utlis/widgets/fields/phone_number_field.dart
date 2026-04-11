import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PhoneInputField extends StatefulWidget {
  final TextEditingController? controller;
  final String countryCode;
  final AutovalidateMode? autovalidateMode;

  const PhoneInputField({
    super.key,
    this.controller,
    this.countryCode = '+91',
    this.autovalidateMode,
  });

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  bool _isFocused = false;
  String? _errorText;

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // ✅ allow empty
    }

    final digits = value.replaceAll(RegExp(r'\s+'), '');
    if (!RegExp(r'^[0-9]{10}$').hasMatch(digits)) {
      return 'Please enter a valid 10-digit phone number';
    }

    return null;
  }

  void _onChanged(String value) {
    if (widget.autovalidateMode == AutovalidateMode.onUserInteraction ||
        _errorText != null) {
      setState(() {
        _errorText = _validatePhone(value);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasError = _errorText != null;

    // Border color logic — matches register_screen style
    Color borderColor() {
      if (hasError) return cs.error;
      if (_isFocused) return cs.primary;
      return cs.outline;
    }

    double borderWidth() => _isFocused ? 1.8 : 1.0;

    return FormField<String>(
      validator: (_) => _validatePhone(widget.controller?.text),
      builder: (formState) {
        final error = formState.errorText ?? _errorText;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Input row ──────────────────────────────────────────────────
            Focus(
              onFocusChange: (focused) => setState(() => _isFocused = focused),
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: error != null ? cs.error : borderColor(),
                    width: error != null ? 1.0 : borderWidth(),
                  ),
                ),
                child: Row(
                  children: [
                    // ── Country prefix ─────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 13),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        border: Border(
                          right: BorderSide(
                            color: error != null ? cs.error : borderColor(),
                            width: 1.0,
                          ),
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          bottomLeft: Radius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // India flag using emoji
                          const Text(
                            '🇮🇳',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.countryCode,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w500,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Phone number input ─────────────────────────────────
                    Expanded(
                      child: TextFormField(
                        controller: widget.controller,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        onChanged: (v) {
                          _onChanged(v);
                          formState.didChange(v);
                        },
                        style: TextStyle(
                          fontSize: 14.5,
                          color: cs.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter Mobile No.',
                          hintStyle: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: cs.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          // All borders transparent — outer Container handles them
                          border: OutlineInputBorder(
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(10),
                              bottomRight: Radius.circular(10),
                            ),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(10),
                              bottomRight: Radius.circular(10),
                            ),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(10),
                              bottomRight: Radius.circular(10),
                            ),
                            borderSide: BorderSide.none,
                          ),
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          // Suppress built-in error display — we render it below
                          errorText: null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Error message ──────────────────────────────────────────────
            if (error != null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Text(
                  error,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.error,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
