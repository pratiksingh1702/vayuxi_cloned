import 'package:isar_community/isar.dart';

part 'manpower_isar.g.dart';

@collection
class ManpowerIsar {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String manpowerId;

  @Index()
  late String type;

  String? fullName;
  String? designation;

  @Index(unique: true)
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

  // ✅ NEW: Sites this manpower is assigned to (site-wise storage)
  List<String> sites = [];

  bool isDeleted = false;
  bool isLeft = false;

  String? reason;

  String? createdAt;
  DateTime updatedAt = DateTime.now();

  String? loginEmail;
  String? loginPassword;
  bool? isLoginEnabled;
}