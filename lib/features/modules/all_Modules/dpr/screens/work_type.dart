// work_type.dart or at the top of your file
class WorkType {
  static const String mechanical = 'mechanical_work';
  static const String insulation = 'insulation_work';

  static bool isValid(String? type) {
    return type == mechanical || type == insulation;
  }
}