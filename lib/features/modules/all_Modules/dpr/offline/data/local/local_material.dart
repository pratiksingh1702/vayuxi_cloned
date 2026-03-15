import 'dart:convert';

import 'package:isar/isar.dart';

import '../../../dpr_insu/model/eqip_insu.dart';
import '../../../dpr_insu/model/piping_insu.dart';

part 'local_material.g.dart';

@collection
class LocalMaterial {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String? serverId;

  /// SCOPE

  late String siteId;
  late String domain;       // insulation | mechanical
  late String designation;  // piping | equipment


  int qty = 0;
  double length = 0;
  String? size;
  String? sizeUom;
  String remarks = '';
  double circumference = 0;
  double zHeight = 0;
  String? materialDataJson;

  /// DATA
  late String name;
  String? uom;
  List<String> images = [];

  /// SYNC
  bool isDirty = false;
  bool isDeleted = false;
  DateTime updatedAt = DateTime.now();
}

extension LocalMaterialMapper on LocalMaterial {

  PipingMaterial toPiping() {
    if (materialDataJson != null && materialDataJson!.isNotEmpty) {
      return PipingMaterial.fromJson(
        jsonDecode(materialDataJson!),
      );
    }

    return PipingMaterial(
      id: serverId ?? id.toString(),
      name: name,
      image: images,
      uom: uom ?? '',
      size: '',
      sizeUom: 'inch',
      qty: 0,
      length: 0,
      circumference: 0,
      circumference1: 0,
      circumference2: 0,
      zHeight: 0,
      gSlantHeight: 0,
      constant: 0,
      totalArea: 0,
      diameterA3: 0,
      diameterB3: 0,
      diameterA2: 0,
      diameterB2: 0,
      diameterA1: 0,
      diameterB1: 0,
      circumferenceFinal: 0,
      layer1Area: 0,
      layer2Area: 0,
      layer3Area: 0,
      circumference3: 0,
      circumference2Calc: 0,
      circumference1Calc: 0,
      o3: 0,
      o2: 0,
      o1: 0,
      remarks: '',
    );
  }

  EquipmentMaterial toEquipment() {
    if (materialDataJson != null && materialDataJson!.isNotEmpty) {
      return EquipmentMaterial.fromJson(
        jsonDecode(materialDataJson!),
      );
    }

    return EquipmentMaterial(
      id: serverId ?? id.toString(),
      name: name,
      image: images,
      uom: uom ?? '',
      qty: 0,
      length: 0,
      circumference: 0,
      circumference1: 0,
      circumference2: 0,
      zHeight: 0,
      gSlantHeight: 0,
      constant: 0,
      totalArea: 0,
      diameterA3: 0,
      diameterB3: 0,
      diameterA2: 0,
      diameterB2: 0,
      diameterA1: 0,
      diameterB1: 0,
      circumferenceFinal: 0,
      layer1Area: 0,
      layer2Area: 0,
      layer3Area: 0,
      circumference3: 0,
      circumference2Calc: 0,
      circumference1Calc: 0,
      o3: 0,
      o2: 0,
      o1: 0,
      remarks: '',
    );
  }
}