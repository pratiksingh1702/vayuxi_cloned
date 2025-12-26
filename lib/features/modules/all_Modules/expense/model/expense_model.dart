class ExpenseModel {
  final String? id;
  final String? expenseType;
  final String? description;
  final DateTime? date;
  final double? amount;
  final String? remarks;
  final String? invoiceNumber;
  final String? hardwareShopName;
  final int? quantity;
  final String? month;
  final int? year;
  final String? place;
  final String? manpowerId;
  final String? siteId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ExpenseModel({
    this.id,
    this.expenseType,
    this.description,
    this.date,
    this.amount,
    this.remarks,
    this.invoiceNumber,
    this.hardwareShopName,
    this.quantity,
    this.month,
    this.year,
    this.place,
    this.manpowerId,
    this.siteId,
    this.createdAt,
    this.updatedAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['_id']?.toString(),
      expenseType: json['expenseType']?.toString(),
      description: json['description']?.toString(),
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      amount: _toDouble(json['amount']),
      remarks: json['remarks']?.toString(),
      invoiceNumber: json['invoiceNumber']?.toString(),
      hardwareShopName: json['hardwareShop']?.toString(),
      quantity: _toInt(json['quantity']),
      month: json['month']?.toString(),
      year: _toInt(json['year']),
      place: json['place']?.toString(),
      manpowerId: json['manpowerId']?.toString(),
      siteId: json['siteId']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'expenseType': expenseType,
      'description': description,
      'date': date?.toIso8601String(),
      'amount': amount,
      'remarks': remarks,
      'invoiceNumber': invoiceNumber,
      'hardwareShop': hardwareShopName,
      'quantity': quantity,
      'month': month,
      'year': year,
      'place': place,
      'manpowerId': manpowerId,
      'siteId': siteId,
    };
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}