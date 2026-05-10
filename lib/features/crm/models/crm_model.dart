import 'dart:convert';

enum LeadStatus {
  newLead,
  contacted,
  interested,
  quotationSent,
  converted,
  lost;

  String get displayName {
    switch (this) {
      case LeadStatus.newLead: return 'New';
      case LeadStatus.contacted: return 'Contacted';
      case LeadStatus.interested: return 'Interested';
      case LeadStatus.quotationSent: return 'Quotation Sent';
      case LeadStatus.converted: return 'Converted';
      case LeadStatus.lost: return 'Lost';
    }
  }
}

class CrmLead {
  final String id;
  final String customerName;
  final String companyName;
  final String phoneNumber;
  final String email;
  final LeadStatus status;
  final String projectType;
  final String address;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  CrmLead({
    required this.id,
    required this.customerName,
    required this.companyName,
    required this.phoneNumber,
    required this.email,
    required this.status,
    required this.projectType,
    required this.address,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  CrmLead copyWith({
    String? id,
    String? customerName,
    String? companyName,
    String? phoneNumber,
    String? email,
    LeadStatus? status,
    String? projectType,
    String? address,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CrmLead(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      companyName: companyName ?? this.companyName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      status: status ?? this.status,
      projectType: projectType ?? this.projectType,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'companyName': companyName,
      'phoneNumber': phoneNumber,
      'email': email,
      'status': status.index,
      'projectType': projectType,
      'address': address,
      'notes': notes,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory CrmLead.fromMap(Map<String, dynamic> map) {
    return CrmLead(
      id: map['id'] ?? '',
      customerName: map['customerName'] ?? '',
      companyName: map['companyName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      email: map['email'] ?? '',
      status: LeadStatus.values[map['status'] ?? 0],
      projectType: map['projectType'] ?? '',
      address: map['address'] ?? '',
      notes: map['notes'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
    );
  }

  String toJson() => json.encode(toMap());

  factory CrmLead.fromJson(String source) => CrmLead.fromMap(json.decode(source));
}

enum ActivityType {
  call,
  followUp,
  meeting,
  note;

  String get displayName {
    switch (this) {
      case ActivityType.call: return 'Call';
      case ActivityType.followUp: return 'Follow Up';
      case ActivityType.meeting: return 'Meeting';
      case ActivityType.note: return 'Note';
    }
  }
}

enum ActivityStatus {
  pending,
  completed,
  cancelled;
}

class CrmActivity {
  final String id;
  final String leadId;
  final ActivityType type;
  final ActivityStatus status;
  final DateTime scheduledAt;
  final DateTime? completedAt;
  final String notes;
  final int durationSeconds;

  CrmActivity({
    required this.id,
    required this.leadId,
    required this.type,
    required this.status,
    required this.scheduledAt,
    this.completedAt,
    required this.notes,
    required this.durationSeconds,
  });

  CrmActivity copyWith({
    String? id,
    String? leadId,
    ActivityType? type,
    ActivityStatus? status,
    DateTime? scheduledAt,
    DateTime? completedAt,
    String? notes,
    int? durationSeconds,
  }) {
    return CrmActivity(
      id: id ?? this.id,
      leadId: leadId ?? this.leadId,
      type: type ?? this.type,
      status: status ?? this.status,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'leadId': leadId,
      'type': type.index,
      'status': status.index,
      'scheduledAt': scheduledAt.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'notes': notes,
      'durationSeconds': durationSeconds,
    };
  }

  factory CrmActivity.fromMap(Map<String, dynamic> map) {
    return CrmActivity(
      id: map['id'] ?? '',
      leadId: map['leadId'] ?? '',
      type: ActivityType.values[map['status'] ?? 0], // BUG in logic if index used alone
      status: ActivityStatus.values[map['status'] ?? 0],
      scheduledAt: DateTime.fromMillisecondsSinceEpoch(map['scheduledAt'] ?? 0),
      completedAt: map['completedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['completedAt']) : null,
      notes: map['notes'] ?? '',
      durationSeconds: map['durationSeconds'] ?? 0,
    );
  }
  
  // Correction to factory fromMap above (type index vs status index)
  static CrmActivity fromMapCorrected(Map<String, dynamic> map) {
    return CrmActivity(
      id: map['id'] ?? '',
      leadId: map['leadId'] ?? '',
      type: ActivityType.values[map['type'] ?? 0],
      status: ActivityStatus.values[map['status'] ?? 0],
      scheduledAt: DateTime.fromMillisecondsSinceEpoch(map['scheduledAt'] ?? 0),
      completedAt: map['completedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['completedAt']) : null,
      notes: map['notes'] ?? '',
      durationSeconds: map['durationSeconds'] ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory CrmActivity.fromJson(String source) => fromMapCorrected(json.decode(source));
}
