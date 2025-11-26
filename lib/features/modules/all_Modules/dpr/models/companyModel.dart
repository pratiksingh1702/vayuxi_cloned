class CompanyModel {
  final String id;
  final String name;
  final String logo;

  CompanyModel({
    required this.id,
    required this.name,
    required this.logo,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['_id'],
      name: json['name'],
      logo: json['logo'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'logo': logo,
  };
}
