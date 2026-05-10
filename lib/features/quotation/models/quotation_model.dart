class QuotationModel {
  final String? id;
  final String leadId;
  final String quotationNumber;
  final DateTime date;
  final List<QuotationItem> items;
  final double subTotal;
  final double taxPercent;
  final double taxAmount;
  final double marginPercent;
  final double marginAmount;
  final double totalAmount;
  final QuotationStatus status;
  final List<QuotationRevision> revisions;
  final String remarks;
  final String projectName;
  final String companyName;
  final double finalAmount;
  final String revisionNumber;

  QuotationModel({
    this.id,
    required this.leadId,
    required this.quotationNumber,
    required this.date,
    required this.items,
    required this.subTotal,
    required this.taxPercent,
    required this.taxAmount,
    required this.marginPercent,
    required this.marginAmount,
    required this.totalAmount,
    this.status = QuotationStatus.draft,
    this.revisions = const [],
    this.remarks = '',
    this.projectName = '',
    this.companyName = '',
    this.finalAmount = 0,
    this.revisionNumber = '1',
  });

  factory QuotationModel.fromJson(Map<String, dynamic> json) {
    return QuotationModel(
      id: json['_id'],
      leadId: json['leadId'] ?? '',
      quotationNumber: json['quotationNumber'] ?? '',
      date: DateTime.parse(json['date']),
      items: (json['items'] as List? ?? [])
          .map((e) => QuotationItem.fromJson(e))
          .toList(),
      subTotal: (json['subTotal'] ?? 0).toDouble(),
      taxPercent: (json['taxPercent'] ?? 0).toDouble(),
      taxAmount: (json['taxAmount'] ?? 0).toDouble(),
      marginPercent: (json['marginPercent'] ?? 0).toDouble(),
      marginAmount: (json['marginAmount'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      status: _parseStatus(json['status']),
      revisions: (json['revisions'] as List? ?? [])
          .map((e) => QuotationRevision.fromJson(e))
          .toList(),
      remarks: json['remarks'] ?? '',
      projectName: json['projectName'] ?? '',
      companyName: json['companyName'] ?? '',
      finalAmount: (json['finalAmount'] ?? 0).toDouble(),
      revisionNumber: json['revisionNumber'] ?? '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'leadId': leadId,
      'quotationNumber': quotationNumber,
      'date': date.toIso8601String(),
      'items': items.map((e) => e.toJson()).toList(),
      'subTotal': subTotal,
      'taxPercent': taxPercent,
      'taxAmount': taxAmount,
      'marginPercent': marginPercent,
      'marginAmount': marginAmount,
      'totalAmount': totalAmount,
      'status': status.name,
      'remarks': remarks,
      'projectName': projectName,
      'companyName': companyName,
      'finalAmount': finalAmount,
      'revisionNumber': revisionNumber,
    };
  }

  static QuotationStatus _parseStatus(String? status) {
    return QuotationStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => QuotationStatus.draft,
    );
  }
}

class QuotationItem {
  final String description;
  final double quantity;
  final String unit;
  final double rate;
  final double amount;

  QuotationItem({
    required this.description,
    required this.quantity,
    required this.unit,
    required this.rate,
    required this.amount,
  });

  factory QuotationItem.fromJson(Map<String, dynamic> json) {
    return QuotationItem(
      description: json['description'] ?? '',
      quantity: (json['quantity'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
      rate: (json['rate'] ?? 0).toDouble(),
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'quantity': quantity,
      'unit': unit,
      'rate': rate,
      'amount': amount,
    };
  }
}

class QuotationRevision {
  final String revisionNumber;
  final DateTime date;
  final String reason;
  final String revisedBy;

  QuotationRevision({
    required this.revisionNumber,
    required this.date,
    required this.reason,
    required this.revisedBy,
  });

  factory QuotationRevision.fromJson(Map<String, dynamic> json) {
    return QuotationRevision(
      revisionNumber: json['revisionNumber'] ?? '',
      date: DateTime.parse(json['date']),
      reason: json['reason'] ?? '',
      revisedBy: json['revisedBy'] ?? '',
    );
  }
}

enum QuotationStatus { draft, sent, approved, rejected, revised }

extension QuotationStatusExtension on QuotationStatus {
  String get displayName {
    switch (this) {
      case QuotationStatus.draft: return 'Draft';
      case QuotationStatus.sent: return 'Sent';
      case QuotationStatus.approved: return 'Approved';
      case QuotationStatus.rejected: return 'Rejected';
      case QuotationStatus.revised: return 'Revised';
    }
  }
}
