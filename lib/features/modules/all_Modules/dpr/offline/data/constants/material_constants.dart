enum MaterialDomain {
  insulation,
  mechanical,
}

enum MaterialDesignation {
  piping,
  equipment,
}

extension DomainX on MaterialDomain {
  String get key => name;
}

extension DesignationX on MaterialDesignation {
  String get key => name;
}
