// site_model_hive.dart
import 'package:hive/hive.dart';
import 'package:untitled2/features/modules/all_Modules/site_Details/repository/siteModel.dart';

part 'siteLocalStorage.g.dart'; // This will be generated

@HiveType(typeId: 0) // Unique typeId for SiteModel
class SiteModelHive {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String siteName;

  @HiveField(2)
  final String address;

  @HiveField(3)
  final String contactPerson;

  @HiveField(4)
  final String gstNo;

  @HiveField(5)
  final String phoneNumber;

  @HiveField(6)
  final String emailId;

  @HiveField(7)
  final String? documentDate; // Nullable

  @HiveField(8)
  final String documentNumber;

  @HiveField(9)
  final bool isDeleted;

  @HiveField(10)
  final String company;

  @HiveField(11)
  final String type;

  @HiveField(12)
  final String createdAt;

  @HiveField(13)
  final String updatedAt;

  SiteModelHive({
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

  // Convert from your original SiteModel to Hive model
  factory SiteModelHive.fromSiteModel(SiteModel site) {
    return SiteModelHive(
      id: site.id,
      siteName: site.siteName,
      address: site.address,
      contactPerson: site.contactPerson,
      gstNo: site.gstNo,
      phoneNumber: site.phoneNumber,
      emailId: site.emailId,
      documentDate: site.documentDate,
      documentNumber: site.documentNumber,
      isDeleted: site.isDeleted,
      company: site.company,
      type: site.type,
      createdAt: site.createdAt,
      updatedAt: site.updatedAt,
    );
  }

  // Convert back to your original SiteModel
  SiteModel toSiteModel() {
    return SiteModel(
      id: id,
      siteName: siteName,
      address: address,
      contactPerson: contactPerson,
      gstNo: gstNo,
      phoneNumber: phoneNumber,
      emailId: emailId,
      documentDate: documentDate,
      documentNumber: documentNumber,
      isDeleted: isDeleted,
      company: company,
      type: type,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // Convert from JSON to Hive model
  factory SiteModelHive.fromJson(Map<String, dynamic> json) {
    return SiteModelHive(
      id: json['_id'] ?? '',
      siteName: json['siteName'] ?? '',
      address: json['address'] ?? '',
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
    );
  }

  // Convert Hive model to JSON
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