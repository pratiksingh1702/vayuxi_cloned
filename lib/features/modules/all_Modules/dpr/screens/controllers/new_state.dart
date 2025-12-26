enum MaterialLoadState { idle, loading, loaded, error }

class AddDprState {
  final List<Map<String, dynamic>> availableMaterials;
  final List<Map<String, dynamic>> selectedPipingMaterials;
  final List<Map<String, dynamic>> selectedEquipmentMaterials;
  final List<Map<String, dynamic>> cardInputs;
  final Map<String, String> validationErrors;

  final bool isSubmitting;
  final bool isLoadingMaterials;
  final bool isEditingName;

  final String dprName;
  final String moc;
  final String floor;
  final String size;
  final String plant;

  final bool pipeFittingOn;
  final bool equipmentOn;

  final MaterialLoadState pipingLoadState;
  final MaterialLoadState equipmentLoadState;

  final String? mechanicalId;

  const AddDprState({
    this.availableMaterials = const [],
    this.selectedPipingMaterials = const [],
    this.selectedEquipmentMaterials = const [],
    this.cardInputs = const [],
    this.validationErrors = const {},
    this.isSubmitting = false,
    this.isLoadingMaterials = false,
    this.isEditingName = true,
    this.dprName = 'New DPR Entry',
    this.moc = '',
    this.floor = '',
    this.size = '',
    this.plant = '',
    this.pipeFittingOn = false,
    this.equipmentOn = false,
    this.pipingLoadState = MaterialLoadState.idle,
    this.equipmentLoadState = MaterialLoadState.idle,
    this.mechanicalId,
  });

  /// ✅ Manual copyWith (SAFE)
  AddDprState copyWith({
    List<Map<String, dynamic>>? availableMaterials,
    List<Map<String, dynamic>>? selectedPipingMaterials,
    List<Map<String, dynamic>>? selectedEquipmentMaterials,
    List<Map<String, dynamic>>? cardInputs,
    Map<String, String>? validationErrors,
    bool? isSubmitting,
    bool? isLoadingMaterials,
    bool? isEditingName,
    String? dprName,
    String? moc,
    String? floor,
    String? size,
    String? plant,
    bool? pipeFittingOn,
    bool? equipmentOn,
    MaterialLoadState? pipingLoadState,
    MaterialLoadState? equipmentLoadState,
    String? mechanicalId,
  }) {
    return AddDprState(
      availableMaterials: availableMaterials ?? this.availableMaterials,
      selectedPipingMaterials:
      selectedPipingMaterials ?? this.selectedPipingMaterials,
      selectedEquipmentMaterials:
      selectedEquipmentMaterials ?? this.selectedEquipmentMaterials,
      cardInputs: cardInputs ?? this.cardInputs,
      validationErrors: validationErrors ?? this.validationErrors,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isLoadingMaterials: isLoadingMaterials ?? this.isLoadingMaterials,
      isEditingName: isEditingName ?? this.isEditingName,
      dprName: dprName ?? this.dprName,
      moc: moc ?? this.moc,
      floor: floor ?? this.floor,
      size: size ?? this.size,
      plant: plant ?? this.plant,
      pipeFittingOn: pipeFittingOn ?? this.pipeFittingOn,
      equipmentOn: equipmentOn ?? this.equipmentOn,
      pipingLoadState: pipingLoadState ?? this.pipingLoadState,
      equipmentLoadState: equipmentLoadState ?? this.equipmentLoadState,
      mechanicalId: mechanicalId ?? this.mechanicalId,
    );
  }
}
