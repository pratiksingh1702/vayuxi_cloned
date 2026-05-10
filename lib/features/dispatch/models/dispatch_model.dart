class DispatchModel {
  final String? id;
  final String workType;
  final String dispatchNumber;
  final String dispatchDate;
  final String vehicleNumber;
  final String driverName;
  final String driverPhone;
  final List<DispatchItem> items;
  final String remarks;
  final String deliveryStatus;

  DispatchModel({
    this.id,
    required this.workType,
    required this.dispatchNumber,
    required this.dispatchDate,
    required this.vehicleNumber,
    required this.driverName,
    required this.driverPhone,
    required this.items,
    required this.remarks,
    this.deliveryStatus = 'pending',
  });

  factory DispatchModel.fromJson(Map<String, dynamic> json) {
    return DispatchModel(
      id: json['_id'],
      workType: json['workType'] ?? '',
      dispatchNumber: json['dispatchNumber'] ?? '',
      dispatchDate: json['dispatchDate'] ?? '',
      vehicleNumber: json['vehicleNumber'] ?? '',
      driverName: json['driverName'] ?? '',
      driverPhone: json['driverPhone'] ?? '',
      items: (json['items'] as List? ?? [])
          .map((e) => DispatchItem.fromJson(e))
          .toList(),
      remarks: json['remarks'] ?? '',
      deliveryStatus: json['deliveryStatus'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'workType': workType,
      'dispatchNumber': dispatchNumber,
      'dispatchDate': dispatchDate,
      'vehicleNumber': vehicleNumber,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'items': items.map((e) => e.toJson()).toList(),
      'remarks': remarks,
      'deliveryStatus': deliveryStatus,
    };
  }
}

class DispatchItem {
  final String itemCode;
  final String itemName;
  final double quantity;
  final String unit;
  final double weight;
  final String remarks;

  DispatchItem({
    required this.itemCode,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.weight,
    this.remarks = '',
  });

  factory DispatchItem.fromJson(Map<String, dynamic> json) {
    return DispatchItem(
      itemCode: json['itemCode'] ?? '',
      itemName: json['itemName'] ?? '',
      quantity: (json['quantity'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
      weight: (json['weight'] ?? 0).toDouble(),
      remarks: json['remarks'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemCode': itemCode,
      'itemName': itemName,
      'quantity': quantity,
      'unit': unit,
      'weight': weight,
      'remarks': remarks,
    };
  }
}

class HandoverModel {
  final String? id;
  final String workType;
  final String handoverNumber;
  final String clientRepresentative;
  final String clientContact;
  final List<HandoverChecklistItem> checklist;
  final String remarks;
  final String status;

  HandoverModel({
    this.id,
    required this.workType,
    required this.handoverNumber,
    required this.clientRepresentative,
    required this.clientContact,
    required this.checklist,
    required this.remarks,
    this.status = 'pending',
  });

  factory HandoverModel.fromJson(Map<String, dynamic> json) {
    return HandoverModel(
      id: json['_id'],
      workType: json['workType'] ?? '',
      handoverNumber: json['handoverNumber'] ?? '',
      clientRepresentative: json['clientRepresentative'] ?? '',
      clientContact: json['clientContact'] ?? '',
      checklist: (json['checklist'] as List? ?? [])
          .map((e) => HandoverChecklistItem.fromJson(e))
          .toList(),
      remarks: json['remarks'] ?? '',
      status: json['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'workType': workType,
      'handoverNumber': handoverNumber,
      'clientRepresentative': clientRepresentative,
      'clientContact': clientContact,
      'checklist': checklist.map((e) => e.toJson()).toList(),
      'remarks': remarks,
    };
  }
}

class HandoverChecklistItem {
  final String item;
  final bool status;
  final List<String> documents;
  final String remarks;

  HandoverChecklistItem({
    required this.item,
    required this.status,
    this.documents = const [],
    this.remarks = '',
  });

  factory HandoverChecklistItem.fromJson(Map<String, dynamic> json) {
    return HandoverChecklistItem(
      item: json['item'] ?? '',
      status: json['status'] ?? false,
      documents: List<String>.from(json['documents'] ?? []),
      remarks: json['remarks'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item': item,
      'status': status,
      'documents': documents,
      'remarks': remarks,
    };
  }
}
