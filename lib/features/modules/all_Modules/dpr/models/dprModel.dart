import 'dart:io';

import 'package:untitled2/features/modules/all_Modules/dpr/models/pipingModel.dart';
import 'package:untitled2/features/modules/all_Modules/dpr/models/rate_file_models.dart';
import 'package:untitled2/features/modules/all_Modules/team/model/teamModel.dart';

import 'equipmentModel.dart';

class DprModel {
  final String? id;
  final String siteId;
  final String teamId;

  final String company;
  final String dprName;
  final String plant;
  final String location;
  final String size;
  final String moc;
  final List<PipingItem> piping;
  final List<EquipmentItem> equipment;
  final List<String> designation;
  final DateTime createdAt;
  final DateTime date;
  final DateTime updatedAt;

  DprModel({
    this.id,
    required this.siteId,
    required this.teamId,
    required this.company,
    required this.dprName,
    required this.plant,
    required this.location,
    required this.size,
    required this.moc,
    required this.piping,
    required this.equipment,
    required this.designation,
    required this.createdAt,
    required this.updatedAt,
    required this.date,
  });

  factory DprModel.fromJson(Map<String, dynamic> json) {
    try {
      // Helper function to safely parse strings and clean them
      String safeString(dynamic value) {
        if (value == null) return '';
        if (value is String) return value.trim();
        if (value is Map && value.containsKey('_id')) {
          return safeString(value['_id']);
        }
        return value.toString().trim();
      }

      // Helper function to safely parse lists
      List<T> safeList<T>(dynamic value, T Function(dynamic) converter) {
        if (value == null) return [];
        if (value is List) {
          return value.where((item) => item != null).map(converter).toList();
        }
        return [];
      }

      // Parse designation - handle both string and array formats
      List<String> parseDesignation(dynamic value) {
        if (value == null) return [];
        if (value is List) {
          return value.whereType<String>().toList();
        }
        if (value is String) {
          return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        }
        return [];
      }

      // Helper function to safely parse dates
      DateTime parseDate(dynamic value) {
        if (value == null || value == "") return DateTime.now();
        try {
          return DateTime.parse(safeString(value));
        } catch (e) {
          print("❌ Date parsing error: $e for value: $value");
          return DateTime.now();
        }
      }

      return DprModel(
        id: safeString(json['_id']),
        siteId: safeString(json['siteId']),
        teamId: safeString(json['teamId']),

        company: safeString(json['company']),
        dprName: safeString(json['dprName']),
        plant: safeString(json['plant']),
        location: safeString(json['location']),
        size: safeString(json['size']),
        moc: safeString(json['moc']),
        piping: safeList(json['piping'], (item) {
          if (item is Map<String, dynamic>) {
            return PipingItem.fromJson(item);
          }
          return PipingItem.empty();
        }),
        equipment: safeList(json['equipment'], (item) {
          if (item is Map<String, dynamic>) {
            return EquipmentItem.fromJson(item);
          }
          return EquipmentItem.empty();
        }),
        designation: parseDesignation(json['designation']),
        date: parseDate(json['date']),
        createdAt: parseDate(json['createdAt']),
        updatedAt: parseDate(json['updatedAt']),
      );
    } catch (e, stack) {
      print('❌ Error parsing DprModel: $e');
      print('❌ Stack trace: $stack');
      print('❌ Problematic JSON: $json');
      rethrow;
    }
  }
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'siteId': siteId,
      'teamId': teamId,
      'company': company,
      'dprName': dprName,
      'plant': plant,
      'location': location,
      'size': size,
      'moc': moc,
      'piping': piping.map((e) => e.toJson()).toList(),
      'equipment': equipment.map((e) => e.toJson()).toList(),
      'designation': designation,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }


}
class MaterialEditResult {
  final String name;
  final File? imageFile;
  final String? imageUrl;
  final String uom;
  final List<DynamicField> fields;
  final String? categoryId;          // ← ADD THIS

  MaterialEditResult({
    required this.name,
    this.imageFile,
    this.imageUrl,
    required this.uom,
    required this.fields,
    this.categoryId,               // ← ADD THIS
  });
}