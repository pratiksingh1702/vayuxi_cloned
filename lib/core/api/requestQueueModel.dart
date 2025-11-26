import 'package:flutter/cupertino.dart';

class QueuedRequest {
  final String id; // Add ID field
  final String method;
  final String path;
  final Map<String, dynamic>? data;
  final Map<String, dynamic>? query;
  final List<Map<String, dynamic>>? files;
  final String contentType;

  QueuedRequest({
    String? id, // Make ID optional for new requests
    required this.method,
    required this.path,
    this.data,
    this.query,
    this.files,
    this.contentType = "json",
  }) : id = id ?? _generateId(); // Generate ID if not provided

  // Helper method to generate unique ID
  static String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${UniqueKey().hashCode}';
  }

  Map<String, dynamic> toJson() => {
    "id": id, // Include ID in JSON
    "method": method,
    "path": path,
    "data": data,
    "query": query,
    "files": files,
    "contentType": contentType,
  };

  factory QueuedRequest.fromJson(Map<String, dynamic> json) => QueuedRequest(
    id: json["id"], // Parse ID from JSON
    method: json["method"],
    path: json["path"],
    data: json["data"] != null ? Map<String, dynamic>.from(json["data"]) : null,
    query: json["query"] != null ? Map<String, dynamic>.from(json["query"]) : null,
    files: json["files"] != null ? List<Map<String, dynamic>>.from(json["files"]) : null,
    contentType: json["contentType"] ?? "json",
  );
}