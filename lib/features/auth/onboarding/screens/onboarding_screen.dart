// features/onboarding/screens/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_access.dart';
import '../provider/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;
  final _textControllers = <int, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingProvider.notifier).fetchQuestions();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in _textControllers.values) c.dispose();
    super.dispose();
  }

  TextEditingController _controllerFor(int questionId) =>
      _textControllers.putIfAbsent(questionId, () => TextEditingController());

  void _next(OnboardingNotifier notifier, OnboardingState state) {
    if (state.isLastPage) {
      _submit(notifier);
    } else {
      notifier.nextPage();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _back(OnboardingNotifier notifier) {
    notifier.prevPage();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _submit(OnboardingNotifier notifier) async {
    final referralCode = await notifier.submitAnswers();
    if (!mounted) return;

    if (referralCode != null) {
      ref.read(appAccessProvider.notifier).markOnboardingCompleted();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Onboarding complete! Check your email for the referral code.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );

      context.go('/trial');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    final theme    = Theme.of(context);

    if (state.status == OnboardingStatus.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (state.status == OnboardingStatus.error && state.questions.isEmpty) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(state.errorMessage ?? 'Something went wrong',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge),
                const SizedBox(height: 24),
                FilledButton(
                    onPressed: notifier.fetchQuestions,
                    child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    if (state.questions.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final total       = state.questions.length;
    final current     = state.currentPage + 1;
    final progress    = current / total;
    final isSubmitting = state.status == OnboardingStatus.submitting;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _OnboardingHeader(
              current:  current,
              total:    total,
              progress: progress,
              onBack:   state.currentPage > 0 ? () => _back(notifier) : null,
            ),
            Expanded(
              child: PageView.builder(
                controller:   _pageController,
                physics:      const NeverScrollableScrollPhysics(),
                itemCount:    total,
                itemBuilder:  (context, index) {
                  final q = state.questions[index];
                  return _QuestionPage(
                    question:       q,
                    selectedAnswer: state.answers[q.questionId],
                    textController: q.isChipType ? null : _controllerFor(q.questionId),
                    onAnswerSelected: (answer) =>
                        notifier.setAnswer(q.questionId, answer),
                  );
                },
              ),
            ),
            if (state.errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 4),
                child: Text(
                  state.errorMessage!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),
            _BottomButton(
              isLastPage: state.isLastPage,
              isEnabled:  state.isCurrentAnswered && !isSubmitting,
              isLoading:  isSubmitting,
              onPressed:  () => _next(notifier, state),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUB-WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({
    required this.current,
    required this.total,
    required this.progress,
    this.onBack,
  });

  final int current;
  final int total;
  final double progress;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (onBack != null)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: onBack,
                )
              else
                const SizedBox(width: 48),
              const Spacer(),
              Text(
                '$current / $total',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value:           progress,
                minHeight:       6,
                backgroundColor:
                theme.colorScheme.primaryContainer.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _QuestionPage extends StatelessWidget {
  const _QuestionPage({
    required this.question,
    required this.selectedAnswer,
    required this.onAnswerSelected,
    this.textController,
  });

  final OnboardingQuestion question;
  final String? selectedAnswer;
  final ValueChanged<String> onAnswerSelected;
  final TextEditingController? textController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              height: 180, width: 180,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.business_center_outlined,
                size: 80,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 32),

          Text(
            question.question,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),

          // ── Chips for 'select' and 'yes_no', TextField for 'text' ─────────
          if (question.isChipType)
            Wrap(
              spacing: 10, runSpacing: 10,
              children: question.options.map((option) {
                return _OptionChip(
                  label:      option,
                  isSelected: selectedAnswer == option,
                  onTap:      () => onAnswerSelected(option),
                );
              }).toList(),
            )
          else
            TextField(
              controller: textController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Type your answer here…',
                filled: true,
                fillColor:
                theme.colorScheme.surfaceVariant.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary, width: 2,
                  ),
                ),
              ),
              onChanged: onAnswerSelected,
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme       = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withOpacity(0.4),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.25),
              blurRadius: 8, offset: const Offset(0, 3),
            ),
          ]
              : [],
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isSelected
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
            fontWeight:
            isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _BottomButton extends StatelessWidget {
  const _BottomButton({
    required this.isLastPage,
    required this.isEnabled,
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLastPage;
  final bool isEnabled;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: SizedBox(
        width: double.infinity, height: 52,
        child: FilledButton(
          onPressed: isEnabled ? onPressed : null,
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: isLoading
              ? const SizedBox(
            width: 22, height: 22,
            child: CircularProgressIndicator(
                strokeWidth: 2.5, color: Colors.white),
          )
              : Text(
            isLastPage ? 'Submit & Continue' : 'Next',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white, fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}