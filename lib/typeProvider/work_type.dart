enum WorkType {
  mechanical,
  insulation,
  structure,
  peb;

  String get apiValue {
    switch (this) {
      case WorkType.mechanical:
        return 'mechanical_work';
      case WorkType.insulation:
        return 'insulation_work';
      case WorkType.structure:
        return 'structure_work';
      case WorkType.peb:
        return 'peb_work';
    }
  }

  String get displayName {
    switch (this) {
      case WorkType.mechanical:
        return 'Mechanical Work';
      case WorkType.insulation:
        return 'Insulation Work';
      case WorkType.structure:
        return 'Structure Work';
      case WorkType.peb:
        return 'PEB Work';
    }
  }

  bool get hasDprSetup => this != WorkType.structure;
  bool get hasRateCard => this != WorkType.structure;
  bool get hasBOQ => this == WorkType.structure;

  static WorkType? fromApiValue(String? value) {
    switch (value) {
      case 'mechanical_work':
        return WorkType.mechanical;
      case 'insulation_work':
        return WorkType.insulation;
      case 'structure_work':
        return WorkType.structure;
      case 'peb_work':
        return WorkType.peb;
      default:
        return null;
    }
  }
}
