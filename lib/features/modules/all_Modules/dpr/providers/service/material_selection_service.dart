import '../../models/rate_file_models.dart';

class MaterialSelectionService {
  // Filter materials by designation
  static List<RateFileMaterial> getMaterialsByDesignation(
      List<RateFileMaterial> allMaterials,
      String designation
      ) {
    return allMaterials.where((material) {
      return material.designation.contains(designation);
    }).toList();
  }

  // Get approved materials only
  static List<RateFileMaterial> getApprovedMaterials(
      List<RateFileMaterial> materials
      ) {
    return materials.where((material) {
      return material.approvalStatus == 'approved';
    }).toList();
  }

  // Get unique MOCs from materials
  static List<String> getAvailableMocs(List<RateFileMaterial> materials) {
    final mocs = <String>{};
    for (var material in materials) {
      mocs.add(material.normalizedMoc);
      for (var variant in material.availableVariants) {
        if (variant.moc.isNotEmpty) {
          mocs.add(variant.moc);
        }
      }
    }
    return mocs.where((moc) => moc.isNotEmpty).toList();
  }

  // Get unique UOMs from materials
  static List<String> getAvailableUoms(List<RateFileMaterial> materials) {
    final uoms = <String>{};
    for (var material in materials) {
      uoms.add(material.uom);
      for (var variant in material.availableVariants) {
        uoms.add(variant.uom);
      }
    }
    return uoms.where((uom) => uom.isNotEmpty).toList();
  }

  // Find matching variant based on selection criteria
  static RateVariant? findMatchingVariant(
      RateFileMaterial material,
      String? selectedMoc,
      String? selectedSize,
      String? selectedFloor,
      ) {
    for (var variant in material.availableVariants) {
      bool matches = true;

      if (selectedMoc != null && selectedMoc.isNotEmpty) {
        matches = matches && variant.moc == selectedMoc;
      }

      if (selectedSize != null && selectedSize.isNotEmpty) {
        // Parse size range logic
        if (variant.sizeRange != null) {
          // Implement size matching logic
        }
      }

      if (selectedFloor != null && selectedFloor.isNotEmpty) {
        matches = matches && variant.floor == selectedFloor;
      }

      if (matches) {
        return variant;
      }
    }

    // Return first variant if no specific match
    return material.availableVariants.isNotEmpty
        ? material.availableVariants.first
        : null;
  }
}