import '../pipingModel.dart';

class PipingMaterialsData {
  static PipingItem _base({
    required String id,
    required String materialName,
    required String image,
    required String uom,
    required String calculationCategory,
    double actualRate = 0,
  }) {
    return PipingItem(
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
      floor: '',
      elevation: '',
      actualRate: actualRate,
      rate: 0,
      moc: 'ms',
      size: 'ALL',
      location: 'sector 23',
      plant: 'plant',
      designation: const ['piping'],
      calculationCategory: calculationCategory,
      dynamicFields: const [],
      remarks: '',
      isFromRateFile: false,
    );
  }
  static final List<PipingItem> materials = [

    _base(
      id: '6950b367d5e7fb761548d914',
      materialName: 'Pipe Erection / Fittings',
      image: 'assets/images/piping/pipe_erection_fittings.webp',
      uom: 'MTR',
      calculationCategory: 'B',
    ),

    _base(
      id: '6950b367d5e7fb761548d915',
      materialName: 'Joints Welding / Fitting',
      image: 'assets/images/piping/joints_welding_fitting.webp',
      uom: 'NOS',
      calculationCategory: 'B',
    ),

    _base(
      id: '6950b367d5e7fb761548d916',
      materialName: 'Elbow 90 Joint / Fitting',
      image: 'assets/images/piping/elbow_90_joint_fitting.webp',
      uom: 'NOS',
      calculationCategory: 'B',
    ),

    _base(
      id: '6950b367d5e7fb761548d917',
      materialName: 'Flange Joints / Fitting',
      image: 'assets/images/piping/flange_joints_fitting.webp',
      uom: 'NOS',
      calculationCategory: 'B',
    ),

    _base(
      id: '6950b367d5e7fb761548d918',
      materialName: 'Tee Joints / Fitting',
      image: 'assets/images/piping/tee_joints_fitting.webp',
      uom: 'NOS',
      calculationCategory: 'B',
    ),

    _base(
      id: '6950b367d5e7fb761548d919',
      materialName: 'Reducer Joints / Fitting',
      image: 'assets/images/piping/reducer_joints_fitting.webp',
      uom: 'NOS',
      calculationCategory: 'B',
    ),

    _base(
      id: '6950b367d5e7fb761548d91a',
      materialName: 'Valve Fitting',
      image: 'assets/images/piping/valve_fitting.webp',
      uom: 'NOS',
      calculationCategory: 'B',
    ),

    _base(
      id: '6950b367d5e7fb761548d91b',
      materialName: 'Blind Fabrication And Fitting',
      image: 'assets/images/piping/blind_fabrication_and_fitting.webp',
      uom: 'NOS',
      calculationCategory: 'B',
      actualRate: 566,
    ),

    _base(
      id: '6950b367d5e7fb761548d91c',
      materialName: 'U Clamp Fitting',
      image: 'assets/images/piping/u_clamp_fitting.webp',
      uom: 'NOS',
      calculationCategory: 'A',
    ),

    _base(
      id: '6950b367d5e7fb761548d91d',
      materialName: 'Support Fabrication And Erection',
      image: 'assets/images/piping/support_fabrication_and_erection.webp',
      uom: 'NOS',
      calculationCategory: 'A',
      actualRate: 566,
    ),

    _base(
      id: '6950b367d5e7fb761548d91e',
      materialName: 'Miter Fabrication',
      image: 'assets/images/piping/miter_fabrication.webp',
      uom: 'NOS',
      calculationCategory: 'B',
    ),

    _base(
      id: '6950b367d5e7fb761548d91f',
      materialName: 'Plate Cutting',
      image: 'assets/images/piping/plate_cutting.webp',
      uom: 'RMT',
      calculationCategory: 'A',
    ),

    _base(
      id: '6950b367d5e7fb761548d920',
      materialName: 'Plate Welding',
      image: 'assets/images/piping/plate_welding.webp',
      uom: 'RMT',
      calculationCategory: 'A',
    ),

    _base(
      id: '6950b367d5e7fb761548d921',
      materialName: 'Shoe Support Fabrication And Erection',
      image: 'assets/images/piping/shoe_support_fabrication_and_erection.webp',
      uom: 'NOS',
      calculationCategory: 'B',
      actualRate: 566,
    ),

    _base(
      id: '6950b367d5e7fb761548d922',
      materialName: 'Shoe Support Dismantling',
      image: 'assets/images/piping/shoe_support_dismantling.webp',
      uom: 'NOS',
      calculationCategory: 'B',
    ),

    _base(
      id: '6950b367d5e7fb761548d923',
      materialName: 'Pneumatic Testing',
      image: 'assets/images/piping/pneumatic_testing.webp',
      uom: 'RMT',
      calculationCategory: 'A',
    ),
  ];
}