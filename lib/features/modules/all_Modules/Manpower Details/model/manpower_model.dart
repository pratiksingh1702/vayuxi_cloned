import 'dart:convert';

class ManpowerModel {
  final String? id;
  final String? fullName;
  final String? designation;
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

  final double? salary;
  final double? basicSalary;
  final double? hra;
  final double? dearnessAllowance;
  final double? specialAllowance;
  final double? travelAllowance;
  final double? medicalAllowance;

  final bool? pfApplicable;

  final String? remarks;

  final bool? isDeleted;
  final bool? isLeft;
  final String? reason;
  final String? type;
  final String? company;

  final String? createdAt;
  final String? updatedAt;

  // Login fields
  final String? loginEmail;
  final String? loginPassword;
  final bool? isLoginEnabled;

  ManpowerModel({
    this.id,
    this.fullName,
    this.designation,
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
    this.salary,
    this.basicSalary,
    this.hra,
    this.dearnessAllowance,
    this.specialAllowance,
    this.travelAllowance,
    this.medicalAllowance,
    this.pfApplicable,
    this.remarks,
    this.isDeleted,
    this.company,
    this.isLeft,
    this.reason,
    this.type,
    this.createdAt,
    this.updatedAt,
    this.loginEmail,
    this.loginPassword,
    this.isLoginEnabled,
  });

  factory ManpowerModel.fromJson(Map<String, dynamic> json) {
    return ManpowerModel(
      id: json['_id']?.toString(),
      fullName: json['fullName']?.toString(),
      designation: json['designation']?.toString(),
      employeeCode: json['employeeCode']?.toString(),
      phoneNumber: json['phoneNumber']?.toString(),

      aadharNumber: json['aadharNumber']?.toString(),
      panNumber: json['panNumber']?.toString(),

      dateOfBirth: json['dateOfBirth']?.toString(),
      dateOfJoining: json['dateOfJoining']?.toString(),

      bankAccountNumber: json['bankAccountNumber']?.toString(),
      ifscCode: json['ifscCode']?.toString(),
      epfNumber: json['epfNumber']?.toString(),
      uanNumber: json['uanNumber']?.toString(),
      esicNumber: json['esicNumber']?.toString(),

      payBasics: json['payBasics']?.toString(),

      salary: _toDouble(json['salary']),
      basicSalary: _toDouble(json['basicSalary']),
      hra: _toDouble(json['hra']),
      dearnessAllowance: _toDouble(json['dearnessAllowance']),
      specialAllowance: _toDouble(json['specialAllowance']),
      travelAllowance: _toDouble(json['travelAllowance']),
      medicalAllowance: _toDouble(json['medicalAllowance']),

      pfApplicable: _toBool(json['pfApplicable']),

      remarks: json['remarks']?.toString(),

      isDeleted: _toBool(json['isDeleted']),
      isLeft: _toBool(json['isLeft']),
      reason: json['reason']?.toString(),
      type: json['type']?.toString(),
      company: json['company']?.toString(),

      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),

      loginEmail: json['loginEmail']?.toString(),
      loginPassword: json['loginPassword']?.toString(),
      isLoginEnabled: _toBool(json['isLoginEnabled']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "fullName": fullName,
      "designation": designation,
      "employeeCode": employeeCode,
      "phoneNumber": phoneNumber,

      "aadharNumber": aadharNumber,
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
      "basicSalary": basicSalary,
      "hra": hra,
      "dearnessAllowance": dearnessAllowance,
      "specialAllowance": specialAllowance,
      "travelAllowance": travelAllowance,
      "medicalAllowance": medicalAllowance,

      "pfApplicable": pfApplicable,

      "remarks": remarks,

      "isDeleted": isDeleted,
      "isLeft": isLeft,
      "reason": reason,
      "type": type,
      "company": company,

      "createdAt": createdAt,
      "updatedAt": updatedAt,

      "loginEmail": loginEmail,
      "loginPassword": loginPassword,
      "isLoginEnabled": isLoginEnabled,
    };
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
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
