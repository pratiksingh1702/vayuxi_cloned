class SiteModel {
  final String id;
  final String siteName;
  final String address;
  final String contactPerson;
  final String gstNo;
  final String phoneNumber;
  final String emailId;
  final String? documentDate; // Nullable since it can be null
  final String documentNumber;
  final bool isDeleted;
  final String company;
  final String type;
  final String createdAt;
  final String updatedAt;

  SiteModel({
    required this.id,
    required this.siteName,
    required this.address,
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
  });

  /// ✅ Convert JSON to SiteModel
  factory SiteModel.fromJson(Map<String, dynamic> json) {
    return SiteModel(
      id: json['_id'] ?? '',
      siteName: json['siteName'] ?? '',
      address: json['address'] ?? '',
      contactPerson: json['contactPerson'] ?? '',
      gstNo: json['gstNo'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      emailId: json['emailId'] ?? '',
      documentDate: json['documentDate'], // Can be null
      documentNumber: json['documentNumber'] ?? '',
      isDeleted: json['isDeleted'] ?? false,
      company: json['company'] ?? '',
      type: json['type'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  /// ✅ Convert SiteModel to JSON
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
    };
  }
}
