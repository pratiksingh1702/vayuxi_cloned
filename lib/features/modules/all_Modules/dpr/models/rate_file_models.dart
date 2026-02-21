  class RateFileMaterial {
    final String id;
    final String rawMaterialName;
    final String MaterialName;
    final String normalizedMaterialName;
    final String normalizedMoc;
    final String uom;
    final String calculationCategory;
    final List<String> designation;
    final String image;
    final String materialMasterId;
    final List<RateVariant> availableVariants;
    final String approvalStatus;
    final bool isDefaultMaterial;
    final String? rejectionReason;
    final DateTime? approvedAt;
    final String? approvedBy;
    final List<DynamicField> dynamicFields;


    const RateFileMaterial({
      required this.id,
      required this.rawMaterialName,
      required this.MaterialName,
      required this.normalizedMaterialName,
      required this.normalizedMoc,
      required this.uom,
      required this.calculationCategory,
      required this.designation,
      required this.image,
      required this.materialMasterId,
      required this.availableVariants,
      required this.approvalStatus,
      required this.isDefaultMaterial,
      required this.dynamicFields,

      this.rejectionReason,
      this.approvedAt,
      this.approvedBy,
    });

    factory RateFileMaterial.fromJson(Map<String, dynamic> json) {
      return RateFileMaterial(
        id: json['_id'] ?? '',
        MaterialName: json['materialName']??'',
        rawMaterialName: json['rawMaterialName'] ?? '',
        normalizedMaterialName: json['normalizedMaterialName'] ?? '',
        normalizedMoc: json['normalizedMoc'] ?? '',
        uom: json['uom'] ?? '',
        calculationCategory: json['calculationCategory'] ?? '',
        designation: List<String>.from(json['designation'] ?? const []),
        image: json['image'] ?? '',
        materialMasterId: json['materialMasterId'] ?? '',
        availableVariants: List<RateVariant>.from(
          (json['availableVariants'] ?? []).map((x) => RateVariant.fromJson(x)),
        ),
        approvalStatus: json['approvalStatus'] ?? 'pending',
        dynamicFields: (json['dynamicFields'] ?? [])
            .map<DynamicField>((e) => DynamicField.fromJson(e))
            .toList(),

        isDefaultMaterial: json['isDefaultMaterial'] ?? false,
        rejectionReason: json['rejectionReason'],
        approvedAt: json['approvedAt'] != null
            ? DateTime.parse(json['approvedAt'])
            : null,
        approvedBy: json['approvedBy'],
      );
    }
    static RateFileMaterial empty() => const RateFileMaterial(
      id: '',
      rawMaterialName: '',
      MaterialName: '',
      normalizedMaterialName: '',
      normalizedMoc: '',
      uom: '',
      calculationCategory: '',
      designation: [],
      image: '',
      materialMasterId: '',
      availableVariants: [],
      approvalStatus: '',
      isDefaultMaterial: false,
      dynamicFields: [],
    );

  }

  class RateVariant {
    final String materialMasterId;
    final String mocId;
    final String moc;
    final String sizeRangeId;
    final String thicknessRangeId;
    final String floorId;
    final String floor;
    final String elevationId;
    final String elevation;
    final double rate;
    final String uom;
    final String remarks;
    final Map<String, dynamic>? sizeRange;
    final Map<String, dynamic>? thicknessRange;

    const RateVariant({
      required this.materialMasterId,
      required this.mocId,
      required this.moc,
      required this.sizeRangeId,
      required this.thicknessRangeId,
      required this.floorId,
      required this.floor,
      required this.elevationId,
      required this.elevation,
      required this.rate,
      required this.uom,
      required this.remarks,
      this.sizeRange,
      this.thicknessRange,
    });

    factory RateVariant.fromJson(Map<String, dynamic> json) {
      return RateVariant(
        materialMasterId: json['materialMasterId'] ?? '',
        mocId: json['mocId'] ?? '',
        moc: json['moc'] ?? '',
        sizeRangeId: json['sizeRangeId'] ?? '',
        thicknessRangeId: json['thicknessRangeId'] ?? '',
        floorId: json['floorId'] ?? '',
        floor: json['floor'] ?? '',
        elevationId: json['elevationId'] ?? '',
        elevation: json['elevation'] ?? '',
        rate: (json['rate'] ?? 0).toDouble(),
        uom: json['uom'] ?? '',
        remarks: json['remarks'] ?? '',
        sizeRange: json['sizeRange'] is Map ? Map<String, dynamic>.from(json['sizeRange']) : null,
        thicknessRange: json['thicknessRange'] is Map ? Map<String, dynamic>.from(json['thicknessRange']) : null,
      );
    }
  }

  class RateFileAnalysis {
    final String id;
    final String name;
    final String fileName;
    final String status;

    final Map<String, dynamic> company;
    final Map<String, dynamic> site;
    final Map<String, dynamic> uploadedBy;
    final List<RateFileMaterial> lineItems;
    final DetectedFields detectedFields;

    final DateTime uploadDate;

    const RateFileAnalysis({
      required this.id,
      required this.name,
      required this.fileName,
      required this.status,
      required this.company,
      required this.site,
      required this.uploadedBy,
      required this.lineItems,
      required this.detectedFields,
      required this.uploadDate,
    });

    factory RateFileAnalysis.fromJson(Map<String, dynamic> json) {
      return RateFileAnalysis(
        id: json['_id'] ?? '',
        name: json['name'] ?? '',
        fileName: json['fileName'] ?? '',
        status: json['status'] ?? '',
        company: _asMap(json['company']),
        site: _asMap(json['site']),
        uploadedBy: _asMap(json['uploadedBy']),
        lineItems: List<RateFileMaterial>.from(
          (json['lineItems'] ?? []).map(
                (x) => RateFileMaterial.fromJson(x),
          ),
        ),
        detectedFields: DetectedFields.fromJson(json['detectedFields']),
        uploadDate: DateTime.parse(
          json['uploadDate'] ?? DateTime.now().toString(),
        ),
      );
    }
    static Map<String, dynamic> _asMap(dynamic value) {
      if (value is Map<String, dynamic>) return value;
      if (value is String) return {'_id': value};
      return {};
    }

  }
  class DetectedFields {
    final bool hasFloor;
    final bool hasElevation;
    final bool hasMoc;
    final bool hasSize;
    final bool hasHP;
    final bool hasThickness;
    final bool hasWeight;
    final bool hasPower;
    final bool hasDiameter;

    final List<String> floors;
    final List<String> elevations;
    final List<String> mocs;
    final List<String> sizes;
    final List<String> thicknesses;
    final List<String> uoms;

    // ✅ NEW
    final List<NamedImage> mocsWithImages;
    final List<NamedImage> floorsWithImages;

    const DetectedFields({
      required this.hasFloor,
      required this.hasElevation,
      required this.hasMoc,
      required this.hasSize,
      required this.hasHP,
      required this.hasThickness,
      required this.hasWeight,
      required this.hasPower,
      required this.hasDiameter,
      required this.floors,
      required this.elevations,
      required this.mocs,
      required this.sizes,
      required this.thicknesses,
      required this.uoms,
      required this.mocsWithImages,
      required this.floorsWithImages,
    });

    factory DetectedFields.fromJson(Map<String, dynamic> json) {
      return DetectedFields(
        hasFloor: json['hasFloor'] ?? false,
        hasElevation: json['hasElevation'] ?? false,
        hasMoc: json['hasMoc'] ?? false,
        hasSize: json['hasSize'] ?? false,
        hasHP: json['hasHP'] ?? false,
        hasThickness: json['hasThickness'] ?? false,
        hasWeight: json['hasWeight'] ?? false,
        hasPower: json['hasPower'] ?? false,
        hasDiameter: json['hasDiameter'] ?? false,

        floors: List<String>.from(json['floors'] ?? const []),
        elevations: List<String>.from(json['elevations'] ?? const []),
        mocs: List<String>.from(json['mocs'] ?? const []),
        sizes: List<String>.from(json['sizes'] ?? const []),
        thicknesses: List<String>.from(json['thicknesses'] ?? const []),
        uoms: List<String>.from(json['uoms'] ?? const []),

        // ✅ NEW
        mocsWithImages: (json['mocsWithImages'] ?? const [])
            .map<NamedImage>((e) => NamedImage.fromJson(e))
            .toList(),

        floorsWithImages: (json['floorsWithImages'] ?? const [])
            .map<NamedImage>((e) => NamedImage.fromJson(e))
            .toList(),
      );
    }

    Map<String, dynamic> toJson() => {
      'hasFloor': hasFloor,
      'hasElevation': hasElevation,
      'hasMoc': hasMoc,
      'hasSize': hasSize,
      'hasHP': hasHP,
      'hasThickness': hasThickness,
      'hasWeight': hasWeight,
      'hasPower': hasPower,
      'hasDiameter': hasDiameter,
      'floors': floors,
      'elevations': elevations,
      'mocs': mocs,
      'sizes': sizes,
      'thicknesses': thicknesses,
      'uoms': uoms,
      'mocsWithImages': mocsWithImages.map((e) => e.toJson()).toList(),
      'floorsWithImages': floorsWithImages.map((e) => e.toJson()).toList(),
    };
  }

  class NamedImage {
    final String name;
    final String image;

    const NamedImage({
      required this.name,
      required this.image,
    });

    factory NamedImage.fromJson(Map<String, dynamic> json) {
      return NamedImage(
        name: json['name'] ?? '',
        image: json['image'] ?? '',
      );
    }

    Map<String, dynamic> toJson() => {
      'name': name,
      'image': image,
    };
  }
  class DynamicField {
    final String key;
    final String label;
    final dynamic value;
    final String unit;
    final String displayText;

    const DynamicField({
      required this.key,
      required this.label,
      this.value,
      required this.unit,
      required this.displayText,
    });
    factory DynamicField.fromJson(Map<String, dynamic> json) {
      return DynamicField(
        key: json['key'] ?? '',
        label: json['label'] ?? '',
        value: json['value']?.toString() ?? '',
        unit: json['unit'] ?? '',
        displayText: json['displayText'] ?? '',
      );
    }
    DynamicField copy() {
      return DynamicField(
        key: key,
        label: label,
        unit: unit,
        displayText: displayText,
      );
    }


    /// ⭐ ALWAYS USE THIS FOR API
    Map<String, dynamic> toJson() => {
      'key': key,
      'label': label,
      'value': value,
      'unit': unit,
      'displayText':
      displayText.isNotEmpty ? displayText : (value?.toString() ?? ''),
    };

    /// ⭐ SAFE IMMUTABLE UPDATE
    DynamicField copyWith({
      String? key,
      String? label,
      dynamic value,
      String? unit,
      String? displayText,
    }) {
      final newValue = value ?? this.value;

      return DynamicField(
        key: key ?? this.key,
        label: label ?? this.label,
        value: newValue,
        unit: unit ?? this.unit,
        displayText: displayText ??
            (newValue == null ? "" : newValue.toString()),
      );
    }
  }


