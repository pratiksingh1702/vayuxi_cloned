class ProcurementRequest {
  final String? id;
  final String requestNumber;
  final String workType;
  final String priority;
  final String expectedDeliveryDate;
  final ProcurementStatus status;
  final String remarks;
  final List<ProcurementItem> items;
  final DateTime? createdAt;
  final String siteId;
  final String description;
  final double quantity;
  final String unit;
  final String requestedBy;
  final DateTime? requestedAt;
  final DateTime? expectedDate;

  ProcurementRequest({
    this.id,
    required this.requestNumber,
    required this.workType,
    required this.priority,
    required this.expectedDeliveryDate,
    this.status = ProcurementStatus.pending,
    required this.remarks,
    required this.items,
    this.createdAt,
    this.siteId = '',
    this.description = '',
    this.quantity = 0,
    this.unit = '',
    this.requestedBy = '',
    this.requestedAt,
    this.expectedDate,
  });

  factory ProcurementRequest.fromJson(Map<String, dynamic> json) {
    return ProcurementRequest(
      id: json['_id'],
      requestNumber: json['requestNumber'] ?? '',
      workType: json['workType'] ?? '',
      priority: json['priority'] ?? 'medium',
      expectedDeliveryDate: json['expectedDeliveryDate'] ?? '',
      status: _parseStatus(json['status']),
      remarks: json['remarks'] ?? '',
      items: (json['items'] as List? ?? [])
          .map((e) => ProcurementItem.fromJson(e))
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      siteId: json['siteId'] ?? '',
      description: json['description'] ?? '',
      quantity: (json['quantity'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
      requestedBy: json['requestedBy'] ?? '',
      requestedAt: json['requestedAt'] != null
          ? DateTime.parse(json['requestedAt'])
          : null,
      expectedDate: json['expectedDate'] != null
          ? DateTime.parse(json['expectedDate'])
          : null,
    );
  }

  static ProcurementStatus _parseStatus(String? status) {
    return ProcurementStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => ProcurementStatus.pending,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requestNumber': requestNumber,
      'workType': workType,
      'priority': priority,
      'expectedDeliveryDate': expectedDeliveryDate,
      'remarks': remarks,
      'items': items.map((e) => e.toJson()).toList(),
      'siteId': siteId,
      'description': description,
      'quantity': quantity,
      'unit': unit,
      'requestedBy': requestedBy,
      'requestedAt': requestedAt?.toIso8601String(),
      'expectedDate': expectedDate?.toIso8601String(),
    };
  }
}

class ProcurementItem {
  final String itemCode;
  final String itemName;
  final String specification;
  final double quantity;
  final String unit;
  final String remarks;

  ProcurementItem({
    required this.itemCode,
    required this.itemName,
    required this.specification,
    required this.quantity,
    required this.unit,
    this.remarks = '',
  });

  factory ProcurementItem.fromJson(Map<String, dynamic> json) {
    return ProcurementItem(
      itemCode: json['itemCode'] ?? '',
      itemName: json['itemName'] ?? '',
      specification: json['specification'] ?? '',
      quantity: (json['quantity'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
      remarks: json['remarks'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemCode': itemCode,
      'itemName': itemName,
      'specification': specification,
      'quantity': quantity,
      'unit': unit,
      'remarks': remarks,
    };
  }
}

class Vendor {
  final String? id;
  final String vendorName;
  final String vendorCode;
  final String contactPerson;
  final String phoneNumber;
  final String email;
  final String address;
  final List<String> materials;
  final List<String> workTypes;
  final double rating;
  final String status;

  Vendor({
    this.id,
    required this.vendorName,
    required this.vendorCode,
    required this.contactPerson,
    required this.phoneNumber,
    required this.email,
    required this.address,
    required this.materials,
    required this.workTypes,
    this.rating = 0.0,
    this.status = 'active',
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['_id'],
      vendorName: json['vendorName'] ?? '',
      vendorCode: json['vendorCode'] ?? '',
      contactPerson: json['contactPerson'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      materials: List<String>.from(json['materials'] ?? []),
      workTypes: List<String>.from(json['workTypes'] ?? []),
      rating: (json['rating'] ?? 0).toDouble(),
      status: json['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vendorName': vendorName,
      'vendorCode': vendorCode,
      'contactPerson': contactPerson,
      'phoneNumber': phoneNumber,
      'email': email,
      'address': address,
      'materials': materials,
      'workTypes': workTypes,
      'rating': rating,
      'status': status,
    };
  }
}

class PurchaseOrder {
  final String? id;
  final String poNumber;
  final String workType;
  final String vendorId;
  final String requestId;
  final String orderDate;
  final String expectedDeliveryDate;
  final String remarks;
  final List<POItem> items;
  final double totalAmount;
  final String status;

  PurchaseOrder({
    this.id,
    required this.poNumber,
    required this.workType,
    required this.vendorId,
    required this.requestId,
    required this.orderDate,
    required this.expectedDeliveryDate,
    required this.remarks,
    required this.items,
    required this.totalAmount,
    this.status = 'pending',
  });

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    return PurchaseOrder(
      id: json['_id'],
      poNumber: json['poNumber'] ?? '',
      workType: json['workType'] ?? '',
      vendorId: json['vendorId'] ?? '',
      requestId: json['requestId'] ?? '',
      orderDate: json['orderDate'] ?? '',
      expectedDeliveryDate: json['expectedDeliveryDate'] ?? '',
      remarks: json['remarks'] ?? '',
      items: (json['items'] as List? ?? [])
          .map((e) => POItem.fromJson(e))
          .toList(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'poNumber': poNumber,
      'workType': workType,
      'vendorId': vendorId,
      'requestId': requestId,
      'orderDate': orderDate,
      'expectedDeliveryDate': expectedDeliveryDate,
      'remarks': remarks,
      'items': items.map((e) => e.toJson()).toList(),
      'totalAmount': totalAmount,
    };
  }
}

class POItem {
  final String itemCode;
  final String itemName;
  final String specification;
  final double quantity;
  final String unit;
  final double rate;
  final double amount;

  POItem({
    required this.itemCode,
    required this.itemName,
    required this.specification,
    required this.quantity,
    required this.unit,
    required this.rate,
    required this.amount,
  });

  factory POItem.fromJson(Map<String, dynamic> json) {
    return POItem(
      itemCode: json['itemCode'] ?? '',
      itemName: json['itemName'] ?? '',
      specification: json['specification'] ?? '',
      quantity: (json['quantity'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
      rate: (json['rate'] ?? 0).toDouble(),
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemCode': itemCode,
      'itemName': itemName,
      'specification': specification,
      'quantity': quantity,
      'unit': unit,
      'rate': rate,
      'amount': amount,
    };
  }
}

enum ProcurementStatus { pending, approved, ordered, received, cancelled }

extension ProcurementStatusExtension on ProcurementStatus {
  String get displayName {
    switch (this) {
      case ProcurementStatus.pending: return 'Pending';
      case ProcurementStatus.approved: return 'Approved';
      case ProcurementStatus.ordered: return 'Ordered';
      case ProcurementStatus.received: return 'Received';
      case ProcurementStatus.cancelled: return 'Cancelled';
    }
  }
}
