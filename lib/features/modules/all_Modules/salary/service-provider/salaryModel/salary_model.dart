// lib/features/modules/all_Modules/salary/model/salary_model.dart

// =============================================================================
// SUB-MODELS
// =============================================================================

class SalaryManpowerDetails {
  final String id;
  final String fullName;
  final String designation;
  final String employeeCode;
  final String? bankAccountNumber;
  final String? ifscCode;
  final double salary;
  final String? totalHour;
  final bool isDeleted;
  final String? company;
  final List<String> sites;
  final bool isLeft;
  final String? reason;
  final String? type;
  final String? adminEmail;
  final String? role;
  final String? dateOfBirth;
  final String? dateOfJoining;
  final String? epfNumber;
  final String? esicNumber;
  final double hra;
  final double basicSalary;
  final double medicalAllowance;
  final String? panNumber;
  final String? payBasics;
  final bool pfApplicable;
  final String? phoneNumber;
  final String? remarks;
  final double specialAllowance;
  final double travelAllowance;
  final String? uanNumber;
  final String? aaddharNumber;
  final String? address;

  const SalaryManpowerDetails({
    required this.id,
    required this.fullName,
    required this.designation,
    required this.employeeCode,
    this.bankAccountNumber,
    this.ifscCode,
    this.salary = 0,
    this.totalHour,
    this.isDeleted = false,
    this.company,
    this.sites = const [],
    this.isLeft = false,
    this.reason,
    this.type,
    this.adminEmail,
    this.role,
    this.dateOfBirth,
    this.dateOfJoining,
    this.epfNumber,
    this.esicNumber,
    this.hra = 0,
    this.basicSalary = 0,
    this.medicalAllowance = 0,
    this.panNumber,
    this.payBasics,
    this.pfApplicable = false,
    this.phoneNumber,
    this.remarks,
    this.specialAllowance = 0,
    this.travelAllowance = 0,
    this.uanNumber,
    this.aaddharNumber,
    this.address,
  });

