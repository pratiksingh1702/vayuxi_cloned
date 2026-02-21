import 'package:flutter_riverpod/flutter_riverpod.dart';

class MaterialTypes {

  static const List<String> pipingMaterials = [
    'PIPE',
    'ELBOW 90°',
    'ELBOW 45°',
    'TEE',
    'REDUCER',
    'CAP',
    'INSULATED FLANGE PAIR (REMOVABLE)',
    'INSULATED FLANGE VALVE (REMOVABLE)',
    'INSULATED FLANGE PAIR (FIXED)',
    'INSULATED FLANGE VALVE (FIXED)',
    'INSULATED WELDED VALVE (FIXED)',
  ];

  static const List<String> equipmentMaterials = [
    'SHELL',
    'DOME',
    'FLAT END',
    'CONE END',
    'REDUCER',
    'FLANGE BOX-1',
    'FLANGE BOX-2',
    'FLANGE BOX-3',
    'FLANGE BOX-4',
    'NOZZLE',
    'PATCH',
  ];

  static const Map<String, String> uomMapping = {
    'PIPE': 'MTR',
    'ELBOW 90°': 'NOS',
    'ELBOW 45°': 'NOS',
    'TEE': 'NOS',
    'REDUCER': 'NOS',
    'CAP': 'NOS',
    'INSULATED FLANGE PAIR (REMOVABLE)': 'NOS',
    'INSULATED FLANGE VALVE (REMOVABLE)': 'NOS',
    'INSULATED FLANGE PAIR (FIXED)': 'NOS',
    'INSULATED FLANGE VALVE (FIXED)': 'NOS',
    'INSULATED WELDED VALVE (FIXED)': 'NOS',
  };

  static bool isPipingMaterial(String name) {
    return pipingMaterials.contains(name);
  }

  static bool isEquipmentMaterial(String name) {
    return equipmentMaterials.contains(name);
  }

  static String getDefaultUom(String materialName) {
    return uomMapping[materialName] ?? '';
  }
}
final dprSizeProvider = StateProvider<String>((ref) => "");
