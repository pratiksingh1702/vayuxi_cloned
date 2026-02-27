class User {
  final String id;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String? profilePhoto;
  final String? aadhaarCard;
  final String? gstNumber;
  final Company? company;
  final String? address;
  final String? other;
  final List<String> selectedServices;
  final String? firstName;
  final String? lastName;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    this.profilePhoto,
    this.aadhaarCard,
    this.gstNumber,
    this.company,
    this.address,
    this.other,
    required this.selectedServices,
    this.firstName,
    this.lastName,
  });

  /// 🔐 SAFE JSON PARSER (NO RUNTIME CRASHES)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _parseString(json['_id'] ?? json['id']),
      email: _parseString(json['email']),
      fullName: _parseString(json['fullName']),
      phoneNumber: _parseString(json['phoneNumber']),
      profilePhoto: _parseNullableString(json['profilePhoto']),
      aadhaarCard: _parseNullableString(json['aadhaarCard']),
      gstNumber: _parseNullableString(json['gstNumber']),
      company: _parseCompany(json['company']),
      address: _parseNullableString(json['address']),
      other: _parseNullableString(json['other']),
      selectedServices: _parseStringList(json['selectedServices']),
      firstName: _parseNullableString(json['firstName']),
      lastName: _parseNullableString(json['lastName']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'profilePhoto': profilePhoto,
      'aadhaarCard': aadhaarCard,
      'gstNumber': gstNumber,
      'company': company?.toJson(),
      'address': address,
      'other': other,
      'selectedServices': selectedServices,
      'firstName': firstName,
      'lastName': lastName,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? profilePhoto,
    String? aadhaarCard,
    String? gstNumber,
    Company? company,
    String? address,
    String? other,
    List<String>? selectedServices,
    String? firstName,
    String? lastName,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      aadhaarCard: aadhaarCard ?? this.aadhaarCard,
      gstNumber: gstNumber ?? this.gstNumber,
      company: company ?? this.company,
      address: address ?? this.address,
      other: other ?? this.other,
      selectedServices: selectedServices ?? this.selectedServices,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
    );
  }
}

class Company {
  final String? id;
  final String? name;
  final String? logo;

  final String? bankName;
  final String? accountName;   // ✅ NEW FIELD
  final String? accountNumber;
  final String? ifscCode;
  final String? branch;
  final String? panNumber;
  final String? digitalSignature;

  const Company({
    this.id,
    this.name,
    this.logo,
    this.bankName,
    this.accountName,   // ✅
    this.accountNumber,
    this.ifscCode,
    this.branch,
    this.panNumber,
    this.digitalSignature,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: _parseNullableString(json['_id'] ?? json['id']),
      name: _parseNullableString(json['name']),
      logo: _parseNullableString(json['logo']),
      bankName: _parseNullableString(json['bankName']),
      accountName: _parseNullableString(json['accountName']), // ✅
      accountNumber: _parseNullableString(json['accountNumber']),
      ifscCode: _parseNullableString(json['ifscCode']),
      branch: _parseNullableString(json['branch']),
      panNumber: _parseNullableString(json['panNumber']),
      digitalSignature: _parseNullableString(json['digitalSignature']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logo': logo,
      'bankName': bankName,
      'accountName': accountName,   // ✅
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'branch': branch,
      'panNumber': panNumber,
      'digitalSignature': digitalSignature,
    };
  }
}

String _parseString(dynamic value) {
  if (value == null) return '';
  return value.toString();
}

String? _parseNullableString(dynamic value) {
  if (value == null) return null;
  return value.toString();
}

List<String> _parseStringList(dynamic value) {
  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }

  if (value is Map) {
    return value.keys.map((e) => e.toString()).toList();
  }

  if (value is String) {
    return value
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  return [];
}

Company? _parseCompany(dynamic value) {
  if (value is Map<String, dynamic>) {
    return Company.fromJson(value);
  }

  // backend sometimes sends only company ID (string)
  return null;
}

