import 'package:flutter/material.dart';

enum WorkType {
  mechanical,
  insulation,
  fabrication,
  structure,
  civil,
  roofing;

  String get apiValue {
    switch (this) {
      case WorkType.mechanical:
        return 'mechanical_work';
      case WorkType.insulation:
        return 'insulation_work';
      case WorkType.structure:
        return 'erection_work';
      case WorkType.civil:
        return 'civil_work';
      case WorkType.roofing:
        return 'roofing_work';
      case WorkType.fabrication:
        return 'fabrication_work';
    }
  }

  String get displayName {
    switch (this) {
      case WorkType.mechanical:
        return 'Mechanical Work';
      case WorkType.insulation:
        return 'Insulation Work';
      case WorkType.structure:
        return 'Structural Erection';
      case WorkType.civil:
        return 'Civil Work';
      case WorkType.roofing:
        return 'Roofing Work';
      case WorkType.fabrication:
        return 'Structural Fabrication';
    }
  }

  Color get accentColor {
    switch (this) {
      case WorkType.mechanical:
        return const Color(0xFF2196F3);
      case WorkType.insulation:
        return const Color(0xFF4CAF50);
      case WorkType.structure:
        return const Color(0xFFFF9800);
      case WorkType.civil:
        return const Color(0xFF795548);
      case WorkType.roofing:
        return const Color(0xFF009688);
      case WorkType.fabrication:
        return const Color(0xFF607D8B);
    }
  }

  String get imagePath {
    switch (this) {
      case WorkType.mechanical:
        return 'assets/images/mechanical_work_card.png';
      case WorkType.insulation:
        return 'assets/images/insulation_work_card.png';
      case WorkType.structure:
        return 'assets/images/struc.png';
      case WorkType.civil:
        return 'assets/images/mech.webp';
      case WorkType.roofing:
        return 'assets/images/mech.webp';
      case WorkType.fabrication:
        return 'assets/images/mech.webp';
    }
  }

  String get subtitle {
    switch (this) {
      case WorkType.mechanical:
        return 'HVAC, Plumbing & Fire';
      case WorkType.insulation:
        return 'Thermal & Acoustic';
      case WorkType.structure:
        return 'Heavy Steel Erection';
      case WorkType.civil:
        return 'Foundation & Concrete';
      case WorkType.roofing:
        return 'Sheeting & Cladding';
      case WorkType.fabrication:
        return 'Structure Manufacturing';
    }
  }

  bool get hasDprSetup => true;
  bool get hasRateCard =>
      this == WorkType.mechanical ||
      this == WorkType.insulation ||
      this == WorkType.roofing ||
      this == WorkType.structure ||
      this == WorkType.fabrication;
  bool get hasBOQ =>
      this == WorkType.structure ||
      this == WorkType.civil ||
      this == WorkType.fabrication;

  static WorkType? fromApiValue(String? value) {
    switch (value) {
      case 'mechanical_work':
        return WorkType.mechanical;
      case 'insulation_work':
        return WorkType.insulation;
      case 'structure_work':
      case 'erection_work':
        return WorkType.structure;
      case 'civil_work':
        return WorkType.civil;
      case 'roofing_work':
        return WorkType.roofing;
      case 'fabrication_work':
        return WorkType.fabrication;
      default:
        return null;
    }
  }
}
