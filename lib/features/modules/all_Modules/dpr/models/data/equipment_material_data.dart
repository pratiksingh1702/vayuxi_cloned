import '../equipmentModel.dart';

class EquipmentMaterialsData {
  static EquipmentItem _base({
    required String id,
    required String materialName,
    required String image,
    required String uom,
    required String calculationCategory,
    double actualRate = 0,
  }) {
    return EquipmentItem(
      id: id,
      rawMaterialName: materialName,
      normalizedMaterialName: materialName.toLowerCase().trim(),
      materialName: materialName,
      image: image,
      qty: 1,
      uom: uom,
      length: 0,
      rmt: 0,
      diameter: 0,
      weight: 0,
      power: 0,
      actualRate: actualRate,
      rate: 0,
      moc: 'ms',
      size: 'ALL',
      location: 'sector 23',
      plant: 'plant',
      designation: const ['equipment'],
      calculationCategory: calculationCategory,
      dynamicFields: const [],
      remarks: '',
      isFromRateFile: false,
    );
  }
  static final List<EquipmentItem> materials = [

    _base(
      id: '6950b367d5e7fb761548d927',
      materialName: 'Reactor,Tank,Equipment Erection & Alignment',
      image: 'assets/images/equipment/reactortankequipment_erection_alignment.webp',
      uom: 'TON',
      calculationCategory: 'A',
    ),

    _base(
      id: '6950b367d5e7fb761548d928',
      materialName: 'Reactor,Tank,Equipment Dismantling',
      image: 'assets/images/equipment/reactortankequipment_dismantling.webp',
      uom: 'TON',
      calculationCategory: 'A',
    ),

    _base(
      id: '6950b367d5e7fb761548d929',
      materialName: 'HDPE Scrubber Erection & Alignment',
      image: 'assets/images/equipment/hdpe_scrubber_erection_alignment.webp',
      uom: 'DIAMETER',
      calculationCategory: 'C',
    ),

    _base(
      id: '6950b367d5e7fb761548d92a',
      materialName: 'HDPE Scrubber Dismantling',
      image: 'assets/images/equipment/hdpe_scrubber_dismantling.webp',
      uom: 'DIAMETER',
      calculationCategory: 'C',
    ),

    _base(
      id: '6950b367d5e7fb761548d92b',
      materialName: 'Condensor Erection & Alignment',
      image: 'assets/images/equipment/condensor_erection_alignment.webp',
      uom: 'M2',
      calculationCategory: 'B',
    ),

    _base(
      id: '6950b367d5e7fb761548d92c',
      materialName: 'Condensor Dismantling',
      image: 'assets/images/equipment/condensor_dismantling.webp',
      uom: 'M2',
      calculationCategory: 'B',
    ),

    _base(
      id: '6950b367d5e7fb761548d92d',
      materialName: 'Pump/Motor/Frame Position Erection',
      image: 'assets/images/equipment/pumpmotorframe_position_erection.webp',
      uom: 'HP',
      calculationCategory: 'A',
    ),

    _base(
      id: '6950b367d5e7fb761548d92e',
      materialName: 'Pump/Motor/Frame Position Dismantling',
      image: 'assets/images/equipment/pumpmotorframe_position_dismantling.webp',
      uom: 'HP',
      calculationCategory: 'A',
    ),

    _base(
      id: '6950b367d5e7fb761548d92f',
      materialName: 'Pump/Motor/Frame Fabrication',
      image: 'assets/images/equipment/pumpmotorframe_fabrication.webp',
      uom: 'HP',
      calculationCategory: 'A',
    ),

    _base(
      id: '6950b367d5e7fb761548d930',
      materialName: 'Gear Box Erection',
      image: 'assets/images/equipment/gear_box_erection.webp',
      uom: 'HP',
      calculationCategory: 'A',
    ),

    _base(
      id: '6950b367d5e7fb761548d931',
      materialName: 'Gear Box Dismantling',
      image: 'assets/images/equipment/gear_box_dismantling.webp',
      uom: 'HP',
      calculationCategory: 'A',
    ),

    _base(
      id: '6950b367d5e7fb761548d932',
      materialName: 'PPERP Blower Alignment & Erection',
      image: 'assets/images/equipment/pperp_blower_alignment_erection.webp',
      uom: 'NOS',
      calculationCategory: 'A',
    ),

    _base(
      id: '6950b367d5e7fb761548d933',
      materialName: 'PPERP Blower Dismantling',
      image: 'assets/images/equipment/pperp_blower_dismantling.webp',
      uom: 'NOS',
      calculationCategory: 'A',
    ),

    _base(
      id: '6950b367d5e7fb761548d934',
      materialName: 'Structure Fabrication & Erection',
      image: 'assets/images/equipment/structure_fabrication_erection.webp',
      uom: 'KG',
      calculationCategory: 'A',
    ),

    _base(
      id: '6950b367d5e7fb761548d935',
      materialName: 'Structure Dismantling',
      image: 'assets/images/equipment/structure_dismantling.webp',
      uom: 'KG',
      calculationCategory: 'A',
    ),
  ];
}