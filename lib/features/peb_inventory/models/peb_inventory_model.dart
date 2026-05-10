class PebInventoryItem {
  final String? id;
  final String materialName;
  final String materialCode;
  final String materialGrade;
  final String materialType;
  final String workType;
  final String moc;
  final String size;
  final String thickness;
  final double currentStock;
  final double currentWeight;
  final String uom;
  final String supplier;

  PebInventoryItem({
    this.id,
    required this.materialName,
    required this.materialCode,
    required this.materialGrade,
    required this.materialType,
    required this.workType,
    required this.moc,
    required this.size,
    required this.thickness,
    this.currentStock = 0,
    this.currentWeight = 0,
    required this.uom,
    required this.supplier,
  });

  factory PebInventoryItem.fromJson(Map<String, dynamic> json) {
    return PebInventoryItem(
      id: json['_id'],
      materialName: json['materialName'] ?? '',
      materialCode: json['materialCode'] ?? '',
      materialGrade: json['materialGrade'] ?? '',
      materialType: json['materialType'] ?? '',
      workType: json['workType'] ?? '',
      moc: json['moc'] ?? '',
      size: json['size'] ?? '',
      thickness: json['thickness'] ?? '',
      currentStock: (json['currentStock'] ?? 0).toDouble(),
      currentWeight: (json['currentWeight'] ?? 0).toDouble(),
      uom: json['uom'] ?? '',
      supplier: json['supplier'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'materialName': materialName,
      'materialCode': materialCode,
      'materialGrade': materialGrade,
      'materialType': materialType,
      'workType': workType,
      'moc': moc,
      'size': size,
      'thickness': thickness,
      'currentStock': currentStock,
      'currentWeight': currentWeight,
      'uom': uom,
      'supplier': supplier,
    };
  }
}

class InventoryMovement {
  final String movementType; // purchase_in, consumption, transfer_out, etc.
  final double quantity;
  final double weight;
  final String uom;
  final String referenceType;
  final String referenceId;
  final String referenceNumber;
  final String projectName;
  final String remarks;

  InventoryMovement({
    required this.movementType,
    required this.quantity,
    required this.weight,
    required this.uom,
    required this.referenceType,
    required this.referenceId,
    required this.referenceNumber,
    required this.projectName,
    required this.remarks,
  });

  Map<String, dynamic> toJson() {
    return {
      'movementType': movementType,
      'quantity': quantity,
      'weight': weight,
      'uom': uom,
      'referenceType': referenceType,
      'referenceId': referenceId,
      'referenceNumber': referenceNumber,
      'projectName': projectName,
      'remarks': remarks,
    };
  }
}
