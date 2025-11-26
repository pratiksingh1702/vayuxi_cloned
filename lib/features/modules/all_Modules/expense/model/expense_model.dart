// models/expense_model.dart
class ExpenseModel {
  final String id;
  final String hardwareShopName;
  final String expenseType;
  final double rateInRs;
  final String? invoiceNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String description; // Add this
  final String remarks; // Add this
  final DateTime date; // Add this

  ExpenseModel({
    required this.id,
    required this.hardwareShopName,
    required this.expenseType,
    this.invoiceNumber,
    required this.rateInRs,
    this.createdAt,
    this.updatedAt,
    required this.description, // Add to constructor
    required this.remarks, // Add to constructor
    required this.date, // Add to constructor
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['_id'] ?? '',
      hardwareShopName: json['hardwareShopName'] ?? '',
      expenseType: json['expenseType'] ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '',
      rateInRs: (json['rateInRs'] ?? 0).toDouble(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      description: json['description'] ?? '', // Add this
      remarks: json['remarks'] ?? '', // Add this
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(), // Add this
    );
  }

  // Optional: Add a toJson method for API calls
  Map<String, dynamic> toJson() {
    return {
      'expenseType': expenseType,
      'description': description,
      'invoiceNumber': invoiceNumber,
      'date': date.toIso8601String(),
      'rateInRs': rateInRs,
      'remarks': remarks,
      'hardwareShopName': hardwareShopName,
    };
  }
}