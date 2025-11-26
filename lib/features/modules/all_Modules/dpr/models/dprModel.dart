import 'package:untitled2/features/modules/all_Modules/dpr/models/pipingModel.dart';
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
  });

  factory DprModel.fromJson(Map<String, dynamic> json) {
    try {
      // Helper function to safely parse strings and clean them
      String safeString(dynamic value) {
        if (value == null) return '';
        if (value is String) return value.trim();
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
        createdAt: DateTime.parse(safeString(json['createdAt'])),
        updatedAt: DateTime.parse(safeString(json['updatedAt'])),
      );
    } catch (e, stack) {
      print('❌ Error parsing DprModel: $e');
      print('❌ Stack trace: $stack');
      print('❌ Problematic JSON: $json');
      rethrow;
    }
  }
}