  factory SalaryManpowerDetails.fromJson(Map<String, dynamic> json) {
    return SalaryManpowerDetails(
      id: json['_id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      designation: json['designation']?.toString() ?? '',
      employeeCode: json['employeeCode']?.toString() ?? '',
      bankAccountNumber: json['bankAccountNumber']?.toString(),
      ifscCode: json['ifscCode']?.toString(),
      salary: _toDouble(json['salary']),
      totalHour: json['totalHour']?.toString(),
      isDeleted: json['isDeleted'] as bool? ?? false,
      company: json['company']?.toString(),
      sites: (json['sites'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isLeft: json['isLeft'] as bool? ?? false,
      reason: json['reason']?.toString(),
      type: json['type']?.toString(),
      adminEmail: json['adminEmail']?.toString(),
      role: json['role']?.toString(),
      dateOfBirth: json['dateOfBirth']?.toString(),
      dateOfJoining: json['dateOfJoining']?.toString(),
      epfNumber: json['epfNumber']?.toString(),
      esicNumber: json['esicNumber']?.toString(),
      hra: _toDouble(json['hra']),
      basicSalary: _toDouble(json['basicSalary']),
      medicalAllowance: _toDouble(json['medicalAllowance']),
      panNumber: json['panNumber']?.toString(),
      payBasics: json['payBasics']?.toString(),
      pfApplicable: json['pfApplicable'] as bool? ?? false,
      phoneNumber: json['phoneNumber']?.toString(),
      remarks: json['remarks']?.toString(),
      specialAllowance: _toDouble(json['specialAllowance']),
      travelAllowance: _toDouble(json['travelAllowance']),
      uanNumber: json['uanNumber']?.toString(),
      aaddharNumber: json['aaddharNumber']?.toString(),
      address: json['address']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'fullName': fullName,
        'designation': designation,
        'employeeCode': employeeCode,
        'bankAccountNumber': bankAccountNumber,
        'ifscCode': ifscCode,
        'salary': salary,
        'totalHour': totalHour,
        'isDeleted': isDeleted,
        'company': company,
        'sites': sites,
        'isLeft': isLeft,
        'reason': reason,
        'type': type,
        'adminEmail': adminEmail,
        'role': role,
        'dateOfBirth': dateOfBirth,
        'dateOfJoining': dateOfJoining,
        'epfNumber': epfNumber,
        'esicNumber': esicNumber,
        'hra': hra,
        'basicSalary': basicSalary,
        'medicalAllowance': medicalAllowance,
        'panNumber': panNumber,
        'payBasics': payBasics,
        'pfApplicable': pfApplicable,
        'phoneNumber': phoneNumber,
        'remarks': remarks,
        'specialAllowance': specialAllowance,
        'travelAllowance': travelAllowance,
        'uanNumber': uanNumber,
        'aaddharNumber': aaddharNumber,
        'address': address,
      };
}

// -----------------------------------------------------------------------------

class SalaryCompanyDetails {
  final String id;
  final String name;
  final String? logo;
  final String? accountNumber;
  final String? bankName;
  final String? branch;
  final String? digitalSignature;
  final String? ifscCode;
  final String? panNumber;
  final String? createdBy;

  const SalaryCompanyDetails({
    required this.id,
    required this.name,
    this.logo,
    this.accountNumber,
    this.bankName,
    this.branch,
    this.digitalSignature,
    this.ifscCode,
    this.panNumber,
    this.createdBy,
  });

  factory SalaryCompanyDetails.fromJson(Map<String, dynamic> json) {
    return SalaryCompanyDetails(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      logo: json['logo']?.toString(),
      accountNumber: json['accountNumber']?.toString(),
      bankName: json['bankName']?.toString(),
      branch: json['branch']?.toString(),
      digitalSignature: json['digitalSignature']?.toString(),
      ifscCode: json['ifscCode']?.toString(),
      panNumber: json['panNumber']?.toString(),
      createdBy: json['createdBy']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'logo': logo,
        'accountNumber': accountNumber,
        'bankName': bankName,
        'branch': branch,
        'digitalSignature': digitalSignature,
        'ifscCode': ifscCode,
        'panNumber': panNumber,
        'createdBy': createdBy,
      };
}

// -----------------------------------------------------------------------------

class SalaryEarnings {
  final double basic;
  final double hra;
  final double da;
  final double specialAllowance;
  final double travelAllowance;
  final double medicalAllowance;
  final double ot;

  const SalaryEarnings({
    this.basic = 0,
    this.hra = 0,
    this.da = 0,
    this.specialAllowance = 0,
    this.travelAllowance = 0,
    this.medicalAllowance = 0,
    this.ot = 0,
  });

  double get total =>
      basic +
      hra +
      da +
      specialAllowance +
      travelAllowance +
      medicalAllowance +
      ot;

  factory SalaryEarnings.fromJson(Map<String, dynamic> json) {
    return SalaryEarnings(
      basic: _toDouble(json['basic']),
      hra: _toDouble(json['hra']),
      da: _toDouble(json['da']),
      specialAllowance: _toDouble(json['specialAllowance']),
      travelAllowance: _toDouble(json['travelAllowance']),
      medicalAllowance: _toDouble(json['medicalAllowance']),
      ot: _toDouble(json['ot']),
    );
  }

  Map<String, dynamic> toJson() => {
        'basic': basic,
        'hra': hra,
        'da': da,
        'specialAllowance': specialAllowance,
        'travelAllowance': travelAllowance,
        'medicalAllowance': medicalAllowance,
        'ot': ot,
      };
}

// -----------------------------------------------------------------------------

class SalaryDeductions {
  final double pf;
  final double esi;
  final double ptax;
  final double lwf;
  final double advance;

  const SalaryDeductions({
    this.pf = 0,
    this.esi = 0,
    this.ptax = 0,
    this.lwf = 0,
    this.advance = 0,
  });

  double get total => pf + esi + ptax + lwf + advance;

  factory SalaryDeductions.fromJson(Map<String, dynamic> json) {
    return SalaryDeductions(
      pf: _toDouble(json['pf']),
      esi: _toDouble(json['esi']),
      ptax: _toDouble(json['ptax']),
      lwf: _toDouble(json['lwf']),
      advance: _toDouble(json['advance']),
    );
  }

  Map<String, dynamic> toJson() => {
        'pf': pf,
        'esi': esi,
        'ptax': ptax,
        'lwf': lwf,
        'advance': advance,
      };
}

// =============================================================================
// MAIN MODEL
// =============================================================================

class SalaryModel {
  final SalaryManpowerDetails manpowerDetails;
  final SalaryCompanyDetails companyDetails;
  final double finalSalary;
  final SalaryEarnings earnings;
  final SalaryDeductions deductions;
  final int presentDays;
  final int absentDays;
  final int totalHours;
  final int month;
  final int year;
  final String company;

  const SalaryModel({
    required this.manpowerDetails,
    required this.companyDetails,
    required this.finalSalary,
    required this.earnings,
    required this.deductions,
    required this.presentDays,
    required this.absentDays,
    required this.totalHours,
    required this.month,
    required this.year,
    required this.company,
  });

  // ── Computed properties ────────────────────────────────────────────────────

  double get netPay => finalSalary;
  double get grossEarnings => earnings.total;
  double get totalDeductions => deductions.total;
  double get monthlyCTC => earnings.total + deductions.pf;
  int get totalDays => presentDays + absentDays;
  double get attendancePercentage =>
      totalDays > 0 ? presentDays / totalDays : 0.0;
  bool get isDeficit => finalSalary < 0;

  String get monthName {
    const names = [
      '',
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December',
    ];
    return (month >= 1 && month <= 12) ? names[month] : 'N/A';
  }

  // ── Factory constructors ───────────────────────────────────────────────────

  factory SalaryModel.fromJson(Map<String, dynamic> json) {
    return SalaryModel(
      manpowerDetails: SalaryManpowerDetails.fromJson(
        json['manpowerDetails'] as Map<String, dynamic>? ?? {},
      ),
      companyDetails: SalaryCompanyDetails.fromJson(
        json['companyDetails'] as Map<String, dynamic>? ?? {},
      ),
      finalSalary: _toDouble(json['finalSalary']),
      earnings: SalaryEarnings.fromJson(
        json['earnings'] as Map<String, dynamic>? ?? {},
      ),
      deductions: SalaryDeductions.fromJson(
        json['deductions'] as Map<String, dynamic>? ?? {},
      ),
      presentDays: (json['presentDays'] as num?)?.toInt() ?? 0,
      absentDays: (json['absentDays'] as num?)?.toInt() ?? 0,
      totalHours: (json['totalHours'] as num?)?.toInt() ?? 0,
      month: (json['month'] as num?)?.toInt() ?? 0,
      year: (json['year'] as num?)?.toInt() ?? 0,
      company: json['company']?.toString() ?? '',
    );
  }

  /// Parse a raw API list response
  static List<SalaryModel> fromJsonList(List<dynamic> list) =>
      list
          .whereType<Map<String, dynamic>>()
          .map(SalaryModel.fromJson)
          .toList();

  Map<String, dynamic> toJson() => {
        'manpowerDetails': manpowerDetails.toJson(),
        'companyDetails': companyDetails.toJson(),
        'finalSalary': finalSalary,
        'earnings': earnings.toJson(),
        'deductions': deductions.toJson(),
        'presentDays': presentDays,
        'absentDays': absentDays,
        'totalHours': totalHours,
        'month': month,
        'year': year,
        'company': company,
      };

  // ── copyWith ───────────────────────────────────────────────────────────────

  SalaryModel copyWith({
    SalaryManpowerDetails? manpowerDetails,
    SalaryCompanyDetails? companyDetails,
    double? finalSalary,
    SalaryEarnings? earnings,
    SalaryDeductions? deductions,
    int? presentDays,
    int? absentDays,
    int? totalHours,
    int? month,
    int? year,
    String? company,
  }) {
    return SalaryModel(
      manpowerDetails: manpowerDetails ?? this.manpowerDetails,
      companyDetails: companyDetails ?? this.companyDetails,
      finalSalary: finalSalary ?? this.finalSalary,
      earnings: earnings ?? this.earnings,
      deductions: deductions ?? this.deductions,
      presentDays: presentDays ?? this.presentDays,
      absentDays: absentDays ?? this.absentDays,
      totalHours: totalHours ?? this.totalHours,
      month: month ?? this.month,
      year: year ?? this.year,
      company: company ?? this.company,
    );
  }

  @override
  String toString() =>
      'SalaryModel(employee: ${manpowerDetails.fullName}, '
      'month: $monthName $year, netPay: $netPay)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SalaryModel &&
          other.manpowerDetails.id == manpowerDetails.id &&
          other.month == month &&
          other.year == year;

  @override
  int get hashCode =>
      manpowerDetails.id.hashCode ^ month.hashCode ^ year.hashCode;
}

// =============================================================================
// PRIVATE HELPER
// =============================================================================

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}