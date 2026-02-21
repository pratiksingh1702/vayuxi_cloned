import '../models/data/equipment_material_data.dart';
import '../models/data/piping_material_data.dart';
import '../models/rate_file_models.dart';

class RateMaterialImageResolver {
  /// quick lookup maps (O(1))
  static final Map<String, String> _pipingMap = {
    for (final m in PipingMaterialsData.materials)
      _normalize(m.materialName): m.image,
  };

  static final Map<String, String> _equipmentMap = {
    for (final m in EquipmentMaterialsData.materials)
      _normalize(m.materialName): m.image,
  };

  static String resolve(
      String materialName,
      List<String> designation,
      ) {
    final key = _normalize(materialName);

    Map<String, String> source;

    if (designation.contains('piping')) {
      source = _pipingMap;
    } else if (designation.contains('equipment')) {
      source = _equipmentMap;
    } else {
      return _default;
    }

    String? bestImage;
    int bestScore = 0;

    for (final entry in source.entries) {
      final candidate = entry.key;

      if (key.contains(candidate) || candidate.contains(key)) {
        final score = candidate.length;

        if (score > bestScore) {
          bestScore = score;
          bestImage = entry.value;
        }
      }
    }

    return bestImage ?? _default;
  }


  static const String _default = 'assets/images/material_default.webp';

  /// remove spacing, case, symbols
  static String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll('&', '')
        .replaceAll('/', '')
        .replaceAll(',', '')
        .replaceAll(RegExp(r'\s+'), '');
  }
}
extension RateFileMaterialImage on RateFileMaterial {
  String resolveImage() {
    return RateMaterialImageResolver.resolve(
      MaterialName,     // or materialName
      designation,     // MUST be List<String>
    );
  }
}
