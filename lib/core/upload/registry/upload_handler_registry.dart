import '../handlers/upload_handler.dart';

/// Register all module handlers here — the only place coupling exists.
class UploadHandlerRegistry {
  UploadHandlerRegistry._();

  static final UploadHandlerRegistry instance = UploadHandlerRegistry._();

  final Map<String, UploadHandler> _handlers = {};

  void register(UploadHandler handler) {
    _handlers[handler.moduleId] = handler;
  }

  UploadHandler resolve(String moduleId) {
    final handler = _handlers[moduleId];
    if (handler == null) {
      throw StateError('No UploadHandler registered for moduleId: "$moduleId"');
    }
    return handler;
  }

  bool isRegistered(String moduleId) => _handlers.containsKey(moduleId);
}