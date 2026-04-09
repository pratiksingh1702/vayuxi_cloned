// lib/features/tour/screen/buddy_overlay.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// BUDDY OVERLAY — premium animated assistant UI
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/tour_controller.dart';
import '../domain/tour_step_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PUBLIC WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class BuddyOverlay extends ConsumerStatefulWidget {
  final TourStep step;
  final int currentStepIndex; // 0-based
  final int totalSteps;
  final bool showHint;
  final bool isMuted;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  final VoidCallback onReplayVoice;
  final VoidCallback onToggleMute;

  const BuddyOverlay({
    super.key,
    required this.step,
    required this.currentStepIndex,
    required this.totalSteps,
    required this.showHint,
    required this.isMuted,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
    required this.onReplayVoice,
    required this.onToggleMute,
  });

  @override
  ConsumerState<BuddyOverlay> createState() => _BuddyOverlayState();
}

class _BuddyOverlayState extends ConsumerState<BuddyOverlay>
    with TickerProviderStateMixin {
  // ── Animations ─────────────────────────────────────────────────────────────
  late final AnimationController _entranceCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _glowCtrl;

  late final Animation<double> _slideAnim;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _pulseAnim;
  late final Animation<double> _glowAnim;
  bool _isExpanded = false;

  // Tracks which step we last animated for (prevents re-animation on rebuild).
  int _lastAnimatedStep = -1;

  @override
  void initState() {
    super.initState();

    // Entrance: slide up + fade in
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _slideAnim = CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.easeOutBack,
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeIn),
    );

    // Pulse: subtle breathing while waiting for tap
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Glow: stronger pulsing while waiting for task
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    _triggerEntrance();
  }

  @override
  void didUpdateWidget(covariant BuddyOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStepIndex != widget.currentStepIndex) {
      _triggerEntrance();
    }
  }

  void _triggerEntrance() {
    if (_lastAnimatedStep == widget.currentStepIndex) return;
    _lastAnimatedStep = widget.currentStepIndex;
    _entranceCtrl.forward(from: 0.0);
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _pulseCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  // ── Colours ────────────────────────────────────────────────────────────────

  static const _bgColor = Color(0xFF1C2237);
  static const _accentBlue = Color(0xFF4D8EFF);
  static const _accentCyan = Color(0xFF00D8FF);
  static const _textPrimary = Color(0xFFF0F4FF);
  static const _textSecondary = Color(0xFF8895B3);
  static const _progressBg = Color(0xFF2A3350);
  static const _hintColor = Color(0xFFFFC542);

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isTask = widget.step.waitMode == BuddyWaitMode.task;
    final isTap = widget.step.waitMode == BuddyWaitMode.tap;
    final progress = widget.totalSteps > 0
        ? (widget.currentStepIndex + 1) / widget.totalSteps
        : 0.0;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.25),
          end: Offset.zero,
        ).animate(_slideAnim),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(left: 2, right: 2, bottom: 2),
            child: _buildCard(progress, isTask, isTap),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(double progress, bool isTask, bool isTap) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnim, _glowAnim]),
      builder: (ctx, _) {
        final scale = (isTap || isTask) ? _pulseAnim.value : 1.0;
        final glowOpacity = isTask ? _glowAnim.value : 0.0;

        return Transform.scale(
          scale: scale,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 560),
            decoration: BoxDecoration(
              color: _bgColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _accentBlue.withOpacity(0.3 + glowOpacity * 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _accentBlue.withOpacity(0.08 + glowOpacity * 0.18),
                  blurRadius: 20 + glowOpacity * 12,
                  spreadRadius: glowOpacity * 3,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildGrabHandle(),
                _buildHeader(),
                AnimatedSize(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeInOut,
                  child: _isExpanded
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildProgressBar(progress),
                            _buildMessage(),
                            if (widget.showHint && widget.step.hintMessage != null)
                              _buildHint(),
                            _buildDivider(),
                          ],
                        )
                      : _buildCompactSummary(progress),
                ),
                _buildControls(isTask),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Sub-widgets ────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 10, 0),
      child: Row(
        children: [
          _BuddyAvatar(pulseAnim: _pulseAnim),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.step.title,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  'Step ${widget.currentStepIndex + 1} of ${widget.totalSteps}',
                  style: TextStyle(
                    color: _accentCyan.withOpacity(0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Mute toggle
          _IconBtn(
            icon: widget.isMuted
                ? Icons.volume_off_rounded
                : Icons.volume_up_rounded,
            color: widget.isMuted ? _textSecondary : _accentCyan,
            onTap: widget.onToggleMute,
            tooltip: widget.isMuted ? 'Unmute' : 'Mute',
          ),
          _IconBtn(
            icon: _isExpanded
                ? Icons.keyboard_arrow_down_rounded
                : Icons.keyboard_arrow_up_rounded,
            color: _accentCyan,
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            tooltip: _isExpanded ? 'Collapse panel' : 'Expand panel',
          ),
          // Skip / Close
          _IconBtn(
            icon: Icons.close_rounded,
            color: _textSecondary,
            onTap: widget.onSkip,
            tooltip: 'Skip tour',
          ),
        ],
      ),
    );
  }

  Widget _buildGrabHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.28),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }

  Widget _buildProgressBar(double progress) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: _progressBg,
              color: _accentBlue,
            ),
          ),
          if (widget.step.progressLabel != null)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                widget.step.progressLabel!,
                style: const TextStyle(
                  color: _textSecondary,
                  fontSize: 10.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessage() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      child: Text(
        widget.step.buddyMessage,
        style: const TextStyle(
          color: _textPrimary,
          fontSize: 13,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildCompactSummary(double progress) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.step.buddyMessage,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 52,
            child: Text(
              '${(progress * 100).round()}%',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: _accentCyan.withOpacity(0.9),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHint() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _hintColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _hintColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_rounded, color: _hintColor, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              widget.step.hintMessage!,
              style: const TextStyle(
                color: _hintColor,
                fontSize: 11.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Divider(
        color: Colors.white.withOpacity(0.07),
        height: 1,
      ),
    );
  }

  Widget _buildControls(bool isTask) {
    final canGoBack = widget.currentStepIndex > 0;
    // "Next" always available (manual skip for non-task steps).
    // For task-driven steps it serves as a manual "I already did it" bypass.
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: Row(
        children: [
          // Replay voice
          _IconBtn(
            icon: Icons.replay_rounded,
            color: _textSecondary,
            onTap: widget.onReplayVoice,
            tooltip: 'Replay voice',
          ),
          const SizedBox(width: 4),

          // Back
          if (canGoBack)
            _TextBtn(
              label: '← Back',
              onTap: widget.onBack,
              color: _textSecondary,
            ),

          const Spacer(),

          // Next / Got it
          _NextButton(
            isTask: isTask,
            enabled: !isTask,
            onTap: widget.onNext,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BUDDY AVATAR — animated character
// ─────────────────────────────────────────────────────────────────────────────

class _BuddyAvatar extends StatelessWidget {
  final Animation<double> pulseAnim;
  const _BuddyAvatar({required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnim,
      builder: (_, __) => Transform.scale(
        scale: pulseAnim.value,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF4D8EFF), Color(0xFF00D8FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4D8EFF).withOpacity(0.4),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Center(
            child: Text(
              '🤖',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MICRO-COMPONENTS
// ─────────────────────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  const _IconBtn({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    // Use GestureDetector instead of InkWell
    // No Material/Overlay/Tooltip needed
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

class _TextBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _TextBtn(
      {required this.label, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  final bool isTask;
  final bool enabled;
  final VoidCallback onTap;

  const _NextButton({
    required this.isTask,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: enabled
                ? const [Color(0xFF4D8EFF), Color(0xFF00D8FF)]
                : const [Color(0xFF5D647A), Color(0xFF6B738C)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color:
                  (enabled ? const Color(0xFF4D8EFF) : const Color(0xFF5D647A))
                      .withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isTask ? "Waiting for action" : "Got it →",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODULE COMPLETION CELEBRATION
// ─────────────────────────────────────────────────────────────────────────────

class ModuleCompletionBadge extends StatefulWidget {
  final String emoji;
  final String moduleName;
  final VoidCallback onContinue;

  const ModuleCompletionBadge({
    super.key,
    required this.emoji,
    required this.moduleName,
    required this.onContinue,
  });

  @override
  State<ModuleCompletionBadge> createState() => _ModuleCompletionBadgeState();
}

class _ModuleCompletionBadgeState extends State<ModuleCompletionBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.6),
      child: Center(
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            width: 280,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: const Color(0xFF1C2237),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: const Color(0xFF4D8EFF).withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4D8EFF).withOpacity(0.2),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.emoji,
                  style: const TextStyle(fontSize: 56),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Module Complete!',
                  style: TextStyle(
                    color: Color(0xFF4D8EFF),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.moduleName,
                  style: const TextStyle(
                    color: Color(0xFFF0F4FF),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "You're crushing it! 🔥",
                  style: TextStyle(
                    color: Color(0xFF8895B3),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: widget.onContinue,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4D8EFF), Color(0xFF00D8FF)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      'Continue →',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
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
