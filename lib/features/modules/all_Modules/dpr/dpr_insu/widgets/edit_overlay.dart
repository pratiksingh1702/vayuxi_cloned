// edit_overlay.dart
import 'dart:ui';
import 'package:flutter/material.dart';

class EditOverlayPage extends StatefulWidget {
  final WidgetBuilder cardBuilder;
  final Listenable? listenable;
  final Future<void> Function() onSave;
  final VoidCallback onCancel;
  final dynamic child;

  const EditOverlayPage({
    super.key,
    required this.cardBuilder,
    this.listenable,
    required this.onSave,
    required this.onCancel,
    this.child,
  });

  @override
  State<EditOverlayPage> createState() => _EditOverlayPageState();
}

class _EditOverlayPageState extends State<EditOverlayPage> {
  @override
  void dispose() {
    // CRITICAL: Clear any focus and ensure overlay is completely removed
    FocusManager.instance.primaryFocus?.unfocus();
    
    // Force any pending animations to complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Clean up any remaining focus nodes
      FocusScope.of(context).unfocus();
    });
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          // Ensure focus is cleared before cancel
          FocusScope.of(context).unfocus();
          widget.onCancel();
        }
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                // Clear focus and cancel on tap outside
                FocusScope.of(context).unfocus();
                widget.onCancel();
              },
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(
                  color: Colors.black.withOpacity(0.45),
                ),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                      child: widget.listenable != null
                          ? AnimatedBuilder(
                              animation: widget.listenable!,
                              builder: (context, _) => widget.cardBuilder(context),
                            )
                          : widget.cardBuilder(context),
                    ),
                  ),
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: _SaveBar(
                      onSave: widget.onSave,
                      onCancel: () {
                        // Clear focus before cancel
                        FocusScope.of(context).unfocus();
                        widget.onCancel();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveBar extends StatefulWidget {
  final Future<void> Function() onSave;
  final VoidCallback onCancel;
  const _SaveBar({required this.onSave, required this.onCancel});

  @override
  State<_SaveBar> createState() => _SaveBarState();
}

class _SaveBarState extends State<_SaveBar> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _saving ? null : widget.onCancel,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Colors.grey),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _saving
                ? null
                : () async {
                    setState(() => _saving = true);
                    await widget.onSave();
                    if (mounted) {
                      setState(() => _saving = false);
                    }
                  },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: const Color(0xFF1B6DCE),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}