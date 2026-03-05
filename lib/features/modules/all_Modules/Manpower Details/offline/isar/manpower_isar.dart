import 'package:isar/isar.dart';

part 'manpower_isar.g.dart';

@collection
class ManpowerIsar {
  Id isarId = Isar.autoIncrement;

  @Index()
  late String manpowerId;

  @Index()
  late String type;

  String? fullName;
  String? designation;
  String? employeeCode;
  String? phoneNumber;

  String? aadharNumber;
  String? panNumber;

  String? dateOfBirth;
  String? dateOfJoining;

  String? bankAccountNumber;
  String? ifscCode;
  String? epfNumber;
  String? uanNumber;
  String? esicNumber;

  String? payBasics;

  double? salary;
  double? basicSalary;
  double? hra;
  double? dearnessAllowance;
  double? specialAllowance;
  double? travelAllowance;
  double? medicalAllowance;
  String? totalHour;
  bool? pfApplicable;

  String? remarks;

  String? company;

  bool isDeleted = false;
  bool isLeft = false;

  String? reason;

  String? createdAt;
  DateTime updatedAt = DateTime.now();

  String? loginEmail;
  String? loginPassword;
  bool? isLoginEnabled;
}
