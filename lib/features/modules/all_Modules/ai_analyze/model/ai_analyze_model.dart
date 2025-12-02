class AudioAnalysis {
  Metadata metadata;
  Modules modules;
  String modelUsed;
  String audioFile;
  int fileSize;

  AudioAnalysis({
    required this.metadata,
    required this.modules,
    required this.modelUsed,
    required this.audioFile,
    required this.fileSize,
  });

  factory AudioAnalysis.fromJson(Map<String, dynamic> json) {
    return AudioAnalysis(
      metadata: Metadata.fromJson(json["metadata"] ?? {}),
      modules: Modules.fromJson(json["modules"] ?? {}),
      modelUsed: json["model_used"]?.toString() ?? "",
      audioFile: json["audio_file"]?.toString() ?? "",
      fileSize: json["file_size"] is int ? json["file_size"] : int.tryParse(json["file_size"]?.toString() ?? "0") ?? 0,
    );
  }
}

// ------------------ METADATA ------------------

class Metadata {
  String status;
  String language;
  String transcript;
  String siteRemarks;

  Metadata({
    required this.status,
    required this.language,
    required this.transcript,
    required this.siteRemarks,
  });

  factory Metadata.fromJson(Map<String, dynamic> json) {
    return Metadata(
      status: json["status"]?.toString() ?? "",
      language: json["language_detected"]?.toString() ?? "",
      transcript: json["raw_transcript_corrected"]?.toString() ?? "",
      siteRemarks: json["site_remarks"]?.toString() ?? "",
    );
  }
}

// ------------------ MODULE WRAPPER ------------------

class Modules {
  AttendanceModule attendance;
  DprModule dpr;
  ExpenseModule expense;
  InventoryModule inventory;

  Modules({
    required this.attendance,
    required this.dpr,
    required this.expense,
    required this.inventory,
  });

  factory Modules.fromJson(Map<String, dynamic> json) {
    return Modules(
      attendance: AttendanceModule.fromJson(json["attendance"] ?? {}),
      dpr: DprModule.fromJson(json["dpr"] ?? {}),
      expense: ExpenseModule.fromJson(json["expense"] ?? {}),
      inventory: InventoryModule.fromJson(json["inventory"] ?? {}),
    );
  }
}

// ------------------ ATTENDANCE ------------------

class AttendanceModule {
  int totalAbsent;
  List<String> absentNames;
  OvertimeDetails overtime;

  AttendanceModule({
    required this.totalAbsent,
    required this.absentNames,
    required this.overtime,
  });

  factory AttendanceModule.fromJson(Map<String, dynamic> json) {
    return AttendanceModule(
      totalAbsent: json["total_absent"] is int ? json["total_absent"] : int.tryParse(json["total_absent"]?.toString() ?? "0") ?? 0,
      absentNames: List<String>.from(json["absent_names"]?.map((x) => x.toString()) ?? []),
      overtime: OvertimeDetails.fromJson(json["overtime_details"] ?? {}),
    );
  }
}

class OvertimeDetails {
  double? durationHours;
  String? appliesTo;

  OvertimeDetails({
    this.durationHours,
    this.appliesTo,
  });

  factory OvertimeDetails.fromJson(Map<String, dynamic> json) {
    return OvertimeDetails(
      durationHours: json["duration_hours"] is double ? json["duration_hours"] : json["duration_hours"] is int ? (json["duration_hours"] as int).toDouble() : null,
      appliesTo: json["applies_to"]?.toString(),
    );
  }
}

// ------------------ DPR MODULE ------------------

class DprModule {
  String material;
  String lineSize;
  String length;
  List<WorkItem> items;

  DprModule({
    required this.material,
    required this.lineSize,
    required this.length,
    required this.items,
  });

  factory DprModule.fromJson(Map<String, dynamic> json) {
    return DprModule(
      material: json["material_of_construction"]?.toString() ?? "",
      lineSize: json["line_size"]?.toString() ?? "",
      length: json["segment_length"].toString()??"" ,
        items: (json["work_items"] as List? ?? [])
          .map((e) => WorkItem.fromJson(e))
          .toList(),
    );
  }
}

class WorkItem {
  String itemName;
  double quantity;
  String unit;

  WorkItem({
    required this.itemName,
    required this.quantity,
    required this.unit,
  });

  factory WorkItem.fromJson(Map<String, dynamic> json) {
    return WorkItem(
      itemName: json["item_name"]?.toString() ?? "",
      quantity: json["quantity"] is double ? json["quantity"] : (json["quantity"] is int ? (json["quantity"] as int).toDouble() : 0.0),
      unit: json["unit"]?.toString() ?? "",
    );
  }
}

// ------------------ EXPENSE MODULE ------------------

class ExpenseModule {
  String source;
  double totalAmount;
  String currency;
  List<ExpenseItem> items;

  ExpenseModule({
    required this.source,
    required this.totalAmount,
    required this.currency,
    required this.items,
  });

  factory ExpenseModule.fromJson(Map<String, dynamic> json) {
    return ExpenseModule(
      source: json["source"]?.toString() ?? "",
      totalAmount: json["total_invoice_amount"] is double ? json["total_invoice_amount"] : (json["total_invoice_amount"] is int ? (json["total_invoice_amount"] as int).toDouble() : 0.0),
      currency: json["currency"]?.toString() ?? "",
      items: (json["items_purchased"] as List? ?? [])
          .map((e) => ExpenseItem.fromJson(e))
          .toList(),
    );
  }
}

class ExpenseItem {
  String name;
  double qty;
  String unit;

  ExpenseItem({
    required this.name,
    required this.qty,
    required this.unit,
  });

  factory ExpenseItem.fromJson(Map<String, dynamic> json) {
    return ExpenseItem(
      name: json["item_name"]?.toString() ?? "",
      qty: json["quantity"] is double ? json["quantity"] : (json["quantity"] is int ? (json["quantity"] as int).toDouble() : 0.0),
      unit: json["unit"]?.toString() ?? "",
    );
  }
}

// ------------------ INVENTORY MODULE ------------------

class InventoryModule {
  String source;
  List<InventoryItem> items;

  InventoryModule({
    required this.source,
    required this.items,
  });

  factory InventoryModule.fromJson(Map<String, dynamic> json) {
    return InventoryModule(
      source: json["source"]?.toString() ?? "",
      items: (json["items_withdrawn"] as List? ?? [])
          .map((e) => InventoryItem.fromJson(e))
          .toList(),
    );
  }
}

class InventoryItem {
  String name;
  double qty;
  String unit;

  InventoryItem({
    required this.name,
    required this.qty,
    required this.unit,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      name: json["item_name"]?.toString() ?? "",
      qty: json["quantity"] is double ? json["quantity"] : (json["quantity"] is int ? (json["quantity"] as int).toDouble() : 0.0),
      unit: json["unit"]?.toString() ?? "",
    );
  }
}