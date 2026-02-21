class Translator {
  final Map<String, dynamic> data;

  Translator(this.data);

  String t(String key) {
    final value = data[key];
    if (value == null) return key; // fail fast
    return value.toString();
  }
}
