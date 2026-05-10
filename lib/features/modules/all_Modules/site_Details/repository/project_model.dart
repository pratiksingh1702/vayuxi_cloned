class ProjectModel {
  final String id;
  final String projectName;
  final String clientName;
  final String status;
  final DateTime startDate;
  final DateTime? endDate;
  final String description;
  final double progress;

  ProjectModel({
    required this.id,
    required this.projectName,
    required this.clientName,
    required this.status,
    required this.startDate,
    this.endDate,
    required this.description,
    this.progress = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectName': projectName,
      'clientName': clientName,
      'status': status,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate?.millisecondsSinceEpoch,
      'description': description,
      'progress': progress,
    };
  }

  factory ProjectModel.fromMap(Map<String, dynamic> map) {
    return ProjectModel(
      id: map['id'] ?? '',
      projectName: map['projectName'] ?? '',
      clientName: map['clientName'] ?? '',
      status: map['status'] ?? 'Active',
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate'] ?? 0),
      endDate: map['endDate'] != null ? DateTime.fromMillisecondsSinceEpoch(map['endDate']) : null,
      description: map['description'] ?? '',
      progress: (map['progress'] ?? 0.0).toDouble(),
    );
  }
}
