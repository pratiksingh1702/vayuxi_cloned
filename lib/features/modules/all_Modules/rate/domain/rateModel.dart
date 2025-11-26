import '../../site_Details/repository/siteModel.dart';

class Rate {
  final String id;
  final SiteModel site;
  final String serviceName;
  final String hsnSacCode;
  final double rate;
  final String uom;
  final String? remarks;
  final bool isDeleted;
  final String company;
  final String type;
  final DateTime createdAt;
  final DateTime updatedAt;

  Rate({
    required this.id,
    required this.site,
    required this.serviceName,
    required this.hsnSacCode,
    required this.rate,
    required this.uom,
    this.remarks,
    required this.isDeleted,
    required this.company,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Rate.fromJson(Map<String, dynamic> json) {
    return Rate(
      id: json['_id'] ?? '',
      site: SiteModel.fromJson(json['siteId'] ?? {}),
      serviceName: json['serviceName'] ?? '',
      hsnSacCode: json['hsnSacCode'] ?? '',
      rate: (json['rate'] ?? 0).toDouble(),
      uom: json['uom'] ?? '',
      remarks: json['remarks'],
      isDeleted: json['isDeleted'] ?? false,
      company: json['company'] ?? '',
      type: json['type'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'siteId': site.toJson(),
    'serviceName': serviceName,
    'hsnSacCode': hsnSacCode,
    'rate': rate,
    'uom': uom,
    'remarks': remarks,
    'isDeleted': isDeleted,
    'company': company,
    'type': type,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  Rate copyWith({
    String? id,
    SiteModel? site,
    String? serviceName,
    String? hsnSacCode,
    double? rate,
    String? uom,
    String? remarks,
    bool? isDeleted,
    String? company,
    String? type,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Rate(
      id: id ?? this.id,
      site: site ?? this.site,
      serviceName: serviceName ?? this.serviceName,
      hsnSacCode: hsnSacCode ?? this.hsnSacCode,
      rate: rate ?? this.rate,
      uom: uom ?? this.uom,
      remarks: remarks ?? this.remarks,
      isDeleted: isDeleted ?? this.isDeleted,
      company: company ?? this.company,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
