import 'package:hive/hive.dart';
import 'requestQueueModel.dart';

class RequestQueue {
  static late Box box;

  static Future init() async {
    box = await Hive.openBox("request_queue");
  }

  // Store with ID as key for easy access and removal
  static Future add(QueuedRequest req) async {
    await box.put(req.id, req.toJson());
  }

  // Get all requests
  static List<QueuedRequest> getAll() {
    return box.values
        .map((e) => QueuedRequest.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // Remove by ID - simple and efficient
  static Future<void> remove(String id) async {
    await box.delete(id);
    await box.flush(); // Force write to disk
  }

  static Future clearAll() async {
    await box.clear();
    await box.flush();
  }


  // Remove multiple requests by IDs
  static Future<void> removeMultiple(List<String> ids) async {
    await box.deleteAll(ids);
  }

  // Get a specific request by ID
  static QueuedRequest? getById(String id) {
    final json = box.get(id);
    return json != null ? QueuedRequest.fromJson(Map<String, dynamic>.from(json)) : null;
  }

  // Check if a request exists by ID
  static bool contains(String id) {
    return box.containsKey(id);
  }

  // Get the number of queued requests
  static int get count {
    return box.length;
  }



  // Get all requests with their IDs (useful for debugging)
  static Map<String, QueuedRequest> getAllWithIds() {
    final result = <String, QueuedRequest>{};
    final allKeys = box.keys.toList();

    for (final key in allKeys) {
      final storedJson = box.get(key);
      if (storedJson != null) {
        result[key.toString()] = QueuedRequest.fromJson(Map<String, dynamic>.from(storedJson));
      }
    }

    return result;
  }
}