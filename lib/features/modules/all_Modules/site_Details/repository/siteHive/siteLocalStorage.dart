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

  @HiveField(14)
  final int teamsCount;

  @HiveField(15)
  final int dprMechanicalCount;

  @HiveField(16)
  final int dprInsulationCount;

  @HiveField(17)
  final int manpowerCount;

  @HiveField(18)
  final int totalDprCount;

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
    this.teamsCount = 0,
    this.dprMechanicalCount = 0,
    this.dprInsulationCount = 0,
    this.manpowerCount = 0,
    this.totalDprCount = 0,
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
      teamsCount: site.counts.teams,
      dprMechanicalCount: site.counts.dprMechanical,
      dprInsulationCount: site.counts.dprInsulation,
      manpowerCount: site.counts.manpower,
      totalDprCount: site.counts.totalDpr,
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
      shippingAddress: '',
      counts: SiteCounts(
        teams: teamsCount,
        dprMechanical: dprMechanicalCount,
        dprInsulation: dprInsulationCount,
        manpower: manpowerCount,
        totalDpr: totalDprCount,
      ),
    );
  }

  // Convert from JSON to Hive model
  factory SiteModelHive.fromJson(Map<String, dynamic> json) {
    final countsJson = json['counts'];
    final counts = SiteCounts.fromJson(countsJson);

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
      teamsCount: counts.teams,
      dprMechanicalCount: counts.dprMechanical,
      dprInsulationCount: counts.dprInsulation,
      manpowerCount: counts.manpower,
      totalDprCount: counts.totalDpr,
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
      'counts': {
        'teams': teamsCount,
        'dprMechanical': dprMechanicalCount,
        'dprInsulation': dprInsulationCount,
        'manpower': manpowerCount,
        'totalDpr': totalDprCount,
      },
    };
  }
}
