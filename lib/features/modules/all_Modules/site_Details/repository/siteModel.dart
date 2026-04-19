class SiteModel {
  final String id;
  final String siteName;
  final String address;
  final String? shippingAddress;
  final String contactPerson;
  final String gstNo;
  final String phoneNumber;
  final String emailId;
  final String? documentDate; // nullable
  final String documentNumber;
  final bool isDeleted;
  final String company;
  final String type;

  final String createdAt;
  final String updatedAt;
  final String? siteImage; // ✅ OPTIONAL FIELD
  final SiteCounts counts;

  SiteModel({
    required this.id,
    required this.siteName,
    required this.address,
    required this.shippingAddress,
    required this.contactPerson,
    required this.gstNo,
    required this.phoneNumber,
    required this.emailId,
    required this.documentDate,
    required this.documentNumber,
    required this.isDeleted,
    required this.company,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.siteImage, // ✅ optional
    this.counts = const SiteCounts(),
  });

  factory SiteModel.fromJson(Map<String, dynamic> json) {
    return SiteModel(
      id: json['_id'] ?? '',
      siteName: json['siteName'] ?? '',
      address: json['address'] ?? '',
      shippingAddress: json['shippingAddress'],
      contactPerson: json['contactPerson'] ?? '',
      gstNo: json['gstNo'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      emailId: json['emailId'] ?? '',
      documentDate: json['documentDate'],
      documentNumber: json['documentNumber'] ?? '',
      isDeleted: json['isDeleted'] ?? false,
      company: json['company'] ?? '',
      type: json['type'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      siteImage: (json['siteImage'] != null &&
              json['siteImage'].toString().trim().isNotEmpty)
          ? json['siteImage']
          : null,
      counts: SiteCounts.fromJson(json['counts']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'siteName': siteName,
      'address': address,
      'contactPerson': contactPerson,
      'gstNo': gstNo,
      'phoneNumber': phoneNumber,
      'emailId': emailId,
      'documentDate': documentDate,
      'documentNumber': documentNumber,
      'isDeleted': isDeleted,
      'company': company,
      'type': type,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'siteImage': siteImage, // ✅ included
      'counts': counts.toJson(),
    };
  }
}

class SiteCounts {
  final int teams;
  final int dprMechanical;
  final int dprInsulation;
  final int manpower;
  final int totalDpr;

  const SiteCounts({
    this.teams = 0,
    this.dprMechanical = 0,
    this.dprInsulation = 0,
    this.manpower = 0,
    this.totalDpr = 0,
  });

  factory SiteCounts.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return const SiteCounts();
    }

    int parseInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return SiteCounts(
      teams: parseInt(json['teams']),
      dprMechanical: parseInt(json['dprMechanical']),
      dprInsulation: parseInt(json['dprInsulation']),
      manpower: parseInt(json['manpower']),
      totalDpr: parseInt(json['totalDpr']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teams': teams,
      'dprMechanical': dprMechanical,
      'dprInsulation': dprInsulation,
      'manpower': manpower,
      'totalDpr': totalDpr,
    };
  }
}
