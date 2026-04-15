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
    };
  }
}
