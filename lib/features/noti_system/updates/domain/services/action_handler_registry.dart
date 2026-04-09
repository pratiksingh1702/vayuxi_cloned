typedef ActionHandler = Future<void> Function(Map<String, dynamic> payload);

/// Register named handlers at app startup.
/// Keeps Function() references out of models entirely.
class ActionHandlerRegistry {
  ActionHandlerRegistry._();
  static final instance = ActionHandlerRegistry._();

  final Map<String, ActionHandler> _handlers = {};

  void register(String key, ActionHandler handler) {
    _handlers[key] = handler;
  }

  ActionHandler? resolve(String key) => _handlers[key];
}