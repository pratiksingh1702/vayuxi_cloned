import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quotation_model.dart';

class QuotationState {
  final List<QuotationModel> quotations;
  final bool isLoading;
  final String? error;

  QuotationState({
    this.quotations = const [],
    this.isLoading = false,
    this.error,
  });

  QuotationState copyWith({
    List<QuotationModel>? quotations,
    bool? isLoading,
    String? error,
  }) {
    return QuotationState(
      quotations: quotations ?? this.quotations,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class QuotationNotifier extends StateNotifier<QuotationState> {
  QuotationNotifier() : super(QuotationState()) {
    fetchQuotations();
  }

  Future<void> fetchQuotations() async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 600));
    final mockQuotations = [
      QuotationModel(
        id: 'Q1',
        leadId: 'L2',
        quotationNumber: 'QTN/2026/001',
        date: DateTime.now().subtract(const Duration(days: 3)),
        projectName: 'Factory Building GIDC',
        companyName: 'Patel Logistics',
        items: [
          QuotationItem(description: 'Main Structure', quantity: 1, unit: 'LS', rate: 1500000, amount: 1500000),
          QuotationItem(description: 'Roofing Sheets', quantity: 5000, unit: 'SQM', rate: 450, amount: 2250000),
        ],
        subTotal: 3750000,
        taxPercent: 18,
        taxAmount: 675000,
        marginPercent: 15,
        marginAmount: 562500,
        totalAmount: 4987500,
        finalAmount: 4987500,
        status: QuotationStatus.sent,
        revisionNumber: '1',
      ),
    ];
    state = state.copyWith(quotations: mockQuotations, isLoading: false);
  }

  void addQuotation(QuotationModel quotation) {
    state = state.copyWith(quotations: [quotation, ...state.quotations]);
  }
}

final quotationProvider = StateNotifierProvider<QuotationNotifier, QuotationState>((ref) {
  return QuotationNotifier();
});
