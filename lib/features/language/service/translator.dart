class Translator {
  final Map<String, dynamic> data;
  final Map<String, dynamic>? fallbackData;

  Translator(this.data, {this.fallbackData});

  String t(String key) {
    final value = data[key];
    if (value != null) return value.toString();
    
    // Try fallback if primary key is missing
    final fallbackValue = fallbackData?[key];
    if (fallbackValue != null) return fallbackValue.toString();
    
    return key; // Final fail-safe: return the key itself
  }
}
