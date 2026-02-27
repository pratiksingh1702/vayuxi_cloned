class TeamModel {
  final String id;
  final String teamName;
  final String? teamLeadId;
  final List<String> teamMemberIds;
  final String company;
  final bool isDeleted;
  final String type;
  final bool isDefaultTeam; // 🔥 NEW FIELD
  final String? createdAt;
  final String? updatedAt;
  final String? teamLeadImage;

  TeamModel({
    required this.id,
    required this.teamName,
    this.teamLeadId,
    required this.teamMemberIds,
    required this.company,
    required this.isDeleted,
    required this.type,
 this.isDefaultTeam=false, // 🔥 REQUIRED
    this.createdAt,
    this.updatedAt,
    this.teamLeadImage,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    return TeamModel(
      id: json['_id']?.toString() ?? '',
      teamName: json['teamName'] ?? '',

      teamLeadId: json['teamLead'] is Map
          ? json['teamLead']['_id']?.toString()
          : json['teamLead']?.toString(),

      teamMemberIds: (json['teamMembers'] as List? ?? [])
          .map((e) => e is Map ? e['_id'].toString() : e.toString())
          .toList(),

      company: json['company'] is Map
          ? json['company']['_id']?.toString() ?? ''
          : json['company']?.toString() ?? '',

      isDeleted: json['isDeleted'] ?? false,
      type: json['type'] ?? '',

      isDefaultTeam: json['isDefaultTeam'] ?? false, // 🔥 IMPORTANT

      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),

      teamLeadImage: json['teamLeadImage']?.toString(),
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
      'isDefaultTeam': isDefaultTeam, // 🔥 INCLUDE
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'teamLeadImage': teamLeadImage,
    };
  }
}