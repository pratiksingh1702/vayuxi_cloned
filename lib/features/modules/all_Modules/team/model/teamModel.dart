class TeamModel {
  final String id;
  final String teamName;
  final String? teamLeadId;
  final List<String> teamMemberIds;
  final String company;
  final bool isDeleted;
  final String type;
  final String? createdAt;
  final String? updatedAt;
  final String? teamLeadImage; // New field

  TeamModel({
    required this.id,
    required this.teamName,
    this.teamLeadId,
    required this.teamMemberIds,
    required this.company,
    required this.isDeleted,
    required this.type,
    this.createdAt,
    this.updatedAt,
    this.teamLeadImage,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    return TeamModel(
      id: json['_id'] ?? '',
      teamName: json['teamName'] ?? '',
      teamLeadId: json['teamLead']?.toString(),
      teamMemberIds: (json['teamMembers'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      company: json['company']?.toString() ?? '',
      isDeleted: json['isDeleted'] ?? false,
      type: json['type'] ?? '',
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      teamLeadImage: json['teamLeadImage']?.toString(), // Safely handle nullable field
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'teamName': teamName,
      'teamLead': teamLeadId,
      'teamMembers': teamMemberIds,
      'company': company,
      'isDeleted': isDeleted,
      'type': type,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'teamLeadImage': teamLeadImage, // Include it in JSON
    };
  }
}
