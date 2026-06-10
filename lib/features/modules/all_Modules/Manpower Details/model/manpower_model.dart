class ManpowerModel {
  final String? id;
  final String? type;
  final String? fullName;
  final String? designation;
  final String? manpowerType;
  final String? employeeCode;
  final String? phoneNumber;
  final String? aadharNumber;
  final String? panNumber;
  final String? dateOfBirth;
  final String? dateOfJoining;
  final String? bankAccountNumber;
  final String? ifscCode;
  final String? epfNumber;
  final String? uanNumber;
  final String? esicNumber;
  final String? payBasics;
  final dynamic totalHour;
  final double? salary;
  final double? basicSalary;
  final double? hra;
  final double? dearnessAllowance;
  final double? specialAllowance;
  final double? travelAllowance;
  final double? medicalAllowance;
  final bool? pfApplicable;
  final String? remarks;
  final String? company;

  // ✅ NEW: Sites this manpower is assigned to
  final List<String> sites;

  final bool? isDeleted;
  final bool? isLeft;
  final String? reason;
  final String? createdAt;
  final String? updatedAt;

  final String? loginEmail;
  final String? loginPassword;
  final bool? isLoginEnabled;

  ManpowerModel({
    this.id,
    this.type,
    this.fullName,
    this.designation,
    this.manpowerType,
    this.employeeCode,
    this.phoneNumber,
    this.aadharNumber,
    this.panNumber,
    this.dateOfBirth,
    this.dateOfJoining,
    this.bankAccountNumber,
    this.ifscCode,
    this.epfNumber,
    this.uanNumber,
    this.esicNumber,
    this.payBasics,
    this.totalHour,
    this.salary,
    this.basicSalary,
    this.hra,
    this.dearnessAllowance,
    this.specialAllowance,
    this.travelAllowance,
    this.medicalAllowance,
    this.pfApplicable,
    this.remarks,
    this.company,
    this.sites = const [],
    this.isDeleted,
    this.isLeft,
    this.reason,
    this.createdAt,
    this.updatedAt,
    this.loginEmail,
    this.loginPassword,
    this.isLoginEnabled,
  });

  factory ManpowerModel.fromJson(Map<String, dynamic> json) {
    // Parse sites: backend sends List of strings or mixed
    List<String> parseSites(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) {
        return raw
            .map((e) => e is Map
                ? (e['_id'] ?? e['id'] ?? '').toString()
                : e.toString())
            .where((s) => s.isNotEmpty)
            .toList();
      }
      return [];
    }

    return ManpowerModel(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      type: json['type'],
      fullName: json['fullName'],
      designation: json['designation'],
      manpowerType: json['manpowerType']?.toString(),
      employeeCode: json['employeeCode'],
      phoneNumber: json['phoneNumber'],
      aadharNumber: json['aadharNumber'] ?? json['aaddharNumber'],
      panNumber: json['panNumber'],
      dateOfBirth: json['dateOfBirth']?.toString(),
      dateOfJoining: json['dateOfJoining']?.toString(),
      bankAccountNumber: json['bankAccountNumber'],
      ifscCode: json['ifscCode'],
      epfNumber: json['epfNumber'],
      uanNumber: json['uanNumber'],
      esicNumber: json['esicNumber'],
      payBasics: json['payBasics'],
      totalHour: json['totalHour'],
      salary: (json['salary'] as num?)?.toDouble(),
      basicSalary: (json['basicSalary'] as num?)?.toDouble(),
      hra: (json['hra'] as num?)?.toDouble(),
      dearnessAllowance:
          (json['dearnessAllowance'] ?? json['da'] as num?)?.toDouble(),
      specialAllowance: (json['specialAllowance'] as num?)?.toDouble(),
      travelAllowance: (json['travelAllowance'] as num?)?.toDouble(),
      medicalAllowance: (json['medicalAllowance'] as num?)?.toDouble(),
      pfApplicable: json['pfApplicable'],
      remarks: json['remarks'],
      company: json['company'] is Map
          ? json['company']['_id']?.toString()
          : json['company']?.toString(),
      sites: parseSites(json['sites']),
      isDeleted: json['isDeleted'],
      isLeft: json['isLeft'],
      reason: json['reason'],
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      loginEmail: json['loginEmail'],
      loginPassword: json['loginPassword'],
      isLoginEnabled: json['isLoginEnabled'],
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'type': type,
        'fullName': fullName,
        'designation': designation,
        'manpowerType': manpowerType,
        'employeeCode': employeeCode,
        'phoneNumber': phoneNumber,
        'aadharNumber': aadharNumber,
        'panNumber': panNumber,
        'dateOfBirth': dateOfBirth,
        'dateOfJoining': dateOfJoining,
        'bankAccountNumber': bankAccountNumber,
        'ifscCode': ifscCode,
        'epfNumber': epfNumber,
        'uanNumber': uanNumber,
        'esicNumber': esicNumber,
        'payBasics': payBasics,
        'totalHour': totalHour,
        'salary': salary,
        'basicSalary': basicSalary,
        'hra': hra,
        'dearnessAllowance': dearnessAllowance,
        'specialAllowance': specialAllowance,
        'travelAllowance': travelAllowance,
        'medicalAllowance': medicalAllowance,
        'pfApplicable': pfApplicable,
        'remarks': remarks,
        'company': company,
        'sites': sites,
        'isDeleted': isDeleted,
        'isLeft': isLeft,
        'reason': reason,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'loginEmail': loginEmail,
        'loginPassword': loginPassword,
        'isLoginEnabled': isLoginEnabled,
      };
}
