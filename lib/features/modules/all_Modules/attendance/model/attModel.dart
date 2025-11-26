import '../../Manpower Details/model/manpower_model.dart';

class AttendanceModel {
  final String id;
  final String siteId;
  final ManpowerModel manpower;
  final double ot; // changed from int
  final String date;
  final String status;
  final double totalHours; // changed from int
  final String company;
  final String type;
  final DateTime createdAt;
  final DateTime updatedAt;

  AttendanceModel({
    required this.id,
    required this.siteId,
    required this.manpower,
    required this.ot,
    required this.date,
    required this.status,
    required this.totalHours,
    required this.company,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['_id'] ?? '',
      siteId: json['siteId'] ?? '',
      manpower: ManpowerModel.fromJson(json['manpowerId']),
      ot: (json['ot'] ?? 0).toDouble(),
      date: json['date'] ?? '',
      status: json['status'] ?? '',
      totalHours: (json['totalHours'] ?? 0).toDouble(),
      company: json['company'] ?? '',
      type: json['type'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "siteId": siteId,
      "manpowerId": manpower.toJson(),
      "ot": ot,
      "date": date,
      "status": status,
      "totalHours": totalHours,
      "company": company,
      "type": type,
      "createdAt": createdAt.toIso8601String(),
      "updatedAt": updatedAt.toIso8601String(),
    };
  }

  AttendanceModel copyWith({
    String? id,
    String? siteId,
    ManpowerModel? manpower,
    double? ot,
    String? date,
    String? status,
    double? totalHours,
    String? company,
    String? type,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      siteId: siteId ?? this.siteId,
      manpower: manpower ?? this.manpower,
      ot: ot ?? this.ot,
      date: date ?? this.date,
      status: status ?? this.status,
      totalHours: totalHours ?? this.totalHours,
      company: company ?? this.company,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
