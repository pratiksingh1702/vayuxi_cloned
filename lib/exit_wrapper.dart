import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

class ExitWrapper extends StatefulWidget {
  final Widget child;
  const ExitWrapper({super.key, required this.child});

  @override
  State<ExitWrapper> createState() => _ExitWrapperState();
}

class _ExitWrapperState extends State<ExitWrapper> {
  bool _exitPromptVisible = false;
  OverlayEntry? _overlayEntry;

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _exitPromptVisible = false);
  }

  Future<void> _onBackPressed() async {
    if (_exitPromptVisible) {
      _removeOverlay();
      await SystemNavigator.pop();
      return;
    }

    setState(() => _exitPromptVisible = true);

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(
                color: Colors.black.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            bottom: 32,
            left: 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF1B2D4B).withOpacity(0.78),
                          const Color(0xFF274A7B).withOpacity(0.70),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.42),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.34),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.exit_to_app_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Press back again to exit',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.15,
                              shadows: [
                                Shadow(
                                  color: Color(0x88000000),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            _removeOverlay();
                            SystemNavigator.pop();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(11),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.18),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Text(
                              'EXIT',
                              style: TextStyle(
                                color: Color(0xFF1B2D4B),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3,
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
        ],
      ),
    );

    // Insert into the root overlay — bypasses ShowCaseWidget entirely
    Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);

    // Auto dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _exitPromptVisible) _removeOverlay();
    });
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBackPressed();
      },
      child: widget.child,
    );
  }
}
