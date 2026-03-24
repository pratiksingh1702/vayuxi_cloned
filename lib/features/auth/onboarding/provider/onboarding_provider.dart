// features/onboarding/provider/onboarding_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../service/onboarding_service.dart';

// ---------------------------------------------------------------------------
// MODEL
// ---------------------------------------------------------------------------

class OnboardingQuestion {
  final int questionId;
  final String question;
  final String type; // 'select' | 'text' | 'yes_no'
  final List<String> options;

  const OnboardingQuestion({
    required this.questionId,
    required this.question,
    required this.type,
    required this.options,
  });

  factory OnboardingQuestion.fromJson(Map<String, dynamic> json) {
    return OnboardingQuestion(
      questionId: json['questionId'] as int,
      question:   json['question']   as String,
      type:       json['type']       as String,
      options: json['options'] != null
          ? List<String>.from(json['options'])
          : [],
    );
  }

  /// Both 'select' and 'yes_no' render as chips — text renders a TextField.
  bool get isChipType => type == 'select' || type == 'yes_no';
}

// ---------------------------------------------------------------------------
// STATE
// ---------------------------------------------------------------------------

enum OnboardingStatus { idle, loading, submitting, success, error }

class OnboardingState {
  final OnboardingStatus status;
  final List<OnboardingQuestion> questions;
  final Map<int, String> answers; // questionId → answer
  final int currentPage;
  final String? referralCode;
  final String? errorMessage;

  const OnboardingState({
    this.status      = OnboardingStatus.idle,
    this.questions   = const [],
    this.answers     = const {},
    this.currentPage = 0,
    this.referralCode,
    this.errorMessage,
  });

  OnboardingState copyWith({
    OnboardingStatus?       status,
    List<OnboardingQuestion>? questions,
    Map<int, String>?       answers,
    int?                    currentPage,
    String?                 referralCode,
    String?                 errorMessage,
  }) {
    return OnboardingState(
      status:       status       ?? this.status,
      questions:    questions    ?? this.questions,
      answers:      answers      ?? this.answers,
      currentPage:  currentPage  ?? this.currentPage,
      referralCode: referralCode ?? this.referralCode,
      errorMessage: errorMessage,
    );
  }

  bool get isCurrentAnswered {
    if (questions.isEmpty) return false;
    final q   = questions[currentPage];
    final ans = answers[q.questionId];
    return ans != null && ans.trim().isNotEmpty;
  }

  bool get allAnswered {
    if (questions.isEmpty) return false;
    return questions.every(
          (q) => answers[q.questionId] != null &&
          answers[q.questionId]!.trim().isNotEmpty,
    );
  }

  bool get isLastPage => currentPage == questions.length - 1;
}

// ---------------------------------------------------------------------------
// NOTIFIER
// ---------------------------------------------------------------------------

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier() : super(const OnboardingState());

  Future<void> fetchQuestions() async {
    state = state.copyWith(
        status: OnboardingStatus.loading, errorMessage: null);
    try {
      final raw       = await OnboardingService.getQuestions();
      final questions = raw.map(OnboardingQuestion.fromJson).toList();
      state = state.copyWith(
        status:      OnboardingStatus.idle,
        questions:   questions,
        currentPage: 0,
        answers:     {},
      );
    } catch (e) {
      state = state.copyWith(
        status:       OnboardingStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void setAnswer(int questionId, String answer) {
    final updated = Map<int, String>.from(state.answers);
    updated[questionId] = answer;
    state = state.copyWith(answers: updated);
  }

  void nextPage() {
    if (!state.isLastPage) {
      state = state.copyWith(currentPage: state.currentPage + 1);
    }
  }

  void prevPage() {
    if (state.currentPage > 0) {
      state = state.copyWith(currentPage: state.currentPage - 1);
    }
  }

  Future<String?> submitAnswers() async {
    if (!state.allAnswered) return null;
    state = state.copyWith(
        status: OnboardingStatus.submitting, errorMessage: null);
    try {
      final payload = state.answers.entries
          .map((e) => {'questionId': e.key, 'answer': e.value})
          .toList();
      final referralCode = await OnboardingService.submitAnswers(payload);
      state = state.copyWith(
        status:       OnboardingStatus.success,
        referralCode: referralCode,
      );
      return referralCode;
    } catch (e) {
      state = state.copyWith(
        status:       OnboardingStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }

  void reset() => state = const OnboardingState();
}

// ---------------------------------------------------------------------------
// PROVIDER
// ---------------------------------------------------------------------------

final onboardingProvider =
StateNotifierProvider<OnboardingNotifier, OnboardingState>(
      (ref) => OnboardingNotifier(),
);