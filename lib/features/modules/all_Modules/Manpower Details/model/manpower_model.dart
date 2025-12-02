class ManpowerModel {
  final String? id;
  final String? fullName;
  final String? designation;
  final String? employeeCode;

  final String? phoneNumber;
  final String? panNumber;
  final String? dateOfBirth;
  final String? dateOfJoining;
  final String? bankAccountNumber;
  final String? ifscCode;
  final String? epfNumber;
  final String? uanNumber;
  final String? esicNumber;

  final String? payBasics;
  final double? salary;

  final String? remarks;
  final bool? isDeleted;
  final String? company;
  final bool? isLeft;
  final String? reason;
  final String? type;

  final String? createdAt;
  final String? updatedAt;

  ManpowerModel({
    this.id,
    this.fullName,
    this.designation,
    this.employeeCode,
    this.phoneNumber,
    this.panNumber,
    this.dateOfBirth,
    this.dateOfJoining,
    this.bankAccountNumber,
    this.ifscCode,
    this.epfNumber,
    this.uanNumber,
    this.esicNumber,
    this.payBasics,
    this.salary,
    this.remarks,
    this.isDeleted,
    this.company,
    this.isLeft,
    this.reason,
    this.type,
    this.createdAt,
    this.updatedAt,
  });

  /// -----------------------------
  /// From JSON (Safe, Error-Proof)
  /// -----------------------------
  factory ManpowerModel.fromJson(Map<String, dynamic> json) {
    return ManpowerModel(
      id: json['_id']?.toString(),
      fullName: json['fullName']?.toString(),
      designation: json['designation']?.toString(),
      employeeCode: json['employeeCode']?.toString(),

      phoneNumber: json['phoneNumber']?.toString(),
      panNumber: json['panNumber']?.toString(),
      dateOfBirth: json['dateOfBirth']?.toString(),
      dateOfJoining: json['dateOfJoining']?.toString(),
      bankAccountNumber: json['bankAccountNumber']?.toString(),
      ifscCode: json['ifscCode']?.toString(),
      epfNumber: json['epfNumber']?.toString(),
      uanNumber: json['uanNumber']?.toString(),
      esicNumber: json['esicNumber']?.toString(),

      payBasics: json['payBasics']?.toString(),

      salary: _toDouble(json['salary']), // safe parsing

      remarks: json['remarks']?.toString(),
      isDeleted: _toBool(json['isDeleted']),
      company: json['company']?.toString(),
      isLeft: _toBool(json['isLeft']),
      reason: json['reason']?.toString(),
      type: json['type']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  /// -----------------------------
  /// To JSON
  /// -----------------------------
  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "fullName": fullName,
      "designation": designation,
      "employeeCode": employeeCode,
      "phoneNumber": phoneNumber,
      "panNumber": panNumber,
      "dateOfBirth": dateOfBirth,
      "dateOfJoining": dateOfJoining,
      "bankAccountNumber": bankAccountNumber,
      "ifscCode": ifscCode,
      "epfNumber": epfNumber,
      "uanNumber": uanNumber,
      "esicNumber": esicNumber,
      "payBasics": payBasics,
      "salary": salary,
      "remarks": remarks,
      "isDeleted": isDeleted,
      "company": company,
      "isLeft": isLeft,
      "reason": reason,
      "type": type,
      "createdAt": createdAt,
      "updatedAt": updatedAt,
    };
  }

  /// -----------------------------
  /// Helpers (to avoid crashes)
  /// -----------------------------
  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static bool? _toBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      if (value.toLowerCase() == "true") return true;
      if (value.toLowerCase() == "false") return false;
    }
    return null;
  }
}
