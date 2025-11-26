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

  User({
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

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      profilePhoto: json['profilePhoto'],
      aadhaarCard: json['aadhaarCard'],
      gstNumber: json['gstNumber'],
      company: json['company'] != null ? Company.fromJson(json['company']) : null,
      address: json['address'],
      other: json['other'],
      selectedServices: List<String>.from(json['selectedServices'] ?? []),
      firstName: json['firstName'],
      lastName: json['lastName'],
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
  final String? name;
  final String? logo;

  Company({this.name, this.logo});

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      name: json['name'],
      logo: json['logo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'logo': logo,
    };
  }

  Company copyWith({
    String? name,
    String? logo,
  }) {
    return Company(
      name: name ?? this.name,
      logo: logo ?? this.logo,
    );
  }
}